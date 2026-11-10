import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/models/mpv_config_models.dart';

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
  });
}
