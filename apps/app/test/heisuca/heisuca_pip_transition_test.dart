import 'package:flutter/material.dart';
import '../../integration_test/support/pip_overflow_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/providers/playback_state_provider.dart';
import 'package:heisuca/services/pip_service.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/services/video_volume_controller.dart';
import 'package:heisuca/watch_together/providers/watch_together_provider.dart';
import 'package:heisuca/widgets/video_controls/player_chrome_controller.dart';
import 'package:heisuca/widgets/video_controls/video_controls.dart';
import 'package:heisuca/widgets/video_controls/mobile_video_controls.dart';
import 'package:heisuca/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/watch_together_fakes.dart';

void main() {
  testWidgets('PiP retira o HUD antes de a janela encolher e restaura ao sair', (tester) async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    await tester.runAsync(() async {
      await LocaleSettings.setLocale(AppLocale.en);
      await initializeDateFormatting('en');
    });
    tester.view.physicalSize = const Size(986, 444);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pip = PipService();
    pip.isPipActive.value = false;
    pip.isPipTransitioning.value = false;
    addTearDown(() {
      pip.isPipActive.value = false;
      pip.isPipTransitioning.value = false;
    });
    final player = FakeSyncPlayer(hasRenderedFrame: true, playing: true);
    final volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
    final playback = PlaybackStateProvider();
    final watch = WatchTogetherProvider();
    final chrome = PlayerChromeController();
    final toast = PlayerToastController();
    addTearDown(player.dispose);
    addTearDown(volume.dispose);
    addTearDown(playback.dispose);
    addTearDown(watch.dispose);
    addTearDown(chrome.dispose);
    addTearDown(toast.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<PlaybackStateProvider>.value(value: playback),
        ChangeNotifierProvider<WatchTogetherProvider>.value(value: watch),
      ],
      child: MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.isis).copyWith(platform: TargetPlatform.android),
        home: Scaffold(body: PlexVideoControls(
          player: player,
          volumeController: volume,
          metadata: testMediaItem(id: 'pip-transition'),
          toastController: toast,
          canNavigateMediaItems: false,
          chromeController: chrome,
          isLive: true,
        )),
      ),
    ));
    await tester.pump();
    expect(find.byType(MobileVideoControls), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Dimensões reais da bancada. O callback de modo ativo ainda NÃO chegou.
    pip.isPipTransitioning.value = true;
    await tester.pump();
    tester.view.physicalSize = const Size(240.8, 108.2);
    await tester.pump();
    expect(pip.isPipActive.value, isFalse);
    expect(find.byType(MobileVideoControls), findsNothing);
    expect(tester.takeException(), isNull);

    pip.isPipActive.value = true;
    pip.isPipTransitioning.value = false;
    await tester.pump();
    expect(find.byType(MobileVideoControls), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(986, 444);
    await tester.pump();
    pip.isPipActive.value = false;
    await tester.pump();
    expect(find.byType(MobileVideoControls), findsOneWidget);
    expect(tester.takeException(), isNull);
    chrome.cancelAutoHide();
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('P1: regra reconhece diagnóstico real do HUD pequeno e rejeita janela cheia', (tester) async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    await tester.runAsync(() async {
      await LocaleSettings.setLocale(AppLocale.en);
      await initializeDateFormatting('en');
    });
    tester.view.physicalSize = const Size(986, 444);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pip = PipService();
    pip.isPipActive.value = false;
    pip.isPipTransitioning.value = false;
    addTearDown(() {
      pip.isPipActive.value = false;
      pip.isPipTransitioning.value = false;
    });
    final player = FakeSyncPlayer(hasRenderedFrame: true, playing: true);
    final volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
    final playback = PlaybackStateProvider();
    final watch = WatchTogetherProvider();
    final chrome = PlayerChromeController();
    final toast = PlayerToastController();
    addTearDown(player.dispose);
    addTearDown(volume.dispose);
    addTearDown(playback.dispose);
    addTearDown(watch.dispose);
    addTearDown(chrome.dispose);
    addTearDown(toast.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<PlaybackStateProvider>.value(value: playback),
        ChangeNotifierProvider<WatchTogetherProvider>.value(value: watch),
      ],
      child: MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.isis).copyWith(platform: TargetPlatform.android),
        home: Scaffold(body: PlexVideoControls(
          player: player,
          volumeController: volume,
          metadata: testMediaItem(id: 'pip-transition'),
          toastController: toast,
          canNavigateMediaItems: false,
          chromeController: chrome,
          isLive: true,
        )),
      ),
    ));
    await tester.pump();
    expect(find.byType(MobileVideoControls), findsOneWidget);
    expect(tester.takeException(), isNull);

    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().startsWith('A RenderFlex overflowed')) errors.add(details);
      else original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(240.8, 108.2);
    await tester.pump();
    expect(errors, isNotEmpty);
    for (final details in errors) {
      expect(pipHudWarning(details, phase: 'entrada', width: 240.8, height: 108.2), isNotNull);
      final source = details.toDiagnosticsNode().toStringDeep();
      expect(knownPipHudOverflow(message: details.exceptionAsString(), source: source,
        phase: 'entrada', width: 240.8, height: 108.2), isTrue, reason: source);
      expect(knownPipHudOverflow(message: details.exceptionAsString(), source: source,
        phase: 'fora', width: 986, height: 444), isFalse);
    }
    chrome.cancelAutoHide();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
