import 'package:flutter/material.dart';
import '../cgflix/cgflix_palette.dart';

/// Design System oficial do Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Estética cinematográfica, refinada, com tipografia Sora e Inter.
class HeisucaTheme {
  // Paleta Heisuca - Roxo / Escuro de Cinema (Padrão)
  static const Color roxoFundo = heisucaShikkokuCanvas;
  static const Color roxoSuperficie = heisucaShikkokuSurface;
  static const Color roxoSuperficieElevada = heisucaShikkokuSurface2;
  static const Color roxoLinha = heisucaShikkokuLine; // Hairline sutil
  static const Color roxoPrimaria = heisucaShikkokuAccent;
  static const Color roxoSelo = Color(0xFFC82B3D); // Vermelho carmim do carimbo Heisuca

  // Paleta Heisuca - Verde Hisui (Claro / Nobre)
  static const Color verdeFundo = heisucaHisuiDarkCanvas;
  static const Color verdeSuperficie = heisucaHisuiDarkSurface;
  static const Color verdeSuperficieElevada = heisucaHisuiDarkSurface2;
  static const Color verdePrimaria = heisucaHisuiAccent;

  // Tipografia
  static const String fonteTitulo = 'Sora';
  static const String fonteTexto = 'Inter';

  // Raios de curvatura modernos
  static const double raioCard = 18.0;
  static const double raioPilula = 999.0;
  static const double raioInput = 14.0;
  static const double raioSquircle = 16.0;

  static ThemeData criarTema({bool verde = false}) {
    final fundo = verde ? verdeFundo : roxoFundo;
    final superficie = verde ? verdeSuperficie : roxoSuperficie;
    final primaria = verde ? verdePrimaria : roxoPrimaria;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: fundo,
      primaryColor: primaria,
      colorScheme: ColorScheme.dark(
        primary: primaria,
        surface: superficie,
        background: fundo,
        onSurface: Colors.white,
        onBackground: Colors.white,
        outline: roxoLinha,
      ),
      fontFamily: fonteTexto,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: fonteTitulo, fontWeight: FontWeight.w700, letterSpacing: -0.02),
        displayMedium: TextStyle(fontFamily: fonteTitulo, fontWeight: FontWeight.w700, letterSpacing: -0.01),
        headlineLarge: TextStyle(fontFamily: fonteTitulo, fontWeight: FontWeight.w600, letterSpacing: -0.01),
        headlineMedium: TextStyle(fontFamily: fonteTitulo, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: fonteTitulo, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(fontFamily: fonteTitulo, fontWeight: FontWeight.w500, fontSize: 15),
        bodyLarge: TextStyle(fontFamily: fonteTexto, fontWeight: FontWeight.w400, fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(fontFamily: fonteTexto, fontWeight: FontWeight.w400, fontSize: 13.5, height: 1.4),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(raioCard),
          side: const BorderSide(color: roxoLinha, width: 1),
        ),
      ),
    );
  }
}
