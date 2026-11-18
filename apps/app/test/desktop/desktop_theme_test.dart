import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/desktop_app.dart';
import 'package:heisuca/desktop/desktop_preferences.dart';
import 'package:heisuca/desktop/desktop_theme.dart';
import 'package:heisuca/design/tema.dart';

void main() {
  test('temas usam os tokens oficiais, botão neutro e contraste de texto pequeno', () {
    for (final palette in [TemaHeisuca.shikkoku, TemaHeisuca.hisui, TemaHeisuca.sumi]) {
      final theme = desktopTheme(palette.nome, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, palette.fundo);
      expect(theme.extension<TemaHeisuca>(), same(palette));
      expect(theme.filledButtonTheme.style!.backgroundColor!.resolve({}), palette.botaoFundo);
      final first = palette.fundo.computeLuminance(), second = palette.texto2.computeLuminance();
      expect((math.max(first, second) + .05) / (math.min(first, second) + .05), greaterThanOrEqualTo(4.5));
      expect(theme.splashFactory, NoSplash.splashFactory);
    }
  });

  testWidgets('tema automático acompanha mudança do sistema e Ajustes cabe com texto 200%', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.binding.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    final preferences = DesktopPreferences()..setTheme('system');
    addTearDown(preferences.dispose);
    await tester.pumpWidget(MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: DesktopApp(preferences: preferences, onSetFullScreen: (value) async => value)));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.brightness, Brightness.light);
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
