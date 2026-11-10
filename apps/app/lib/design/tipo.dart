import 'package:flutter/material.dart';

import '../heisuca/theme/heisuca_base.dart';
import 'tema.dart';

/// Escala de texto da V2: tamanhos e pesos dos tokens, tinta do tema.
abstract final class Tipo {
  /// Algarismos de largura fixa: tempo, progresso e contagem não "dançam" ao mudar.
  static const List<FontFeature> algarismos = <FontFeature>[FontFeature.tabularFigures()];

  static const double _alturaDeTitulo = 1.15;
  static const double _alturaDeTexto = 1.45;

  static TextStyle _estilo(double tamanho, int peso, Color cor, double altura) => TextStyle(
    fontFamily: HeisucaBase.fonteTexto,
    fontSize: tamanho,
    fontWeight: FontWeight.values[(peso ~/ 100) - 1],
    height: altura,
    color: cor,
  );

  static TextStyle destaque(TemaHeisuca t) =>
      _estilo(HeisucaBase.tamanhoDestaque, HeisucaBase.pesoNegrito, t.texto, _alturaDeTitulo);
  static TextStyle titulo(TemaHeisuca t) =>
      _estilo(HeisucaBase.tamanhoTitulo, HeisucaBase.pesoNegrito, t.texto, _alturaDeTitulo);
  static TextStyle subtitulo(TemaHeisuca t) =>
      _estilo(HeisucaBase.tamanhoSubtitulo, HeisucaBase.pesoForte, t.texto, _alturaDeTitulo);
  static TextStyle texto(TemaHeisuca t) =>
      _estilo(HeisucaBase.tamanhoTexto, HeisucaBase.pesoNormal, t.texto, _alturaDeTexto);
  static TextStyle pequeno(TemaHeisuca t) =>
      _estilo(HeisucaBase.tamanhoPequeno, HeisucaBase.pesoNormal, t.texto2, _alturaDeTexto);
  static TextStyle legenda(TemaHeisuca t) =>
      _estilo(HeisucaBase.tamanhoLegenda, HeisucaBase.pesoMedio, t.texto2, _alturaDeTexto);

  /// Tempo e progresso ("12:04", "restam 38 min"): [pequeno] com algarismos de largura fixa.
  static TextStyle tempo(TemaHeisuca t) => pequeno(t).copyWith(fontFeatures: algarismos);

  static TextTheme textos(TemaHeisuca t) => TextTheme(
    displaySmall: destaque(t),
    headlineMedium: titulo(t),
    titleLarge: subtitulo(t),
    titleMedium: texto(t).copyWith(fontWeight: FontWeight.w600),
    bodyLarge: texto(t),
    bodyMedium: pequeno(t).copyWith(color: t.texto),
    bodySmall: legenda(t),
    labelLarge: pequeno(t).copyWith(color: t.texto, fontWeight: FontWeight.w600),
    labelMedium: legenda(t),
    labelSmall: legenda(t),
  );
}
