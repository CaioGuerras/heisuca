import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/dialogs.dart';
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
  final phase = Platform.environment['P3_DIALOG_PHASE'];
  for (final mode in [settings.ThemeMode.oled, settings.ThemeMode.light, settings.ThemeMode.dark]) {
    for (final (device, size, dpr) in [
      ('moto', const Size(1080, 2400), 2.625),
      ('tab', const Size(1200, 1920), 1.5),
    ]) {
      for (final landscape in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          for (final scene in ['confirmar', 'nome', 'erro', 'opcao', 'carregando']) {
            final tag = '$scene-${mode.name}-$device-${landscape ? "paisagem" : "retrato"}-f${(scale * 100).round()}';
            testWidgets('P3 diálogo $tag', (tester) async {
              await settings.SettingsService.getInstance();
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
                await tester.pumpWidget(TranslationProvider(child: MaterialApp(
                  theme: mode == settings.ThemeMode.light ? cgflixLightTheme() : cgflixDarkTheme(mode),
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale), disableAnimations: true),
                    child: RepaintBoundary(key: boundary, child: child!)),
                  home: Scaffold(body: Builder(builder: (context) => Center(child: TextButton(
                    onPressed: () {
                      switch (scene) {
                        case 'confirmar':
                          unawaited(showConfirmDialog(context, title: t.common.logout,
                            message: t.messages.logoutConfirm, confirmText: t.common.logout, isDestructive: true));
                        case 'nome':
                          unawaited(showTextInputDialog(context, title: t.mpvConfig.saveAsPreset,
                            labelText: t.mpvConfig.presetName, hintText: t.mpvConfig.presetNameHint));
                        case 'erro': unawaited(showMediaUnreadableDialog(context));
                        case 'opcao':
                          // Argumentos do fluxo existente de remoção de regra. Não cria regra/offline.
                          unawaited(showConfirmWithSwitchDialog(context, title: t.downloads.removeSyncRule,
                            message: t.downloads.removeListSyncRuleConfirm(title: 'Filmes da família'),
                            confirmText: t.downloads.removeSyncRule, switchTitle: t.downloads.deleteSyncRuleDownloads,
                            switchSubtitle: t.downloads.deleteSyncRuleDownloadsDescription));
                        case 'carregando': showLoadingDialog(context);
                      }
                    }, child: const Text('Abrir'))))),
                )));
                await tester.tap(find.text('Abrir'));
                for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
                if (scene != 'carregando') {
                  expect(find.byType(AlertDialog), findsOneWidget);
                  final rect = tester.getRect(find.byType(AlertDialog));
                  final window = tester.view.physicalSize / dpr;
                  if (rect.left < 0 || rect.top < 0 || rect.right > window.width || rect.bottom > window.height) {
                    errors.add('O diálogo fica fora da janela: $rect / $window.');
                  }
                  final touch = await heisucaTapTargets.evaluate(tester);
                  if (!touch.passed) errors.add(touch.reason!);
                } else { expect(find.byType(CircularProgressIndicator), findsOneWidget); }
                if (phase != null) {
                  final out = Directory('../../docs/evidencias/p3/dialogos-$phase')..createSync(recursive: true);
                  await tester.runAsync(() async {
                    final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
                    final frame = await render.toImage(pixelRatio: dpr);
                    final png = await frame.toByteData(format: ui.ImageByteFormat.png);
                    File('${out.path}/$tag.png').writeAsBytesSync(png!.buffer.asUint8List());
                    frame.dispose();
                  });
                  File('${out.path}/$tag.json').writeAsStringSync(jsonEncode({
                    'cena': scene, 'tema': mode.name, 'dispositivo': device, 'fonte': scale,
                    'larguraPx': tester.view.physicalSize.width, 'alturaPx': tester.view.physicalSize.height,
                    'dpr': dpr, 'erros': errors, 'limite': 'diálogo real com argumentos do app; sem aparelho nativo',
                  }));
                }
                if (scene == 'opcao') {
                  final control = find.byType(Switch);
                  expect(tester.widget<Switch>(control).value, isFalse);
                  await tester.ensureVisible(control);
                  await tester.pump();
                  await tester.tap(control);
                  await tester.pump();
                  expect(tester.widget<Switch>(control).value, isTrue);
                }
                if (scene == 'nome') {
                  await tester.enterText(find.byType(EditableText), 'Família');
                  await tester.pump();
                  final field = tester.widget<EditableText>(find.byType(EditableText));
                  expect(field.controller.text, 'Família');
                  expect(field.style.fontFamily, 'Inter');
                }
              } finally {
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
