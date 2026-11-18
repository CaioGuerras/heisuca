import 'package:flutter/material.dart';

import '../design/tema.dart';
import '../cgflix/cgflix_palette.dart';

TemaHeisuca desktopPalette(String choice, Brightness systemBrightness) => switch (choice) {
  'hisui' => TemaHeisuca.hisui,
  'sumi' => TemaHeisuca.sumi,
  'system' when systemBrightness == Brightness.light => TemaHeisuca.hisui,
  _ => TemaHeisuca.shikkoku,
};

ThemeData desktopTheme(String choice, Brightness systemBrightness) {
  final palette = desktopPalette(choice, systemBrightness);
  final base = palette.paraMaterial();
  return base.copyWith(
    extensions: [palette, palette.brilho == Brightness.light ? CgflixPalette.heitor
      : palette.nome == 'sumi' ? CgflixPalette.sumi : CgflixPalette.isis],
    splashFactory: NoSplash.splashFactory,
    hoverColor: palette.acentoSuave.withValues(alpha: 0.35),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: palette.superficie2,
        borderRadius: BorderRadius.circular(12), border: Border.all(color: palette.borda)),
      textStyle: base.textTheme.bodySmall?.copyWith(color: palette.texto),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: palette.superficie2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.borda)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.foco, width: 2)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(palette.texto),
      side: WidgetStateProperty.resolveWith((states) => BorderSide(
        color: states.contains(WidgetState.focused) ? palette.foco : palette.borda,
        width: states.contains(WidgetState.focused) ? 2 : 1)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
    )),
  );
}
