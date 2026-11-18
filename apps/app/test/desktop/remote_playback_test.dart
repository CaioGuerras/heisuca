import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/desktop_playback_controller.dart';
import 'package:heisuca/desktop/remote/desktop_remote_playback.dart';
import 'package:heisuca/desktop/remote/desktop_servers_controller.dart';
import 'package:heisuca/exceptions/media_server_exceptions.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/playback_report_metadata.dart';
import 'package:heisuca/utils/media_server_http_client.dart' show AbortController;
import 'package:heisuca/media/library_query.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/mpv/models.dart';
import 'package:heisuca/mpv/player/player.dart';
import 'package:heisuca/mpv/player/player_state.dart';
import 'package:heisuca/mpv/player/player_streams.dart';
import 'package:heisuca/services/playback_initialization_types.dart';

class _FakePlayer implements Player {
  _FakePlayer() {
    streams = PlayerStreams(
      playing: playingController.stream,
      completed: completedController.stream,
      buffering: bufferingController.stream,
      position: positionController.stream,
      duration: durationController.stream,
      seekable: seekableController.stream,
      buffer: bufferController.stream,
      volume: volumeController.stream,
      rate: rateController.stream,
      tracks: tracksController.stream,
      track: trackController.stream,
      log: logController.stream,
      error: errorController.stream,
      audioDevice: audioDeviceController.stream,
      audioDevices: audioDevicesController.stream,
      bufferRanges: bufferRangesController.stream,
      playbackRestart: playbackRestartController.stream,
      fileStarted: fileStartedController.stream,
      fileLoaded: fileLoadedController.stream,
      fileLoadFailed: fileLoadFailedController.stream,
      sourceStarted: sourceStartedController.stream,
      sourceReady: sourceReadyController.stream,
      sourceFailed: sourceFailedController.stream,
      backendSwitched: backendSwitchedController.stream,
    );
  }

  final playingController = StreamController<bool>.broadcast();
  final completedController = StreamController<bool>.broadcast();
  final bufferingController = StreamController<bool>.broadcast();
  final positionController = StreamController<Duration>.broadcast();
  final durationController = StreamController<Duration>.broadcast();
  final seekableController = StreamController<bool>.broadcast();
  final bufferController = StreamController<Duration>.broadcast();
  final volumeController = StreamController<double>.broadcast();
  final rateController = StreamController<double>.broadcast();
  final tracksController = StreamController<Tracks>.broadcast();
  final trackController = StreamController<TrackSelection>.broadcast();
  final logController = StreamController<PlayerLog>.broadcast();
  final errorController = StreamController<PlayerError>.broadcast();
  final audioDeviceController = StreamController<AudioDevice>.broadcast();
  final audioDevicesController = StreamController<List<AudioDevice>>.broadcast();
  final bufferRangesController = StreamController<List<BufferRange>>.broadcast();
  final playbackRestartController = StreamController<void>.broadcast();
  final fileStartedController = StreamController<void>.broadcast();
  final fileLoadedController = StreamController<void>.broadcast();
  final fileLoadFailedController = StreamController<void>.broadcast();
  final sourceStartedController = StreamController<PlayerSourceStarted>.broadcast();
  final sourceReadyController = StreamController<PlayerSourceReady>.broadcast();
  final sourceFailedController = StreamController<PlayerSourceFailed>.broadcast();
  final backendSwitchedController = StreamController<void>.broadcast();

  @override
  late final PlayerStreams streams;

  PlayerState _state = const PlayerState();
  bool _disposed = false;

  final List<Media> openedMedia = [];
  List<SubtitleTrack>? lastExternalSubtitles;

  @override
  PlayerState get state => _state;
  set state(PlayerState value) => _state = value;

  @override
  Duration get currentPosition => _state.position;

  @override
  bool get disposed => _disposed;

  @override
  String get playerType => 'mpv';

  void emitFrameRendered() {
    _state = _state.copyWith(hasRenderedFrame: true);
    if (!playbackRestartController.isClosed) {
      playbackRestartController.add(null);
    }
  }

  void emitCompleted(bool value) {
    _state = _state.copyWith(completed: value, playing: !value);
    completedController.add(value);
    playingController.add(!value);
  }

  void updatePosition(Duration pos, {Duration? dur}) {
    _state = _state.copyWith(position: pos, duration: dur ?? _state.duration);
    if (!positionController.isClosed) {
      positionController.add(pos);
    }
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
  }) async {
    openedMedia.add(media);
    lastExternalSubtitles = externalSubtitles;
    _state = _state.copyWith(hasRenderedFrame: false, playing: play);
    playingController.add(play);
    if (!fileStartedController.isClosed) {
      fileStartedController.add(null);
    }
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    _disposed = true;
    await Future.wait([
      playingController.close(),
      completedController.close(),
      bufferingController.close(),
      positionController.close(),
      durationController.close(),
      seekableController.close(),
      bufferController.close(),
      volumeController.close(),
      rateController.close(),
      tracksController.close(),
      trackController.close(),
      logController.close(),
      errorController.close(),
      audioDeviceController.close(),
      audioDevicesController.close(),
      bufferRangesController.close(),
      playbackRestartController.close(),
      fileStartedController.close(),
      fileLoadedController.close(),
      fileLoadFailedController.close(),
      sourceStartedController.close(),
      sourceReadyController.close(),
      sourceFailedController.close(),
      backendSwitchedController.close(),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClient implements MediaServerClient {
  _FakeClient({
    this.initializationResult,
    this.streamHeaders = const {'X-Custom-Header': 'custom-val'},
    this.onDeckEpisode,
    this.descendantEpisodes = const [],
    this.initDelay = Duration.zero,
    this.initError,
  });

  PlaybackInitializationResult? initializationResult;
  @override
  final Map<String, String> streamHeaders;
  MediaItem? onDeckEpisode;
  List<MediaItem> descendantEpisodes;
  Duration initDelay;
  Object? initError;

  int watchedCalls = 0;
  @override
  Future<void> markWatched(MediaItem item) async { watchedCalls++; }

  final List<PlaybackInitializationOptions> initOptionsCalls = [];
  final List<Map<String, dynamic>> startedCalls = [];
  final List<Map<String, dynamic>> progressCalls = [];
  final List<Map<String, dynamic>> stoppedCalls = [];

  @override
  ServerId get serverId => ServerId('fake-server-1');

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  double get watchedThreshold => 0.9;

  @override
  bool get marksWatchedOnPlaybackStopped => false;

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem item)? onItemReady,
  }) async {
    return (item: null, onDeckEpisode: onDeckEpisode);
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    return LibraryPage<MediaItem>(
      items: descendantEpisodes,
      totalCount: descendantEpisodes.length,
    );
  }

  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(
    PlaybackInitializationOptions options,
  ) async {
    initOptionsCalls.add(options);
    if (initDelay > Duration.zero) {
      await Future<void>.delayed(initDelay);
    }
    if (initError != null) {
      throw initError!;
    }
    return initializationResult ??
        PlaybackInitializationResult(
          availableVersions: const [],
          videoUrl: 'http://127.0.0.1:8096/stream/video.mkv',
          playSessionId: options.sessionIdentifier,
          playMethod: 'DirectPlay',
        );
  }

  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    startedCalls.add({
      'itemId': itemId,
      'position': position,
      'duration': duration,
      'playSessionId': playSessionId,
    });
  }

  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    progressCalls.add({
      'itemId': itemId,
      'position': position,
      'duration': duration,
      'isPaused': isPaused,
    });
  }

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) async {
    stoppedCalls.add({
      'itemId': itemId,
      'position': position,
      'duration': duration,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<_FakePlayer> createdPlayers;
  late DesktopPlaybackController playback;

  setUp(() {
    createdPlayers = [];
    playback = DesktopPlaybackController(
      playerFactory: () {
        final p = _FakePlayer();
        createdPlayers.add(p);
        return p;
      },
    );
  });

  tearDown(() {
    playback.dispose();
  });

  DesktopServerConnection createServer(_FakeClient client) {
    return DesktopServerConnection(
      id: 'srv-1',
      name: 'Plex Server',
      backend: MediaBackend.plex,
      client: client,
    );
  }

  test('headers/start/subs sao repassados para playback.open', () async {
    final sub = SubtitleTrack.uri('http://127.0.0.1/sub.srt', title: 'PT-BR');
    final client = _FakeClient(
      streamHeaders: {'X-Custom-Auth': 'token-123'},
      initializationResult: PlaybackInitializationResult(
        availableVersions: const [],
        videoUrl: 'http://127.0.0.1/video.mp4',
        subtitleSidecars: [PlaybackSubtitleSidecar(sourceStreamId: 1, track: sub)],
      ),
    );
    final server = createServer(client);
    final coordinator = DesktopRemotePlaybackCoordinator(playback: playback);

    final item = MediaItem.plex(
      id: 'item-1',
      kind: MediaKind.movie,
      title: 'Filme Alpha',
      viewOffsetMs: 12000,
    );

    await coordinator.play(server, item);

    final player = createdPlayers.first;
    expect(player.openedMedia.length, 1);
    expect(player.openedMedia.first.headers, {'X-Custom-Auth': 'token-123'});
    expect(player.openedMedia.first.start, const Duration(milliseconds: 12000));
    expect(player.lastExternalSubtitles?.length, 1);
    expect(player.lastExternalSubtitles?.first.title, 'PT-BR');
    expect(playback.title, 'Filme Alpha');
  });

  test('nenhum Started antes do frame e Tracker envia Start/Progress/Stop 1x', () async {
    final client = _FakeClient();
    final server = createServer(client);
    final coordinator = DesktopRemotePlaybackCoordinator(
      playback: playback,
      trackerInterval: const Duration(milliseconds: 100),
    );

    final item = MediaItem.plex(
      id: 'item-2',
      kind: MediaKind.movie,
      title: 'Filme Beta',
      durationMs: 60000,
    );

    final playFuture = coordinator.play(server, item);
    await Future<void>.delayed(Duration.zero);

    final player = createdPlayers.first;
    expect(client.startedCalls, isEmpty, reason: 'Nenhum Started antes do primeiro frame');

    player.emitFrameRendered();
    await playFuture;
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(client.startedCalls.length, 1);
    expect(client.startedCalls.first['itemId'], 'item-2');

    player.updatePosition(const Duration(seconds: 10), dur: const Duration(seconds: 60));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(client.progressCalls, isNotEmpty);

    await coordinator.stop();
    expect(client.stoppedCalls.length, 1);

    // Stop subsequente em sessão inativa é no-op
    await coordinator.stop();
    expect(client.stoppedCalls.length, 1);
  });

  test('Local B com MESMO TITULO enquanto A negocia descarta A sem tocar em B', () async {
    final client = _FakeClient(
      initDelay: const Duration(milliseconds: 80),
    );
    final server = createServer(client);
    final coordinator = DesktopRemotePlaybackCoordinator(playback: playback);

    final itemA = MediaItem.plex(
      id: 'item-a',
      kind: MediaKind.movie,
      title: 'Mesmo Titulo',
    );

    // Inicia negociação de A (assíncrona)
    final playAFuture = coordinator.play(server, itemA);

    // Enquanto A negocia, Local B abre com exatamente o MESMO TÍTULO
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await playback.open('/path/to/local_video.mp4', displayTitle: 'Mesmo Titulo');
    final localPlayer = createdPlayers.last;
    localPlayer.emitFrameRendered();
    await Future<void>.delayed(Duration.zero);

    await playAFuture;

    expect(playback.hasMedia, isTrue);
    expect(createdPlayers.last, same(localPlayer), reason: 'A atrasado não deve ter aberto player sucessor');
    expect(client.startedCalls, isEmpty, reason: 'A foi descartado e não deve reportar start');
  });

  test('stop inativo nao fecha video local', () async {
    final coordinator = DesktopRemotePlaybackCoordinator(playback: playback);

    await playback.open('/local/file.mp4', displayTitle: 'Video Local');
    final localPlayer = createdPlayers.first;
    localPlayer.emitFrameRendered();
    await Future<void>.delayed(Duration.zero);
    expect(playback.hasMedia, isTrue);

    // Chamada a stop() no coordinator sem nenhuma sessão remota ativa
    await coordinator.stop();

    expect(playback.hasMedia, isTrue);
    expect(localPlayer.disposed, isFalse);
  });

  test('Stop usa snapshot antigo e nao posicao de video local sucessor', () async {
    final client = _FakeClient();
    final server = createServer(client);
    final coordinator = DesktopRemotePlaybackCoordinator(playback: playback);

    final item = MediaItem.plex(
      id: 'item-snap',
      kind: MediaKind.movie,
      title: 'Remoto Snap',
      durationMs: 120000,
    );

    await coordinator.play(server, item);
    final remotePlayer = createdPlayers.first;
    remotePlayer.emitFrameRendered();
    remotePlayer.updatePosition(const Duration(seconds: 25), dur: const Duration(seconds: 120));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // Local sucessor entra e avança a reprodução para 100 segundos
    await playback.open('/local/other.mp4', displayTitle: 'Local Novo');
    final localPlayer = createdPlayers.last;
    localPlayer.emitFrameRendered();
    await Future<void>.delayed(Duration.zero);
    localPlayer.updatePosition(const Duration(seconds: 100), dur: const Duration(seconds: 120));

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(client.stoppedCalls.length, 1);
    expect(
      client.stoppedCalls.first['position'],
      const Duration(seconds: 25),
      reason: 'O Stop do vídeo remoto deve usar o snapshot de sua época e jamais a posição da mídia sucessora',
    );
  });

  test('erro na negociacao nao vaza canarios ou URLs privadas', () async {
    final client = _FakeClient(
      initError: MediaServerHttpException(
        type: MediaServerHttpErrorType.unknown,
        statusCode: 403,
        message: 'FORBIDDEN CANARY_TOKEN_XYZ https://secret.plex.direct/video?token=SUPER_SECRET',
      ),
    );
    final server = createServer(client);
    final coordinator = DesktopRemotePlaybackCoordinator(playback: playback);

    final item = MediaItem.plex(
      id: 'item-err',
      kind: MediaKind.movie,
      title: 'Filme Erro',
    );

    await coordinator.play(server, item);

    expect(coordinator.error, isNotNull);
    expect(coordinator.error!.contains('CANARY_TOKEN_XYZ'), isFalse);
    expect(coordinator.error!.contains('SUPER_SECRET'), isFalse);
    expect(coordinator.error!.contains('https://'), isFalse);
    expect(coordinator.error, 'Acesso negado ao servidor de mídia.');
  });
  test('série resolve onDeck e temporada resolve primeiro episódio, nunca o contêiner', () async {
    const ep = MediaItem.plex(id: 'ep-real', kind: MediaKind.episode, title: 'Ep');
    final client = _FakeClient(onDeckEpisode: ep, descendantEpisodes: [ep]);
    final coordinator = DesktopRemotePlaybackCoordinator(playback: playback);
    addTearDown(coordinator.dispose);
    await coordinator.play(createServer(client),
        const MediaItem.plex(id: 'serie', kind: MediaKind.show, title: 'Série'));
    expect(client.initOptionsCalls.last.metadata.id, 'ep-real');
    await coordinator.play(createServer(client),
        const MediaItem.plex(id: 'temporada', kind: MediaKind.season, title: 'Temporada'));
    expect(client.initOptionsCalls.last.metadata.id, 'ep-real');
  });

  test('stop durante negociação impede abertura tardia', () async {
    final client = _FakeClient(initDelay: const Duration(milliseconds: 60));
    final coordinator = DesktopRemotePlaybackCoordinator(playback: playback);
    addTearDown(coordinator.dispose);
    final request = coordinator.play(createServer(client),
        const MediaItem.plex(id: 'cancelado', kind: MediaKind.movie, title: 'Cancelado'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await coordinator.stop();
    await request;
    expect(createdPlayers, isEmpty);
    expect(client.startedCalls, isEmpty);
    expect(coordinator.busy, isFalse);
  });

  test('fim envia Stop uma vez e replay abre nova sessão de progresso', () async {
    final client = _FakeClient();
    final coordinator = DesktopRemotePlaybackCoordinator(playback: playback,
        trackerInterval: const Duration(milliseconds: 30));
    addTearDown(coordinator.dispose);
    await coordinator.play(createServer(client), const MediaItem.plex(
        id: 'fim', kind: MediaKind.movie, title: 'Fim', durationMs: 60000));
    final player = createdPlayers.single;
    player.emitFrameRendered();
    player.updatePosition(const Duration(seconds: 60), dur: const Duration(seconds: 60));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    player.emitCompleted(true);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    expect(client.stoppedCalls, hasLength(1));
    final count = client.progressCalls.length;
    await Future<void>.delayed(const Duration(milliseconds: 90));
    expect(client.progressCalls, hasLength(count), reason: 'Não manter heartbeat após fim');
    player.updatePosition(Duration.zero);
    player.emitCompleted(false);
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(client.startedCalls, hasLength(2));
    await coordinator.stop();
    expect(client.stoppedCalls, hasLength(2));
  });

}
