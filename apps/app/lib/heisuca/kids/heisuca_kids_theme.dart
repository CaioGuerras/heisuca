import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../profiles/active_profile_provider.dart';
import 'heisuca_kids.dart';
import '../../utils/platform_detector.dart';
import '../../theme/mono_theme.dart';

/// Tema do app enquanto o perfil ativo é infantil (nulo = tema escolhido pela pessoa).
/// Depende do perfil ativo e do registro kids: reconstrói quando um dos dois muda.
ThemeData? heisucaKidsTheme(BuildContext context) {
  final activeId = context.select<ActiveProfileProvider?, String?>((p) => p?.activeId);
  context.watch<HeisucaKids>();
  final variant = HeisucaKids.instance.variantFor(activeId);
  if (variant == null || PlatformDetector.isTV()) return null;
  final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  return monoTheme(dark: dark, kids: variant);
}
