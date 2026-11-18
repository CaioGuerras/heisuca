import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/desktop_playback_controller.dart';
import 'package:heisuca/mpv/models.dart';
import 'package:heisuca/mpv/player/player.dart';
import 'package:heisuca/mpv/player/player_state.dart';
import 'package:heisuca/mpv/player/player_streams.dart';

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
      backendSwitched: _backendSwitchedController.stream,
    );
  }

  final Set<String> activeStreams = <String>{};

  StreamController<T> _tracked<T>(String name) {
    return StreamController<T>.broadcast(
      onListen: () => activeStreams.add(name),
      onCancel: () => activeStreams.remove(name),
    );
  }

  late final StreamController<bool> _playingController = _tracked<bool>('playing');
  late final StreamController<bool> _completedController = _tracked<bool>('completed');
  late final StreamController<bool> _bufferingController = _tracked<bool>('buffering');
  late final StreamController<Duration> _positionController = _tracked<Duration>('position');
  late final StreamController<Duration> _durationController = _tracked<Duration>('duration');
  late final StreamController<bool> _seekableController = _tracked<bool>('seekable');
  late final StreamController<Duration> _bufferController = _tracked<Duration>('buffer');
  late final StreamController<double> _volumeController = _tracked<double>('volume');
  late final StreamController<double> _rateController = _tracked<double>('rate');
  late final StreamController<Tracks> _tracksController = _tracked<Tracks>('tracks');
  late final StreamController<TrackSelection> _trackController = _tracked<TrackSelection>('track');
  late final StreamController<PlayerLog> _logController = _tracked<PlayerLog>('log');
  late final StreamController<PlayerError> _errorController = _tracked<PlayerError>('error');
  late final StreamController<AudioDevice> _audioDeviceController = _tracked<AudioDevice>('audioDevice');
  late final StreamController<List<AudioDevice>> _audioDevicesController = _tracked<List<AudioDevice>>('audioDevices');
  late final StreamController<List<BufferRange>> _bufferRangesController = _tracked<List<BufferRange>>('bufferRanges');
  late final StreamController<void> _playbackRestartController = _tracked<void>('playbackRestart');
  late final StreamController<void> _fileLoadedController = _tracked<void>('fileLoaded');
  late final StreamController<void> _fileStartedController = _tracked<void>('fileStarted');
  late final StreamController<void> _fileLoadFailedController = _tracked<void>('fileLoadFailed');
  late final StreamController<PlayerSourceStarted> _sourceStartedController = _tracked<PlayerSourceStarted>('sourceStarted');
  late final StreamController<PlayerSourceReady> _sourceReadyController = _tracked<PlayerSourceReady>('sourceReady');
  late final StreamController<PlayerSourceFailed> _sourceFailedController = _tracked<PlayerSourceFailed>('sourceFailed');
  late final StreamController<void> _backendSwitchedController = _tracked<void>('backendSwitched');

  late final PlayerStreams _streams;
  PlayerState _state = const PlayerState();
  bool _disposed = false;

  final List<String> callLog = <String>[];
  final List<Media> openedMedia = <Media>[];
  final List<Duration> soughtPositions = <Duration>[];
  final List<double> setVolumes = <double>[];
  final List<AudioTrack> selectedAudioTracks = <AudioTrack>[];
  final List<SubtitleTrack> selectedSubtitleTracks = <SubtitleTrack>[];

  Future<void> Function(Media media)? onOpen;
  Future<void> Function()? onStop;
  Future<void> Function()? onDispose;

  @override
  PlayerState get state => _state;

  set state(PlayerState value) => _state = value;

  @override
  PlayerStreams get streams => _streams;

  @override
  Duration get currentPosition => _state.position;

  @override
  String get playerType => 'mpv';

  @override
  bool get disposed => _disposed;

  void emitPlaybackRestart() {
    _state = _state.copyWith(hasRenderedFrame: true);
    _playbackRestartController.add(null);
  }

  void emitFileStarted() {
    _state = _state.copyWith(hasRenderedFrame: false);
    _fileStartedController.add(null);
  }

  void emitFileLoaded() => _fileLoadedController.add(null);

  void emitFileLoadFailed() => _fileLoadFailedController.add(null);

  void emitSourceStarted(int sourceId) => _sourceStartedController.add(PlayerSourceStarted(sourceId));

  void emitSourceFailed(int sourceId) => _sourceFailedController.add(PlayerSourceFailed(sourceId));

  void emitPlaying(bool playing) {
    _state = _state.copyWith(playing: playing);
    _playingController.add(playing);
  }

  void emitLog(PlayerLog log) => _logController.add(log);

  void emitError(PlayerError error) => _errorController.add(error);

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
  }) async {
    callLog.add('open');
    openedMedia.add(media);
    // Match native start-file: a new source clears the old rendered frame.
    _state = _state.copyWith(hasRenderedFrame: false);
    _fileStartedController.add(null);
    if (onOpen != null) {
      await onOpen!(media);
    }
  }

  @override
  Future<void> play() async {
    callLog.add('play');
    _state = _state.copyWith(playing: true);
  }

  @override
  Future<void> pause() async {
    callLog.add('pause');
    _state = _state.copyWith(playing: false);
  }

  @override
  Future<void> playOrPause() async {
    callLog.add('playOrPause');
    _state = _state.copyWith(playing: !_state.playing);
  }

  @override
  Future<void> stop() async {
    callLog.add('stop');
    _state = _state.copyWith(playing: false, hasRenderedFrame: false);
    if (onStop != null) {
      await onStop!();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    callLog.add('seek');
    soughtPositions.add(position);
    _state = _state.copyWith(position: position);
  }

  @override
  Future<void> setVolume(double volume) async {
    callLog.add('setVolume');
    setVolumes.add(volume);
    _state = _state.copyWith(volume: volume);
  }

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    callLog.add('selectAudioTrack');
    selectedAudioTracks.add(track);
    _state = _state.copyWith(track: _state.track.copyWith(audio: track));
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    callLog.add('selectSubtitleTrack');
    selectedSubtitleTracks.add(track);
    _state = _state.copyWith(track: _state.track.copyWith(subtitle: track));
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    callLog.add('dispose');
    _disposed = true;
    if (onDispose != null) {
      await onDispose!();
    }
    await Future.wait<void>(<Future<void>>[
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
      _backendSwitchedController.close(),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('fechar interrompe open nativo que nunca completa sem depender do watchdog', () {
    fakeAsync((async) {
      final nativeOpen = Completer<void>();
      final fake = _FakePlayer()..onOpen = (_) => nativeOpen.future;
      final controller = DesktopPlaybackController(playerFactory: () => fake);
      var closed = false;
      unawaited(controller.open('/tmp/travado.mkv'));
      async.flushMicrotasks();
      unawaited(controller.close().then((_) => closed = true));
      async.flushMicrotasks();
      try {
        expect(closed, isTrue, reason: 'close deve liberar a fila mesmo sem resposta nativa');
        expect(fake.disposed, isTrue);
      } finally {
        controller.dispose();
        async.flushMicrotasks();
      }
    });
  });

  group('DesktopPlaybackController - inicialização lazy e segurança sem mídia', () {
    test('não cria Player no construtor e métodos sem mídia são seguros', () async {
      var factoryCalls = 0;
      final controller = DesktopPlaybackController(
        playerFactory: () {
          factoryCalls++;
          return _FakePlayer();
        },
      );

      expect(factoryCalls, 0);
      expect(controller.player, isNull);
      expect(controller.state.playing, isFalse);
      expect(controller.state.hasRenderedFrame, isFalse);
      expect(controller.title, isNull);
      expect(controller.error, isNull);
      expect(controller.opening, isFalse);
      expect(controller.hasMedia, isFalse);

      await controller.close();
      await controller.togglePause();
      await controller.seek(const Duration(seconds: 10));
      await controller.setVolume(42);
      await controller.selectAudio(AudioTrack.auto);
      await controller.selectSubtitle(SubtitleTrack.off);
      await controller.addSubtitle('/tmp/legenda.srt');

      expect(factoryCalls, 0);
      expect(controller.player, isNull);
      expect(controller.error, isNull);
      controller.dispose();
    });
  });

  group('DesktopPlaybackController - validação WindowsUnicode, Unix, file URI e esquemas maliciosos', () {
    test('preserva WindowsUnicode, #, % literal, UNC, Unix e file URI via package:path', () async {
      final fake = _FakePlayer();
      final controller = DesktopPlaybackController(playerFactory: () => fake);

      await controller.open(r'C:\Vídeos\アニメ #1 [100%] %20.mkv');
      expect(fake.openedMedia.last.uri, r'C:\Vídeos\アニメ #1 [100%] %20.mkv');
      expect(controller.title, 'アニメ #1 [100%] %20.mkv');
      fake.emitPlaybackRestart();
      await Future<void>.microtask(() {});

      await controller.open(r'D:/Filmes/temp/../Série #2 50%.mp4');
      expect(fake.openedMedia.last.uri, r'D:\Filmes\Série #2 50%.mp4');
      expect(controller.title, 'Série #2 50%.mp4');
      fake.emitPlaybackRestart();
      await Future<void>.microtask(() {});

      await controller.open(r'\\servidor\midia\pasta\..\filme #1 100%.mkv');
      expect(fake.openedMedia.last.uri, r'\\servidor\midia\filme #1 100%.mkv');
      expect(controller.title, 'filme #1 100%.mkv');
      fake.emitPlaybackRestart();
      await Future<void>.microtask(() {});

      await controller.open(r'\\?\C:\caminho\longo\filme #1 100%.mkv');
      expect(fake.openedMedia.last.uri, r'\\?\C:\caminho\longo\filme #1 100%.mkv');
      fake.emitPlaybackRestart();
      await Future<void>.microtask(() {});

      await controller.open('file:///C:/V%C3%ADdeos/%E3%82%A2%E3%83%8B%E3%83%A1%20%231%20100%25.mkv');
      expect(fake.openedMedia.last.uri, r'C:\Vídeos\アニメ #1 100%.mkv');
      expect(controller.title, 'アニメ #1 100%.mkv');
      fake.emitPlaybackRestart();
      await Future<void>.microtask(() {});

      await controller.open('file://localhost/C:/Filmes/a/../teste%20%231.mkv');
      expect(fake.openedMedia.last.uri, r'C:\Filmes\teste #1.mkv');
      fake.emitPlaybackRestart();
      await Future<void>.microtask(() {});

      await controller.open('/home/usuário/Vídeos/sub/../アニメ #1 [100%] %20.mkv');
      expect(fake.openedMedia.last.uri, '/home/usuário/Vídeos/アニメ #1 [100%] %20.mkv');
      expect(controller.title, 'アニメ #1 [100%] %20.mkv');
      fake.emitPlaybackRestart();
      await Future<void>.microtask(() {});

      await controller.open('file:///home/usu%C3%A1rio/V%C3%ADdeos/%E3%82%A2%E3%83%8B%E3%83%A1%20%231%20100%25.mkv');
      expect(fake.openedMedia.last.uri, '/home/usuário/Vídeos/アニメ #1 100%.mkv');
      fake.emitPlaybackRestart();
      await Future<void>.microtask(() {});

      await controller.open('https://cdn.example.com/media/Ep%2001.mkv?token=SEGREDO_TOKEN');
      expect(fake.openedMedia.last.uri, 'https://cdn.example.com/media/Ep%2001.mkv?token=SEGREDO_TOKEN');
      expect(controller.title, 'Ep 01.mkv');
      expect(controller.title, isNot(contains('SEGREDO_TOKEN')));
      expect(controller.title, isNot(contains('cdn.example.com')));

      expect(
        DesktopPlaybackController.normalizeSourceForTest(
          'file://servidor/compartilhamento/V%C3%ADdeos/filme%20%231.mkv',
          isWindows: true,
        ),
        r'\\servidor\compartilhamento\Vídeos\filme #1.mkv',
      );
      expect(
        DesktopPlaybackController.normalizeSourceForTest(
          'file://servidor/compartilhamento/filme.mkv',
          isWindows: false,
        ),
        isNull,
      );

      controller.dispose();
    });

    test('rejeita esquema malicioso, userInfo e caminhos inválidos sem inicializar Player nem vazar URI', () async {
      final maliciousInputs = <String>[
        '',
        '   ',
        'javascript:alert(1)',
        'data:video/mp4;base64,AAAA',
        'smb://servidor/pasta/filme.mkv',
        'ftp://host.local/filme.mkv',
        'rtsp://host.local/stream',
        'content://media/external/video/1',
        'edl://segment.mkv',
        'fd://0',
        'lavfi://testsrc',
        '//evil.example.com/filme.mp4',
        'http://usuario:senha123@example.com/filme.mp4?token=SECRET99',
        'https://usuario@example.com/filme.mp4',
        'https://@example.com/filme.mp4',
        'file://usuario:senha@localhost/tmp/filme.mkv',
        'file:///tmp/bad%00.mkv',
        'file:///tmp/filme.mkv#fragmento',
        'file:///tmp/filme.mkv?token=SECRET99',
        r'\\.\PhysicalDrive0',
        r'C:\',
        '/',
        'relativo/filme.mkv',
        '/tmp/invalido\nquebra.mkv',
      ];

      for (final source in maliciousInputs) {
        var created = 0;
        final controller = DesktopPlaybackController(
          playerFactory: () {
            created++;
            return _FakePlayer();
          },
        );

        await controller.open(source);

        expect(created, 0, reason: 'Não deve instanciar Player para: $source');
        expect(controller.player, isNull);
        expect(controller.opening, isFalse);
        expect(controller.hasMedia, isFalse);
        expect(controller.title, isNull);
        expect(controller.error, isNotNull);
        expect(controller.error, isNot(contains('usuario')));
        expect(controller.error, isNot(contains('senha')));
        expect(controller.error, isNot(contains('SECRET99')));
        expect(controller.error, isNot(contains('example.com')));
        expect(controller.error, isNot(contains('javascript')));
        expect(controller.error, isNot(contains('PhysicalDrive0')));
        controller.dispose();
      }
    });
  });

  group('DesktopPlaybackController - timeout sem frame e confirmação por frame real', () {
    test('Future.open retornar não basta; timeout sem frame falha e evento atrasado não vira sucesso', () {
      fakeAsync((async) {
        final fake = _FakePlayer();
        final controller = DesktopPlaybackController(playerFactory: () => fake);

        unawaited(controller.open('/tmp/filme.mkv'));
        async.flushMicrotasks();

        expect(fake.openedMedia, hasLength(1));
        expect(controller.opening, isTrue);
        expect(controller.hasMedia, isFalse);

        // Eventos parciais sem frame não confirmam abertura.
        fake.emitFileLoaded();
        fake.emitPlaying(true);
        async.flushMicrotasks();
        expect(controller.opening, isTrue);
        expect(controller.hasMedia, isFalse);

        async.elapse(const Duration(seconds: 24));
        expect(controller.opening, isTrue);
        expect(controller.error, isNull);

        async.elapse(const Duration(seconds: 1));
        expect(controller.opening, isFalse);
        expect(controller.hasMedia, isFalse);
        expect(controller.error, isNotNull);
        expect(fake.callLog, contains('stop'));

        final capturedError = controller.error;
        // Evento atrasado após erro não pode converter erro em sucesso.
        fake.emitPlaybackRestart();
        fake.emitPlaying(true);
        async.flushMicrotasks();

        expect(controller.hasMedia, isFalse);
        expect(controller.opening, isFalse);
        expect(controller.error, capturedError);
        expect(controller.state.playing, isFalse);

        controller.dispose();
      });
    });

    test('encerra watchdog quando playbackRestart confirma frame real', () {
      fakeAsync((async) {
        final fake = _FakePlayer();
        final controller = DesktopPlaybackController(playerFactory: () => fake);

        unawaited(controller.open('/tmp/filme.mkv'));
        async.flushMicrotasks();
        expect(controller.opening, isTrue);

        async.elapse(const Duration(seconds: 2));
        fake.emitPlaybackRestart();
        async.flushMicrotasks();

        expect(controller.opening, isFalse);
        expect(controller.hasMedia, isTrue);
        expect(controller.state.hasRenderedFrame, isTrue);
        expect(controller.error, isNull);

        // Passar o tempo restante de timeout não pode disparar erro.
        async.elapse(const Duration(seconds: 30));
        expect(controller.hasMedia, isTrue);
        expect(controller.error, isNull);
        expect(fake.callLog.where((c) => c == 'stop'), isEmpty);

        controller.dispose();
      });
    });

    test('player.open travado desbloqueia no timeout sem deadlock', () {
      fakeAsync((async) {
        final fake = _FakePlayer()..onOpen = (_) => Completer<void>().future;
        final controller = DesktopPlaybackController(playerFactory: () => fake);

        var completed = false;
        unawaited(controller.open('/tmp/travado.mkv').then((_) => completed = true));
        async.flushMicrotasks();
        expect(completed, isFalse);
        expect(controller.opening, isTrue);

        async.elapse(const Duration(seconds: 25));
        expect(completed, isTrue);
        expect(controller.opening, isFalse);
        expect(controller.hasMedia, isFalse);
        expect(controller.error, isNotNull);

        controller.dispose();
      });
    });

    test('confirma também quando hasRenderedFrame transiciona de false para true no open', () async {
      final fake = _FakePlayer()
        ..onOpen = (_) async {
          // Atualiza state direto sem stream playbackRestart.
        };
      final controller = DesktopPlaybackController(playerFactory: () => fake);
      fake.onOpen = (_) async {
        fake.state = fake.state.copyWith(hasRenderedFrame: true);
      };

      await controller.open('/tmp/direto.mkv');
      expect(controller.opening, isFalse);
      expect(controller.hasMedia, isTrue);
      expect(controller.state.hasRenderedFrame, isTrue);

      controller.dispose();
    });
  });

  group('DesktopPlaybackController - falha nativa e separação de erro', () {
    test('trata falha na factory sem inicializar player', () async {
      final controller = DesktopPlaybackController(
        playerFactory: () => throw StateError('falha https://user:pass@host/a?token=SEG'),
      );

      await controller.open('/tmp/video.mkv');
      expect(controller.player, isNull);
      expect(controller.opening, isFalse);
      expect(controller.hasMedia, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.error, isNot(contains('SEG')));
      expect(controller.error, isNot(contains('https://')));

      controller.dispose();
    });

    test('trata PlayerInitializationException e descarta player quebrado', () async {
      var creations = 0;
      late _FakePlayer firstPlayer;
      late _FakePlayer secondPlayer;
      final controller = DesktopPlaybackController(
        playerFactory: () {
          creations++;
          final p = _FakePlayer();
          if (creations == 1) {
            firstPlayer = p..onOpen = (_) => Future<void>.error(const PlayerInitializationException());
          } else {
            secondPlayer = p;
          }
          return p;
        },
      );

      await controller.open('/tmp/video.mkv');
      expect(controller.opening, isFalse);
      expect(controller.hasMedia, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.player, isNull);
      expect(firstPlayer.disposed, isTrue);

      await controller.open('/tmp/video2.mkv');
      secondPlayer.emitPlaybackRestart();
      await Future<void>.microtask(() {});
      expect(creations, 2);
      expect(controller.hasMedia, isTrue);
      expect(controller.error, isNull);

      controller.dispose();
    });

    test('sanitiza exceção bruta de open com URL, usuário e token', () async {
      final fake = _FakePlayer()
        ..onOpen = (_) => Future<void>.error(
          Exception('libmpv failed at https://caio:topsecret@media.internal/x.mkv?token=ABC_XYZ'),
        );
      final controller = DesktopPlaybackController(playerFactory: () => fake);

      await controller.open('https://media.internal/x.mkv?token=ABC_XYZ');
      expect(controller.opening, isFalse);
      expect(controller.hasMedia, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.error, isNot(contains('caio')));
      expect(controller.error, isNot(contains('topsecret')));
      expect(controller.error, isNot(contains('ABC_XYZ')));
      expect(controller.error, isNot(contains('media.internal')));

      controller.dispose();
    });

    test('separa evento generic error de falha ao iniciar e trata fileLoadFailed/sourceFailed', () {
      fakeAsync((async) {
        final fake = _FakePlayer();
        final controller = DesktopPlaybackController(playerFactory: () => fake);

        unawaited(controller.open('https://cdn.example.com/movie.mkv?token=SECRET'));
        async.flushMicrotasks();

        // Erro genérico de propriedade/plataforma sem cause fatal não aborta abertura.
        fake.emitError(const PlayerError('Failed to set video rect: transient https://cdn.example.com?token=SECRET'));
        async.flushMicrotasks();
        expect(controller.opening, isTrue);
        expect(controller.error, isNull);

        fake.emitPlaybackRestart();
        async.flushMicrotasks();
        expect(controller.hasMedia, isTrue);

        // Novo open falha com log 404 + fileLoadFailed.
        unawaited(controller.open('https://cdn.example.com/missing.mkv?token=SECRET'));
        async.flushMicrotasks();
        fake.emitLog(
          const PlayerLog(
            level: PlayerLogLevel.warn,
            prefix: 'ffmpeg',
            text: 'http: HTTP error 404 Not Found https://cdn.example.com/missing.mkv?token=SECRET',
          ),
        );
        fake.emitFileLoadFailed();
        async.flushMicrotasks();

        expect(controller.opening, isFalse);
        expect(controller.hasMedia, isFalse);
        expect(controller.error, contains('404'));
        expect(controller.error, isNot(contains('SECRET')));
        expect(controller.error, isNot(contains('cdn.example.com')));

        // playbackRestart atrasado após fileLoadFailed é ignorado.
        fake.emitPlaybackRestart();
        async.flushMicrotasks();
        expect(controller.hasMedia, isFalse);
        expect(controller.error, contains('404'));

        // sourceFailed antigo é ignorado quando sourceId atual é outro.
        unawaited(controller.open('/tmp/novo.mkv'));
        async.flushMicrotasks();
        fake.emitSourceStarted(20);
        fake.emitSourceFailed(10);
        async.flushMicrotasks();
        expect(controller.opening, isTrue);
        expect(controller.error, isNull);

        fake.emitSourceFailed(20);
        async.flushMicrotasks();
        expect(controller.opening, isFalse);
        expect(controller.error, isNotNull);

        controller.dispose();
      });
    });
  });

  group('DesktopPlaybackController - concorrência abrir/fechar e ações com mídia', () {
    test('substituir abertura travada usa player novo e ignora resultado antigo', () async {
      final oldOpen = Completer<void>();
      final oldPlayer = _FakePlayer()..onOpen = (_) => oldOpen.future;
      final newPlayer = _FakePlayer();
      var creations = 0;
      final controller = DesktopPlaybackController(
        playerFactory: () => creations++ == 0 ? oldPlayer : newPlayer,
      );
      final first = controller.open('/tmp/antigo.mkv');
      await Future<void>.microtask(() {});
      final second = controller.open('/tmp/novo.mkv');
      await Future.wait([first, second]); // oldOpen deliberately never completed yet.
      expect(oldPlayer.disposed, isTrue);
      expect(newPlayer.openedMedia.single.uri, '/tmp/novo.mkv');
      expect(controller.opening, isTrue);
      oldOpen.complete(); // Native completion from the retired source.
      await Future<void>.microtask(() {});
      expect(controller.hasMedia, isFalse);
      expect(controller.title, 'novo.mkv');
      newPlayer.emitPlaybackRestart();
      await Future<void>.microtask(() {});
      expect(controller.hasMedia, isTrue);
      expect(controller.title, 'novo.mkv');
      controller.dispose();
    });

    test('open inválido concorrente invalida abertura em andamento e não vira sucesso', () async {
      final fake = _FakePlayer();
      final slowOpen = Completer<void>();
      fake.onOpen = (_) => slowOpen.future;

      final controller = DesktopPlaybackController(playerFactory: () => fake);
      final f1 = controller.open('/tmp/valido.mkv');
      await Future<void>.microtask(() {});
      final f2 = controller.open('javascript:alert(1)');

      slowOpen.complete();
      await Future.wait<void>(<Future<void>>[f1, f2]);

      expect(controller.opening, isFalse);
      expect(controller.hasMedia, isFalse);
      expect(controller.error, isNotNull);

      expect(fake.disposed, isTrue);
      expect(fake.activeStreams, isEmpty);
      expect(controller.hasMedia, isFalse);
      expect(controller.error, isNotNull);

      controller.dispose();
    });

    test('controles de reprodução, clamp e addSubtitle funcionam com mídia ativa', () async {
      final fake = _FakePlayer();
      final controller = DesktopPlaybackController(playerFactory: () => fake);

      await controller.open('/tmp/filme.mkv');
      fake.emitPlaybackRestart();
      await Future<void>.microtask(() {});

      await controller.togglePause();
      await controller.seek(const Duration(seconds: -5));
      await controller.seek(const Duration(seconds: 42));
      await controller.setVolume(150);
      await controller.setVolume(-10);
      await controller.setVolume(double.nan);
      const audio = AudioTrack(id: '2', title: 'Japonês');
      const sub = SubtitleTrack(id: '3', title: 'PT-BR');
      await controller.selectAudio(audio);
      await controller.selectSubtitle(sub);

      await controller.addSubtitle('https://evil.example.com/sub.srt?token=123');
      expect(controller.error, isNotNull);
      expect(controller.error, isNot(contains('evil.example.com')));

      await controller.addSubtitle(r'C:\Legendas\アニメ #1 [100%].srt');
      expect(controller.error, isNull);
      expect(fake.selectedSubtitleTracks.last.uri, r'C:\Legendas\アニメ #1 [100%].srt');
      expect(fake.selectedSubtitleTracks.last.isExternal, isTrue);

      expect(controller.state.playing, isTrue);
      expect(fake.soughtPositions, <Duration>[Duration.zero, const Duration(seconds: 42)]);
      expect(fake.setVolumes, <double>[100.0, 0.0]);
      expect(fake.selectedAudioTracks, <AudioTrack>[audio]);

      controller.dispose();
    });
  });

  group('DesktopPlaybackController - dispose e métodos após dispose', () {
    test('dispose cancela subscriptions/timers, captura erro de teardown e métodos após dispose são seguros', () async {
      final fake = _FakePlayer()..onDispose = () => Future<void>.error(StateError('native teardown failure'));
      var notifications = 0;
      final controller = DesktopPlaybackController(playerFactory: () => fake)
        ..addListener(() => notifications++);

      await controller.open('/tmp/video.mkv');
      expect(fake.activeStreams, isNotEmpty);
      final countBeforeDispose = notifications;

      controller.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(fake.disposed, isTrue);
      expect(fake.activeStreams, isEmpty);
      expect(controller.player, isNull);
      expect(controller.opening, isFalse);
      expect(controller.hasMedia, isFalse);
      expect(controller.title, isNull);

      // Chamadas após dispose não devem lançar, chamar player nem notificar.
      final logCountBefore = fake.callLog.length;
      await controller.open('/tmp/outro.mkv');
      await controller.close();
      await controller.togglePause();
      await controller.seek(const Duration(seconds: 5));
      await controller.setVolume(50);
      await controller.selectAudio(AudioTrack.auto);
      await controller.selectSubtitle(SubtitleTrack.off);
      await controller.addSubtitle('/tmp/legenda.ass');
      controller.dispose();

      expect(fake.callLog.length, logCountBefore);
      expect(notifications, countBeforeDispose);
    });
  });
}
