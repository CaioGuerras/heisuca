import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_logo.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/heisuca/heisuca_profile_screen.dart';
import 'package:heisuca/heisuca/heisuca_title_parts.dart';
import 'package:heisuca/widgets/settings_section.dart';
import '../cgflix/cgflix_contraste_test.dart' show contrast;
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/screens/settings/about_screen.dart';
import 'package:heisuca/screens/settings/mpv_config_screen.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetSharedPreferencesForTest);
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.pt);
    PackageInfo.setMockInitialValues(appName: 'Heisuca', packageName: 'app.heisuca.player.teste.home',
        version: '2.0.34', buildNumber: '2036', buildSignature: '');
  });
  testWidgets('P3 editor avançado usa a fonte monoespaçada do app', (tester) async {
    await settings.SettingsService.getInstance();
    await tester.pumpWidget(TranslationProvider(child: MaterialApp(theme: cgflixAppTheme(),
      home: const MpvConfigScreen())));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(find.byType(EditableText)).style.fontFamily, cgflixMonoFamily);
  });
  for (final (name, widget) in [
    ('ficha', const HeisucaSectionTitle('Episódios', colors: HeisucaTitleColors(
      page: Colors.black, text: Colors.white, accent: Colors.white, isLight: false))),
    ('configurações', const SettingsSectionHeader('Reprodução')),
  ]) {
    testWidgets('P3 título de seção $name renderiza Sora', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(), home: Scaffold(body: widget)));
      final text = tester.widget<RichText>(find.byType(RichText).first);
      expect(text.text.style!.fontFamily, 'Sora');
    });
  }
  for (final (name, theme) in [
    ('Shikkoku', cgflixAppTheme()),
    ('Hisui claro', cgflixLightTheme()),
    ('Hisui escuro', cgflixDarkTheme(settings.ThemeMode.dark)),
  ]) {
    testWidgets('P3 $name: outras fontes usam a superfície do tema', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: theme, home: const HeisucaLoginScreen()));
      await tester.tap(find.text('Outros servidores e pastas locais'));
      await tester.pumpAndSettle();
      expect(tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
        theme.extension<CgflixPalette>()!.surface);
    });
    testWidgets('P3 $name: ícones de Você acompanham o destaque do tema', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: theme, home: const HeisucaProfileScreen()));
      await tester.pump();
      final icon = tester.widget<Icon>(find.byIcon(Symbols.download_rounded));
      expect(icon.color, theme.extension<CgflixPalette>()!.accent);
    });
    for (final (screen, child) in [('login', const HeisucaLoginScreen()), ('Você', const HeisucaProfileScreen())]) {
      testWidgets('P3 $name: $screen usa o canvas do tema', (tester) async {
        await tester.pumpWidget(MaterialApp(theme: theme, home: child));
        await tester.pump();
        expect(tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
            theme.extension<CgflixPalette>()!.background);
      });
    }
    testWidgets('P3 $name: dica do campo de login tem AA no preenchimento real', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: theme, home: const HeisucaLoginScreen()));
      await tester.pump();
      final decorator = tester.widget<InputDecorator>(find.byType(InputDecorator).first);
      final bg = decorator.decoration.fillColor!;
      final fg = decorator.decoration.hintStyle!.color!;
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
    });
    test('P3 $name: títulos Sora e texto Inter no contrato do tema', () {
      final t = theme.textTheme;
      for (final style in [t.displayLarge, t.displayMedium, t.displaySmall,
          t.headlineLarge, t.headlineMedium, t.headlineSmall,
          t.titleLarge, t.titleMedium, t.titleSmall]) {
        expect(style!.fontFamily, 'Sora');
      }
      for (final style in [t.bodyLarge, t.bodyMedium, t.bodySmall, t.labelLarge, t.labelMedium, t.labelSmall]) {
        expect(style!.fontFamily, 'Inter');
      }
      expect(theme.appBarTheme.titleTextStyle!.fontFamily, 'Sora');
    });
  }
  testWidgets('P3 logo completo é SVG, sem palavra digitada', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(),
      home: const Scaffold(body: HeisucaLogo(comSlogan: true))));
    await tester.pumpAndSettle();
    expect(find.text('HEISUCA'), findsNothing);
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture).first);
    expect((svg.bytesLoader as SvgAssetLoader).assetName, contains('marca_site_'));
    expect(find.text('Nada entre você e o filme.'), findsOneWidget);
  });
  testWidgets('P3 Sobre usa marca SVG, sem palavra digitada', (tester) async {
    await tester.pumpWidget(TranslationProvider(child: MaterialApp(theme: cgflixAppTheme(), home: const AboutScreen())));
    await tester.pumpAndSettle();
    expect(find.text('HEISUCA'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
