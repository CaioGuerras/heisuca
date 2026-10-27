import 'package:flutter_test/flutter_test.dart';
import '../../integration_test/support/pip_overflow_policy.dart';

void main() {
  const cases = [
    ('widgets/video_controls_header.dart:59:12', 'right', 151),
    ('mobile_video_controls.dart:387:16', 'right', 7.2),
    ('mobile_video_controls.dart:237:14', 'bottom', 212),
  ];
  for (final entry in cases) {
    test('HUD conhecido: ${entry.$1}, só na fase e janela PiP', () {
      bool allowed({String phase = 'ativo', double width = 240.8, double height = 108.2,
        String? source, String? message}) => knownPipHudOverflow(
          message: message ?? 'A RenderFlex overflowed by ${entry.$3} pixels on the ${entry.$2}.',
          source: source ?? entry.$1, phase: phase, width: width, height: height);
      expect(allowed(), isTrue);
      expect(allowed(width: 227.8, height: 128), isTrue);
      expect(allowed(phase: 'entrada'), isTrue);
      expect(allowed(phase: 'saída'), isTrue);
      expect(allowed(width: 914, height: 411), isFalse);
      expect(allowed(phase: 'fora'), isFalse);
      expect(allowed(source: 'login.dart:59:12'), isFalse);
      expect(allowed(message: 'Null check operator used on a null value'), isFalse);
      expect(allowed(width: 0), isFalse);
      expect(allowed(width: 321), isFalse);
    });
  }
}
