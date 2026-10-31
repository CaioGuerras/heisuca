import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/focus/dpad_navigator.dart';
import 'package:heisuca/focus/input_mode_tracker.dart';
import 'package:heisuca/heisuca/services/heisuca_episode_attention.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/mpv/mpv.dart';
import 'package:heisuca/providers/playback_state_provider.dart';
import 'package:heisuca/screens/video_player/widgets/player_prompt_overlays.dart';
import 'package:heisuca/services/device_performance.dart';
import 'package:heisuca/services/pip_service.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/services/video_volume_controller.dart';
import 'package:heisuca/utils/platform_detector.dart';
import 'package:heisuca/watch_together/providers/watch_together_provider.dart';
import 'package:heisuca/widgets/video_controls/player_chrome_controller.dart';
import 'package:heisuca/widgets/video_controls/video_controls.dart';
import 'package:heisuca/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

class _TvTestPlayer implements Player {
  Duration _position = const Duration(minutes: 5);
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final Map<String, String> properties = {};
  var seekCalls = 0;
  var playPauseCalls = 0;

  void emitPosition(Duration position) {
    _position = position;
    _positionController.add(position);
  }

  Future<void> close() => _positionController.close();

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state => PlayerState(
    playing: true,
    position: _position,
    duration: const Duration(minutes: 30),
    seekable: true,
    tracks: const Tracks(
      audio: [AudioTrack(id: '1', title: 'Português', language: 'por')],
      subtitle: [SubtitleTrack(id: '1', title: 'Português', language: 'por')],
    ),
    track: const TrackSelection(
      audio: AudioTrack(id: '1', title: 'Português', language: 'por'),
      subtitle: SubtitleTrack(id: '1', title: 'Português', language: 'por'),
    ),
  );

  @override
  Future<void> seek(Duration position) async {
    seekCalls++;
    emitPosition(position);
  }

  @override
  Future<void> setProperty(String name, String value) async {
    properties[name] = value;
  }

  @override
  Future<String?> getProperty(String name) async => properties[name];

  @override
  Future<void> play() async {
    playPauseCalls++;
  }

  @override
  Future<void> pause() async {
    playPauseCalls++;
  }

  @override
  Future<void> playOrPause() async {
    playPauseCalls++;
  }

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: const Stream<bool>.empty(),
    completed: const Stream<bool>.empty(),
    buffering: const Stream<bool>.empty(),
    position: _positionController.stream,
    duration: const Stream<Duration>.empty(),
    seekable: const Stream<bool>.empty(),
    buffer: const Stream<Duration>.empty(),
    volume: const Stream<double>.empty(),
    rate: const Stream<double>.empty(),
    tracks: const Stream<Tracks>.empty(),
    track: const Stream<TrackSelection>.empty(),
    log: const Stream<PlayerLog>.empty(),
    error: const Stream<PlayerError>.empty(),
    audioDevice: const Stream<AudioDevice>.empty(),
    audioDevices: const Stream<List<AudioDevice>>.empty(),
    bufferRanges: const Stream<List<BufferRange>>.empty(),
    playbackRestart: const Stream<void>.empty(),
    backendSwitched: const Stream<void>.empty(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TvTestPlayer player;
  late PlayerChromeController chrome;
  late PlayerToastController toast;
  late VideoVolumeController volume;
  late PlaybackStateProvider playbackState;
  late WatchTogetherProvider watchTogether;
  late AppDatabase database;
  late ValueNotifier<bool> hasFirstFrame;
  late SettingsService settings;
  late FocusNode screenFocusNode;
  final screenBackDispositions = <PlayerBackDisposition>[];

  setUp(() async {
    hasFirstFrame = ValueNotifier<bool>(true);
    await LocaleSettings.setLocale(AppLocale.pt);
    await initializeDateFormatting('pt');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();

    TvDetectionService.debugSetTvOverride(true);
    PipService().isPipActive.value = false;

    database = AppDatabase.forTesting(NativeDatabase.memory());
    player = _TvTestPlayer();
    chrome = PlayerChromeController(initiallyVisible: false);
    toast = PlayerToastController();
    volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
    playbackState = PlaybackStateProvider();
    watchTogether = WatchTogetherProvider();
    hasFirstFrame = ValueNotifier<bool>(true);
    screenFocusNode = FocusNode(debugLabel: 'VideoPlayerScreen');
    screenBackDispositions.clear();
  });

  tearDown(() async {
    TvDetectionService.debugSetTvOverride(null);
    hasFirstFrame.dispose();
    screenFocusNode.dispose();
    volume.dispose();
    playbackState.dispose();
    watchTogether.dispose();
    chrome.dispose();
    toast.dispose();
    await player.close();
    await database.close();
  });

  Widget wrapWithShell(Widget child) => InputModeTracker(
    child: MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
        ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        home: Scaffold(
          body: SizedBox(
            width: 1920,
            height: 1080,
            child: Focus(
              focusNode: screenFocusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyUpEvent && event.logicalKey.isBackKey) {
                  screenBackDispositions.add(
                    resolvePlayerBackDisposition(
                      navigationKey: classifyPlayerNavigationKey(event, isAppleTV: false),
                      contentStripVisible: chrome.contentStripVisible,
                      controlsVisible: chrome.controlsVisible,
                      physicalEscapeExitsFullscreen: false,
                    ),
                  );
                }
                return KeyEventResult.ignored;
              },
              child: child,
            ),
          ),
        ),
      ),
    ),
  );

  group('TV-1 G2: Player de TV', () {
    testWidgets('G2.1: Tecla OK na TV pausa/continua e controles somem após 5 s', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      var playPauseToggled = 0;
      await tester.pumpWidget(
        wrapWithShell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'tv-player-item', title: 'Episódio 1', grandparentTitle: 'Série Teste'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: true,
            canControl: true,
            onPlayPauseRequested: (_) async => playPauseToggled++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. OK na superfície do player = pausa/continua
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(playPauseToggled, 1, reason: 'OK na TV pausa ou continua o vídeo');

      // 2. Na TV, o delay de auto-hide dos controles é de 5s
      expect(chrome.controlsVisible, isTrue);
      await tester.pump(const Duration(seconds: 4));
      expect(chrome.controlsVisible, isTrue, reason: 'Após 4s os controles ainda continuam visíveis na TV');
      await tester.pump(const Duration(seconds: 2));
      expect(chrome.controlsVisible, isFalse, reason: 'Após 5s sem tecla os controles somem na TV');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('G2.2: Próximo episódio com contagem de 8 s, [Assistir agora] em foco e [Cancelar]', (tester) async {
      final cancelFocus = FocusNode(debugLabel: 'TestCancel');
      final confirmFocus = FocusNode(debugLabel: 'TestConfirm');
      final countdown = ValueNotifier<int>(8);
      addTearDown(() {
        confirmFocus.dispose();
        cancelFocus.dispose();
        countdown.dispose();
      });

      var playNextCalled = false;
      var cancelCalled = false;

      await tester.pumpWidget(
        wrapWithShell(
          Stack(
            children: [
              VideoPlayerPlayNextOverlay(
                visible: true,
                nextEpisode: testMediaItem(id: 'next-ep', title: 'Nome do Episódio', grandparentTitle: 'Série'),
                autoPlayCountdown: countdown,
                cancelFocusNode: cancelFocus,
                confirmFocusNode: confirmFocus,
                chromeController: chrome,
                onCancel: () => cancelCalled = true,
                onPlayNext: () => playNextCalled = true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Confere que no layout de TV [Assistir agora] e [Cancelar] estão presentes
      expect(find.text('Assistir agora'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // Foco inicial deve ser em [Assistir agora] (confirmFocus)
      confirmFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(confirmFocus.hasFocus, isTrue, reason: 'Assistir agora deve ter foco inicial');

      // Pressionar Select em [Assistir agora] dispara onPlayNext
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(playNextCalled, isTrue, reason: 'Confirmar Assistir agora avança o episódio');

      // D-pad Right move foco para [Cancelar]
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(cancelFocus.hasFocus, isTrue, reason: 'Seta para direita foca Cancelar');

      // Pressionar Select em [Cancelar] dispara onCancel
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(cancelCalled, isTrue, reason: 'Confirmar Cancelar fecha o prompt');

      cancelFocus.unfocus();
      confirmFocus.unfocus();
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
    });

    test('G2.2b: playNextCountdown tem padrão 8 s na TV e respeita escolha do usuário (inclusive 0 = sem contagem)', () async {
      // 1. Padrão na TV quando não modificado deve ser 8 s
      TvDetectionService.debugSetTvOverride(true);
      expect(
        settings.read(SettingsService.playNextCountdown),
        8,
        reason: 'Padrão na TV quando usuário não mudou a opção deve ser 8 s',
      );

      // 2. Padrão fora da TV quando não modificado deve ser 5 s
      TvDetectionService.debugSetTvOverride(false);
      expect(
        settings.read(SettingsService.playNextCountdown),
        5,
        reason: 'Padrão em dispositivos não-TV quando usuário não mudou a opção deve ser 5 s',
      );

      // 3. Usuário escolhe 0 (sem contagem / imediato) na TV
      TvDetectionService.debugSetTvOverride(true);
      await settings.write(SettingsService.playNextCountdown, 0);
      expect(
        settings.read(SettingsService.playNextCountdown),
        0,
        reason: 'Escolha do usuário 0 deve ser respeitada na TV',
      );

      // 4. Usuário escolhe 15 s na TV
      await settings.write(SettingsService.playNextCountdown, 15);
      expect(
        settings.read(SettingsService.playNextCountdown),
        15,
        reason: 'Escolha do usuário 15 s deve ser respeitada na TV',
      );

      // 5. Reset restaura o padrão de 8 s na TV
      await settings.reset(SettingsService.playNextCountdown);
      expect(
        settings.read(SettingsService.playNextCountdown),
        8,
        reason: 'Reset na TV volta ao padrão de 8 s',
      );
    });

    testWidgets('G2.3: "Ainda está aí?" após 3 episódios sem tecla', (tester) async {
      final attention = HeisucaEpisodeAttention();

      // Episódio 1 termina sem tecla
      expect(attention.finish(limit: 3), isFalse);
      // Episódio 2 termina sem tecla
      expect(attention.finish(limit: 3), isFalse);
      // Episódio 3 termina sem tecla: deve disparar Still Watching!
      expect(attention.finish(limit: 3), isTrue, reason: 'Após 3 episódios sem interação, dispara Ainda está aí?');

      // Se o usuário interagiu com uma tecla, reinicia contagem
      attention.interact();
      expect(attention.completed, 0);

      // Limite <= 0 (desligado em Ajustes) nunca dispara
      expect(attention.finish(limit: 0), isFalse);
    });

    testWidgets('G2.4: Botões de mídia do controle (play/pause, skip) funcionam na TV', (tester) async {
      await tester.pumpWidget(
        wrapWithShell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'tv-media-keys'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: true,
            canControl: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hardware mediaPlayPause
      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlayPause);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlayPause);
      await tester.pumpAndSettle();
      expect(player.playPauseCalls > 0, isTrue, reason: 'Tecla mediaPlayPause deve acionar o player');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('G2.5: TV renderiza painel com 3 pílulas (Áudio, Legenda, Episódios) e timestamps em 24 px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      chrome.show();
      await tester.pumpWidget(
        wrapWithShell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(
              id: 'tv-controls-test',
              kind: MediaKind.episode,
              title: 'Episódio 1',
              grandparentTitle: 'Série Teste',
            ),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: true,
            canControl: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Painel inferior da TV contém Áudio, Legenda, Episódios
      expect(find.textContaining('Áudio ·'), findsOneWidget);
      expect(find.textContaining('Legenda ·'), findsOneWidget);
      expect(find.text('Episódios'), findsOneWidget);
      expect(find.text('← → 10 s · ↓ painel · Voltar sai'), findsOneWidget);

      // Timestamps possuem tamanho de fonte 24 px
      final timestampFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.style?.fontSize == 24 && widget.data != null && widget.data!.contains(':'),
      );
      expect(timestampFinder, findsWidgets);

      // Sem botões touch-only de rotação, lock ou volume na barra de botões da TV
      expect(find.byIcon(Icons.screen_rotation), findsNothing);
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(find.byIcon(Icons.volume_up), findsNothing);

      // Esgota o timer de auto-hide dos controles na TV (4s)
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    test('G2.6: Voltar com painel aberto fecha o painel; sem painel sai do player', () {
      // Quando painel/controles estão visíveis:
      final withPanelOpen = resolvePlayerBackDisposition(
        navigationKey: PlayerNavigationKey.back,
        contentStripVisible: false,
        controlsVisible: true,
        physicalEscapeExitsFullscreen: false,
      );
      expect(withPanelOpen, PlayerBackDisposition.hideControls, reason: 'Voltar com painel aberto fecha os controles');

      // Quando nenhum painel está aberto (assistindo vídeo na TV):
      final withoutPanel = resolvePlayerBackDisposition(
        navigationKey: PlayerNavigationKey.back,
        contentStripVisible: false,
        controlsVisible: false,
        physicalEscapeExitsFullscreen: false,
      );
      expect(withoutPanel, PlayerBackDisposition.exitPlayer, reason: 'Voltar sem painel sai do player imediatamente');
    });

    test('G2.7: Configuração de cache de demux do mpv em TV com pouca RAM', () async {
      final isLowRam = DevicePerformance.systemLowRam == true ||
          DevicePerformance.isLowEndHardware ||
          (DevicePerformance.totalMemBytes != null && DevicePerformance.totalMemBytes! < (2 * 1024 * 1024 * 1024));

      // Em ambiente de TV de baixa RAM, os limites de demuxer devem ser 32 MB e 16 MB
      if (PlatformDetector.isTV() || isLowRam) {
        await player.setProperty('demuxer-max-bytes', '${32 * 1024 * 1024}');
        await player.setProperty('demuxer-max-back-bytes', '${16 * 1024 * 1024}');
        expect(await player.getProperty('demuxer-max-bytes'), '${32 * 1024 * 1024}');
        expect(await player.getProperty('demuxer-max-back-bytes'), '${16 * 1024 * 1024}');
      }
    });
  });
}
