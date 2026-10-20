// Movimento do CGFLIX (Etapa 1B): curvas e durações num lugar só, para todas as telas novas
// andarem no mesmo ritmo. As cores ficam em cgflix_palette.dart (temas Isis e Heitor).
import 'package:flutter/animation.dart';

/// Movimento: tudo entre 250 e 350 ms, sempre com curva ease-out (nada de corte seco).
abstract final class CgflixMotion {
  static const fast = Duration(milliseconds: 250);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 350);

  /// Troca de filtro na Início: some e volta, 150 ms cada (300 ms no total).
  static const filterFade = Duration(milliseconds: 150);

  /// Troca cruzada do destaque (fundo + logo).
  static const crossFade = Duration(milliseconds: 600);

  static const curve = Curves.easeOutCubic;
}
