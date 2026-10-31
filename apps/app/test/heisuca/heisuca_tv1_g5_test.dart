import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/models/transcode_quality_preset.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';
import 'package:heisuca/services/jellyfin_client.dart';
import 'package:heisuca/services/jellyfin_playback_bundle.dart';
import 'package:heisuca/services/jellyfin_playback_warmup_service.dart';
import 'package:heisuca/services/playback_initialization_types.dart';
import 'package:heisuca/services/plex_api_cache.dart';
import 'package:heisuca/utils/platform_detector.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  DateTime currentTime = DateTime(2026, 10, 31, 12, 0, 0);

  setUp(() async {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
    TvDetectionService.debugSetTvOverride(true);

    currentTime = DateTime(2026, 10, 31, 12, 0, 0);
    JellyfinPlaybackWarmupService.instance.clear();
    JellyfinPlaybackWarmupService.instance.clock = () => currentTime;
  });

  tearDown(() async {
    JellyfinPlaybackWarmupService.instance.clear();
    TvDetectionService.debugSetTvOverride(null);
    await db.close();
  });

  Map<String, dynamic> itemJson(String id, {String kind = 'Movie', String container = 'mkv'}) {
    return {
      'Id': id,
      'Name': 'Item $id',
      'Type': kind,
      'MediaSources': [
        {
          'Id': 'src-$id',
          'Container': container,
          'SupportsDirectPlay': true,
          'SupportsDirectStream': true,
          'MediaStreams': [
            {'Type': 'Video', 'Index': 0, 'Codec': 'hevc', 'Height': 1080, 'Width': 1920},
            {'Type': 'Audio', 'Index': 1, 'Codec': 'aac', 'Language': 'por', 'IsDefault': true},
          ],
        },
      ],
    };
  }

  (JellyfinClient, List<String>) createMockClient({
    String serverMachineId = 'srv-1',
    String userId = 'usr-1',
    bool failItem = false,
  }) {
    final requestedPaths = <String>[];
    final client = testJellyfinClient(
      connection: testJellyfinConnection(
        machineId: serverMachineId,
        userId: userId,
      ),
      handler: (req) async {
        requestedPaths.add(req.url.path);
        if (failItem && req.url.path.contains('/Items/')) {
          return http.Response('Server error', 500);
        }
        if (req.url.path.contains('/Shows/NextUp')) {
          return http.Response(
            jsonEncode({
              'Items': [itemJson('ep-next', kind: 'Episode')],
              'TotalRecordCount': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        final match = RegExp(r'/Items/([^/?]+)').firstMatch(req.url.path);
        final itemId = match?.group(1) ?? 'item-1';
        final kind = itemId.startsWith('show') ? 'Series' : (itemId.startsWith('ep') ? 'Episode' : 'Movie');
        return http.Response(
          jsonEncode(itemJson(itemId, kind: kind)),
          200,
          headers: {'content-type': 'application/json'},
        );
      },
    );
    return (client, requestedPaths);
  }

  group('G5 — JellyfinPlaybackWarmupService & TV play na hora', () {
    test('1. foco < 700 ms não pede', () async {
      final (client, requests) = createMockClient();
      addTearDown(client.close);

      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );

      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: item,
      );

      // Espera 300 ms e perde o foco
      await Future<void>.delayed(const Duration(milliseconds: 300));
      JellyfinPlaybackWarmupService.instance.onFocusLost();

      // Espera passar o tempo que seria de 700 ms
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(requests, isEmpty, reason: 'Foco < 700 ms não deve disparar nenhuma requisição');
    });

    test('2. foco >= 700 ms pede 1 vez', () async {
      final (client, requests) = createMockClient();
      addTearDown(client.close);

      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );

      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: item,
      );

      // Aguarda os 700 ms do debounce + margem
      await Future<void>.delayed(const Duration(milliseconds: 750));

      expect(requests.length, 1, reason: 'Foco mantido >= 700 ms deve disparar exatamente 1 requisição');
      expect(requests.first, contains('/Items/movie-1'));
    });

    test('3. dois focos rápidos = 1 pedido (o último)', () async {
      final (client, requests) = createMockClient();
      addTearDown(client.close);

      final item1 = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );
      final item2 = testMediaItem(
        id: 'movie-2',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );

      // Foca item 1
      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: item1,
      );

      // 200 ms depois, foca item 2 (antes dos 700 ms)
      await Future<void>.delayed(const Duration(milliseconds: 200));
      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: item2,
      );

      // Espera 750 ms
      await Future<void>.delayed(const Duration(milliseconds: 750));

      expect(requests.length, 1, reason: 'Dois focos rápidos devem gerar apenas 1 pedido para o último item');
      expect(requests.first, contains('/Items/movie-2'));
    });

    test('4. Play em 60 s reaproveita (0 chamadas novas)', () async {
      final (client, requests) = createMockClient();
      addTearDown(client.close);

      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );

      // Pré-aquece
      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: item,
      );
      await Future<void>.delayed(const Duration(milliseconds: 750));
      await JellyfinPlaybackWarmupService.instance.inFlightWarmup;
      expect(requests.length, 1);

      // Avança o relógio para 50 segundos depois (< 60 s)
      currentTime = currentTime.add(const Duration(seconds: 50));

      final countBeforePlay = requests.length;

      // Executa getPlaybackInitialization (Play)
      final init = await client.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: item,
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.original,
        ),
      );

      expect(init.videoUrl, isNotNull);
      expect(init.playMethod, 'DirectPlay');
      expect(requests.length, countBeforePlay, reason: 'Play dentro de 60 s deve reutilizar o cache sem novas chamadas');
    });

    test('5. Play após 61 s pede de novo', () async {
      final (client, requests) = createMockClient();
      addTearDown(client.close);

      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );

      // Pré-aquece
      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: item,
      );
      await Future<void>.delayed(const Duration(milliseconds: 750));
      await JellyfinPlaybackWarmupService.instance.inFlightWarmup;
      expect(requests.length, 1);

      // Avança o relógio para 61 segundos depois (> 60 s)
      currentTime = currentTime.add(const Duration(seconds: 61));

      final countBeforePlay = requests.length;

      // Executa getPlaybackInitialization (Play)
      final init = await client.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: item,
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.original,
        ),
      );

      expect(init.videoUrl, isNotNull);
      expect(requests.length, greaterThan(countBeforePlay), reason: 'Play após 61 s deve buscar novamente');
    });

    test('6. troca de usuário/servidor invalida', () async {
      final (client1, requests1) = createMockClient(serverMachineId: 'srv-1', userId: 'usr-1');
      final (client2, requests2) = createMockClient(serverMachineId: 'srv-1', userId: 'usr-2');
      addTearDown(client1.close);
      addTearDown(client2.close);

      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );

      // Pré-aquece com client1 (usr-1)
      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client1,
        item: item,
      );
      await Future<void>.delayed(const Duration(milliseconds: 750));
      expect(requests1.length, 1);

      // client2 (usr-2) tenta dar Play no mesmo item
      final init = await client2.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: item,
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.original,
        ),
      );

      expect(init.videoUrl, isNotNull);
      expect(requests2, isNotEmpty, reason: 'Cache de outro usuário não pode ser usado por novo usuário');
    });

    test('7. erro no pré-aquecimento não quebra o Play', () async {
      // Cliente que falha no pré-aquecimento
      final (client, requests) = createMockClient(failItem: true);
      addTearDown(client.close);

      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );

      // Pré-aquece (vai falhar internamente e capturar silenciosamente)
      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: item,
      );
      await Future<void>.delayed(const Duration(milliseconds: 750));

      // Agora client não falha mais
      final (goodClient, goodRequests) = createMockClient();
      addTearDown(goodClient.close);

      final init = await goodClient.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: item,
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.original,
        ),
      );

      expect(init.videoUrl, isNotNull);
      expect(goodRequests, isNotEmpty);
    });

    test('8. fora da TV nunca pede', () async {
      TvDetectionService.debugSetTvOverride(false);
      expect(PlatformDetector.isTV(), isFalse);

      final (client, requests) = createMockClient();
      addTearDown(client.close);

      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );

      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: item,
      );

      await Future<void>.delayed(const Duration(milliseconds: 800));

      expect(requests, isEmpty, reason: 'Fora da TV (celular, tablet), o pré-aquecimento nunca deve disparar');
    });

    test('Série: pré-aquece o episódio de Continuar/próximo', () async {
      final (client, requests) = createMockClient();
      addTearDown(client.close);

      final showItem = testMediaItem(
        id: 'show-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.show,
        serverId: 'srv-1',
      );

      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: showItem,
      );

      await Future<void>.delayed(const Duration(milliseconds: 750));

      // Deve ter chamado NextUp e depois o bundle do episódio retornado (ep-next)
      expect(requests.any((r) => r.contains('/Shows/NextUp')), isTrue);
      expect(requests.any((r) => r.contains('/Items/ep-next')), isTrue);

      // Play no episódio ep-next dentro dos 60 s não faz chamadas adicionais
      final epItem = testMediaItem(
        id: 'ep-next',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.episode,
        serverId: 'srv-1',
      );

      final countBeforePlay = requests.length;
      final init = await client.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: epItem,
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.original,
        ),
      );

      expect(init.videoUrl, isNotNull);
      expect(requests.length, countBeforePlay, reason: 'Episódio pré-aquecido via série foi aproveitado com 0 novas chamadas');
    });

    test('Cache respeita limite máximo de 8 itens (LRU)', () {
      final service = JellyfinPlaybackWarmupService.instance;
      for (int i = 0; i < 10; i++) {
        service.put(
          serverId: 'srv-1',
          userId: 'usr-1',
          itemId: 'item-$i',
          bundle: const JellyfinPlaybackBundle(
            availableVersions: [],
            selectedSource: {},
            chapters: [],
            selectedSourceIndex: 0,
            selectedSourceId: 'src',
            container: 'mkv',
          ),
        );
      }

      // Itens 0 e 1 devem ter sido descartados
      expect(service.get(serverId: 'srv-1', userId: 'usr-1', itemId: 'item-0'), isNull);
      expect(service.get(serverId: 'srv-1', userId: 'usr-1', itemId: 'item-1'), isNull);

      // Itens 2 a 9 devem existir
      for (int i = 2; i < 10; i++) {
        expect(service.get(serverId: 'srv-1', userId: 'usr-1', itemId: 'item-$i'), isNotNull);
      }
    });
  });
}
