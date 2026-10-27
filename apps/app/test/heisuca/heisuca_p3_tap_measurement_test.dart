import 'dart:ui' show Rect;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/heisuca_tap_targets.dart';

void main() {
  // Coordenadas locais do campo de servidor na captura/inspeção P3: a
  // semântica também recorta o alvo na borda da janela de rolagem.
  for (final (name, rect, clip, skip) in [
    ('recorte superior', const Rect.fromLTRB(0, 54.7, 858.3, 79), const Rect.fromLTRB(-28, 54.7, 886.3, 418.2), true),
    ('recorte inferior', const Rect.fromLTRB(0, 0, 858.3, 39.2), const Rect.fromLTRB(-28, -324.3, 886.3, 39.2), true),
    ('controle pequeno inteiro', const Rect.fromLTRB(0, 0, 100, 40), const Rect.fromLTRB(-28, -88.3, 886.3, 275.2), false),
    ('controle adequado inteiro', const Rect.fromLTRB(0, 0, 100, 56), const Rect.fromLTRB(-28, -88.3, 886.3, 275.2), false),
  ]) {
    test('P3 medição: $name', () {
      final node = SemanticsNode();
      node.updateWith(config: SemanticsConfiguration()..onTap = () {}, childrenInInversePaintOrder: []);
      node.rect = rect;
      node.parentPaintClipRect = clip;
      // Pai rolável: é o único caso em que a borda do recorte é ignorada.
      final scroller = SemanticsNode();
      scroller.updateWith(config: SemanticsConfiguration()..onScrollUp = () {},
        childrenInInversePaintOrder: [node]);
      expect(heisucaTapTargets.shouldSkipNode(node), skip);
    });
  }

  test('P3 prova negativa: botão 24x24 encostado no ClipRect fora de rolagem reprova', () {
    final node = SemanticsNode();
    node.updateWith(config: SemanticsConfiguration()..onTap = () {}, childrenInInversePaintOrder: []);
    node.rect = const Rect.fromLTRB(0, 0, 24, 24);
    node.parentPaintClipRect = const Rect.fromLTRB(0, 0, 200, 200); // encostado na borda
    final parent = SemanticsNode();
    parent.updateWith(config: SemanticsConfiguration()..isSemanticBoundary = true,
      childrenInInversePaintOrder: [node]);
    expect(heisucaTapTargets.shouldSkipNode(node), isFalse);
  });
}
