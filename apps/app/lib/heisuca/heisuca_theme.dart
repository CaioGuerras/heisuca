import 'package:flutter/material.dart';
import '../cgflix/cgflix_theme.dart';
import 'theme/heisuca_base.dart';
import 'theme/temas/tema_shikkoku.dart';

/// Design System oficial do Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Estética cinematográfica, refinada, com tipografia Inter.
class HeisucaTheme {
  // Paleta Heisuca - Roxo / Escuro de Cinema (Padrão)
  static const Color roxoFundo = heisucaShikkokuCanvas;
  static const Color roxoSuperficie = heisucaShikkokuSurface;
  static const Color roxoSuperficieElevada = heisucaShikkokuSurface2;
  static const Color roxoLinha = heisucaShikkokuLine; // Hairline sutil
  static const Color roxoPrimaria = heisucaShikkokuAccent;
  static const Color roxoSelo = TemaShikkoku.temaCorSelo; // Vermelho carmim do carimbo Heisuca

  // Paleta Heisuca - Verde Hisui (Claro / Nobre)
  static const Color verdeFundo = heisucaHisuiDarkCanvas;
  static const Color verdeSuperficie = heisucaHisuiDarkSurface;
  static const Color verdeSuperficieElevada = heisucaHisuiDarkSurface2;
  static const Color verdePrimaria = heisucaHisuiAccent;

  // Tipografia
  static const String fonteTitulo = HeisucaBase.fonteTitulo;
  static const String fonteTexto = 'Inter';

  // Raios de curvatura modernos
  static const double raioCard = 18.0;
  static const double raioPilula = 999.0;
  static const double raioInput = 14.0;
  static const double raioSquircle = 16.0;

  static ThemeData criarTema({bool verde = false}) {
    return cgflixAppTheme(verde ? CgflixThemeVariant.heitor : CgflixThemeVariant.isis);
  }
}
