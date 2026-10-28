import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/models/companion_remote/remote_command.dart';
import 'package:heisuca/models/mpv_config_models.dart';
import 'package:heisuca/watch_together/models/watch_session.dart';
import 'package:heisuca/watch_together/services/recent_rooms_service.dart';

void main() {
  group('JSON model round trips', () {
    test('MpvPreset preserves ISO timestamp shape', () {
      final createdAt = DateTime.utc(2024, 1, 2, 3, 4, 5);
      final preset = MpvPreset(name: 'Anime', text: 'profile=gpu-hq', createdAt: createdAt);

      expect(preset.toJson(), {'name': 'Anime', 'text': 'profile=gpu-hq', 'createdAt': createdAt.toIso8601String()});

      final decoded = MpvPreset.fromJson(preset.toJson());
      expect(decoded.name, preset.name);
      expect(decoded.text, preset.text);
      expect(decoded.createdAt, createdAt);
    });

    test('RecentRoom preserves epoch timestamp and control mode index', () {
      final lastUsed = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final room = RecentRoom(
        code: 'ABCD',
        relayScope: 'scope-digest',
        name: 'Movie night',
        lastUsed: lastUsed,
        controlMode: ControlMode.anyone,
      );

      expect(room.toJson(), {
        'code': 'ABCD',
        'relayScope': 'scope-digest',
        'name': 'Movie night',
        'lastUsed': 1700000000000,
        'controlMode': 1,
      });

      final decoded = RecentRoom.fromJson(room.toJson());
      expect(decoded.code, room.code);
      expect(decoded.relayScope, room.relayScope);
      expect(decoded.name, room.name);
      expect(decoded.lastUsed, lastUsed);
      expect(decoded.controlMode, ControlMode.anyone);
    });

    test('RecentRoom omits nullable fields when absent', () {
      final lastUsed = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final room = RecentRoom(code: 'ABCD', relayScope: 'scope-digest', lastUsed: lastUsed);

      expect(room.toJson(), {'code': 'ABCD', 'relayScope': 'scope-digest', 'lastUsed': 1700000000000});
    });

    test('RecentRoom requires relay scope when decoding', () {
      expect(() => RecentRoom.fromJson({'code': 'ABCD', 'lastUsed': 1700000000000}), throwsA(anything));
    });

    test('RemoteCommand keeps compact protocol keys and unknown fallback', () {
      const command = RemoteCommand(type: RemoteCommandType.volumeSet, data: {'value': 50});

      expect(command.toJson(), {
        't': RemoteCommandType.volumeSet.index,
        'd': {'value': 50},
      });

      final decoded = RemoteCommand.fromJson(command.toJson());
      expect(decoded.type, RemoteCommandType.volumeSet);
      expect(decoded.data, {'value': 50});

      final unknown = RemoteCommand.fromJson({'t': 999});
      expect(unknown.type, RemoteCommandType.ping);
    });
  });
}
