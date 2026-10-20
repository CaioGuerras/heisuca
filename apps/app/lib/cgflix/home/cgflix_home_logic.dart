// Regras da Início do CGFLIX ("só o nosso acervo") sem widgets, para dar para testar:
// ordem das linhas, consultas ao Jellyfin, leitura do emalta.json, chips e gêneros.
import '../../media/media_kind.dart';
import '../../media/media_library.dart';

/// As linhas da Início, nesta ordem (o destaque fica acima de todas).
/// Etapa 1E: sai "Novos episódios" (episódio não tem capa própria e virava miniatura de cena);
/// "Novidades em séries e animes" já traz as séries com episódio novo, com a capa da série.
enum CgflixRowKind { continueWatching, trending, releases, newMovies, newShows, genre }

/// Ordem fixa das linhas fixas; as de gênero vêm depois, uma por gênero.
const cgflixFixedRowOrder = [
  CgflixRowKind.continueWatching,
  CgflixRowKind.trending,
  CgflixRowKind.releases,
  CgflixRowKind.newMovies,
  CgflixRowKind.newShows,
];

/// Títulos iguais aos do site. Com um chip ativo, "Novidades" fala só daquele tipo.
String cgflixRowTitle(CgflixRowKind kind, {String? genre, String? trendingTitle, CgflixHomeFilter? filter}) =>
    switch (kind) {
      CgflixRowKind.continueWatching => 'Continuar assistindo',
      CgflixRowKind.trending =>
        (trendingTitle?.trim().isNotEmpty ?? false) ? trendingTitle!.trim() : cgflixTrendingTitle,
      CgflixRowKind.releases => 'Lançamentos',
      CgflixRowKind.newMovies => 'Novidades em filmes',
      CgflixRowKind.newShows => switch (filter?.kind) {
        CgflixChipKind.shows => 'Novidades em séries',
        CgflixChipKind.animes => 'Novidades em animes',
        _ => 'Novidades em séries e animes',
      },
      CgflixRowKind.genre => genre ?? '',
    };

/// Chip ativo na Início (Filmes, Séries ou Animes): destaque e linhas só daquela biblioteca.
class CgflixHomeFilter {
  const CgflixHomeFilter(this.kind, this.libraryId);
  CgflixHomeFilter.fromChip(CgflixLibraryChip chip) : this(chip.kind, chip.library.id);

  final CgflixChipKind kind;
  final String libraryId;

  bool get isMovies => kind == CgflixChipKind.movies;

  /// Tipo de item do Jellyfin que a biblioteca guarda.
  String get itemType => isMovies ? 'Movie' : 'Series';

  /// Separa o cache do aparelho de cada filtro.
  String get cacheSuffix => '@$libraryId';

  @override
  bool operator ==(Object other) => other is CgflixHomeFilter && other.kind == kind && other.libraryId == libraryId;

  @override
  int get hashCode => Object.hash(kind, libraryId);
}

const cgflixTrendingTitle = 'Em alta no Brasil';

/// Quantos itens cada linha pede ao servidor.
const cgflixRowLimit = 20;

/// Quantos gêneros viram linhas (os com mais títulos primeiro).
const cgflixMaxGenreRows = 10;

/// Endereço do arquivo de "Em alta", relativo ao endereço do servidor.
const cgflixTrendingPath = '/cgflix/emalta.json';

/// Por quanto tempo o "Em alta" vale no aparelho.
const cgflixTrendingCacheTtl = Duration(hours: 1);

/// Troca do destaque.
const cgflixHeroInterval = Duration(seconds: 8);

/// Parâmetros de `GET /Items` para cada linha que vem de consulta direta.
/// Linhas que não são consulta (Continuar, Em alta) devolvem `null`.
///
/// Com [filter] (chip ativo), tudo fica dentro da biblioteca escolhida e as linhas que não
/// fazem sentido para ela (ex.: "Novidades em séries" em Filmes) devolvem `null` e somem.
Map<String, String>? cgflixRowQuery(CgflixRowKind kind, {String? genre, DateTime? now, CgflixHomeFilter? filter}) {
  if (filter != null) return _filteredRowQuery(kind, filter, genre: genre, now: now);
  final today = (now ?? DateTime.now()).toUtc();
  final limit = '$cgflixRowLimit';
  return switch (kind) {
    CgflixRowKind.continueWatching || CgflixRowKind.trending => null,
    // Filmes pela data de lançamento (sem os que ainda vão estrear).
    CgflixRowKind.releases => {
      'IncludeItemTypes': 'Movie',
      'SortBy': 'PremiereDate,SortName',
      'SortOrder': 'Descending,Ascending',
      'MaxPremiereDate': today.toIso8601String(),
      'Limit': limit,
    },
    CgflixRowKind.newMovies => {
      'IncludeItemTypes': 'Movie',
      'SortBy': 'DateCreated,SortName',
      'SortOrder': 'Descending,Ascending',
      'Limit': limit,
    },
    // Séries (e animes) pela data do último conteúdo novo.
    CgflixRowKind.newShows => {
      'IncludeItemTypes': 'Series',
      'SortBy': 'DateLastContentAdded,SortName',
      'SortOrder': 'Descending,Ascending',
      'Limit': limit,
    },
    CgflixRowKind.genre => {
      'IncludeItemTypes': 'Movie,Series',
      'Genres': genre ?? '',
      'SortBy': 'CommunityRating,SortName',
      'SortOrder': 'Descending,Ascending',
      'Limit': limit,
    },
  };
}

Map<String, String>? _filteredRowQuery(CgflixRowKind kind, CgflixHomeFilter filter, {String? genre, DateTime? now}) {
  final base = cgflixRowQuery(kind, genre: genre, now: now);
  if (base == null) return null;
  final scoped = {...base, 'ParentId': filter.libraryId};
  return switch (kind) {
    // Lançamentos: filmes ou séries (pela estreia), conforme a biblioteca.
    CgflixRowKind.releases || CgflixRowKind.genre => {...scoped, 'IncludeItemTypes': filter.itemType},
    CgflixRowKind.newMovies => filter.isMovies ? scoped : null,
    CgflixRowKind.newShows => filter.isMovies ? null : scoped,
    CgflixRowKind.continueWatching || CgflixRowKind.trending => null,
  };
}

/// Destaque: filmes e séries com fundo e logo, sorteados pelo servidor (com chip ativo,
/// só da biblioteca escolhida).
Map<String, String> cgflixHeroQuery({CgflixHomeFilter? filter}) => {
  'IncludeItemTypes': filter?.itemType ?? 'Movie,Series',
  'ImageTypes': 'Backdrop,Logo',
  'SortBy': 'Random',
  'Limit': '8',
  if (filter != null) 'ParentId': filter.libraryId,
};

// ---------------------------------------------------------------------------
// Em alta no Brasil

class CgflixTrendingEntry {
  const CgflixTrendingEntry({required this.id, this.name, this.type, this.library});
  final String id;
  final String? name;
  final String? type;

  /// Biblioteca do título no ranking ("filmes", "series" ou "animes"), quando o arquivo diz.
  final String? library;
}

/// Mínimo de títulos para a linha "Em alta" de uma categoria aparecer.
const cgflixTrendingMinItems = 3;

class CgflixTrending {
  const CgflixTrending({required this.title, required this.entries, this.byLibrary});
  final String title;

  /// Já na ordem do ranking (geral, usado na Início).
  final List<CgflixTrendingEntry> entries;

  /// Ranking de cada categoria (`porBiblioteca` do emalta.json, desde 07/10); null se o arquivo
  /// não tiver o campo.
  final Map<CgflixChipKind, List<CgflixTrendingEntry>>? byLibrary;

  List<String> get ids => [for (final e in entries) e.id];

  /// Lê `{"titulo","itens":[{"id","nome","tipo","biblioteca"}],"porBiblioteca":{"filmes":[...],
  /// "series":[...],"animes":[...]}}`. Tolerante: ignora itens sem id e ids repetidos; devolve
  /// `null` se não houver nenhum item aproveitável (nem no geral nem por categoria).
  static CgflixTrending? parse(Object? json) {
    if (json is! Map) return null;
    final entries = _parseEntries(json['itens']);
    Map<CgflixChipKind, List<CgflixTrendingEntry>>? byLibrary;
    final rawByLibrary = json['porBiblioteca'];
    if (rawByLibrary is Map) {
      byLibrary = {};
      for (final MapEntry(:key, :value) in rawByLibrary.entries) {
        final kind = cgflixTrendingLibraryKind('$key');
        if (kind != null) byLibrary[kind] = _parseEntries(value);
      }
    }
    if (entries.isEmpty && (byLibrary == null || byLibrary.values.every((l) => l.isEmpty))) return null;
    final title = json['titulo'];
    return CgflixTrending(
      title: title is String && title.trim().isNotEmpty ? title.trim() : cgflixTrendingTitle,
      entries: entries,
      byLibrary: byLibrary,
    );
  }

  static List<CgflixTrendingEntry> _parseEntries(Object? rawItems) {
    if (rawItems is! List) return const [];
    final seen = <String>{};
    final entries = <CgflixTrendingEntry>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final id = raw['id'];
      final idText = id is String ? id.trim() : (id is num ? '$id' : '');
      if (idText.isEmpty || !seen.add(idText)) continue;
      final library = raw['biblioteca'];
      entries.add(
        CgflixTrendingEntry(
          id: idText,
          name: raw['nome'] is String ? raw['nome'] as String : null,
          type: raw['tipo'] is String ? raw['tipo'] as String : null,
          library: library is String && library.trim().isNotEmpty ? library.trim() : null,
        ),
      );
    }
    return entries;
  }

  /// Ids do "Em alta" de uma categoria, na ordem do ranking; `null` = esconder a linha.
  ///
  /// 1. `porBiblioteca` (o certo): a lista da categoria;
  /// 2. sem ele, os `itens` cuja `biblioteca` é a da categoria;
  /// 3. sem nenhum dos dois, Filmes ainda separa pelo tipo (filme é sempre filme), mas Séries e
  ///    Animes não têm como (as duas bibliotecas guardam "Series"): a linha some.
  /// Com menos de [cgflixTrendingMinItems] títulos a linha também some.
  List<String>? idsFor(CgflixChipKind kind) {
    final List<CgflixTrendingEntry> picked;
    final byLibrary = this.byLibrary;
    if (byLibrary != null) {
      picked = byLibrary[kind] ?? const [];
    } else if (entries.any((e) => e.library != null)) {
      picked = [
        for (final e in entries)
          if (cgflixTrendingLibraryKind(e.library) == kind) e,
      ];
    } else if (kind == CgflixChipKind.movies) {
      picked = [
        for (final e in entries)
          if (e.type == null || e.type == 'Movie') e,
      ];
    } else {
      return null;
    }
    final ids = [for (final e in picked.take(10)) e.id];
    return ids.length < cgflixTrendingMinItems ? null : ids;
  }
}

/// Categoria de um nome de biblioteca do emalta.json ("filmes", "Séries", "animes"...).
CgflixChipKind? cgflixTrendingLibraryKind(String? raw) {
  if (raw == null) return null;
  final name = cgflixNormalize(raw);
  if (name.startsWith('film') || name == 'movies' || name == 'movie') return CgflixChipKind.movies;
  if (name.startsWith('anime')) return CgflixChipKind.animes;
  if (name.startsWith('serie') || name == 'shows' || name == 'tvshows') return CgflixChipKind.shows;
  return null;
}

/// Reordena [items] pela ordem de [ids] (o `/Items?Ids=` do Jellyfin não garante ordem).
/// Itens que o servidor não devolveu (apagados, sem permissão) simplesmente somem.
List<T> cgflixOrderByIds<T>(List<T> items, List<String> ids, String Function(T) idOf) {
  final byId = {for (final item in items) idOf(item): item};
  return [
    for (final id in ids)
      if (byId[id] != null) byId[id] as T,
  ];
}

// ---------------------------------------------------------------------------
// Chips Filmes · Séries · Animes

enum CgflixChipKind { movies, shows, animes }

class CgflixLibraryChip {
  const CgflixLibraryChip(this.kind, this.library);
  final CgflixChipKind kind;
  final MediaLibrary library;

  String get label => switch (kind) {
    CgflixChipKind.movies => 'Filmes',
    CgflixChipKind.shows => 'Séries',
    CgflixChipKind.animes => 'Animes',
  };
}

/// Minúsculas e sem acento, para comparar nomes de biblioteca.
String cgflixNormalize(String text) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final lower = text.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }
  return buffer.toString();
}

bool _isAnimeLibrary(MediaLibrary library) {
  final name = cgflixNormalize(library.title);
  return name == 'animes' || name == 'anime';
}

/// Filmes = primeira biblioteca de filmes; Séries = primeira de séries que não é a de
/// animes; Animes = biblioteca de séries chamada "Animes". Chip sem biblioteca some.
List<CgflixLibraryChip> cgflixLibraryChips(List<MediaLibrary> libraries) {
  final visible = libraries.where((l) => !l.hidden).toList();
  MediaLibrary? movies;
  MediaLibrary? shows;
  MediaLibrary? animes;
  for (final library in visible) {
    if (library.kind == MediaKind.movie) {
      movies ??= library;
    } else if (library.kind == MediaKind.show) {
      if (_isAnimeLibrary(library)) {
        animes ??= library;
      } else {
        shows ??= library;
      }
    }
  }
  return [
    if (movies != null) CgflixLibraryChip(CgflixChipKind.movies, movies),
    if (shows != null) CgflixLibraryChip(CgflixChipKind.shows, shows),
    if (animes != null) CgflixLibraryChip(CgflixChipKind.animes, animes),
  ];
}

// ---------------------------------------------------------------------------
// Gêneros

/// Escolhe os gêneros que viram linha: os com mais títulos primeiro (quando o servidor
/// manda as contagens), sem repetidos nem vazios, no máximo [max].
List<String> cgflixPickGenres(List<Map<String, dynamic>> raw, {int max = cgflixMaxGenreRows}) {
  int? countOf(Map<String, dynamic> genre) {
    final movies = genre['MovieCount'];
    final series = genre['SeriesCount'];
    if (movies is! num && series is! num) return null;
    return (movies is num ? movies.toInt() : 0) + (series is num ? series.toInt() : 0);
  }

  final seen = <String>{};
  final entries = <({String name, int? count, int index})>[];
  for (var i = 0; i < raw.length; i++) {
    final name = raw[i]['Name'];
    if (name is! String || name.trim().isEmpty) continue;
    if (!seen.add(cgflixNormalize(name))) continue;
    final count = countOf(raw[i]);
    if (count == 0) continue;
    entries.add((name: name.trim(), count: count, index: i));
  }
  final hasCounts = entries.any((e) => e.count != null);
  if (hasCounts) {
    entries.sort((a, b) {
      final byCount = (b.count ?? 0).compareTo(a.count ?? 0);
      return byCount != 0 ? byCount : a.index.compareTo(b.index);
    });
  }
  return [for (final e in entries.take(max)) e.name];
}
