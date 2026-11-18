import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/desktop_app.dart';
import 'package:heisuca/desktop/desktop_playback_controller.dart';
import 'package:heisuca/models/audio_channel_limit.dart';
import 'package:heisuca/mpv/models.dart';
import 'package:heisuca/mpv/player/audio_rendering_mode.dart';
import 'package:heisuca/mpv/player/player.dart';
import 'package:heisuca/mpv/player/player_state.dart';
import 'package:heisuca/mpv/player/player_streams.dart';
import 'package:heisuca/mpv/video.dart';

class _FakePlayer implements Player {
  _FakePlayer() {
    _streams = PlayerStreams(
      playing: _playingController.stream,
      completed: _completedController.stream,
      buffering: _bufferingController.stream,
      position: _positionController.stream,
      duration: _durationController.stream,
      seekable: _seekableController.stream,
      buffer: _bufferController.stream,
      volume: _volumeController.stream,
      rate: _rateController.stream,
      tracks: _tracksController.stream,
      track: _trackController.stream,
      log: _logController.stream,
      error: _errorController.stream,
      audioDevice: _audioDeviceController.stream,
      audioDevices: _audioDevicesController.stream,
      bufferRanges: _bufferRangesController.stream,
      playbackRestart: _playbackRestartController.stream,
      fileLoaded: _fileLoadedController.stream,
      fileStarted: _fileStartedController.stream,
      fileLoadFailed: _fileLoadFailedController.stream,
      sourceStarted: _sourceStartedController.stream,
      sourceReady: _sourceReadyController.stream,
      sourceFailed: _sourceFailedController.stream,
      primaryMediaReady: _primaryMediaReadyController.stream,
      backendSwitched: _backendSwitchedController.stream,
    );
  }

  final _playingController = StreamController<bool>.broadcast();
  final _completedController = StreamController<bool>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _seekableController = StreamController<bool>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _volumeController = StreamController<double>.broadcast();
  final _rateController = StreamController<double>.broadcast();
  final _tracksController = StreamController<Tracks>.broadcast();
  final _trackController = StreamController<TrackSelection>.broadcast();
  final _logController = StreamController<PlayerLog>.broadcast();
  final _errorController = StreamController<PlayerError>.broadcast();
  final _audioDeviceController = StreamController<AudioDevice>.broadcast();
  final _audioDevicesController = StreamController<List<AudioDevice>>.broadcast();
  final _bufferRangesController = StreamController<List<BufferRange>>.broadcast();
  final _playbackRestartController = StreamController<void>.broadcast();
  final _fileLoadedController = StreamController<void>.broadcast();
  final _fileStartedController = StreamController<void>.broadcast();
  final _fileLoadFailedController = StreamController<void>.broadcast();
  final _sourceStartedController = StreamController<PlayerSourceStarted>.broadcast();
  final _sourceReadyController = StreamController<PlayerSourceReady>.broadcast();
  final _sourceFailedController = StreamController<PlayerSourceFailed>.broadcast();
  final _primaryMediaReadyController = StreamController<void>.broadcast();
  final _backendSwitchedController = StreamController<void>.broadcast();

  late final PlayerStreams _streams;
  PlayerState _state = const PlayerState();
  bool _disposed = false;
  int _sourceCounter = 0;

  final List<Media> openedMedia = [];
  final List<Duration> seekPositions = [];
  final List<double> volumes = [];
  final List<AudioTrack> selectedAudioTracks = [];
  final List<SubtitleTrack> selectedSubtitleTracks = [];
  final List<List<String>> commands = [];
  int togglePauseCalls = 0;

  void emitPosition(Duration value) {
    _state = _state.copyWith(position: value);
    _positionController.add(value);
  }

  void emitReadyFrame({
    Duration duration = const Duration(minutes: 10),
    Duration position = Duration.zero,
    bool playing = true,
    bool seekable = true,
    Tracks? tracks,
    TrackSelection? track,
  }) {
    final resolvedTracks = tracks ?? _state.tracks;
    final resolvedTrack = track ?? _state.track;
    _state = _state.copyWith(
      playing: playing,
      completed: false,
      buffering: false,
      duration: duration,
      position: position,
      seekable: seekable,
      tracks: resolvedTracks,
      track: resolvedTrack,
      hasRenderedFrame: true,
    );
    _durationController.add(duration);
    _positionController.add(position);
    _seekableController.add(seekable);
    _playingController.add(playing);
    _tracksController.add(resolvedTracks);
    _trackController.add(resolvedTrack);
    _fileLoadedController.add(null);
    _playbackRestartController.add(null);
    _sourceReadyController.add(PlayerSourceReady(sourceId: _sourceCounter, position: position));
  }

  @override
  PlayerState get state => _state;

  @override
  PlayerStreams get streams => _streams;

  @override
  Duration get currentPosition => _state.position;

  @override
  Duration? get outgoingSourcePosition => null;

  @override
  bool get audioPassthroughActive => false;

  @override
  String get playerType => 'mpv';

  @override
  bool get supportsSecondarySubtitles => true;

  @override
  bool get detectsFpsAfterRender => false;

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  @override
  bool get providesNativeStats => false;

  @override
  bool get disposed => _disposed;

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
  }) async {
    _sourceCounter += 1;
    openedMedia.add(media);
    _state = _state.copyWith(hasRenderedFrame: false, playing: play);
    _fileStartedController.add(null);
    _sourceStartedController.add(PlayerSourceStarted(_sourceCounter));
  }

  @override
  Future<void> play() async {
    togglePauseCalls += 1;
    _state = _state.copyWith(playing: true);
    _playingController.add(true);
  }

  @override
  Future<void> pause() async {
    togglePauseCalls += 1;
    _state = _state.copyWith(playing: false);
    _playingController.add(false);
  }

  @override
  Future<void> playOrPause() async {
    togglePauseCalls += 1;
    final next = !_state.playing;
    _state = _state.copyWith(playing: next);
    _playingController.add(next);
  }

  @override
  Future<void> stop() async {
    _state = _state.copyWith(playing: false, position: Duration.zero);
    _playingController.add(false);
    _positionController.add(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    seekPositions.add(position);
    _state = _state.copyWith(position: position);
    _positionController.add(position);
  }

  @override
  Future<void> setNext(Media? media) async {}

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    selectedAudioTracks.add(track);
    final nextSelection = _state.track.copyWith(audio: track);
    _state = _state.copyWith(track: nextSelection);
    _trackController.add(nextSelection);
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    selectedSubtitleTracks.add(track);
    final nextSelection = _state.track.copyWith(subtitle: track);
    _state = _state.copyWith(track: nextSelection);
    _trackController.add(nextSelection);
  }

  @override
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {}

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
    _state = _state.copyWith(volume: volume);
    _volumeController.add(volume);
  }

  @override
  Future<void> setRate(double rate) async {
    _state = _state.copyWith(rate: rate);
    _rateController.add(rate);
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {}

  @override
  Future<void> setProperty(String name, String value) async {}

  @override
  Future<String?> getProperty(String name) async => null;

  @override
  Future<void> setLogLevel(String level) async {}

  @override
  Future<void> command(List<String> args) async {
    commands.add(args);
  }

  @override
  Future<void> awaitDisplayModeSwitch({int extraDelayMs = 0}) async {}

  @override
  Future<void> configureSubtitleFonts() async {}

  @override
  Future<void> setAudioPassthrough(bool enabled) async {}

  @override
  Future<AudioRenderingMode?> getAudioRenderingMode() async => null;

  @override
  Future<void> setAudioNormalization(bool enabled) async {}

  @override
  Future<void> setAudioChannelLimit(
    AudioChannelLimit limit, {
    required int centerBoostDb,
    required bool normalize,
  }) async {}

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async => true;

  @override
  Future<void> setBackgroundAudio(bool enabled) async {}

  @override
  Future<void> setContinueListening(bool allowed) async {}

  @override
  Future<void> updateFrame() async {}

  @override
  Future<bool> isHdrOutputSupported() async => false;

  @override
  Future<bool> setVideoFrameRate(
    double fps,
    int durationMs, {
    int extraDelayMs = 0,
    int videoWidth = 0,
    int videoHeight = 0,
    bool matchResolution = false,
  }) async =>
      false;

  @override
  Future<void> clearVideoFrameRate() async {}

  @override
  Future<void> setSubtitleStyle({
    required double fontSize,
    required String textColor,
    required double borderSize,
    required String borderColor,
    required String bgColor,
    required int bgOpacity,
    int subtitlePosition = 100,
    bool bold = false,
    bool italic = false,
    bool anchorToScreen = false,
  }) async {}

  @override
  Future<void> setBoxFitMode(int mode) async {}

  @override
  Future<void> setVideoZoom(double scale) async {}

  @override
  Future<Map<String, dynamic>> getStats() async => const {};

  @override
  Future<String> runtimePlayerType() async => 'mpv';

  @override
  Future<bool> requestAudioFocus() async => true;

  @override
  Future<void> abandonAudioFocus() async {}

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait([
      _playingController.close(),
      _completedController.close(),
      _bufferingController.close(),
      _positionController.close(),
      _durationController.close(),
      _seekableController.close(),
      _bufferController.close(),
      _volumeController.close(),
      _rateController.close(),
      _tracksController.close(),
      _trackController.close(),
      _logController.close(),
      _errorController.close(),
      _audioDeviceController.close(),
      _audioDevicesController.close(),
      _bufferRangesController.close(),
      _playbackRestartController.close(),
      _fileLoadedController.close(),
      _fileStartedController.close(),
      _fileLoadFailedController.close(),
      _sourceStartedController.close(),
      _sourceReadyController.close(),
      _sourceFailedController.close(),
      _primaryMediaReadyController.close(),
      _backendSwitchedController.close(),
    ]);
  }
}

void main() {
  testWidgets('ticks de reprodução não mantêm os controles permanentemente visíveis', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = _FakePlayer();
    final controller = DesktopPlaybackController(playerFactory: () => fake);
    await tester.pumpWidget(DesktopApp(controller: controller, onSetFullScreen: (value) async => value));
    await controller.open('/tmp/video.mkv');
    fake.emitReadyFrame();
    await tester.pump();
    expect(find.text('Legendas').hitTestable(), findsOneWidget);
    for (var i=1; i<=4; i++) {
      await tester.pump(const Duration(seconds: 1));
      fake.emitPosition(Duration(seconds: i));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Legendas').hitTestable(), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('falha do seletor mostra aviso seguro sem erro assíncrono', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = DesktopPlaybackController(playerFactory: () => _FakePlayer());
    await tester.pumpWidget(DesktopApp(
      controller: controller,
      onPickVideoFile: () async => throw PlatformException(code: 'native-picker', message: 'PRIVATE_PATH'),
      onSetFullScreen: (value) async => value,
    ));
    await tester.tap(find.text('Abrir arquivo'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível abrir o seletor de arquivos. Tente novamente.'), findsOneWidget);
    expect(find.textContaining('PRIVATE_PATH'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('arquivo inicial é encaminhado sem exigir login', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = _FakePlayer();
    final controller = DesktopPlaybackController(playerFactory: () => fake);
    await tester.pumpWidget(DesktopApp(
      controller: controller,
      initialSource: '/tmp/ação teste.mkv',
      onSetFullScreen: (value) async => value,
    ));
    await tester.pump();
    expect(controller.title, 'ação teste.mkv');
    expect(controller.opening, isTrue);
    expect(find.textContaining('Entrar'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('exibe home limpa sem login e erro legível quando URI inválida ou timeout ocorre', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var fakePlayer = _FakePlayer();
    final controller = DesktopPlaybackController(
      playerFactory: () => fakePlayer.disposed ? fakePlayer = _FakePlayer() : fakePlayer,
      openTimeout: const Duration(milliseconds: 80),
    );

    await tester.pumpWidget(DesktopApp(controller: controller));
    await tester.pump();

    expect(find.text('Heisuca'), findsOneWidget);
    expect(find.text('Abrir arquivo'), findsOneWidget);
    expect(find.text('Abrir URL'), findsOneWidget);
    expect(find.textContaining('Plex'), findsNothing);
    expect(find.textContaining('Jellyfin'), findsNothing);

    // Validação legível no diálogo de URL.
    await tester.tap(find.text('Abrir URL'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ftp://servidor.invalido/filme.mp4');
    await tester.tap(find.text('Reproduzir'));
    await tester.pump();
    expect(find.textContaining('Protocolo não suportado'), findsOneWidget);
    expect(fakePlayer.openedMedia, isEmpty);

    // URI válida inicia abertura aguardando quadro real e falha de forma legível após timeout.
    await tester.enterText(find.byType(TextField), 'https://exemplo.invalid/filme.mp4');
    await tester.tap(find.text('Reproduzir'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Abrindo mídia...'), findsOneWidget);
    final videoBoxBeforeFrame = tester.widget<ColoredBox>(find.descendant(
      of: find.byType(Video),
      matching: find.byType(ColoredBox),
    ).first);
    expect(videoBoxBeforeFrame.color, isNot(Colors.transparent));

    await tester.pump(const Duration(milliseconds: 140));
    expect(controller.opening, isFalse);
    expect(controller.error, isNotNull);
    expect(controller.error!.trim(), isNotEmpty);
    expect(find.text(controller.error!), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await controller.close();
    controller.dispose();
  });

  testWidgets('cancelar file picker e diálogo de URL não inicia reprodução nem gera erro', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var fakePlayer = _FakePlayer();
    final controller = DesktopPlaybackController(playerFactory: () => fakePlayer.disposed ? fakePlayer = _FakePlayer() : fakePlayer);
    var filePickerCalls = 0;

    await tester.pumpWidget(
      DesktopApp(
        controller: controller,
        onPickVideoFile: () async {
          filePickerCalls += 1;
          return null;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Abrir arquivo'));
    await tester.pumpAndSettle();
    expect(filePickerCalls, 1);
    expect(fakePlayer.openedMedia, isEmpty);
    expect(controller.hasMedia, isFalse);
    expect(controller.error, isNull);

    await tester.tap(find.text('Abrir URL'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'https://exemplo.invalid/video.mp4');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(fakePlayer.openedMedia, isEmpty);
    expect(controller.hasMedia, isFalse);
    expect(controller.error, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await controller.close();
    controller.dispose();
  });

  testWidgets('atalhos não interceptam digitação no TextField e controlam player fora do campo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var fakePlayer = _FakePlayer();
    final controller = DesktopPlaybackController(playerFactory: () => fakePlayer.disposed ? fakePlayer = _FakePlayer() : fakePlayer);
    final fullscreenHistory = <bool>[];
    var openFileShortcutCalls = 0;

    await tester.pumpWidget(
      DesktopApp(
        controller: controller,
        onPickVideoFile: () async {
          openFileShortcutCalls += 1;
          return null;
        },
        onSetFullScreen: (value) async {
          fullscreenHistory.add(value);
          return value;
        },
      ),
    );
    await tester.pump();

    // Abre diálogo via Ctrl+L.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);

    // Enquanto TextField está focado, Espaço, F e setas não acionam atalhos.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(fullscreenHistory, isEmpty);
    expect(fakePlayer.togglePauseCalls, 0);
    expect(fakePlayer.seekPositions, isEmpty);

    await tester.enterText(find.byType(TextField), 'https://exemplo.invalid/f_o_l.mp4');
    await tester.tap(find.text('Reproduzir'));
    await tester.pump();

    const audioTracks = [
      AudioTrack(id: '1', title: 'Japonês', language: 'jpn', codec: 'aac', channels: 2),
      AudioTrack(id: '2', title: 'Português', language: 'por', codec: 'eac3', channels: 6),
    ];
    const subtitleTracks = [
      SubtitleTrack(id: '1', title: 'Português (BR)', language: 'por', codec: 'ass'),
    ];
    fakePlayer.emitReadyFrame(
      duration: const Duration(minutes: 5),
      position: const Duration(seconds: 30),
      tracks: const Tracks(audio: audioTracks, subtitle: subtitleTracks),
      track: TrackSelection(audio: audioTracks.first, subtitle: subtitleTracks.first),
    );
    await tester.pump();

    // Fundo do Scaffold e do Video ficam transparentes após primeiro quadro confirmado.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.transparent);
    final videoBox = tester.widget<ColoredBox>(find.descendant(
      of: find.byType(Video),
      matching: find.byType(ColoredBox),
    ).first);
    expect(videoBox.color, Colors.transparent);

    // Atalhos fora do TextField funcionam normalmente.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(fakePlayer.togglePauseCalls, 1);
    expect(fakePlayer.seekPositions, [const Duration(seconds: 40)]);
    expect(fullscreenHistory, [true]);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fullscreenHistory, [true, false]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(openFileShortcutCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await controller.close();
    controller.dispose();
  });

  testWidgets('menus de áudio/legenda e responsividade em 800x600 com escala de texto 200%', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var fakePlayer = _FakePlayer();
    final controller = DesktopPlaybackController(playerFactory: () => fakePlayer.disposed ? fakePlayer = _FakePlayer() : fakePlayer);
    const externalSubPath = r'C:\legendas\filme.srt';

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: DesktopApp(
          controller: controller,
          onPickSubtitleFile: () async => externalSubPath,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    unawaited(controller.open('https://exemplo.invalid/filme.mp4'));
    await tester.pump();

    const audio2 = AudioTrack(id: '2', title: 'Português', language: 'por', codec: 'aac', channels: 2);
    const sub1 = SubtitleTrack(id: '1', title: 'Legenda Padrão', language: 'por', codec: 'srt');
    fakePlayer.emitReadyFrame(
      playing: false,
      duration: const Duration(minutes: 20),
      position: const Duration(minutes: 1),
      tracks: const Tracks(audio: [audio2], subtitle: [sub1]),
      track: const TrackSelection(audio: audio2, subtitle: sub1),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Menu de áudio com faixa real + desligado/automático.
    await tester.tap(find.text('Áudio'));
    await tester.pumpAndSettle();
    expect(find.text('Automático'), findsOneWidget);
    expect(find.text('Desligado'), findsOneWidget);
    await tester.tap(find.text('Desligado'));
    await tester.pumpAndSettle();
    expect(fakePlayer.selectedAudioTracks.last.id, AudioTrack.off.id);

    // Menu de legendas com seleção off e legenda externa.
    await tester.tap(find.text('Legendas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir legenda externa (SRT, ASS, VTT)...'));
    await tester.pumpAndSettle();

    final addedViaTrack = fakePlayer.selectedSubtitleTracks
        .any((t) => t.uri == externalSubPath || t.id.contains(externalSubPath));
    final addedViaCommand = fakePlayer.commands
        .any((args) => args.contains('sub-add') && args.contains(externalSubPath));
    expect(addedViaTrack || addedViaCommand, isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await controller.close();
    controller.dispose();
  });
}
