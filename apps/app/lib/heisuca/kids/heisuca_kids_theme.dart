import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cgflix/cgflix_theme.dart';
import '../../profiles/active_profile_provider.dart';
import 'heisuca_kids.dart';

/// Tema do app enquanto o perfil ativo é infantil (nulo = tema escolhido pela pessoa).
/// Depende do perfil ativo e do registro kids: reconstrói quando um dos dois muda.
ThemeData? heisucaKidsTheme(BuildContext context) {
  final activeId = context.select<ActiveProfileProvider?, String?>((p) => p?.activeId);
  context.watch<HeisucaKids>();
  final variant = HeisucaKids.instance.variantFor(activeId);
  return variant == null ? null : cgflixAppTheme(variant);
}
