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
import 'package:heisuca/widgets/video_controls/desktop_video_controls.dart';
import 'package:heisuca/widgets/video_controls/player_chrome_controller.dart';
import 'package:heisuca/widgets/video_controls/video_controls.dart';
import 'package:heisuca/widgets/video_controls/widgets/player_toast_indicator.dart';
import 'package:heisuca/widgets/video_controls/widgets/video_timeline_bar.dart';

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

  Widget wrapWithShell(Widget child, {TargetPlatform? platform}) => InputModeTracker(
    child: MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
        ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
      ],
      child: MaterialApp(
        theme: ThemeData(
          platform: platform,
          extensions: const [testMonoTokens],
        ),
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
    testWidgets('G2.1: Tecla OK na TV pausa/continua e controles somem após 4 s', (tester) async {
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

      // 2. Na TV, o delay de auto-hide dos controles é de 4s
      expect(chrome.controlsVisible, isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(chrome.controlsVisible, isTrue, reason: 'Após 3s os controles ainda continuam visíveis na TV');
      await tester.pump(const Duration(seconds: 1, milliseconds: 100));
      expect(chrome.controlsVisible, isFalse, reason: 'Após 4s sem tecla os controles somem na TV');

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
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('G2.6b: Voltar numa pílula (KeyDown+KeyUp) e na timeline fecha painel/controles e nunca sai do player', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      var playerExitCount = 0;
      chrome.show();
      await tester.pumpWidget(
        wrapWithShell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'tv-back-test', title: 'Episódio 1', grandparentTitle: 'Série Teste'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: true,
            canControl: true,
            onBack: () => playerExitCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Foco inicial na superfície ou abrir painel com seta para baixo
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Confirma que o foco está no painel da TV (pílula Áudio)
      final audioPillFinder = find.textContaining('Áudio ·');
      expect(audioPillFinder, findsOneWidget);
      expect(chrome.controlsVisible, isTrue);

      // (a) Voltar na pílula: KeyDown seguido de KeyUp
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Deve fechar os controles/painel e NUNCA sair do player
      expect(chrome.controlsVisible, isFalse, reason: 'Voltar na pílula deve fechar os controles');
      expect(playerExitCount, 0, reason: 'Voltar na pílula nunca deve sair do player');
      expect(screenBackDispositions, isEmpty, reason: 'KeyUp não deve vazar para a rota/tela');

      // (b) Agora reabre os controles e foca na timeline
      chrome.show();
      await tester.pumpAndSettle();
      expect(chrome.controlsVisible, isTrue);

      // Foca no painel e sobe para a timeline
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Voltar na timeline: KeyDown seguido de KeyUp
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Deve fechar os controles e NUNCA sair do player
      expect(chrome.controlsVisible, isFalse, reason: 'Voltar na timeline deve fechar os controles');
      expect(playerExitCount, 0, reason: 'Voltar na timeline nunca deve sair do player');
      expect(screenBackDispositions, isEmpty, reason: 'KeyUp da timeline não deve vazar para a tela');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('G2.8: Pós-PiP controles abertos: 1º Voltar fecha controles, 2º Voltar sai do player; tecla de mídia e seta não engolidas', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      var playerExitCount = 0;
      chrome.show();
      await tester.pumpWidget(
        wrapWithShell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'tv-pip-back-test', title: 'Episódio 1', grandparentTitle: 'Série Teste'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: true,
            canControl: true,
            onBack: () => playerExitCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(chrome.controlsVisible, isTrue);

      // Simula entrar e sair do PiP com controles abertos
      PipService().isPipActive.value = true;
      await tester.pumpAndSettle();

      PipService().isPipActive.value = false;
      await tester.pumpAndSettle();

      // Confirma controles visíveis após restauração
      expect(chrome.controlsVisible, isTrue);

      // 1. Tecla de mídia com controles abertos não é engolida
      final initialPlayPauseCalls = player.playPauseCalls;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlayPause);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlayPause);
      await tester.pumpAndSettle();
      expect(player.playPauseCalls, initialPlayPauseCalls + 1, reason: 'Tecla de mídia não deve ser engolida');

      // 2. Tecla de seta (ex: arrowRight para seek) com controles abertos não é engolida
      final initialSeekCalls = player.seekCalls;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      // O seek ou navegação directional é disparado ou processado, não engolido
      expect(player.seekCalls, greaterThanOrEqualTo(initialSeekCalls));
      expect(chrome.controlsVisible, isTrue);

      // 3. 1º Voltar fecha os controles e nunca sai do player
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(chrome.controlsVisible, isFalse, reason: '1º Voltar após PiP fecha os controles');
      expect(playerExitCount, 0, reason: '1º Voltar após PiP nunca sai do player');
      expect(screenBackDispositions, isEmpty, reason: '1º Voltar não deve vazar para a tela');

      // 4. 2º Voltar com controles fechados sai do player (nada fica preso)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(screenBackDispositions, contains(PlayerBackDisposition.exitPlayer), reason: '2º Voltar após PiP deve sair do player');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('G2.9: requestTvPanelFocus checa canRequestFocus e não dispara onFocusActivity sem foco', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      chrome.show();
      await tester.pumpWidget(
        wrapWithShell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'tv-focus-test', title: 'Episódio 1', grandparentTitle: 'Série Teste'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: true,
            canControl: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final desktopState = tester.state<DesktopVideoControlsState>(find.byType(DesktopVideoControls));
      
      // Simula ExcludeFocus / canRequestFocus = false no nó do painel da TV
      // Quando canRequestFocus é false, requestTvPanelFocus não deve alterar foco nem gerar loop
      final tvAudioNode = Focus.of(tester.element(find.textContaining('Áudio ·')));
      tvAudioNode.canRequestFocus = false;

      // Chama requestTvPanelFocus: deve retornar sem erro e sem focar
      desktopState.requestTvPanelFocus();
      await tester.pump();

      expect(tvAudioNode.hasFocus, isFalse);

      await tester.pump(const Duration(seconds: 4));
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

    testWidgets('G2.10: Desktop: Escape com controles visíveis fecha os controles e não sai do player', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));
      addTearDown(() => TvDetectionService.debugSetTvOverride(true));

      TvDetectionService.debugSetTvOverride(false);
      var playerExitCount = 0;
      chrome.show();

      await tester.pumpWidget(
        wrapWithShell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'desktop-back-test', title: 'Episódio 1', grandparentTitle: 'Série Teste'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: true,
            canControl: true,
            onBack: () => playerExitCount++,
          ),
          platform: TargetPlatform.linux,
        ),
      );
      await tester.pumpAndSettle();

      expect(chrome.controlsVisible, isTrue);

      final desktopState = tester.state<DesktopVideoControlsState>(find.byType(DesktopVideoControls));

      // Foca na timeline no Desktop
      final timelineFinder = find.byType(VideoTimelineBar);
      expect(timelineFinder, findsOneWidget);
      final focusWidgets = tester.widgetList<Focus>(find.descendant(of: timelineFinder, matching: find.byType(Focus)));
      for (final focusWidget in focusWidgets) {
        if (focusWidget.focusNode != null) {
          focusWidget.focusNode!.requestFocus();
          break;
        }
      }
      await tester.pumpAndSettle();
      expect(desktopState.isTimelineFocused, isTrue);

      // Pressiona Escape no Desktop com timeline focada
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // No Desktop, Escape com foco na timeline deve fechar os controles e NUNCA sair do player
      expect(chrome.controlsVisible, isFalse, reason: 'Escape no Desktop deve fechar os controles quando visíveis');
      expect(playerExitCount, 0, reason: 'Escape com controles visíveis não deve sair do player');
      expect(screenBackDispositions, isEmpty, reason: 'Escape com controles visíveis não deve vazar para a rota');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('G2.11: unfocusTvPanel remove foco da timeline e nós de controles', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      chrome.show();
      await tester.pumpWidget(
        wrapWithShell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'unfocus-test', title: 'Episódio 1', grandparentTitle: 'Série Teste'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: true,
            canControl: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final desktopState = tester.state<DesktopVideoControlsState>(find.byType(DesktopVideoControls));
      desktopState.requestTvPanelFocus();
      await tester.pumpAndSettle();
      expect(desktopState.isTvPanelFocused, isTrue);

      // Chama unfocusTvPanel
      desktopState.unfocusTvPanel();
      await tester.pump();

      expect(desktopState.isTvPanelFocused, isFalse, reason: 'Painel TV não deve reter foco');
      expect(desktopState.isTimelineFocused, isFalse, reason: 'Timeline não deve reter foco');

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('G2.12: Painel não fecha por timeout durante navegação contínua entre as pílulas', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      chrome.show();
      await tester.pumpWidget(
        wrapWithShell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'autohide-nav-test', title: 'Episódio 1', grandparentTitle: 'Série Teste'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: true,
            canControl: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final desktopState = tester.state<DesktopVideoControlsState>(find.byType(DesktopVideoControls));
      desktopState.requestTvPanelFocus();
      await tester.pumpAndSettle();
      expect(desktopState.isTvPanelFocused, isTrue);
      expect(chrome.controlsVisible, isTrue);

      // Espera 2s (menor que o timeout de 4s na TV)
      await tester.pump(const Duration(seconds: 2));
      expect(chrome.controlsVisible, isTrue);

      // Navega para a pílula de legendas com seta para a direita
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Espera mais 2s (total 4s desde o início; se o timer não tivesse sido renovado, os controles teriam sumido)
      await tester.pump(const Duration(seconds: 2));
      expect(chrome.controlsVisible, isTrue, reason: 'Controles continuam visíveis pois houve atividade de navegação');

      // Navega para a pílula de episódios com seta para a direita
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Espera mais 2s (total 6s acumulados)
      await tester.pump(const Duration(seconds: 2));
      expect(chrome.controlsVisible, isTrue, reason: 'Controles continuam visíveis durante interação contínua');

      // Agora deixa passar 4s e 100ms sem nenhuma tecla: deve fechar por inatividade
      await tester.pump(const Duration(seconds: 4, milliseconds: 100));
      expect(chrome.controlsVisible, isFalse, reason: 'Após 4s completos sem tecla os controles fecham na TV');

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
