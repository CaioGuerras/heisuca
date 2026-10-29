import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_settings_screen.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/providers/theme_provider.dart';
import 'package:heisuca/services/settings_service.dart' as settings;

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
  });

  testWidgets('F3: a tela mostra 2 temas (Shikkoku e Hisui) e não mostra Hisui escuro', (tester) async {
    tester.view.physicalSize = const Size(412, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = await settings.SettingsService.getInstance();
    await service.write(settings.SettingsService.themeMode, settings.ThemeMode.oled);
    final provider = ThemeProvider();
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<ThemeProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: cgflixAppTheme(CgflixThemeVariant.isis),
            home: const Scaffold(body: HeisucaSettingsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shikkoku'), findsOneWidget);
    expect(find.text('Hisui'), findsOneWidget);
    expect(find.text('Hisui escuro'), findsNothing);
  });

  test('F3: dark salvo migra para Shikkoku (ThemeMode.oled)', () async {
    resetSharedPreferencesForTest(initialAsync: {'theme_mode': 'dark'});

    final service = await settings.SettingsService.getInstance();
    final mode = service.read(settings.SettingsService.themeMode);
    expect(mode, settings.ThemeMode.oled);
    expect(service.readNullableString('theme_mode'), 'oled');

    final provider = ThemeProvider();
    addTearDown(provider.dispose);
    expect(provider.themeMode, settings.ThemeMode.oled);
  });

  test('F3: modo Automático com sistema escuro resolve Shikkoku (CgflixPalette.isis)', () {
    final darkTheme = cgflixBrandTheme(
      ThemeData(brightness: Brightness.dark),
      oled: false,
    );
    final palette = darkTheme.extension<CgflixPalette>();
    expect(palette?.variant, CgflixThemeVariant.isis);
  });
}
