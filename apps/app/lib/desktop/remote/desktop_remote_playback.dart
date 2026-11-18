import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../exceptions/media_server_exceptions.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../media/media_source_info.dart';
import '../../mpv/player/player.dart';
import '../../services/playback_initialization_types.dart';
import '../../services/playback_progress_tracker.dart';
import '../desktop_playback_controller.dart';
import 'desktop_servers_controller.dart';

typedef RemoteTrackerFactory = PlaybackProgressTracker Function({
  required MediaServerClient? client,
  required MediaItem metadata,
  required Player player,
  required bool Function()? canReportPlayback,
  required bool Function()? hasRenderedPlayback,
  String? playSessionId,
  String? playMethod,
  MediaSourceInfo? mediaInfo,
  Duration updateInterval,
});

class DesktopRemotePlaybackCoordinator extends ChangeNotifier {
  DesktopRemotePlaybackCoordinator({
    required DesktopPlaybackController playback,
    RemoteTrackerFactory? trackerFactory,
    Duration trackerInterval = const Duration(seconds: 10),
    Duration negotiationTimeout = const Duration(seconds: 15),
    Uuid? uuid,
  })  : _playback = playback, // ignore: prefer_initializing_formals
        _trackerFactory = trackerFactory ?? _defaultTrackerFactory,
        _trackerInterval = trackerInterval, // ignore: prefer_initializing_formals
        _negotiationTimeout = negotiationTimeout, // ignore: prefer_initializing_formals
        _uuid = uuid ?? const Uuid();

  final DesktopPlaybackController _playback;
  final RemoteTrackerFactory _trackerFactory;
  final Duration _trackerInterval;
  final Duration _negotiationTimeout;
  final Uuid _uuid;

  DesktopPlaybackController get playback => _playback;

  bool _busy = false;
  String? _error;
  bool _disposed = false;
  int _requestEpoch = 0;

  _RemotePlaybackSession? _activeSession;

  bool get busy => _busy;
  String? get error => _error;

  static PlaybackProgressTracker _defaultTrackerFactory({
    required MediaServerClient? client,
    required MediaItem metadata,
    required Player player,
    required bool Function()? canReportPlayback,
    required bool Function()? hasRenderedPlayback,
    String? playSessionId,
    String? playMethod,
    MediaSourceInfo? mediaInfo,
    Duration updateInterval = const Duration(seconds: 10),
  }) {
    return PlaybackProgressTracker(
      client: client,
      metadata: metadata,
      player: player,
      canReportPlayback: canReportPlayback,
      hasRenderedPlayback: hasRenderedPlayback,
      playSessionId: playSessionId,
      playMethod: playMethod,
      mediaInfo: mediaInfo,
      updateInterval: updateInterval,
    );
  }

  Future<void> play(
    DesktopServerConnection server,
    MediaItem item, {
    int? selectedMediaIndex,
  }) async {
    if (_disposed) return;
    final requestEpoch = ++_requestEpoch;
    bool isCurrent() => !_disposed && requestEpoch == _requestEpoch;

    _busy = true;
    _error = null;
    _notify();

    // 1. Fechar sessão remota anterior se houver
    await _stopActiveSession();
    if (!isCurrent()) return;

    // 2. Fechar mídia em reprodução no controller (local ou remota anterior)
    if (_playback.hasMedia || _playback.opening) {
      await _playback.close();
    }

    if (!isCurrent()) return;

    // 3. Congelar sourceEpoch ANTES de await resolver/getPlaybackInitialization
    final frozenEpoch = _playback.sourceEpoch;

    final MediaItem resolvedItem;
    final PlaybackInitializationResult initResult;
    final String sessionId = _uuid.v4();

    try {
      resolvedItem = await _resolvePlayableItem(server.client, item)
          .timeout(_negotiationTimeout);

      if (!isCurrent()) return;
      if (_playback.sourceEpoch != frozenEpoch) {
        // Epoch mudou durante a resolução: descartar sem tocar no player
        _busy = false;
        _notify();
        return;
      }

      final options = PlaybackInitializationOptions(
        metadata: resolvedItem,
        selectedMediaIndex: selectedMediaIndex,
        sessionIdentifier: sessionId,
        transcodeSessionId: sessionId,
      );

      initResult = await server.client
          .getPlaybackInitialization(options)
          .timeout(_negotiationTimeout);
    } catch (e) {
      if (!isCurrent()) return;
      if (_playback.sourceEpoch != frozenEpoch) {
        _busy = false;
        _notify();
        return;
      }
      _busy = false;
      _error = _mapNegotiationError(e);
      _notify();
      return;
    }

    if (!isCurrent()) return;
      if (_playback.sourceEpoch != frozenEpoch) {
      _busy = false;
      _notify();
      return;
    }

    final videoUrl = initResult.videoUrl;
    if (videoUrl == null || videoUrl.trim().isEmpty) {
      _busy = false;
      _error = 'Endereço de vídeo não fornecido pelo servidor.';
      _notify();
      return;
    }

    // A sessão espera sourceEpoch + 1 pois open incrementa sincronamente antes do primeiro await
    final expectedEpoch = frozenEpoch + 1;
    final session = _RemotePlaybackSession(
      coordinator: this,
      server: server,
      item: resolvedItem,
      expectedEpoch: expectedEpoch,
      sessionId: initResult.playSessionId ?? sessionId,
      initResult: initResult,
      trackerFactory: _trackerFactory,
      trackerInterval: _trackerInterval,
    );

    _activeSession = session;
    _playback.addListener(session.onPlaybackChanged);

    final title = resolvedItem.title?.trim().isNotEmpty == true
        ? resolvedItem.title!.trim()
        : item.title?.trim().isNotEmpty == true
            ? item.title!.trim()
            : null;

    final startOffset = resolvedItem.viewOffsetMs != null && resolvedItem.viewOffsetMs! > 0
        ? Duration(milliseconds: resolvedItem.viewOffsetMs!)
        : null;

    final externalSubs = initResult.externalSubtitles.isNotEmpty
        ? initResult.externalSubtitles
        : null;

    try {
      await _playback.open(
        videoUrl,
        headers: server.client.streamHeaders.isNotEmpty ? server.client.streamHeaders : null,
        displayTitle: title,
        start: startOffset,
        externalSubtitles: externalSubs,
      );
    } catch (_) {
      if (_activeSession == session) {
        _error = 'Não foi possível abrir a mídia remota.';
        await session.finalize();
        _activeSession = null;
      }
    } finally {
      if (_activeSession == session) {
        _busy = false;
        _notify();
      }
    }
  }

  Future<void> stop() async {
    if (_disposed) return;
    final requestEpoch = ++_requestEpoch;
    final session = _activeSession;
    if (session == null) {
      // Cancel negotiation too, without closing any unrelated local source.
      _busy = false;
      _notify();
      return;
    }

    _activeSession = null;
    _busy = true;
    _notify();

    try {
      await session.finalize();
      if (_playback.sourceEpoch == session.expectedEpoch) {
        await _playback.close();
      }
    } finally {
      if (!_disposed && requestEpoch == _requestEpoch) {
        _busy = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_requestEpoch;
    final session = _activeSession;
    _activeSession = null;
    if (session != null) {
      unawaited(session.finalize());
    }
    super.dispose();
  }

  Future<void> _stopActiveSession() async {
    final session = _activeSession;
    if (session != null) {
      _activeSession = null;
      await session.finalize();
    }
  }

  void _onSessionSuperseded(_RemotePlaybackSession session) {
    if (_activeSession == session) {
      _activeSession = null;
      _busy = false;
      _notify();
    }
  }

  void _onSessionError(String? errorMessage) {
    _error = errorMessage;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<MediaItem> _resolvePlayableItem(MediaServerClient client, MediaItem item) async {
    switch (item.kind) {
      case MediaKind.movie:
      case MediaKind.episode:
      case MediaKind.clip:
        return item;

      case MediaKind.show:
        try {
          final result = await client.fetchItemWithOnDeck(item.id);
          final onDeck = result.onDeckEpisode;
          if (onDeck != null && onDeck.kind == MediaKind.episode) {
            return onDeck;
          }
        } on MediaServerAuthException {
          rethrow;
        } on MediaServerHttpException catch (error) {
          if (error.statusCode == 401 || error.statusCode == 403) rethrow;
        } on Object {
          // Optional on-deck lookup; the bounded first-page fallback remains.
        }
        final page = await client.fetchPlayableDescendantsPage(
          item.id,
          start: 0,
          size: 1,
        );
        if (page.items.isNotEmpty) {
          return page.items.first;
        }
        throw const PlaybackException('Nenhum episódio reproduzível encontrado para esta série.');

      case MediaKind.season:
        final page = await client.fetchPlayableDescendantsPage(
          item.id,
          start: 0,
          size: 1,
        );
        if (page.items.isNotEmpty) {
          return page.items.first;
        }
        throw const PlaybackException('Nenhum episódio reproduzível encontrado para esta temporada.');

      default:
        throw const PlaybackException('Tipo de mídia não suportado para reprodução remota.');
    }
  }

  static String _mapNegotiationError(Object error) {
    if (error is TimeoutException) {
      return 'Tempo limite esgotado ao conectar ao servidor.';
    }
    if (error is MediaServerHttpException) {
      if (error.statusCode == 401) {
        return 'Sessão expirada. Faça login novamente.';
      }
      if (error.statusCode == 403) {
        return 'Acesso negado ao servidor de mídia.';
      }
      if (error.statusCode != null && error.statusCode! >= 500) {
        return 'Servidor de mídia temporariamente indisponível.';
      }
      return 'Falha na comunicação com o servidor de mídia.';
    }
    if (error is MediaServerAuthException) {
      return error.statusCode == 403
          ? 'Acesso negado ao servidor de mídia.'
          : 'Sessão expirada. Faça login novamente.';
    }
    if (error is PlaybackException) {
      return 'Não foi possível obter uma fonte reproduzível deste título.';
    }
    return 'Não foi possível inicializar a reprodução remota.';
  }
}

class _RemotePlaybackSession {
  _RemotePlaybackSession({
    required this.coordinator,
    required this.server,
    required this.item,
    required this.expectedEpoch,
    required this.sessionId,
    required this.initResult,
    required this.trackerFactory,
    required this.trackerInterval,
  })  : _lastPositionSnapshot = item.viewOffsetMs != null && item.viewOffsetMs! > 0
            ? Duration(milliseconds: item.viewOffsetMs!)
            : Duration.zero,
        _lastDurationSnapshot = item.durationMs != null && item.durationMs! > 0
            ? Duration(milliseconds: item.durationMs!)
            : Duration.zero;

  final DesktopRemotePlaybackCoordinator coordinator;
  final DesktopServerConnection server;
  final MediaItem item;
  final int expectedEpoch;
  final String sessionId;
  final PlaybackInitializationResult initResult;
  final RemoteTrackerFactory trackerFactory;
  final Duration trackerInterval;

  PlaybackProgressTracker? _tracker;
  bool _hasRenderedFrame = false;
  bool _trackingStarted = false;
  Duration _lastPositionSnapshot;
  Duration _lastDurationSnapshot;

  bool _finalized = false;
  Future<void>? _finalizeFuture;
  Future<void>? _endStop;
  bool _resumingAfterEnd = false;

  void onPlaybackChanged() {
    if (_finalized) return;

    final controller = coordinator.playback;

    // onPlaybackChanged só aceita a época esperada
    if (controller.sourceEpoch != expectedEpoch) {
      coordinator._onSessionSuperseded(this);
      unawaited(finalize());
      return;
    }

    if (controller.error != null) {
      coordinator._onSessionError(controller.error);
      coordinator._onSessionSuperseded(this);
      unawaited(finalize());
      return;
    }

    final player = controller.player;
    if (player != null && _tracker == null) {
      // Controller anuncia Player antes do await open: criar tracker desse player
      _tracker = trackerFactory(
        client: server.client,
        metadata: item,
        player: player,
        canReportPlayback: () {
          // canReportPlayback verifica epoch e frame/hasMedia
          return !_finalized && coordinator.playback.sourceEpoch == expectedEpoch &&
              coordinator.playback.hasMedia && _hasRenderedFrame;
        },
        hasRenderedPlayback: () => _hasRenderedFrame,
        playSessionId: sessionId,
        playMethod: initResult.playMethod,
        mediaInfo: initResult.mediaInfo,
        updateInterval: trackerInterval,
      );
    }

    // Guardar snapshots enquanto a época for desta sessão
    final state = controller.state;
    if (_hasRenderedFrame || controller.hasMedia || state.hasRenderedFrame) {
      _lastPositionSnapshot = state.position;
    }
    if (state.duration > Duration.zero) {
      _lastDurationSnapshot = state.duration;
    }

    if (_trackingStarted && state.completed && _endStop == null) {
      _tracker?.stopTracking();
      _endStop = _tracker?.sendStoppedProgressOnce(positionOverride: _lastPositionSnapshot);
    } else if (_endStop != null && !state.completed && state.isActive && !_resumingAfterEnd) {
      _resumingAfterEnd = true;
      unawaited(_resumeAfterEnd());
    }

    // Iniciar tracking apenas no primeiro frame
    if (!_trackingStarted && (state.hasRenderedFrame || controller.hasMedia)) {
      _hasRenderedFrame = true;
      _trackingStarted = true;
      _tracker?.startTracking(
        initialPosition: _lastPositionSnapshot > Duration.zero ? _lastPositionSnapshot : null,
        initialDuration: _lastDurationSnapshot > Duration.zero ? _lastDurationSnapshot : null,
      );
    }
  }

  Future<void> _resumeAfterEnd() async {
    try {
      await _endStop?.timeout(const Duration(seconds: 2));
    } on Object {
      // The terminal report is best-effort; playback must stay responsive.
    }
    _resumingAfterEnd = false;
    if (_finalized || coordinator.playback.sourceEpoch != expectedEpoch ||
        !coordinator.playback.state.isActive || coordinator.playback.state.completed) {
      return;
    }
    _endStop = null;
    _tracker?.resumeAfterStoppedReport();
    _tracker?.startTracking(initialPosition: _lastPositionSnapshot, initialDuration: _lastDurationSnapshot);
  }

  Future<void> finalize() {
    if (_finalizeFuture != null) return _finalizeFuture!;
    _finalized = true;
    coordinator.playback.removeListener(onPlaybackChanged);

    final future = _doFinalize();
    _finalizeFuture = future;
    return future;
  }

  Future<void> _doFinalize() async {
    final tracker = _tracker;
    if (tracker == null) return;

    tracker.stopTracking();

    // Finalizar com future memoizado passando snapshot gravado desta época
    final stopFuture = tracker.sendStoppedProgressOnce(
      positionOverride: _lastPositionSnapshot,
    );

    try {
      // Flush bounded de 2s sem travar UI
      await stopFuture.timeout(const Duration(seconds: 2));
    } catch (_) {}

    tracker.dispose();
  }
}
