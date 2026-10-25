import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/pump.dart';
import '../../test_helpers/predictive_back.dart';
import '../../test_helpers/watch_together_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  // Route-global wakelock serialization spans these successive routes. Keep
  // their lifecycle on one clock, like the application, not separate FakeAsync zones.
  testWidgets('Back bounds removable routes without fencing Retry on a root route', (tester) async {
    for (final pushed in [true, false]) {
      final key = GlobalKey<VideoPlayerScreenState>();
      final navigator = GlobalKey<NavigatorState>();
      var initializations = 0;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') {
            initializations++;
            return true;
          }
          if (call.method == 'observeProperty') {
            throw PlatformException(code: 'initialization_failure');
          }
          return null;
        },
        testBody: () async {
          final player = _TouchExitPlayer();
          try {
            final screen = VideoPlayerScreen(key: key, metadata: testMediaItem(), isOffline: true);
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create: (_) => PlaybackStateProvider(),
                child: MaterialApp(
                  navigatorKey: navigator,
                  home: pushed ? const Scaffold(body: Text('Browse')) : screen,
                ),
              ),
            );
            if (pushed) {
              unawaited(VideoPlayerRoute(builder: (_) => screen).push(navigator.currentState!));
            }
            await pumpUntil(tester, () => find.widgetWithText(OutlinedButton, 'Back').evaluate().isNotEmpty);
            key.currentState!.player = player;
            await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
            await tester.pump();
            if (pushed) {
              await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
              await tester.pump(const Duration(seconds: 1));
              await tester.pump();
              // A saída foi aceita no limite de 1 s; agora a rota oficial ainda
              // precisa concluir sua animação antes de descartar o State.
              expect(ModalRoute.of(key.currentContext!)!.animation!.status, AnimationStatus.reverse);
              await pumpUntil(tester, () => key.currentState == null);
              expect(key.currentState, isNull);
              expect(find.text('Browse'), findsOneWidget);
              expect(player.pauseCalls, 1);
              var stoppedDone = false;
              final stopped = expectLater(
                PlaybackCoordinator.instance.shutdownVideo(),
                throwsA(isA<PlatformException>().having((error) => error.code, 'code', 'late_pause_failure')),
              ).whenComplete(() => stoppedDone = true);
              player.pauseGate.completeError(PlatformException(code: 'late_pause_failure'));
              await pumpUntil(tester, () => stoppedDone);
              await stopped;
              expect(find.text('Browse'), findsOneWidget);
              expect(tester.takeException(), isNull);
            } else {
              await tester.pump(const Duration(seconds: 2));
              expect(key.currentState, isNotNull);
              expect(player.pauseCalls, 0);
              await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
              await pumpUntil(
                tester,
                () => initializations == 2 && find.widgetWithText(FilledButton, 'Retry').evaluate().isNotEmpty,
              );
            }
          } finally {
            if (!player.pauseGate.isCompleted) player.pauseGate.complete();
            await tester.pumpWidget(const SizedBox.shrink());
            var retirementDone = false;
            final retirement = PlaybackCoordinator.instance.shutdownVideo().whenComplete(() => retirementDone = true);
            await pumpUntil(tester, () => retirementDone);
            await retirement;
          }
        },
      );
    }
  });

  // A route pushed onto the player's own navigator inside the exit grace
  // period must not fence the accepted exit: the player leaves by identity
  // and the covering route stays put (#2290).
  testWidgets('Back nativo retira o player coberto sem aguardar a limpeza nem retirar a cobertura', (tester) async {
    final player = _TouchExitPlayer();
    final screen = await _pushHeldPlayer(tester, player);
    final navigator = screen.navigator;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.binding.handlePopRoute();
    await tester.pump();
    // O sistema confirmou o pop. A nova rota chega durante a animação, com
    // limpeza nativa ainda pendente; ela não pode ser retirada por essa limpeza.
    unawaited(
      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Cover')))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(screen.key.currentState, isNotNull, reason: 'a rota oficial ainda anima');
    expect(ModalRoute.of(screen.key.currentContext!)!.animation!.status, AnimationStatus.reverse);
    await tester.pump(const Duration(milliseconds: 200));
    expect(screen.key.currentState, isNull);
    expect(player.pauseGate.isCompleted, isFalse, reason: 'a resposta nativa não prende a navegação');
    expect(find.text('Cover'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(screen.key.currentState, isNull);
    expect(find.text('Cover'), findsOneWidget, reason: 'removing the player cannot take the covering route');
    expect(find.text('Browse'), findsNothing, reason: 'the exit must not unwind past the covering route');
    expect(player.pauseCalls, 1);
  });
  for (final edge in [0, 1]) {
    testWidgets('player: gesto $edge cancela sem pausar e confirma com aposentadoria pendente', (tester) async {
      tester.view.physicalSize = const Size(412, 914); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final player = _TouchExitPlayer();
      final screen = await _pushHeldPlayer(tester, player);
      await tester.pump(const Duration(milliseconds: 600));
      screen.key.currentState!.chromeController.setContentStripVisible(true);
      await tester.pump();
      await tester.binding.handlePopRoute(); await tester.pump();
      expect(screen.key.currentState!.chromeController.contentStripVisible, isFalse);
      expect(player.pauseCalls, 0, reason: 'o primeiro voltar fecha só o painel');
      await sendPredictiveBack(tester, 'startBackGesture', edge: edge);
      await sendPredictiveBack(tester, 'updateBackGestureProgress', edge: edge, progress: .35);
      await sendPredictiveBack(tester, 'cancelBackGesture', edge: edge);
      await tester.pump(const Duration(milliseconds: 600));
      expect(screen.key.currentState, isNotNull); expect(player.pauseCalls, 0);
      await sendPredictiveBack(tester, 'startBackGesture', edge: edge);
      await sendPredictiveBack(tester, 'updateBackGestureProgress', edge: edge, progress: .65);
      await sendPredictiveBack(tester, 'commitBackGesture', edge: edge);
      await tester.pump(const Duration(milliseconds: 600));
      expect(screen.key.currentState, isNull); expect(player.pauseCalls, 1);
      expect(find.text('Browse'), findsOneWidget);
      expect(player.pauseGate.isCompleted, isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

}

class _TouchExitPlayer extends FakeSyncPlayer {
  _TouchExitPlayer() : super(playing: true);

  final pauseGate = Completer<void>();
  int pauseCalls = 0;

  @override
  Future<void> abandonAudioFocus() async {}

  @override
  Future<void> pause() async {
    pauseCalls++;
    await pauseGate.future;
  }
}

/// Mounts a player route over a `Browse` root with startup held by music
/// arbitration and [player] already installed.
///
/// A second `VideoPlayerScreen` in this isolate never reaches `initialize` -
/// it inherits the predecessor's native-channel release, which no longer
/// settles once that test's clock is gone (see `test_helpers/hdr_startup.dart`).
/// The route-exit path does not need startup at all, and holding it also keeps
/// cleanup pending so the navigation budget governs the exit.
Future<({GlobalKey<VideoPlayerScreenState> key, GlobalKey<NavigatorState> navigator})> _pushHeldPlayer(
  WidgetTester tester,
  _TouchExitPlayer player,
) async {
  final key = GlobalKey<VideoPlayerScreenState>();
  final navigator = GlobalKey<NavigatorState>();
  final initializationHold = Completer<void>();
  Future<void> holdInitialization() => initializationHold.future;
  PlaybackCoordinator.instance.registerMusicSession(stopAndDispose: holdInitialization);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    PlaybackCoordinator.instance.unregisterMusicSession(holdInitialization);
    if (!player.pauseGate.isCompleted) player.pauseGate.complete();
    if (!initializationHold.isCompleted) initializationHold.complete();
    await tester.pump();
  });
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => PlaybackStateProvider(),
      child: MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Browse')),
      ),
    ),
  );
  unawaited(
    VideoPlayerRoute(
      builder: (_) => VideoPlayerScreen(key: key, metadata: testMediaItem(), isOffline: true),
    ).push(navigator.currentState!),
  );
  await tester.pump();
  key.currentState!.player = player;
  return (key: key, navigator: navigator);
}
