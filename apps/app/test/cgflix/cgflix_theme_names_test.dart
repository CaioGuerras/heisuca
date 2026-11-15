import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme_picker.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/tela_oled.dart';

void main() {
  tearDown(() => TelaOled.ativa = false);

  test('nomes visíveis dos temas', () {
    expect(cgflixThemeName(settings.ThemeMode.system), 'Automático');
    expect(cgflixThemeName(settings.ThemeMode.oled), 'Escuro');
    expect(cgflixThemeName(settings.ThemeMode.dark), 'Escuro');
    expect(cgflixThemeName(settings.ThemeMode.light), 'Claro');
    expect(cgflixThemeName(settings.ThemeMode.sumi), 'OLED');
  });

  test('descrições dos temas', () {
    expect(cgflixThemeDescription(settings.ThemeMode.oled), 'Fundo escuro');
    expect(cgflixThemeDescription(settings.ThemeMode.light), 'Fundo claro');
    expect(cgflixThemeDescription(settings.ThemeMode.sumi), 'Preto puro, economiza bateria em tela OLED');
    expect(cgflixThemeDescription(settings.ThemeMode.system), 'Segue o modo claro/escuro do aparelho');
    TelaOled.ativa = true;
    expect(cgflixThemeDescription(settings.ThemeMode.system), 'Segue o aparelho; no escuro usa o OLED');
  });
}
