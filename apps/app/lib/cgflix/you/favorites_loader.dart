import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../services/catalog/catalog_source.dart';
import '../../services/jellyfin_client.dart';
import '../../services/plex_client.dart';
import '../../utils/external_ids.dart';
import '../../utils/media_server_timeouts.dart';

/// Carrega por fonte, antes de construir cartões. Uma fonte indisponível não
/// esconde as demais; se nenhuma respondeu, a tela recebe o erro habitual.
Future<List<MediaItem>> carregarFavoritos({
  required List<JellyfinClient> jellyfin,
  required CatalogSource? plex,
  required List<PlexClient> servidoresPlex,
}) async {
  final fontes = <Future<List<MediaItem>> Function()>[
    for (final cliente in jellyfin) () => _favoritosDoServidor(cliente),
    if (servidoresPlex.isNotEmpty)
      () async {
        if (plex == null) throw StateError('Conta Plex indisponível');
        return _listaDoPlex(plex, servidoresPlex);
      },
  ];
  final respostas = await _emLote(fontes, (fonte) async {
    try {
      return await fonte();
    } catch (_) {
      return null;
    }
  });
  if (!respostas.any((resposta) => resposta != null)) throw StateError('Lista indisponível');

  final vistos = <String>{};
  final itens = <MediaItem>[];
  for (final item in respostas.nonNulls.expand((itens) => itens)) {
    final raw = item.raw ?? const <String, Object?>{};
    final providers = raw['ProviderIds'];
    final ids = providers is Map
        ? ExternalIds.fromJellyfinProviderIds(providers.cast<String, Object?>())
        : ExternalIds.fromGuids(
            raw['Guid'] is List ? raw['Guid'] as List : const [],
          ).fillFrom(ExternalIds.fromLegacyPlexGuid(item.guid));
    final chaves = {
      'servidor:${item.globalKey}',
      for (final id in ids.toJson().entries) '${item.kind.id}/${id.key}:${id.value}',
      if (item.guid?.startsWith('plex://') ?? false) '${item.kind.id}/${item.guid}',
    };
    final repetido = chaves.any(vistos.contains);
    vistos.addAll(chaves);
    if (!repetido) itens.add(item);
  }
  return itens..sort((a, b) => a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));
}

Future<List<MediaItem>> _favoritosDoServidor(JellyfinClient cliente) async {
  final bibliotecas = await cliente.fetchLibraries().timeout(MediaServerTimeouts.libraryLookup);
  final itens = <MediaItem>[];
  for (final biblioteca in bibliotecas) {
    var inicio = 0;
    while (true) {
      final raw = await cliente.cgflixFetchRawItems({
        'ParentId': biblioteca.id,
        'Filters': 'IsFavorite',
        'IncludeItemTypes': 'Movie,Series',
        'SortBy': 'SortName',
        'SortOrder': 'Ascending',
        'Fields':
            'Overview,DateCreated,ProviderIds,Genres,ChildCount,RecursiveItemCount,'
            'ProductionYear,OfficialRating,PremiereDate,UserDataLastPlayedDate',
        'Limit': '300',
        'StartIndex': '$inicio',
      });
      itens.addAll(cliente.cgflixMapItems(raw).map((item) => item.copyWith(libraryTitle: biblioteca.title)));
      inicio += raw.length;
      if (raw.length < 300) break;
    }
  }
  return itens;
}

Future<List<MediaItem>> _listaDoPlex(CatalogSource fonte, List<PlexClient> servidores) async {
  final encontrados = <MediaItem>[];
  final vistos = <String>{};
  var consultas = 0;
  var respostas = 0;
  for (var pagina = 1; ; pagina++) {
    final lista = await fonte
        .fetchRow(CatalogRowId.watchlist, page: pagina, limit: 100)
        .timeout(MediaServerTimeouts.libraryLookup);
    final titulos = lista.items
        .where((item) => (item.kind == MediaKind.movie || item.kind == MediaKind.show) && vistos.add(item.identityKey))
        .toList();
    final lotes = await _emLote(
      [
        for (final titulo in titulos)
          for (final servidor in servidores) (titulo, servidor),
      ],
      (pedido) async {
        final (titulo, servidor) = pedido;
        consultas++;
        try {
          final id = titulo.ids.plex;
          final itens = await servidor
              .findByExternalIds(
                titulo.ids.toExternalIds(),
                kind: titulo.kind,
                plexGuid: id == null ? null : 'plex://${titulo.kind == MediaKind.movie ? 'movie' : 'show'}/$id',
              )
              .timeout(MediaServerTimeouts.libraryLookup);
          respostas++;
          return [for (final item in itens ?? <MediaItem>[]) item.copyWith(isFavorite: true)];
        } catch (_) {
          return <MediaItem>[];
        }
      },
    );
    encontrados.addAll(lotes.expand((itens) => itens));
    if (!lista.hasMore) break;
  }
  if (consultas > 0 && respostas == 0) throw StateError('Servidores Plex indisponíveis');
  return encontrados;
}

/// Quatro trabalhadores compartilham a fila; cada pedido roda uma única vez.
Future<List<R>> _emLote<T, R>(List<T> pedidos, Future<R> Function(T) executar) async {
  var proximo = 0;
  final respostas = <int, R>{};
  Future<void> trabalhar() async {
    while (proximo < pedidos.length) {
      final indice = proximo++;
      respostas[indice] = await executar(pedidos[indice]);
    }
  }

  await Future.wait([for (var i = 0; i < 4 && i < pedidos.length; i++) trabalhar()]);
  return [for (var i = 0; i < pedidos.length; i++) respostas[i] as R];
}
