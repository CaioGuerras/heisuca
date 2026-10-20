import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/services/settings_service.dart' as settings;

void main() {
  test('Isis (padrão): escuro, fundo preto puro e destaque roxo', () {
    final theme = cgflixAppTheme();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(theme.colorScheme, cgflixIsisScheme);
    expect(theme.colorScheme.surface, const Color(0xFF120E1A));
    expect(theme.progressIndicatorTheme.color, const Color(0xFFA855F7));
    expect(theme.extension<CgflixPalette>(), CgflixPalette.isis);
  });

  test('Heitor: claro, fundo #f4fcee, botões e foco em primary verde', () {
    final theme = cgflixAppTheme(CgflixThemeVariant.heitor);
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF4FCEE));
    expect(theme.colorScheme, cgflixHeitorScheme);
    expect(theme.colorScheme.primary, const Color(0xFF006E28));
    expect(theme.progressIndicatorTheme.color, const Color(0xFF006E28));
    expect(theme.extension<CgflixPalette>(), CgflixPalette.heitor);
    expect(theme.filledButtonTheme.style?.backgroundColor?.resolve({}), const Color(0xFF006E28));
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
