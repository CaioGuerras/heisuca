import '../cgflix/home/cgflix_home_logic.dart';
import '../cgflix/home/cgflix_home_repository.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../services/jellyfin_client.dart';
import '../services/plex_client.dart';
import '../utils/external_ids.dart';
import 'heisuca_upcoming.dart';

/// O vínculo é declarado em cada feed; nenhuma identidade/endereço fixo.
bool heisucaFeedLinksPlex(Object? feed, String serverId) =>
    feed is Map && feed['plex'] is List && (feed['plex'] as List).contains(serverId);
ExternalIds heisucaFeedIds(Map entry) => ExternalIds(
  tmdb: _positiveId(entry['tmdb']), tvdb: _positiveId(entry['tvdb']));
int? _positiveId(Object? value) {
  final id = int.tryParse('$value');
  return id != null && id > 0 ? id : null;
}

class HeisucaPlexHomeRepository implements HeisucaHomeRepository {
  HeisucaPlexHomeRepository(this.client, {required List<JellyfinClient> feedClients})
      : _feedClients = List.unmodifiable(feedClients);
  @override
  final PlexClient client;
  final List<JellyfinClient> _feedClients;
  DateTime _loadedAt = DateTime.now();
  final _pending = <String, Future<Object?>>{};
  final _feedLoads = <String, Future<({JellyfinClient client, Map feed})?>>{};
  JellyfinClient? _upcomingSource;
  @override
  MediaServerClient get upcomingImageClient => _upcomingSource ?? client;
  Future<T> _remember<T>(String key, Future<T> Function() load) {
    if (DateTime.now().difference(_loadedAt) > const Duration(minutes: 10)) forgetMemory();
    return (_pending[key] ??= load()) as Future<T>;
  }

  Future<({JellyfinClient client, Map feed})?> _linkedFeed(String path) =>
      _feedLoads.putIfAbsent(path, () async {
        for (final source in _feedClients) {
          try {
            final feed = await source.cgflixGetJson(path);
            if (heisucaFeedLinksPlex(feed, client.serverId.value)) {
              return (client: source, feed: feed as Map);
            }
          } catch (_) { /* Sem vínculo acessível: nenhuma fileira ou aviso. */ }
        }
        return null;
      });
  @override
  void forgetMemory() { _loadedAt = DateTime.now(); _pending.clear(); _feedLoads.clear(); _upcomingSource = null; }
  @override
  void dispose() => forgetMemory();
  @override
  Future<List<MediaLibrary>> videoLibraries() => _remember('libraries', () async =>
      (await client.fetchLibraries()).where((l) => !l.hidden &&
        const [MediaKind.movie, MediaKind.show, MediaKind.unknown].contains(l.kind)).toList());
  Future<CgflixRowData> _library(MediaLibrary library) => _remember('library:${library.id}', () async {
    final page = await client.fetchLibraryPage(library.id, size: 20, filters: {'sort': 'addedAt:desc'});
    return CgflixRowData(items: page.items, title: library.title);
  });
  @override
  Stream<CgflixRowData> watchLibrary(MediaLibrary library) => _library(library).asStream();
  @override
  Stream<CgflixRowData> watchHero() => _remember('hero', () async {
    final rows = await Future.wait((await videoLibraries()).map(_library));
    return CgflixRowData(items: rows.expand((row) => row.items)
      .where((item) => item.artPath != null).take(8).toList());
  }).asStream();
  @override
  Stream<CgflixRowData> watchRow(CgflixRowKind kind) => _remember('row:${kind.name}', () async =>
      CgflixRowData(items: kind == CgflixRowKind.continueWatching
        ? await client.fetchContinueWatching() : const [])).asStream();
  @override
  Stream<CgflixRowData> watchTrending() => _remember('trending', () async {
    final linked = await _linkedFeed('/cgflix/emalta.json');
    if (linked == null || linked.feed['itens'] is! List) return const CgflixRowData(items: []);
    final items = <MediaItem>[];
    final seen = <String>{};
    for (final entry in (linked.feed['itens'] as List).whereType<Map>()) {
      final ids = heisucaFeedIds(entry);
      if (!ids.hasCatalogIds) continue;
      try {
        final matches = await client.findByExternalIds(ids,
          kind: entry['tipo'] == 'Movie' ? MediaKind.movie : MediaKind.show,
          titles: [if (entry['nome'] is String) entry['nome'] as String]);
        final match = matches?.firstOrNull;
        if (match != null && seen.add(match.id)) items.add(match);
      } catch (_) { /* Sem consulta confirmada, não há correspondência. */ }
      if (items.length == 10) break;
    }
    return CgflixRowData(items: items, title: linked.feed['titulo'] as String?);
  }).asStream();
  @override
  Future<List<HeisucaUpcoming>> upcoming() => _remember('upcoming', () async {
    final linked = await _linkedFeed('/cgflix/embreve.json');
    if (linked == null) return const <HeisucaUpcoming>[];
    try {
      final source = linked.client;
      final sections = await Future.wait([
        source.cgflixGetJson('/HomeScreen/Section/UpcomingShows?UserId=${Uri.encodeQueryComponent(source.cgflixUserId)}'),
        source.cgflixGetJson('/HomeScreen/Section/UpcomingMovies?UserId=${Uri.encodeQueryComponent(source.cgflixUserId)}'),
      ]);
      _upcomingSource = source;
      return [...heisucaParseUpcoming(linked.feed, sections[0], isMovie: false),
        ...heisucaParseUpcoming(linked.feed, sections[1], isMovie: true)];
    } catch (_) { return const <HeisucaUpcoming>[]; }
  });
  @override
  Future<MediaItem?> resolveUpcoming(HeisucaUpcoming item) => _remember('upcoming:${item.id}', () async {
    final ids = ExternalIds(tmdb: item.tmdbId, tvdb: item.tvdbId);
    if (!ids.hasCatalogIds) return null;
    final matches = await client.findByExternalIds(ids,
      kind: item.isMovie ? MediaKind.movie : MediaKind.show, titles: [item.title]);
    return matches?.firstOrNull;
  });
}
