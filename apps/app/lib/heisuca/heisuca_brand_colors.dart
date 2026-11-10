import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cgflix/cgflix_palette.dart';

/// A geometria da marca continua no SVG; só seus papéis de cor seguem o tema.
class HeisucaBrandColors extends ColorMapper {
  const HeisucaBrandColors(this.palette);
  final CgflixPalette palette;

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    if (palette.variant.isKids || color.a == 0) return color;
    if (id?.startsWith('heisuca-word-') == true) return palette.text;
    if (id?.startsWith('heisuca-ink-') == true) return palette.onAction;
    if (id?.startsWith('heisuca-fill-') == true) return palette.accent;
    return color;
  }

  @override
  bool operator ==(Object other) => other is HeisucaBrandColors && identical(other.palette, palette);
  @override
  int get hashCode => identityHashCode(palette);
}
