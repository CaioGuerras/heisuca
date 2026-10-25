// Caio, 25/10: retirados somente casos dos serviços removidos; demais serviços e filas continuam cobertos.
import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/trackers/simkl/simkl_tracker.dart';
import 'package:plezy/services/trackers/tracker_coordinator.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/utils/external_ids.dart';
import '../../test_helpers/media_items.dart';

class _FakeMediaServerClient implements MediaServerClient {
  @override
  final ServerId serverId;
  @override
  String? get serverName => null;

  final Map<String, ExternalIds> externalIdsByItem;
  final Map<String, List<MediaItem>> descendantsByParent;
  final List<String> externalIdCalls = [];
  final List<String> descendantCalls = [];


  @override
  final double watchedThreshold = 0.9;

  _FakeMediaServerClient({
    ServerId? serverId,
    required this.externalIdsByItem,
    required this.descendantsByParent,
  }) : serverId = serverId ?? ServerId('server-1');

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    externalIdCalls.add(itemId);
    return externalIdsByItem[itemId] ?? const ExternalIds();
  }

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    descendantCalls.add(parentId);
    return descendantsByParent[parentId] ?? const [];
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _season() => testMediaItem(
  id: 'season-1',
  backend: MediaBackend.plex,
  kind: MediaKind.season,
  title: 'Season 1',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
  index: 1,
  parentId: 'show-1',
);

MediaItem _episode(int number, {int season = 1}) => testMediaItem(
  id: 'episode-$season-$number',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode $number',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
  parentIndex: season,
  index: number,
);

/// An episode that already knows its show, as playback metadata does — the
/// resolver reads the show's guids through `grandparentId`.
MediaItem _episodeOfShow(int number, {int season = 1}) => testMediaItem(
  id: 'episode-$season-$number',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode $number',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
  grandparentId: 'show-1',
  parentIndex: season,
  index: number,
);

MediaItem _show() => testMediaItem(
  id: 'show-1',
  backend: MediaBackend.plex,
  kind: MediaKind.show,
  title: 'Show 1',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
);

TrackerSession _simklSession() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(accessToken: 'token', createdAt: now);
}

void main() {
  group('TrackerCoordinator manual watched sync', () {
    final coordinator = TrackerCoordinator.instance;
    final simkl = SimklTracker.instance;

    setUp(() async {
      await simkl.setEnabled(true);
    });

    tearDown(() async {
      coordinator.cancelInFlight();
      coordinator.debugUseResolverDependencies();
      simkl.rebindSession(null, onSessionInvalidated: () {});
      await simkl.setEnabled(false);
    });

    test('writes a manually watched season to Simkl as one request and fills missing show context', () async {
      final bodies = <Map<String, dynamic>>[];
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/sync/history');
        bodies.add((json.decode(request.body) as Map).cast<String, dynamic>());
        return http.Response('{}', 200);
      });
      simkl.rebindSession(_simklSession(), onSessionInvalidated: () {}, httpClient: httpClient);

      final client = _FakeMediaServerClient(
        externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345)},
        descendantsByParent: {
          'season-1': [_episode(1), _episode(2)],
        },
      );

      await coordinator.markWatched(_season(), client);

      expect(client.descendantCalls, ['season-1']);
      expect(client.externalIdCalls, ['show-1']);
      expect(bodies, [
        {
          'shows': [
            {
              'ids': {'tvdb': 12345},
              'seasons': [
                {
                  'number': 1,
                  'episodes': [
                    {'number': 1},
                    {'number': 2},
                  ],
                },
              ],
            },
          ],
        },
      ]);
    });

    test('a long show goes to Simkl in capped batches, never one request per episode', () async {
      final episodeCounts = <int>[];
      final httpClient = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        var count = 0;
        for (final show in body['shows'] as List) {
          for (final season in (show as Map)['seasons'] as List) {
            count += ((season as Map)['episodes'] as List).length;
          }
        }
        episodeCounts.add(count);
        return http.Response('{}', 201);
      });
      simkl.rebindSession(
        _simklSession(),
        onSessionInvalidated: () {},
        httpClient: httpClient,
        writeSpacing: Duration.zero,
      );
      const episodeCount = TrackerConstants.historyBatchSize * 2 + 5;
      final client = _FakeMediaServerClient(
        externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345)},
        descendantsByParent: {
          'show-1': [
            for (var number = 1; number <= episodeCount; number++)
              _episodeOfShow(number, season: (number - 1) ~/ 25 + 1),
          ],
        },
      );

      await coordinator.markWatched(_show(), client);

      expect(episodeCounts, [TrackerConstants.historyBatchSize, TrackerConstants.historyBatchSize, 5]);
    });



    // A HAMA-matched library identifies anime by AniDB id and nothing else, so
    // every tracker used to be skipped with "no external IDs" (#1788).






    test('removes a manually unwatched season from Simkl history in one request', () async {
      final bodies = <Map<String, dynamic>>[];
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/sync/history/remove');
        bodies.add((json.decode(request.body) as Map).cast<String, dynamic>());
        return http.Response('{}', 200);
      });
      simkl.rebindSession(_simklSession(), onSessionInvalidated: () {}, httpClient: httpClient);

      final client = _FakeMediaServerClient(
        externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345)},
        descendantsByParent: {
          'season-1': [_episode(1), _episode(2)],
        },
      );

      await coordinator.markUnwatched(_season(), client);

      expect(client.descendantCalls, ['season-1']);
      expect(bodies, [
        {
          'shows': [
            {
              'ids': {'tvdb': 12345},
              'seasons': [
                {
                  'number': 1,
                  'episodes': [
                    {'number': 1},
                    {'number': 2},
                  ],
                },
              ],
            },
          ],
        },
      ]);
    });



    test('playback resolver is recreated when the server client changes', () async {
      simkl.rebindSession(
        _simklSession(),
        onSessionInvalidated: () {},
        httpClient: MockClient((_) async => http.Response('{}', 200)),
        writeSpacing: Duration.zero,
      );

      final firstClient = _FakeMediaServerClient(
        serverId: ServerId('server-a'),
        externalIdsByItem: {'show-a': const ExternalIds(tvdb: 111)},
        descendantsByParent: const {},
      );
      final secondClient = _FakeMediaServerClient(
        serverId: ServerId('server-b'),
        externalIdsByItem: {'show-b': const ExternalIds(tvdb: 222)},
        descendantsByParent: const {},
      );
      final firstEpisode = _episode(
        1,
      ).copyWith(id: 'episode-a', serverId: ServerId('server-a'), grandparentId: 'show-a');
      final secondEpisode = _episode(
        1,
      ).copyWith(id: 'episode-b', serverId: ServerId('server-b'), grandparentId: 'show-b');

      await coordinator.startPlayback(firstEpisode, firstClient);
      await coordinator.startPlayback(secondEpisode, secondClient);

      expect(firstClient.externalIdCalls, ['show-a']);
      expect(secondClient.externalIdCalls, ['show-b']);
    });
  });

}
