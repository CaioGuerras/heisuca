import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/home/cgflix_cards.dart';
import 'package:heisuca/heisuca/heisuca_home_screen.dart';
import 'package:heisuca/heisuca/heisuca_library_screen.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import '../cgflix/cgflix_contraste_test.dart' show contrast;
import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/heisuca_tap_targets.dart';
import '../test_helpers/prefs.dart';
import '../visual/heisuca_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetSharedPreferencesForTest);
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.pt);
    await heisucaLoadFonts();
    await (FontLoader('Sora')..addFont(rootBundle.load('assets/fonts/Sora-VF.ttf'))).load();
  });
  final phase = Platform.environment['P3_STATE_PHASE'];
  for (final mode in [settings.ThemeMode.oled, settings.ThemeMode.light, settings.ThemeMode.dark]) {
    for (final (device, size, dpr) in [
      ('moto', const Size(1080, 2400), 2.625),
      ('tab', const Size(1200, 1920), 1.5),
    ]) {
      for (final landscape in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          for (final (screen, scenario) in [
            ('inicio', 'vazio'), ('inicio', 'erro'), ('inicio', 'carregando'), ('inicio', 'offline'),
            ('biblioteca', 'vazio'), ('biblioteca', 'erro'), ('biblioteca', 'carregando'),
          ]) {
            final tag = '$screen-$scenario-${mode.name}-$device-${landscape ? "paisagem" : "retrato"}-f${(scale * 100).round()}';
            testWidgets('P3 estado $tag', (tester) async {
              final f = HeisucaP3Fixture(scenario: scenario);
              await tester.runAsync(() => f.initialize(mode));
              addTearDown(() => tester.runAsync(f.dispose));
              tester.view.devicePixelRatio = dpr;
              tester.view.physicalSize = landscape ? Size(size.height, size.width) : size;
              tester.view.padding = FakeViewPadding(top: 24 * dpr, bottom: 24 * dpr);
              addTearDown(tester.view.reset);
              final boundary = GlobalKey();
              final semantics = tester.ensureSemantics();
              final errors = <String>[];
              final previous = FlutterError.onError;
              FlutterError.onError = (details) {
                errors.add(details.toString());
                if (!(details.library == 'rendering library' && details.exceptionAsString().contains('RenderFlex overflowed'))) {
                  previous?.call(details);
                }
              };
              try {
                await tester.pumpWidget(f.wrap(MaterialApp(
                  theme: mode == settings.ThemeMode.light ? cgflixLightTheme() : cgflixDarkTheme(mode),
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale), disableAnimations: true),
                    child: RepaintBoundary(key: boundary, child: child!)),
                  home: f.scope(screen == 'inicio' ? const HeisucaHomeScreen() : const HeisucaLibraryScreen()),
                )));
                for (var i = 0; i < 10; i++) {
                  await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 20)));
                  await tester.pump(const Duration(milliseconds: 100));
                }
                if (screen == 'inicio' && scenario == 'erro') {
                  if (find.text('Não foi possível conectar ao acervo').evaluate().isEmpty) {
                    errors.add('Falha sem cache termina sem mensagem de erro na Início.');
                  } else {
                    final hint = tester.widget<Text>(find.text('Verifique a conexão ou puxe para atualizar'));
                    final bg = tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor!;
                    if (contrast(Color.alphaBlend(hint.style!.color!, bg), bg) < 4.5) {
                      errors.add('Texto de orientação do erro não passa AA no fundo real.');
                    }
                  }
                }
                if (screen == 'inicio' && scenario == 'offline') {
                  final heading = find.text('Esta fonte está indisponível');
                  expect(heading, findsOneWidget);
                  final text = tester.widget<RichText>(find.descendant(of: heading, matching: find.byType(RichText)));
                  if (text.text.style!.fontFamily != 'Sora') errors.add('Título de fonte indisponível não usa Sora.');
                }
                if (screen == 'inicio' && scenario == 'carregando') expect(find.byType(CgflixShimmer), findsWidgets);
                if (screen == 'biblioteca') {
                  if (scenario == 'erro') {
                    expect(find.text('Não foi possível carregar as bibliotecas.'), findsOneWidget);
                    if (find.text('Nenhum título disponível nesta seleção.').evaluate().isNotEmpty) {
                      errors.add('Falha de carregamento também é apresentada como biblioteca vazia.');
                    }
                  } else if (scenario == 'vazio') {
                    expect(find.text('Nenhum título disponível nesta seleção.'), findsOneWidget);
                  } else { expect(find.byType(LinearProgressIndicator), findsWidgets); }
                }
                final targets = await heisucaTapTargets.evaluate(tester);
                if (!targets.passed) errors.add(targets.reason!);
                if (phase != null) {
                  final out = Directory('../../docs/evidencias/p3/estados-$phase')..createSync(recursive: true);
                  await tester.runAsync(() async {
                    final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
                    final frame = await render.toImage(pixelRatio: dpr);
                    final png = await frame.toByteData(format: ui.ImageByteFormat.png);
                    File('${out.path}/$tag.png').writeAsBytesSync(png!.buffer.asUint8List());
                    frame.dispose();
                  });
                  File('${out.path}/$tag.json').writeAsStringSync(jsonEncode({
                    'tela': screen, 'estado': scenario, 'tema': mode.name, 'dispositivo': device, 'fonte': scale,
                    'larguraPx': tester.view.physicalSize.width, 'alturaPx': tester.view.physicalSize.height,
                    'dpr': dpr, 'erros': errors, 'limite': 'tela e cliente reais com servidor HTTP falso; sem aparelho',
                  }));
                }
              } finally {
                f.releasePendingResponses();
                await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 20)));
                await tester.pump(const Duration(milliseconds: 100));
                await tester.pumpWidget(const SizedBox());
                await tester.pump();
                FlutterError.onError = previous;
                semantics.dispose();
              }
              expect(errors, isEmpty, reason: tag);
            }, variant: TargetPlatformVariant.only(TargetPlatform.android));
          }
        }
      }
    }
  }
}
