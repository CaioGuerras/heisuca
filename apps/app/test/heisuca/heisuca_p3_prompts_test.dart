import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/providers/playback_state_provider.dart';
import 'package:heisuca/screens/video_player/widgets/player_prompt_overlays.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/widgets/video_controls/player_chrome_controller.dart';
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
  final phase = Platform.environment['P3_PROMPT_PHASE'];
  for (final mode in [settings.ThemeMode.oled, settings.ThemeMode.light, settings.ThemeMode.dark]) {
    for (final (device, size, dpr) in [
      ('moto', const Size(1080, 2400), 2.625),
      ('tab', const Size(1200, 1920), 1.5),
    ]) {
      for (final landscape in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          for (final scene in ['sono', 'episodios', 'proximo']) {
            final tag = '$scene-${mode.name}-$device-${landscape ? "paisagem" : "retrato"}-f${(scale * 100).round()}';
            testWidgets('P3 prompt $tag', (tester) async {
              await settings.SettingsService.getInstance();
              tester.view.devicePixelRatio = dpr;
              tester.view.physicalSize = landscape ? Size(size.height, size.width) : size;
              tester.view.padding = FakeViewPadding(top: 24 * dpr, bottom: 24 * dpr);
              addTearDown(tester.view.reset);
              final chrome = PlayerChromeController();
              final playback = PlaybackStateProvider();
              final cancel = FocusNode();
              final confirm = FocusNode();
              final countdown = ValueNotifier(30);
              addTearDown(chrome.dispose);
              addTearDown(playback.dispose);
              addTearDown(cancel.dispose);
              addTearDown(confirm.dispose);
              addTearDown(countdown.dispose);
              final episode = MediaItem.jellyfin(id: 'ep2', serverId: 'srv-1', kind: MediaKind.episode,
                title: 'Uma história para continuar em família', parentIndex: 1, index: 2);
              final heading = scene == 'proximo' ? 'T1 E2 · ${episode.title}' : t.videoControls.stillWatching;
              final prompt = scene == 'proximo'
                  ? VideoPlayerPlayNextOverlay(visible: true, nextEpisode: episode,
                      autoPlayCountdown: countdown, cancelFocusNode: cancel, confirmFocusNode: confirm,
                      chromeController: chrome, onCancel: () {}, onPlayNext: () {})
                  : VideoPlayerStillWatchingOverlay(visible: true, pausedForEpisodes: scene == 'episodios',
                      countdown: countdown, pauseFocusNode: cancel, continueFocusNode: confirm,
                      chromeController: chrome, onPause: () {}, onContinue: () {});
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
                await tester.pumpWidget(ChangeNotifierProvider.value(value: playback, child: MaterialApp(
                  theme: mode == settings.ThemeMode.light ? cgflixLightTheme() : cgflixDarkTheme(mode),
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale), disableAnimations: true),
                    child: RepaintBoundary(key: boundary, child: child!)),
                  home: Scaffold(body: Stack(children: [prompt])),
                )));
                await tester.pumpAndSettle();
                final headingFinder = find.text(heading);
                expect(headingFinder, findsOneWidget);
                final renderedHeading = tester.widget<RichText>(find.descendant(of: headingFinder, matching: find.byType(RichText)));
                if (renderedHeading.text.style!.fontFamily != 'Sora') errors.add('Título do aviso não renderiza Sora.');
                final card = tester.widget<Container>(find.ancestor(of: headingFinder, matching: find.byType(Container)).first);
                final color = (card.decoration! as BoxDecoration).color;
                if (color != cgflixDarkTheme(mode).extension<CgflixPalette>()!.surface && mode != settings.ThemeMode.light ||
                    mode == settings.ThemeMode.light && color != cgflixLightTheme().extension<CgflixPalette>()!.surface) {
                  errors.add('O aviso usa uma superfície fora da paleta.');
                }
                final rect = tester.getRect(find.byWidget(prompt));
                final window = tester.view.physicalSize / dpr;
                if (rect.left < 0 || rect.top < 0 || rect.right > window.width || rect.bottom > window.height) {
                  errors.add('O aviso fica fora da janela: $rect / $window.');
                }
                final touch = await heisucaTapTargets.evaluate(tester);
                if (!touch.passed) errors.add(touch.reason!);
                if (phase != null) {
                  final out = Directory('../../docs/evidencias/p3/prompts-$phase')..createSync(recursive: true);
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
                    'dpr': dpr, 'erros': errors, 'limite': 'widget real; sem player/aparelho nativo',
                  }));
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
