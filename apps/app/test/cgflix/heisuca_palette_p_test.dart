import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/theme/mono_theme.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import '../test_helpers/prefs.dart';
import 'package:heisuca/theme/mono_tokens.dart';
import 'package:heisuca/heisuca/heisuca_brand_colors.dart';
import 'package:heisuca/providers/theme_provider.dart';
import 'package:heisuca/cgflix/requests/cgflix_requests_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'cgflix_contraste_test.dart' show contrast;
import 'package:heisuca/heisuca/heisuca_home_style.dart';
import 'package:heisuca/heisuca/heisuca_theme.dart';

void main() {
  setUp(resetSharedPreferencesForTest);
  test('P2 Hisui escuro permanece escolhido depois da abertura', () async {
    final service = await settings.SettingsService.getInstance();
    await service.write(settings.SettingsService.themeMode, settings.ThemeMode.dark);
    final provider = ThemeProvider();
    await Future<void>.delayed(Duration.zero);
    expect(provider.themeMode, settings.ThemeMode.dark);
    expect(provider.darkTheme.scaffoldBackgroundColor, const Color(0xFF051F20));
    expect(cgflixDarkTheme(provider.themeMode), provider.darkTheme);
    provider.dispose();
    expect(service.read(settings.SettingsService.themeMode), settings.ThemeMode.dark);
  });
  test('P2 contraste e cores da marca não alteram o modo infantil', () {
    for (final p in [CgflixPalette.ichigo, CgflixPalette.sorairo]) {
      expect(HeisucaBrandColors(p).substitute('heisuca-word-1', 'path', 'fill', Colors.red), Colors.red);
    }
  });
  test('P2 abertura Android usa os mesmos fundos', () {
    final colors = File('android/app/src/main/res/values/colors.xml').readAsStringSync().toUpperCase();
    for (final color in ['17151C', 'DAF1DE', '051F20']) {
      expect(colors, contains('#$color'));
    }
  });
  test('P2 tokens de compatibilidade seguem a mesma paleta', () {
    expect(HeisucaTheme.roxoFundo, CgflixPalette.isis.background);
    expect(HeisucaTheme.roxoPrimaria, CgflixPalette.isis.accent);
  });
  test('P2 fallback da arte respeita o canvas do tema', () {
    expect(heisucaPageColor(null, isLight: false), CgflixPalette.isis.background);
    expect(heisucaPageColor(null, isLight: true), CgflixPalette.heitor.background);
  });
  testWidgets('P2 selo de erro mantém AA no cartão escuro', (tester) async {
    const p = CgflixPalette.isis;
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(),
      home: Scaffold(backgroundColor: p.surface, body: CgflixStatusBadge(
        label: 'Não disponível', icon: Symbols.block_rounded, color: p.danger))));
    final text = tester.widget<Text>(find.text('Não disponível'));
    final badge = tester.widget<Container>(find.ancestor(of: find.text('Não disponível'), matching: find.byType(Container)).first);
    final bg = Color.alphaBlend((badge.decoration! as BoxDecoration).color!, p.surface);
    expect(contrast(text.style!.color!, bg), greaterThanOrEqualTo(4.5));
  });
  for (final entry in [
    (true, true, const Color(0xFF17151C), const Color(0xFF292531), const Color(0xFFE2DDE7)),
    (false, false, const Color(0xFFDAF1DE), const Color(0xFFFFFFFF), const Color(0xFF051F20)),
    (true, false, const Color(0xFF051F20), const Color(0xFF0B2B26), const Color(0xFFDAF1DE)),
  ]) {
    test('P2 tokens e Material concordam: dark=${entry.$1}, oled=${entry.$2}', () {
      final theme = monoTheme(dark: entry.$1, oled: entry.$2);
      final p = theme.extension<CgflixPalette>()!;
      final t = theme.extension<MonoTokens>()!;
      expect(p.background, entry.$3);
      expect(theme.scaffoldBackgroundColor, entry.$3);
      expect(t.bg, entry.$3);
      expect(p.surface, entry.$4);
      expect(t.surface, entry.$4);
      expect(theme.colorScheme.onSurface, entry.$5);
      expect(p.isLight, !entry.$1);
      final mapper = HeisucaBrandColors(p);
      expect(mapper.substitute('heisuca-word-1', 'path', 'fill', Colors.red), p.text);
      expect(mapper.substitute('heisuca-ink-2', 'path', 'fill', Colors.red), p.onAction);
      expect(mapper.substitute('heisuca-fill-0', 'rect', 'fill', Colors.red), p.accent);
    });
  }
}
