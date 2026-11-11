import 'package:flutter/widgets.dart';

import '../heisuca/theme/heisuca_base.dart';

/// Formas e medidas da V2: cantos em superelipse, pílula e a grade de espaço dos tokens.
abstract final class Forma {
  static const double raioPequeno = HeisucaBase.raioPequeno;
  static const double raioMedio = HeisucaBase.raioMedio;
  static const double raioGrande = HeisucaBase.raioGrande;

  /// Menor área de toque aceita (acessibilidade do Android).
  static const double toqueMinimo = 48;

  static const double espaco1 = HeisucaBase.espaco1;
  static const double espaco2 = HeisucaBase.espaco2;
  static const double espaco3 = HeisucaBase.espaco3;
  static const double espaco4 = HeisucaBase.espaco4;
  static const double espaco6 = HeisucaBase.espaco6;

  /// Largura do anel de foco (teclado, controle e leitor de tela).
  static const double anelDeFoco = HeisucaBase.focoBorda;

  /// Canto contínuo (superelipse) de raio [raio].
  static OutlinedBorder superelipse(double raio, {BorderSide lado = BorderSide.none}) =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(raio), side: lado);

  /// Pílula: botões, ilha e selos.
  static OutlinedBorder pilula({BorderSide lado = BorderSide.none}) => StadiumBorder(side: lado);
}
