import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cgflix/cgflix_palette.dart';
import 'theme/heisuca_base.dart';
import 'theme/temas/tema_shikkoku.dart';
import 'theme/temas/tema_hisui.dart';

/// A geometria da marca continua no SVG; só seus papéis de cor seguem o tema.
class HeisucaBrandColors extends ColorMapper {
  const HeisucaBrandColors(this.palette);
  final CgflixPalette palette;

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    if (color.a == 0) return color;
    if (id?.startsWith('heisuca-word-') == true) return palette.text;
    if (id?.startsWith('heisuca-ink-') == true) return HeisucaBase.marcaKanjiDoSelo;
    if (id?.startsWith('heisuca-fill-') == true) {
      return palette.isLight ? TemaHisui.temaCorSelo : TemaShikkoku.temaCorSelo;
    }
    return color;
  }

  @override
  bool operator ==(Object other) => other is HeisucaBrandColors && identical(other.palette, palette);
  @override
  int get hashCode => identityHashCode(palette);
}
