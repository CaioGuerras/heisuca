import 'package:heisuca/heisuca/kids/heisuca_kids_opening.dart';
import 'package:heisuca/cgflix/cgflix_app_icon.dart';
import 'dart:io';
import 'package:heisuca/theme/mono_theme.dart';
import 'package:heisuca/heisuca/theme/temas/tema_ichigo_noite.dart';
import 'package:heisuca/heisuca/theme/temas/tema_sorairo_noite.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/cgflix_theme_picker.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/platform_detector.dart';
import 'package:heisuca/heisuca/theme/temas/tema_shikkoku.dart';
import 'package:heisuca/heisuca/theme/temas/tema_hisui.dart';
import 'package:heisuca/heisuca/theme/temas/tema_sumi.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('tokens gerados são cópias exatas da fonte da marca', () {
    for (final file in [
      'heisuca_base.dart',
      'temas/tema_shikkoku.dart',
      'temas/tema_hisui.dart',
      'temas/tema_sumi.dart',
      'temas/tema_ichigo.dart',
      'temas/tema_ichigo_noite.dart',
      'temas/tema_sorairo.dart',
      'temas/tema_sorairo_noite.dart',
    ]) {
      expect(
        File('lib/heisuca/theme/$file').readAsStringSync(),
        File('../../docs/marca_2026-11-09/dart/$file').readAsStringSync(),
        reason: file,
      );
    }
  });
  for (final variant in [CgflixThemeVariant.ichigo, CgflixThemeVariant.sorairo]) {
    for (final dark in [false, true]) {
      test('acento ${variant.name}, escuro=$dark: fundo e texto permanecem adultos', () {
        final palette = monoTheme(dark: dark, kids: variant).extension<CgflixPalette>()!;
        final base = dark ? CgflixPalette.isis : CgflixPalette.heitor;
        expect(palette.background, base.background);
        expect(palette.surface, base.surface);
        expect(palette.text, base.text);
        expect(palette.action, base.action);
        if (dark) {
          expect(
            palette.accent,
            variant == CgflixThemeVariant.ichigo ? TemaIchigoNoite.temaCorAcento : TemaSorairoNoite.temaCorAcento,
          );
        }
      });
    }
  }
  test('Sumi usa os tokens neutros oficiais', () {
    final sumi = cgflixDarkTheme(settings.ThemeMode.sumi).extension<CgflixPalette>()!;
    expect(sumi.background, TemaSumi.temaCorFundo);
    expect(sumi.text, TemaSumi.temaCorTexto);
    expect(sumi.action, TemaSumi.temaCorBotaoFundo);
  });
  tearDown(() => TvDetectionService.debugSetTvOverride(null));
  for (final entrada in {
    'Shinju': 'light',
    'verde': 'light',
    'roxo': 'oled',
    'dark': 'oled',
    'projetor': 'sumi',
    'claro': 'light',
    'Matinê': 'light',
    'Automático': 'system',
  }.entries) {
    test('migra e persiste o nome antigo ${entrada.key}', () async {
      resetSharedPreferencesForTest(initialAsync: {'theme_mode': entrada.key});
      final service = await settings.SettingsService.getInstance();
      expect(service.read(settings.SettingsService.themeMode).name, entrada.value);
      expect(service.readNullableString('theme_mode'), entrada.value);
    });
  }
  test('TV migra tema claro salvo para Shikkoku', () async {
    TvDetectionService.debugSetTvOverride(true);
    resetSharedPreferencesForTest(initialAsync: {'theme_mode': 'light'});
    final service = await settings.SettingsService.getInstance();
    expect(service.read(settings.SettingsService.themeMode).name, 'oled');
    expect(service.readNullableString('theme_mode'), 'oled');
  });
  test('TV oferece apenas Shikkoku e Sumi', () {
    TvDetectionService.debugSetTvOverride(true);
    expect(cgflixThemeChoices.map(cgflixThemeName), ['Shikkoku', 'Sumi']);
  });
  test('celular oferece Automático e os três temas', () {
    TvDetectionService.debugSetTvOverride(false);
    expect(cgflixThemeChoices.map(cgflixThemeName), ['Automático', 'Shikkoku', 'Hisui', 'Sumi']);
  });
  for (final t in [
    ('Shikkoku', TemaShikkoku.temaCorFundo, TemaShikkoku.temaCorTexto, TemaShikkoku.temaCorTexto2),
    ('Hisui', TemaHisui.temaCorFundo, TemaHisui.temaCorTexto, TemaHisui.temaCorTexto2),
    ('Sumi', TemaSumi.temaCorFundo, TemaSumi.temaCorTexto, TemaSumi.temaCorTexto2),
  ]) {
    test('${t.$1}: contraste dos tokens oficiais', () {
      double contraste(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return (math.max(x, y) + .05) / (math.min(x, y) + .05);
      }

      expect(contraste(t.$2, t.$3), greaterThanOrEqualTo(7));
      expect(contraste(t.$2, t.$4), greaterThanOrEqualTo(4.5));
    });
  }
  testWidgets('ícone automático acompanha o sistema', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    expect(cgflixWantsHeitorIcon(settings.ThemeMode.system), isTrue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    expect(cgflixWantsHeitorIcon(settings.ThemeMode.system), isFalse);
  });
  testWidgets('TV: abertura infantil mantém Shikkoku ou Sumi, mesmo com sistema claro', (tester) async {
    TvDetectionService.debugSetTvOverride(true);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    for (final adult in [CgflixThemeVariant.isis, CgflixThemeVariant.sumi]) {
      final theme = cgflixAppTheme(adult);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const HeisucaKidsOpening(variant: CgflixThemeVariant.ichigo, name: 'Perfil'),
        ),
      );
      final material = tester.widget<Material>(
        find.descendant(of: find.byType(HeisucaKidsOpening), matching: find.byType(Material)).first,
      );
      expect(material.color, theme.extension<CgflixPalette>()!.background);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets('player usa só neutros do Sumi e conserva o tema fora dele', (tester) async {
    ThemeData? primeiro;
    for (final variant in [CgflixThemeVariant.isis, CgflixThemeVariant.heitor, CgflixThemeVariant.sumi]) {
      final externo = cgflixAppTheme(variant);
      late ThemeData interno;
      await tester.pumpWidget(
        MaterialApp(
          theme: externo,
          home: cgflixAlwaysDark(
            Builder(
              builder: (context) {
                interno = Theme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      final palette = interno.extension<CgflixPalette>()!;
      expect(palette.background, TemaSumi.temaCorFundo);
      expect(palette.accent, TemaSumi.temaCorTexto);
      expect(palette.progress, TemaSumi.temaCorTexto);
      expect(interno.colorScheme.primary, TemaSumi.temaCorTexto);
      expect(interno.radioTheme.fillColor!.resolve({WidgetState.selected}), TemaSumi.temaCorTexto);
      expect(interno.sliderTheme.activeTrackColor, TemaSumi.temaCorTexto);
      expect(interno.progressIndicatorTheme.color, TemaSumi.temaCorTexto);
      primeiro ??= interno;
      expect(identical(primeiro, interno), isTrue, reason: 'tema do player deve permanecer em cache');
      expect(externo.extension<CgflixPalette>(), CgflixPalette.forVariant(variant));
      if (variant == CgflixThemeVariant.sumi) {
        expect(externo.colorScheme.primary, TemaSumi.temaCorAcento);
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
  test('tema aplicado usa tokens e botão neutro', () {
    final tema = cgflixAppTheme();
    expect(tema.scaffoldBackgroundColor, TemaShikkoku.temaCorFundo);
    expect(tema.textTheme.titleLarge?.fontFamily, 'Inter');
    expect(tema.filledButtonTheme.style!.backgroundColor!.resolve({}), TemaShikkoku.temaCorBotaoFundo);
  });
}
