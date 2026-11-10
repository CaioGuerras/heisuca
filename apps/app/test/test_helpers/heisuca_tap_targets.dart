import 'dart:ui' show Size;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const heisucaTapTargets = _HeisucaTapTargets();

class _HeisucaTapTargets extends MinimumTapTargetGuideline {
  const _HeisucaTapTargets() : super(
    size: const Size(48, 48),
    link: 'https://support.google.com/accessibility/android/answer/7101858?hl=pt-BR',
  );

  @override
  bool shouldSkipNode(SemanticsNode node) {
    if (super.shouldSkipNode(node)) return true;
    // O Flutter já ignora a borda de ancestrais com rolagem implícita. Uma
    // SingleChildScrollView também pode fornecer um recorte diretamente no
    // nó: medir só esse fragmento confunde rolagem com botão pequeno.
    // Só vale dentro de uma área rolável: fora dela, um alvo encostado na
    // borda do recorte é um botão pequeno de verdade e deve ser medido.
    if (!_inScrollable(node)) return false;
    final clip = node.parentPaintClipRect;
    if (clip == null) return false;
    final rect = node.rect;
    const tolerance = 0.001; // A mesma tolerância de borda do guia do Flutter.
    return rect.left <= clip.left + tolerance || rect.right >= clip.right - tolerance ||
        rect.top <= clip.top + tolerance || rect.bottom >= clip.bottom - tolerance;
  }

  /// Algum ancestral rola (rolagem implícita ou ações de rolagem).
  static bool _inScrollable(SemanticsNode node) {
    for (SemanticsNode? p = node.parent; p != null; p = p.parent) {
      final data = p.getSemanticsData();
      if (data.flagsCollection.hasImplicitScrolling) return true;
      if (data.hasAction(SemanticsAction.scrollUp) || data.hasAction(SemanticsAction.scrollDown) ||
          data.hasAction(SemanticsAction.scrollLeft) || data.hasAction(SemanticsAction.scrollRight)) {
        return true;
      }
    }
    return false;
  }
}
