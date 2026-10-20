// Busca unificada do CGFLIX (Etapa 1C): o mesmo título ou a mesma pessoa vindo de vários
// servidores (o Jellyfin do CGFLIX e os Plex compartilhados com a conta) vira UM cartão só.
//
// Regras (sem widgets, para dar para testar):
// - Títulos: juntam quando batem os IDs externos (tmdb/imdb/tvdb nos GUIDs do Plex e nos
//   ProviderIds do Jellyfin, ou o mesmo guid `plex://` entre servidores Plex). Sem ID em comum,
//   juntam por título normalizado (sem acento/caixa/pontuação) + ano + tipo. Dois itens com
//   IDs do mesmo provedor e valores diferentes NUNCA juntam (homônimos e refilmagens).
// - Pessoas: por nome normalizado (a busca de pessoas do Plex e do Jellyfin não traz ID externo).
// - Fonte que abre: (1) servidor CGFLIX (Jellyfin principal), (2) onde já há progresso,
//   (3) maior resolução, (4) quem respondeu primeiro.
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../../media/media_backend.dart';
import '../cgflix_defaults.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_person.dart';
import '../../media/media_version.dart';
import '../../media/search_hit.dart';
import '../../services/data_aggregation_service.dart';
import '../../utils/external_ids.dart';
import '../../utils/search_relevance.dart';

// ---------------------------------------------------------------------------
// Normalização

final _marks = RegExp(r'\p{M}+', unicode: true);
final _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Minúsculas, sem acento e sem pontuação; espaços simples. "Ação: O Filme!" → "acao o filme".
String cgflixSearchNormalize(String? text) {
  if (text == null) return '';
  final decomposed = unorm.nfd(text.toLowerCase()).replaceAll(_marks, '');
  return decomposed.replaceAll(_separators, ' ').trim();
}

// ---------------------------------------------------------------------------
// Identidade de um título

/// Tipo usado na chave: filme e série nunca se juntam, mesmo com o mesmo nome.
String _kindKey(MediaItem item) => switch (item.kind) {
  MediaKind.movie => 'movie',
  MediaKind.show => 'show',
  MediaKind.season => 'season',
  MediaKind.episode => 'episode',
  MediaKind.collection => 'collection',
  final other => other.id,
};

/// IDs externos do item, por provedor (`tmdb` → `123`). O tipo entra na chave porque o
/// tmdb de filme e o de série são numerações diferentes.
Map<String, String> cgflixExternalKeys(MediaItem item) {
  final keys = <String, String>{};
  final kind = _kindKey(item);
  void addIds(ExternalIds ids) {
    if (ids.imdb case final imdb?) keys['imdb'] = imdb;
    if (ids.tmdb case final tmdb?) keys['tmdb'] = '$kind:$tmdb';
    if (ids.tvdb case final tvdb?) keys['tvdb'] = '$kind:$tvdb';
  }

  final guid = item.guid;
  if (guid != null && guid.startsWith('plex://')) keys['plex'] = guid;
  if (guid != null) addIds(ExternalIds.fromLegacyPlexGuid(guid));
  final raw = item.raw;
  final providerIds = raw?['ProviderIds'];
  if (providerIds is Map) addIds(ExternalIds.fromJellyfinProviderIds(providerIds.cast<String, Object?>()));
  final guids = raw?['Guid'];
  if (guids is List) addIds(ExternalIds.fromGuids(guids));
  return keys;
}

/// Chave de quem não tem ID em comum: título normalizado + ano + tipo. Episódios e
/// temporadas usam a série e os números (o título do episódio se repete entre séries).
String cgflixTitleKey(MediaItem item) {
  final kind = _kindKey(item);
  switch (item.kind) {
    case MediaKind.episode:
      return '$kind|${cgflixSearchNormalize(item.grandparentTitle)}|${item.parentIndex}|${item.index}';
    case MediaKind.season:
      return '$kind|${cgflixSearchNormalize(item.parentTitle ?? item.grandparentTitle)}|${item.index}';
    case MediaKind.collection:
      return '$kind|${cgflixSearchNormalize(item.title)}';
    default:
      return '$kind|${cgflixSearchNormalize(item.title)}|${item.year ?? ''}';
  }
}

class _Identity {
  _Identity(MediaItem item) : external = cgflixExternalKeys(item), title = cgflixTitleKey(item);
  final Map<String, String> external;
  final String title;

  bool sharesIdWith(_Identity other) =>
      external.entries.any((e) => other.external[e.key] != null && other.external[e.key] == e.value);

  /// Mesmo provedor com valores diferentes: são obras diferentes, não junta nunca.
  bool conflictsWith(_Identity other) =>
      external.entries.any((e) => other.external[e.key] != null && other.external[e.key] != e.value);
}

// ---------------------------------------------------------------------------
// Escolha da fonte

/// Altura da melhor versão (0 quando o servidor não informou).
int _bestHeight(MediaItem item) {
  var best = 0;
  for (final MediaVersion version in item.mediaVersions ?? const <MediaVersion>[]) {
    final height = version.resolutionHeight;
    if (height != null && height > best) best = height;
  }
  return best;
}

/// 0 = Jellyfin (o servidor principal do CGFLIX), 1 = servidor chamado "CGFLIX", 2 = os outros.
int cgflixServerRank(MediaItem item) {
  if (item.backend == MediaBackend.jellyfin) return 0;
  if (cgflixSearchNormalize(item.serverName) == 'cgflix') return 1;
  return 2;
}

bool _hasProgress(MediaItem item) =>
    item.hasActiveProgress || (item.viewOffsetMs ?? 0) > 0 || (item.viewedLeafCount ?? 0) > 0 || item.isWatched;

/// Ordena as fontes de um mesmo título da preferida para a última (ordem estável:
/// empate fica com quem respondeu primeiro).
List<MediaItem> cgflixOrderSources(List<MediaItem> sources) {
  final indexed = [for (var i = 0; i < sources.length; i++) (i, sources[i])];
  indexed.sort((a, b) {
    final byServer = cgflixServerRank(a.$2).compareTo(cgflixServerRank(b.$2));
    if (byServer != 0) return byServer;
    final byProgress = (_hasProgress(b.$2) ? 1 : 0).compareTo(_hasProgress(a.$2) ? 1 : 0);
    if (byProgress != 0) return byProgress;
    final byResolution = _bestHeight(b.$2).compareTo(_bestHeight(a.$2));
    if (byResolution != 0) return byResolution;
    return a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

// ---------------------------------------------------------------------------
// Agrupamento

/// Um cartão da busca: [best] abre e é desenhado; [sources] = todas as cópias, a melhor primeiro.
class CgflixTitleGroup {
  CgflixTitleGroup(List<MediaItem> sources) : sources = cgflixOrderSources(sources);
  final List<MediaItem> sources;
  MediaItem get best => sources.first;
}

class CgflixPersonGroup {
  CgflixPersonGroup(List<MediaPerson> people) : people = _orderPeople(people);
  final List<MediaPerson> people;
  MediaPerson get best => people.first;

  /// Quem tem foto vem antes; entre eles, o Jellyfin do CGFLIX; empate = quem respondeu primeiro.
  static List<MediaPerson> _orderPeople(List<MediaPerson> people) {
    int rank(MediaPerson p) => (p.thumbPath == null ? 2 : 0) + (p.backend == MediaBackend.jellyfin ? 0 : 1);
    final indexed = [for (var i = 0; i < people.length; i++) (i, people[i])];
    indexed.sort((a, b) {
      final byRank = rank(a.$2).compareTo(rank(b.$2));
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
    return [for (final entry in indexed) entry.$2];
  }
}

/// Junta as cópias do mesmo título. Os grupos saem na ordem em que o primeiro membro
/// apareceu (a ordem dos servidores/relevância de quem chamou é preservada).
List<CgflixTitleGroup> cgflixGroupTitles(List<MediaItem> items) {
  final groups = <({List<MediaItem> items, List<_Identity> ids})>[];
  for (final item in items) {
    final identity = _Identity(item);
    ({List<MediaItem> items, List<_Identity> ids})? target;
    for (final group in groups) {
      if (group.ids.any(identity.conflictsWith)) continue;
      final sameId = group.ids.any(identity.sharesIdWith);
      final sameTitle = group.ids.any((other) => other.title == identity.title);
      if (sameId || sameTitle) {
        target = group;
        break;
      }
    }
    if (target == null) {
      groups.add((items: [item], ids: [identity]));
    } else {
      // A mesma cópia (mesma chave global) não entra duas vezes.
      if (target.items.any((i) => i.globalKey == item.globalKey)) continue;
      target.items.add(item);
      target.ids.add(identity);
    }
  }
  return [for (final group in groups) CgflixTitleGroup(group.items)];
}

/// Junta a mesma pessoa vinda de vários servidores (nome normalizado).
List<CgflixPersonGroup> cgflixGroupPeople(List<MediaPerson> people) {
  final byName = <String, List<MediaPerson>>{};
  for (final person in people) {
    final key = cgflixSearchNormalize(person.name);
    final list = byName.putIfAbsent(key.isEmpty ? person.globalKey : key, () => []);
    if (!list.any((p) => p.globalKey == person.globalKey)) list.add(person);
  }
  return [for (final list in byName.values) CgflixPersonGroup(list)];
}

// ---------------------------------------------------------------------------
// Ordem dos grupos no resultado

/// Títulos primeiro, depois Pessoas, depois Coleções/sagas (ordem estável dentro de cada grupo).
List<SearchHit> cgflixOrderHitsByCategory(List<SearchHit> hits) {
  int category(SearchHit hit) => switch (hit) {
    MediaSearchHit(:final item) => item.kind == MediaKind.collection ? 2 : 0,
    PersonSearchHit() => 1,
  };
  final indexed = [for (var i = 0; i < hits.length; i++) (i, hits[i])];
  indexed.sort((a, b) {
    final byCategory = category(a.$2).compareTo(category(b.$2));
    return byCategory != 0 ? byCategory : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

// ---------------------------------------------------------------------------
// Fontes lembradas (para o seletor "Disponível em N servidores" e a página da pessoa)

/// Guarda, por chave global, as outras cópias de cada cartão unificado. Limitado para não
/// crescer sem fim numa sessão longa (os mais antigos saem primeiro).
abstract final class CgflixSourceRegistry {
  static const _maxEntries = 600;
  static final _titles = <String, List<MediaItem>>{};
  static final _people = <String, List<MediaPerson>>{};

  static void rememberTitles(Iterable<CgflixTitleGroup> groups) {
    for (final group in groups) {
      if (group.sources.length < 2) continue;
      for (final source in group.sources) {
        _titles.remove(source.globalKey);
        _titles[source.globalKey] = group.sources;
      }
    }
    _trim(_titles);
  }

  static void rememberPeople(Iterable<CgflixPersonGroup> groups) {
    for (final group in groups) {
      if (group.people.length < 2) continue;
      for (final person in group.people) {
        _people.remove(person.globalKey);
        _people[person.globalKey] = group.people;
      }
    }
    _trim(_people);
  }

  static void _trim(Map<String, Object> map) {
    while (map.length > _maxEntries) {
      map.remove(map.keys.first);
    }
  }

  /// Todas as cópias do título com esta chave (vazio quando só existe uma).
  static List<MediaItem> sourcesFor(String globalKey) => _titles[globalKey] ?? const [];

  /// A mesma pessoa nos outros servidores (vazio quando só existe uma).
  static List<MediaPerson> peopleFor(String globalKey) => _people[globalKey] ?? const [];

  static void clear() {
    _titles.clear();
    _people.clear();
  }
}

// ---------------------------------------------------------------------------
// Gancho da tela de busca

/// Troca o resultado bruto (uma linha por servidor) pelo unificado: um cartão por título e
/// por pessoa, na ordem Títulos → Pessoas → Coleções. Os grupos ficam lembrados no
/// [CgflixSourceRegistry] para a página do título e a da pessoa.
SearchAggregationResult cgflixUnifySearchResult(SearchAggregationResult result, String query) {
  if (!cgflixUnifiedSearch) return result;
  final titleGroups = cgflixGroupTitles(result.candidates);
  final peopleGroups = cgflixGroupPeople(result.people);
  CgflixSourceRegistry.rememberTitles(titleGroups);
  CgflixSourceRegistry.rememberPeople(peopleGroups);
  final titles = [for (final group in titleGroups) group.best];
  final people = [for (final group in peopleGroups) group.best];
  final ranked = rankSearchHits(
    [for (final item in titles) MediaSearchHit(item), for (final person in people) PersonSearchHit(person)],
    query,
    limit: defaultMediaSearchLimit,
  );
  return (
    hits: cgflixOrderHitsByCategory(ranked),
    candidates: titles,
    people: people,
    succeededServerIds: result.succeededServerIds,
    cancelledServerIds: result.cancelledServerIds,
    failedServerIds: result.failedServerIds,
  );
}
