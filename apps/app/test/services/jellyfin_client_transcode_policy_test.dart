import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/connection/connection.dart';
import 'package:heisuca/media/media_server_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

/// Accounts without `Policy.EnableVideoPlaybackTranscoding` get every
/// transcode refused by the server, so the client must stop advertising video
/// transcoding for them; the quality picker then offers only the versions.
void main() {
  group('Jellyfin per-account video transcoding', () {
    test('unknown permission keeps the server default', () {
      final client = testJellyfinClient(handler: (_) async => jsonResponse(<String, Object?>{}));
      addTearDown(client.close);
      expect(client.connection.canTranscodeVideo, isNull);
      expect(client.capabilities.videoTranscoding, isTrue);
    });

    test('a saved "no transcoding" connection hides transcoding', () {
      final client = testJellyfinClient(
        connection: testJellyfinConnection().copyWith(canTranscodeVideo: false),
        handler: (_) async => jsonResponse(<String, Object?>{}),
      );
      addTearDown(client.close);
      expect(client.capabilities.videoTranscoding, isFalse);
    });

    test('checkHealth picks up the policy and reports the change', () async {
      var allowed = false;
      final updates = <JellyfinConnection>[];
      final client = testJellyfinClient(
        handler: (_) async => jsonResponse({
          'Id': 'user-1',
          'Policy': {'IsAdministrator': false, 'EnableVideoPlaybackTranscoding': allowed},
        }),
      );
      addTearDown(client.close);
      client.onConnectionUpdated = updates.add;

      expect(await client.checkHealth(), HealthStatus.online);
      expect(client.capabilities.videoTranscoding, isFalse);
      expect(updates.single.canTranscodeVideo, isFalse);

      allowed = true;
      expect(await client.checkHealth(), HealthStatus.online);
      expect(client.capabilities.videoTranscoding, isTrue);
      expect(updates.length, 2);
    });

    test('the permission survives a config round trip', () {
      final saved = testJellyfinConnection().copyWith(canTranscodeVideo: false);
      final restored = JellyfinConnection.fromConfigJson(
        id: saved.id,
        json: saved.toConfigJson(),
        createdAt: saved.createdAt,
      );
      expect(restored.canTranscodeVideo, isFalse);
    });
  });
}
