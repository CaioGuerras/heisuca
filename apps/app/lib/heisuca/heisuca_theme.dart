import 'package:flutter/material.dart';

/// Design System oficial do Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Estética cinematográfica, refinada, com tipografia Sora e Inter.
class HeisucaTheme {
  // Paleta Heisuca - Roxo / Escuro de Cinema (Padrão)
  static const Color roxoFundo = Color(0xFF07060A);
  static const Color roxoSuperficie = Color(0xFF121018);
  static const Color roxoSuperficieElevada = Color(0xFF1B1824);
  static const Color roxoLinha = Color(0x1FFFFFFF); // Hairline sutil
  static const Color roxoPrimaria = Color(0xFFA855F7);
  static const Color roxoSelo = Color(0xFFC82B3D); // Vermelho carmim do carimbo Heisuca

  // Paleta Heisuca - Verde Hisui (Claro / Nobre)
  static const Color verdeFundo = Color(0xFF0A1410);
  static const Color verdeSuperficie = Color(0xFF12201A);
  static const Color verdeSuperficieElevada = Color(0xFF1B2E26);
  static const Color verdePrimaria = Color(0xFF22C55E);

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
      cardTheme: CardTheme(
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
