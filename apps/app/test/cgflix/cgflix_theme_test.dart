import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/services/settings_service.dart' as settings;

void main() {
  test('Isis (padrão): escuro, Obsidian Plum', () {
    final theme = cgflixAppTheme();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF17151C));
    expect(theme.colorScheme, cgflixIsisScheme);
    expect(theme.colorScheme.surface, const Color(0xFF17151C));
    expect(theme.progressIndicatorTheme.color, const Color(0xFFC7BBD4));
    expect(theme.extension<CgflixPalette>(), CgflixPalette.isis);
  });

  test('Heitor: claro, fundo #f4fcee, botões e foco em primary verde', () {
    final theme = cgflixAppTheme(CgflixThemeVariant.heitor);
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFDAF1DE));
    expect(theme.colorScheme, cgflixHeitorScheme);
    expect(theme.colorScheme.primary, const Color(0xFF235347));
    expect(theme.progressIndicatorTheme.color, const Color(0xFF235347));
    expect(theme.extension<CgflixPalette>(), CgflixPalette.heitor);
    expect(theme.filledButtonTheme.style?.backgroundColor?.resolve({}), const Color(0xFF235347));
    expect(theme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness, Brightness.dark);
  });

  test('escolha guardada no themeMode: Isis = oled, Heitor = light, Automático = system', () {
    expect(cgflixMaterialThemeMode(settings.ThemeMode.oled), ThemeMode.dark);
    expect(cgflixMaterialThemeMode(settings.ThemeMode.dark), ThemeMode.dark);
    expect(cgflixMaterialThemeMode(settings.ThemeMode.light), ThemeMode.light);
    expect(cgflixMaterialThemeMode(settings.ThemeMode.system), ThemeMode.system);
  });

  testWidgets('player sempre escuro, mesmo dentro do Heitor', (tester) async {
    late Brightness inside;
    await tester.pumpWidget(
      MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.heitor),
        home: cgflixAlwaysDark(
          Builder(
            builder: (context) {
              inside = Theme.of(context).brightness;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(inside, Brightness.dark);
  });
}
