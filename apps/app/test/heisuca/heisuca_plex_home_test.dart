import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/heisuca/heisuca_plex_home_repository.dart';
import 'package:plezy/heisuca/heisuca_upcoming.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
  });
  tearDown(() => db.close());

  for (final link in [null, <String>[], ['outro'], ['plex-casa']]) {
    test('feeds com vínculo $link: ranking confirmado e calendário da sessão salva', () async {
      final jfRequests = <Uri>[];
      final plexRequests = <Uri>[];
      final jf = testJellyfinClient(handler: (request) async {
        jfRequests.add(request.url);
        if (request.url.path == '/cgflix/emalta.json') {
          return jsonResponse({'plex': link, 'itens': [
            {'id': 'jf-a', 'tipo': 'Movie', 'tmdb': 10},
            {'id': 'jf-b', 'tipo': 'Movie', 'tmdb': 999},
            {'id': 'jf-c', 'tipo': 'Movie', 'tmdb': 20},
          ]});
        }
        if (request.url.path == '/cgflix/embreve.json') {
          return jsonResponse({'plex': link, 's': {'7': {'nome': 'Série', 'jf': 'jf7', 'tmdb': 70, 'tvdb': 71}}, 'm': {}});
        }
        return jsonResponse({'Items': request.url.path.contains('UpcomingShows') ? [
          {'SeriesName': 'Série', 'PremiereDate': '2026-10-26', 'ProviderIds': {'SonarrSeriesId': '7', 'EpisodeInfo': 'S01E02'}}
        ] : []});
      });
      final plex = testPlexClient(serverId: ServerId('plex-casa'), handler: (request) async {
        plexRequests.add(request.url);
        final guid = request.url.queryParameters['guid'] ?? '';
        final id = guid.contains('://10') ? 10 : guid.contains('://20') ? 20 : guid.contains('://70') ? 70 : null;
        return jsonResponse({'MediaContainer': {'Metadata': [if (id != null)
          {'ratingKey': 'plex-$id', 'type': id == 70 ? 'show' : 'movie', 'title': 'Título $id',
            'guid': 'com.plexapp.agents.themoviedb://$id?lang=pt', 'Guid': [{'id': 'tmdb://$id'}]},
        ]}});
      });
      addTearDown(jf.close); addTearDown(plex.close);
      final repo = HeisucaPlexHomeRepository(plex, feedClients: [jf]);
      addTearDown(repo.dispose);
      final ranking = await repo.watchTrending().last;
      final upcoming = await repo.upcoming();
      if (link?.contains('plex-casa') ?? false) {
        expect(ranking.items.map((i) => i.id), ['plex-10', 'plex-20']);
        expect(upcoming.single.tvdbId, 71);
        expect(upcoming.single.subtitle, '26/10 · S01E02');
        expect(repo.upcomingImageClient, same(jf));
        expect((await repo.resolveUpcoming(upcoming.single))?.id, 'plex-70');
        expect(await repo.resolveUpcoming(const HeisucaUpcoming(id: 'missing', title: 'Fora do Plex',
          subtitle: '', isMovie: true, tmdbId: 999)), isNull);
        expect(jfRequests.where((u) => u.path.contains('HomeScreen')).every((u) => u.queryParameters['UserId'] == 'user-1'), isTrue);
      } else {
        expect(ranking.items, isEmpty); expect(upcoming, isEmpty);
        expect(plexRequests, isEmpty);
        expect(jfRequests.where((u) => u.path.contains('HomeScreen')), isEmpty);
      }
    });
  }
  test('sem conexão Jellyfin e sem match não inventa disponibilidade', () async {
    final plex = testPlexClient(); addTearDown(plex.close);
    final repo = HeisucaPlexHomeRepository(plex, feedClients: []); addTearDown(repo.dispose);
    expect((await repo.watchTrending().last).items, isEmpty);
    expect(await repo.upcoming(), isEmpty);
    expect(await repo.resolveUpcoming(const HeisucaUpcoming(id: 'x', title: 'x', subtitle: '', isMovie: true)), isNull);
  });
  test('feed inacessível não abre calendário; atualização revalida o vínculo', () async {
    var available = false;
    var feeds = 0;
    var calendars = 0;
    final jf = testJellyfinClient(handler: (request) async {
      if (request.url.path == '/cgflix/embreve.json') {
        feeds++;
        return available ? jsonResponse({'plex': ['server-1'], 'm': {}, 's': {}})
          : jsonResponse({}, status: 404);
      }
      calendars++;
      return jsonResponse({'Items': []});
    });
    final plex = testPlexClient();
    addTearDown(jf.close); addTearDown(plex.close);
    final repo = HeisucaPlexHomeRepository(plex, feedClients: [jf]); addTearDown(repo.dispose);
    expect(await repo.upcoming(), isEmpty);
    expect(calendars, 0);
    available = true;
    expect(await repo.upcoming(), isEmpty);
    expect(feeds, 1);
    repo.forgetMemory();
    expect(await repo.upcoming(), isEmpty);
    expect(feeds, 2); expect(calendars, 2);
  });
  test('bibliotecas preservam ordem, nomes e consulta própria, sem hubs promovidos', () async {
    final requests = <Uri>[];
    final plex = testPlexClient(handler: (request) async {
      requests.add(request.url);
      if (request.url.path == '/library/sections') return jsonResponse({'MediaContainer': {'Directory': [
        {'key': '2', 'title': 'Animes', 'type': 'show'}, {'key': '1', 'title': 'Filmes', 'type': 'movie'},
        {'key': '3', 'title': 'Música', 'type': 'artist'},
      ]}});
      return jsonResponse({'MediaContainer': {'Metadata': [
        {'ratingKey': request.url.path.contains('/2/') ? 'anime' : 'filme', 'title': 'Título', 'type': 'show', 'art': '/art.jpg'}
      ], 'totalSize': 1}});
    });
    addTearDown(plex.close);
    final repo = HeisucaPlexHomeRepository(plex, feedClients: []); addTearDown(repo.dispose);
    final libraries = await repo.videoLibraries();
    expect(libraries.map((l) => l.title), ['Animes', 'Filmes']);
    expect((await repo.watchLibrary(libraries.first).last).items.single.id, 'anime');
    expect((await repo.watchHero().last).items.map((i) => i.id), ['anime', 'filme']);
    expect(requests.any((u) => u.path.contains('hubs')), isFalse);
    expect(requests.where((u) => u.path.endsWith('/all')).every((u) => u.queryParameters['sort'] == 'addedAt:desc'), isTrue);
  });
}
