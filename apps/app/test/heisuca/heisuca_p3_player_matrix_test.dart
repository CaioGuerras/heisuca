import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/watch_together/providers/watch_together_provider.dart';
import 'package:heisuca/widgets/overlay_sheet.dart';
import 'package:heisuca/widgets/video_controls/mobile_video_controls.dart';
import 'package:heisuca/widgets/video_controls/models/track_controls_state.dart';
import '../test_helpers/player_hud_fixture.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/heisuca_tap_targets.dart';
import '../visual/heisuca_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetSharedPreferencesForTest);
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.pt);
    await initializeDateFormatting('pt');
    await heisucaLoadFonts();
    await (FontLoader('Sora')..addFont(rootBundle.load('assets/fonts/Sora-VF.ttf'))).load();
  });
  final phase = Platform.environment['P3_PLAYER_PHASE'];
  final onlyCase = Platform.environment['P3_PLAYER_CASE'];
  for (final mode in [settings.ThemeMode.oled, settings.ThemeMode.light, settings.ThemeMode.dark]) {
    for (final (device, size, dpr) in [
      ('moto', const Size(1080, 2400), 2.625),
      ('tab', const Size(1200, 1920), 1.5),
    ]) {
      for (final landscape in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          for (final scene in ['hud', 'faixas', 'ajustes', 'qualidade']) {
            final tag = '$scene-${mode.name}-$device-${landscape ? "paisagem" : "retrato"}-f${(scale * 100).round()}';
            if (onlyCase != null && tag != onlyCase) continue;
            testWidgets('P3 player $tag', (tester) async {
              await settings.SettingsService.getInstance();
              tester.view.devicePixelRatio = dpr;
              tester.view.physicalSize = landscape ? Size(size.height, size.width) : size;
              tester.view.padding = FakeViewPadding(top: 24 * dpr, bottom: 24 * dpr);
              addTearDown(tester.view.reset);
              final player = HeisucaHudPlayer();
              final watch = WatchTogetherProvider();
              addTearDown(player.dispose);
              addTearDown(watch.dispose);
              final boundary = GlobalKey();
              final errors = <String>[];
              final handler = FlutterError.onError;
              final semantics = tester.ensureSemantics();
              FlutterError.onError = (details) {
                errors.add(details.toString());
                if (!(details.library == 'rendering library' && details.exceptionAsString().contains('RenderFlex overflowed'))) {
                  handler?.call(details);
                }
              };
              try {
                await tester.pumpWidget(ChangeNotifierProvider.value(value: watch, child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: mode == settings.ThemeMode.light ? cgflixLightTheme() : cgflixDarkTheme(mode),
                  builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale), disableAnimations: true),
                    child: RepaintBoundary(key: boundary, child: child!)),
                  home: Scaffold(body: OverlaySheetHost(child: MobileVideoControls(
                    player: player, metadata: testMediaItem(id: 'ep', title: 'Uma viagem para lembrar'),
                    chapters: const [], chaptersLoaded: true, seekTimeSmall: 10,
                    trackChapterControls: const SizedBox.shrink(),
                    heisucaTrackState: TrackControlsState(serverSupportsTranscoding: true,
                      onSwitchQualityPreset: (_) {}, onAudioTrackChanged: (_) {}, onSubtitleTrackChanged: (_) {},
                      onTogglePIPMode: () {}, onCycleBoxFitMode: () {}, onToggleScreenLock: () {},
                      onToggleRotationLock: () {}, onToggleAmbientLighting: () {}),
                    onSeek: (_) {}, onSeekEnd: (_) {}, onPlayPause: () {},
                  ))),
                )));
                await tester.pumpAndSettle();
                if (scene == 'faixas') {
                  await tester.ensureVisible(find.textContaining('Japonês 5.1'));
                  await tester.pumpAndSettle();
                  await tester.tap(find.textContaining('Japonês 5.1'));
                  await tester.pumpAndSettle();
                  expect(find.textContaining('Português'), findsWidgets);
                } else if (scene == 'ajustes' || scene == 'qualidade') {
                  await tester.ensureVisible(find.text('Ajustes'));
                  await tester.pumpAndSettle();
                  await tester.tap(find.text('Ajustes'));
                  await tester.pumpAndSettle();
                  if (scene == 'qualidade') {
                    await tester.tap(find.text('Qualidade'));
                    await tester.pumpAndSettle();
                  }
                }
                final targets = await heisucaTapTargets.evaluate(tester);
                if (!targets.passed) errors.add(targets.reason!);
                if (phase != null) {
                  final out = Directory('../../docs/evidencias/p3/player-$phase')..createSync(recursive: true);
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
                    'dpr': dpr, 'erros': errors,
                    'limite': 'HUD e folhas reais com player falso em Linux; não comprova vídeo nativo/aparelho/PiP',
                  }));
                }
                await tester.pumpWidget(const SizedBox());
                await tester.pump();
              } finally { FlutterError.onError = handler; semantics.dispose(); }
              expect(errors, isEmpty, reason: tag);
            }, variant: TargetPlatformVariant.only(TargetPlatform.android));
          }
        }
      }
    }
  }
}
