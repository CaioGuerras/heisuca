import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/heisuca/heisuca_title_logo.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';
import 'package:heisuca/services/plex_api_cache.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db); JellyfinApiCache.initialize(db);
  });
  tearDown(() => db.close());
  final item = MediaItem.plex(id: '11406', serverId: 'plex-family', kind: MediaKind.show, title: 'Ranma');

  test('logo do próprio servidor tem prioridade e não consulta nenhum endpoint', () async {
    var calls = 0;
    final plex = testPlexClient(handler: (_) async { calls++; return jsonResponse({}); });
    final jf = testJellyfinClient(handler: (_) async { calls++; return jsonResponse({}); });
    addTearDown(plex.close); addTearDown(jf.close);
    final logo = await HeisucaLogoResolver().resolve(item.copyWith(clearLogoPath: '/own.png'), plex, [jf]);
    expect(logo?.client, same(plex)); expect(logo?.path, '/own.png'); expect(calls, 0);
  });
  for (final matching in [true, false]) {
    test('Plex sem logo + Jellyfin vinculado: identidade confirmada $matching', () async {
      var plexCalls = 0;
      var jfCalls = 0;
      final plex = testPlexClient(serverId: ServerId('plex-family'), handler: (request) async {
        plexCalls++;
        expect(request.url.queryParameters['includeGuids'], '1');
        return jsonResponse({'MediaContainer': {'Metadata': [
          {'ratingKey': '11406', 'Guid': [{'id': 'tmdb://5'}, {'id': 'tvdb://6'}, {'id': 'imdb://tt7'}]}
        ]}});
      });
      final jf = testJellyfinClient(handler: (request) async {
        jfCalls++;
        if (request.url.path.startsWith('/cgflix/')) return jsonResponse({'plex': ['plex-family']});
        if (request.url.path == '/Items') {
          expect(request.url.queryParameters['SearchTerm'], 'Ranma');
          return jsonResponse({'Items': [
            {'Id': 'jf-ranma', 'Name': 'Ranma', 'Type': 'Series', 'LibraryId': 'series',
              'ProviderIds': {'Tmdb': matching ? '5' : '999'}, 'ImageTags': {'Logo': 'logo-tag'}}
          ]});
        }
        return jsonResponse([]);
      });
      addTearDown(plex.close); addTearDown(jf.close);
      final resolver = HeisucaLogoResolver();
      final request = resolver.resolve(item, plex, [jf]);
      expect(resolver.resolve(item, plex, [jf]), same(request));
      final logo = await request;
      if (matching) {
        expect(logo?.client, same(jf));
        expect(logo?.path, contains('/Items/jf-ranma/Images/Logo'));
      } else { expect(logo, isNull); }
      final savedCalls = jfCalls;
      expect(await resolver.resolve(item, plex, [jf]), same(logo));
      expect(plexCalls, 1); expect(jfCalls, savedCalls);
      // Outro perfil/conjunto de conexões não reutiliza a imagem anterior.
      expect(await resolver.resolve(item, plex, []), isNull);
    });
  }
  test('sem vínculo, IDs ou conexão salva fica em texto; nenhum nome basta', () async {
    var lookups = 0;
    final jf = testJellyfinClient(handler: (request) async {
      if (request.url.path == '/Items') lookups++;
      return jsonResponse({'plex': ['other']});
    });
    var hasIds = true;
    final plex = testPlexClient(serverId: ServerId('plex-family'), handler: (_) async => jsonResponse({
      'MediaContainer': {'Metadata': [{'ratingKey': '11406', 'Guid': hasIds ? [{'id': 'tmdb://5'}] : []}]}
    }));
    addTearDown(plex.close); addTearDown(jf.close);
    expect(await HeisucaLogoResolver().resolve(item, plex, [jf]), isNull);
    hasIds = false;
    expect(await HeisucaLogoResolver().resolve(item.copyWith(id: 'other-item'), plex, [jf]), isNull);
    expect(lookups, 0);
    expect(await HeisucaLogoResolver().resolve(item, plex, []), isNull);
  });
}
