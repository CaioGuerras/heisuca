import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_layout.dart';

void main() {
  // motorola edge 70: 1080×2400 px a ~2,6 → ~412×914 dp em pé.
  const edgePortrait = Size(412, 914);
  const edgeLandscape = Size(914, 412);

  test('a conta antiga da 1C lançava exceção deitado (causa da tela preta)', () {
    expect(() => (edgeLandscape.width * 1.15).clamp(360.0, edgeLandscape.height * 0.68), throwsArgumentError);
  });

  test('destaque cabe em pé e deitado, em todas as larguras', () {
    for (final size in const [
      Size(360, 640),
      edgePortrait,
      Size(800, 1280),
      Size(640, 360),
      edgeLandscape,
      Size(1280, 800),
      Size(320, 300),
    ]) {
      final h = cgflixHeroHeight(size);
      expect(h, greaterThan(0), reason: '$size');
      if (cgflixIsLandscape(size)) {
        expect(h, lessThanOrEqualTo(520), reason: '$size');
        expect(h, greaterThanOrEqualTo(240), reason: '$size');
      } else {
        expect(h, greaterThanOrEqualTo(360), reason: '$size');
      }
    }
  });

  test('deitado no celular: destaque compacto; tablet em pé não', () {
    expect(cgflixHeroCompact(edgeLandscape), isTrue);
    expect(cgflixHeroCompact(edgePortrait), isFalse);
    expect(cgflixHeroCompact(const Size(800, 1280)), isFalse);
  });
}
