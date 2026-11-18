import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../mpv/models.dart';
import '../mpv/player/player.dart';
import '../mpv/player/player_state.dart';
import '../mpv/player/player_streams.dart';

class _ResolvedMediaSource {
  const _ResolvedMediaSource({
    required this.uri,
    required this.title,
    required this.isLocal,
  });

  final String uri;
  final String? title;
  final bool isLocal;
}

class _SourceResolution {
  const _SourceResolution.valid(this.source) : errorMessage = null;
  const _SourceResolution.invalid(this.errorMessage) : source = null;

  final _ResolvedMediaSource? source;
  final String? errorMessage;
}

/// Controlador de reprodução desktop desacoplado de servidor/login/banco.
class DesktopPlaybackController extends ChangeNotifier {
  DesktopPlaybackController({
    Player Function()? playerFactory,
    Duration openTimeout = const Duration(seconds: 25),
  })  : _playerFactory = playerFactory ?? _defaultPlayerFactory,
        _openTimeout = openTimeout.isNegative ? Duration.zero : openTimeout;

  static const String _msgInvalidSource = 'Origem de mídia inválida ou não suportada.';
  static const String _msgCredentialsNotAllowed = 'Endereços com credenciais não são permitidos.';
  static const String _msgUnsupportedScheme = 'Esquema ou origem de mídia não suportado.';
  static const String _msgInitFailed = 'Não foi possível iniciar o reprodutor de vídeo.';
  static const String _msgOpenFailed = 'Não foi possível abrir a mídia.';
  static const String _msgLoadFailed = 'Não foi possível carregar ou reproduzir a mídia.';
  static const String _msgTimeout = 'Tempo esgotado ao aguardar o primeiro quadro da mídia.';
  static const String _msgHttp403 = 'Acesso negado ao carregar a mídia (erro 403).';
  static const String _msgHttp404 = 'Mídia não encontrada (erro 404).';
  static const String _msgHttp500 = 'Erro interno do servidor ao reproduzir a mídia (erro 500).';
  static const String _msgHttp503 = 'Servidor temporariamente indisponível (erro 503).';
  static const String _msgStreamInitFailed = 'Não foi possível inicializar as faixas de áudio ou vídeo.';
  static const String _msgAudioOutputFailed = 'Falha no dispositivo de saída de áudio.';
  static const String _msgInvalidSubtitle = 'Caminho de legenda inválido ou não suportado.';
  static const String _msgSubtitleLoadFailed = 'Não foi possível carregar a legenda.';
  static const String _msgPlaybackControlFailed = 'Não foi possível executar o comando de reprodução.';

  static final RegExp _controlCharsPattern = RegExp(r'[\x00-\x1F\x7F]');
  static final RegExp _windowsDrivePathPattern = RegExp(r'^[A-Za-z]:[\\/]');
  static final RegExp _windowsUncPathPattern = RegExp(r'^\\\\[^\\/]+[\\/][^\\/]+[\\/]');
  static final RegExp _windowsExtendedDrivePattern = RegExp(r'^\\\\\?\\[A-Za-z]:\\');
  static final RegExp _windowsExtendedUncPattern = RegExp(r'^\\\\\?\\[Uu][Nn][Cc]\\([^\\/]+)\\([^\\/]+)\\(.+)$');
  static final RegExp _fileUriDrivePrefixPattern = RegExp(r'^/[A-Za-z]:(?:/|$)');

  final Player Function() _playerFactory;
  final Duration _openTimeout;

  final List<StreamSubscription<Object?>> _subscriptions = <StreamSubscription<Object?>>[];
  Future<void> _serialQueue = Future<void>.value();
  Timer? _watchdogTimer;
  Completer<void>? _activeOpenCallCompleter;

  Player? _player;
  PlayerState _state = const PlayerState();
  String? _title;
  String? _error;
  bool _opening = false;
  bool _hasMedia = false;
  bool _disposed = false;

  int _openGeneration = 0;
  int? _lastHttpStatus;
  int? _activeSourceId;
  bool _canConfirmFromState = false;

  static Player _defaultPlayerFactory() => Player();

  Player? get player => _player;

  PlayerState get state => _state;

  String? get title => _title;

  String? get error => _error;

  bool get opening => _opening;

  bool get hasMedia => _hasMedia;

  @visibleForTesting
  static String? normalizeSourceForTest(String source, {bool? isWindows}) {
    return _resolveMediaSource(source, isWindows: isWindows).source?.uri;
  }

  Future<void> open(String source) async {
    if (_disposed) return;

    _retirePlayer();
    final resolution = _resolveMediaSource(source);
    final resolved = resolution.source;
    if (resolved == null) {
      ++_openGeneration;
      _cancelWatchdog();
      _cancelSubscriptions();
      _opening = false;
      _hasMedia = false;
      _title = null;
      _state = const PlayerState();
      _error = resolution.errorMessage ?? _msgInvalidSource;
      _lastHttpStatus = null;
      _activeSourceId = null;
      _canConfirmFromState = false;
      notifyListeners();

      return;
    }

    final attemptGen = ++_openGeneration;
    _cancelWatchdog();
    _cancelSubscriptions();
    _opening = true;
    _hasMedia = false;
    _title = resolved.title;
    _error = null;
    _state = const PlayerState();
    _lastHttpStatus = null;
    _activeSourceId = null;
    _canConfirmFromState = false;
    notifyListeners();

    await _enqueue(() async {
      if (_disposed || _openGeneration != attemptGen) return;

      final targetPlayer = _ensurePlayer(attemptGen);
      if (targetPlayer == null || _disposed || _openGeneration != attemptGen) {
        return;
      }

      _attachStreams(targetPlayer, attemptGen);
      // Video must mount and send its native rectangle while open is pending,
      // rather than waiting for a frame that may itself require that surface.
      notifyListeners();
      final beforeState = targetPlayer.state;
      _canConfirmFromState = !beforeState.hasRenderedFrame;
      _startWatchdog(attemptGen);

      await _performPlayerOpen(targetPlayer, Media(resolved.uri), attemptGen);
      if (_disposed || _openGeneration != attemptGen) return;

      final afterState = targetPlayer.state;
      final changed = _applyStateDiff(beforeState, afterState);
      if (_opening && _error == null && _canConfirmFromState && afterState.hasRenderedFrame) {
        _confirmFrame(attemptGen);
        return;
      }
      if (changed) {
        notifyListeners();
      }
    });
  }

  Future<void> close() async {
    if (_disposed) return;
    _retirePlayer();
    ++_openGeneration;
    _cancelWatchdog();
    _cancelSubscriptions();

    final hadChanges = _opening ||
        _hasMedia ||
        _title != null ||
        _error != null ||
        !identical(_state, const PlayerState());
    _opening = false;
    _hasMedia = false;
    _title = null;
    _error = null;
    _state = const PlayerState();
    _lastHttpStatus = null;
    _activeSourceId = null;
    _canConfirmFromState = false;
    if (hadChanges) {
      notifyListeners();
    }

  }

  Future<void> togglePause() => _runPlaybackAction((activePlayer) => activePlayer.playOrPause());

  Future<void> seek(Duration position) {
    final target = position.isNegative ? Duration.zero : position;
    return _runPlaybackAction((activePlayer) => activePlayer.seek(target));
  }

  Future<void> setVolume(double volume) async {
    if (_disposed || !_hasMedia || volume.isNaN || volume.isInfinite) return;
    final clamped = volume.clamp(0.0, 100.0).toDouble();
    await _runPlaybackAction((activePlayer) => activePlayer.setVolume(clamped));
  }

  Future<void> selectAudio(AudioTrack track) {
    return _runPlaybackAction((activePlayer) => activePlayer.selectAudioTrack(track));
  }

  Future<void> selectSubtitle(SubtitleTrack track) {
    return _runPlaybackAction((activePlayer) => activePlayer.selectSubtitleTrack(track));
  }

  Future<void> addSubtitle(String path) async {
    if (_disposed || !_hasMedia) return;
    final activePlayer = _player;
    if (activePlayer == null || activePlayer.disposed) return;

    final resolved = _resolveMediaSource(path).source;
    if (resolved == null || !resolved.isLocal) {
      _error = _msgInvalidSubtitle;
      notifyListeners();
      return;
    }

    final track = SubtitleTrack.uri(resolved.uri, title: resolved.title);
    await _runPlaybackAction(
      (targetPlayer) => targetPlayer.selectSubtitleTrack(track),
      errorMessage: _msgSubtitleLoadFailed,
      clearErrorOnSuccess: true,
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_openGeneration;
    _cancelWatchdog();
    _cancelSubscriptions();
    _completeActiveOpenCall();

    final playerToDispose = _player;
    _player = null;
    _opening = false;
    _hasMedia = false;
    _title = null;
    _error = null;
    _state = const PlayerState();
    _lastHttpStatus = null;
    _activeSourceId = null;
    _canConfirmFromState = false;

    if (playerToDispose != null && !playerToDispose.disposed) {
      unawaited(_disposePlayerSafely(playerToDispose));
    }
    super.dispose();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _serialQueue.then<void>((_) => action());
    _serialQueue = next.catchError((Object _) {});
    return next;
  }

  Player? _ensurePlayer(int attemptGen) {
    final existing = _player;
    if (existing != null && !existing.disposed) {
      return existing;
    }
    final Player created;
    try {
      created = _playerFactory();
    } on Object catch (_) {
      _failAttempt(attemptGen, _msgInitFailed);
      return null;
    }
    if (created.disposed) {
      _failAttempt(attemptGen, _msgInitFailed);
      return null;
    }
    _player = created;
    return created;
  }

  Future<void> _performPlayerOpen(Player targetPlayer, Media media, int attemptGen) async {
    final callCompleter = Completer<void>();
    _activeOpenCallCompleter = callCompleter;

    late final Future<void> openFuture;
    try {
      openFuture = targetPlayer.open(media);
    } on Object catch (err) {
      if (identical(_activeOpenCallCompleter, callCompleter)) {
        _activeOpenCallCompleter = null;
      }
      if (!callCompleter.isCompleted) {
        callCompleter.complete();
      }
      _handleOpenException(err, attemptGen);
      return;
    }

    unawaited(openFuture.then<void>(
      (_) {
        if (!callCompleter.isCompleted) {
          callCompleter.complete();
        }
      },
      onError: (Object err, StackTrace _) {
        if (!callCompleter.isCompleted) {
          callCompleter.completeError(err);
        }
      },
    ));

    try {
      await callCompleter.future;
    } on Object catch (err) {
      if (identical(_activeOpenCallCompleter, callCompleter)) {
        _activeOpenCallCompleter = null;
      }
      _handleOpenException(err, attemptGen);
      return;
    }

    if (identical(_activeOpenCallCompleter, callCompleter)) {
      _activeOpenCallCompleter = null;
    }
  }

  void _handleOpenException(Object err, int attemptGen) {
    if (_disposed || _openGeneration != attemptGen) return;
    if (err is PlayerInitializationException) {
      _failAttempt(attemptGen, _msgInitFailed);
    } else {
      _failAttempt(attemptGen, _msgOpenFailed);
    }
  }

  void _startWatchdog(int attemptGen) {
    _cancelWatchdog();
    _watchdogTimer = Timer(_openTimeout, () {
      if (_disposed || _openGeneration != attemptGen || !_opening) return;
      final message = _lastHttpStatus == 503 ? _msgHttp503 : _msgTimeout;
      _failAttempt(attemptGen, message);
    });
  }

  void _cancelWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  // Each media source owns one Player lifetime. Reusing an EventChannel
  // listener cannot distinguish queued events from the outgoing source.
  // PlayerBase serializes native ownership/disposal across these instances.
  void _retirePlayer() {
    _cancelSubscriptions();
    _completeActiveOpenCall();
    final retired = _player;
    _player = null;
    if (retired != null && !retired.disposed) {
      unawaited(_disposePlayerSafely(retired));
    }
  }

  void _completeActiveOpenCall() {
    final completer = _activeOpenCallCompleter;
    _activeOpenCallCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _confirmFrame(int attemptGen) {
    if (_disposed || _openGeneration != attemptGen || !_opening || _error != null) {
      return;
    }
    _cancelWatchdog();
    _opening = false;
    _hasMedia = true;
    _state = _state.copyWith(hasRenderedFrame: true);
    notifyListeners();
  }

  void _failAttempt(int attemptGen, String safeMessage) {
    if (_disposed || _openGeneration != attemptGen) return;

    _retirePlayer();
    _cancelWatchdog();
    _cancelSubscriptions();
    _completeActiveOpenCall();

    ++_openGeneration;
    _opening = false;
    _hasMedia = false;
    _title = null;
    _state = const PlayerState();
    _error = safeMessage;
    _lastHttpStatus = null;
    _activeSourceId = null;
    _canConfirmFromState = false;

    notifyListeners();
  }

  void _attachStreams(Player targetPlayer, int attemptGen) {
    _cancelSubscriptions();
    final streams = targetPlayer.streams;

    bool isActiveSession() =>
        !_disposed && _openGeneration == attemptGen && (_opening || _hasMedia);

    void onStreamError(Object _) {}

    void updateState(PlayerState Function(PlayerState current) transform) {
      if (!isActiveSession()) return;
      _state = transform(_state);
      if (_opening && _error == null && _canConfirmFromState && targetPlayer.state.hasRenderedFrame) {
        _confirmFrame(attemptGen);
        return;
      }
      notifyListeners();
    }

    _subscriptions.addAll(<StreamSubscription<Object?>>[
      streams.playing.listen((value) => updateState((s) => s.copyWith(playing: value)), onError: onStreamError),
      streams.completed.listen((value) => updateState((s) => s.copyWith(completed: value)), onError: onStreamError),
      streams.buffering.listen((value) => updateState((s) => s.copyWith(buffering: value)), onError: onStreamError),
      streams.position.listen((value) => updateState((s) => s.copyWith(position: value)), onError: onStreamError),
      streams.duration.listen((value) => updateState((s) => s.copyWith(duration: value)), onError: onStreamError),
      streams.seekable.listen((value) => updateState((s) => s.copyWith(seekable: value)), onError: onStreamError),
      streams.buffer.listen((value) => updateState((s) => s.copyWith(buffer: value)), onError: onStreamError),
      streams.volume.listen((value) => updateState((s) => s.copyWith(volume: value)), onError: onStreamError),
      streams.rate.listen((value) => updateState((s) => s.copyWith(rate: value)), onError: onStreamError),
      streams.tracks.listen((value) => updateState((s) => s.copyWith(tracks: value)), onError: onStreamError),
      streams.track.listen((value) => updateState((s) => s.copyWith(track: value)), onError: onStreamError),
      streams.audioDevice.listen((value) => updateState((s) => s.copyWith(audioDevice: value)), onError: onStreamError),
      streams.audioDevices.listen((value) => updateState((s) => s.copyWith(audioDevices: value)), onError: onStreamError),
      streams.bufferRanges.listen((value) => updateState((s) => s.copyWith(bufferRanges: value)), onError: onStreamError),
      streams.fileStarted.listen((_) {
        if (!isActiveSession()) return;
        _canConfirmFromState = true;
        if (_opening && _state.hasRenderedFrame) {
          _state = _state.copyWith(hasRenderedFrame: false);
          notifyListeners();
        }
      }, onError: onStreamError),
      streams.sourceStarted.listen((PlayerSourceStarted event) {
        if (!isActiveSession()) return;
        _activeSourceId = event.sourceId;
      }, onError: onStreamError),
      streams.playbackRestart.listen((_) {
        if (!isActiveSession()) return;
        if (_opening && _canConfirmFromState) {
          _confirmFrame(attemptGen);
        } else if (_hasMedia && !_state.hasRenderedFrame) {
          _state = _state.copyWith(hasRenderedFrame: true);
          notifyListeners();
        }
      }, onError: onStreamError),
      streams.fileLoadFailed.listen((_) {
        if (!isActiveSession()) return;
        _failAttempt(attemptGen, _messageForHttpStatus(_lastHttpStatus));
      }, onError: onStreamError),
      streams.sourceFailed.listen((PlayerSourceFailed event) {
        if (!isActiveSession()) return;
        if (_activeSourceId != null && event.sourceId != _activeSourceId) return;
        _failAttempt(attemptGen, _messageForHttpStatus(_lastHttpStatus));
      }, onError: onStreamError),
      streams.log.listen((PlayerLog logEntry) {
        if (!isActiveSession()) return;
        if (logEntry.level != PlayerLogLevel.warn &&
            logEntry.level != PlayerLogLevel.error &&
            logEntry.level != PlayerLogLevel.fatal) {
          return;
        }
        final status = PlayerError.httpStatusFromLog(logEntry.text);
        if (status != null && (fatalPlaybackHttpStatuses.contains(status) || status == 503)) {
          _lastHttpStatus = status;
        }
      }, onError: onStreamError),
      streams.error.listen((PlayerError playerError) {
        if (!isActiveSession()) return;
        final fatalMessage = _fatalErrorMessageForCause(playerError.cause);
        if (fatalMessage == null) {
          // Erros genéricos de plataforma/propriedade permanecem separados de falha de abertura.
          return;
        }
        _failAttempt(attemptGen, fatalMessage);
      }, onError: onStreamError),
    ]);
  }

  void _cancelSubscriptions() {
    if (_subscriptions.isEmpty) return;
    final active = List<StreamSubscription<Object?>>.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in active) {
      try {
        unawaited(subscription.cancel().then<void>((_) {}, onError: (Object _) {}));
      } on Object catch (_) {
        // Ignora erro síncrono durante cancelamento de inscrição.
      }
    }
  }

  Future<void> _runPlaybackAction(
    Future<void> Function(Player activePlayer) action, {
    String errorMessage = _msgPlaybackControlFailed,
    bool clearErrorOnSuccess = false,
  }) async {
    if (_disposed || !_hasMedia) return;
    final activePlayer = _player;
    if (activePlayer == null || activePlayer.disposed) return;

    final actionGen = _openGeneration;
    final before = activePlayer.state;
    try {
      await action(activePlayer);
    } on Object catch (_) {
      if (_disposed || _openGeneration != actionGen || !_hasMedia) return;
      _error = errorMessage;
      notifyListeners();
      return;
    }

    if (_disposed || _openGeneration != actionGen || !_hasMedia) return;
    var changed = _applyStateDiff(before, activePlayer.state);
    if (clearErrorOnSuccess && _error != null) {
      _error = null;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  bool _applyStateDiff(PlayerState before, PlayerState after) {
    var next = _state;
    if (after.playing != before.playing) next = next.copyWith(playing: after.playing);
    if (after.completed != before.completed) next = next.copyWith(completed: after.completed);
    if (after.buffering != before.buffering) next = next.copyWith(buffering: after.buffering);
    if (after.position != before.position) next = next.copyWith(position: after.position);
    if (after.duration != before.duration) next = next.copyWith(duration: after.duration);
    if (after.seekable != before.seekable) next = next.copyWith(seekable: after.seekable);
    if (after.buffer != before.buffer) next = next.copyWith(buffer: after.buffer);
    if (after.volume != before.volume) next = next.copyWith(volume: after.volume);
    if (after.rate != before.rate) next = next.copyWith(rate: after.rate);
    if (after.tracks != before.tracks) next = next.copyWith(tracks: after.tracks);
    if (after.track != before.track) next = next.copyWith(track: after.track);
    if (after.audioDevice != before.audioDevice) next = next.copyWith(audioDevice: after.audioDevice);
    if (after.audioDevices != before.audioDevices) next = next.copyWith(audioDevices: after.audioDevices);
    if (after.bufferRanges != before.bufferRanges) next = next.copyWith(bufferRanges: after.bufferRanges);
    if (identical(next, _state)) return false;
    _state = next;
    return true;
  }

  Future<void> _disposePlayerSafely(Player targetPlayer) async {
    try {
      await targetPlayer.dispose();
    } on Object catch (_) {
      // Captura falha assíncrona de dispose para não vazar erro não tratado.
    }
  }

  static String? _fatalErrorMessageForCause(String? cause) {
    return switch (cause) {
      PlayerError.playerInitFailed => _msgInitFailed,
      PlayerError.serverHttp404 => _msgHttp404,
      PlayerError.serverHttp500 => _msgHttp500,
      PlayerError.serverHttp503 => _msgHttp503,
      PlayerError.openTimedOut => _msgTimeout,
      PlayerError.streamInitFailed => _msgStreamInitFailed,
      PlayerError.audioOutputFailed => _msgAudioOutputFailed,
      _ => null,
    };
  }

  static String _messageForHttpStatus(int? status) {
    return switch (status) {
      403 => _msgHttp403,
      404 => _msgHttp404,
      500 => _msgHttp500,
      503 => _msgHttp503,
      _ => _msgLoadFailed,
    };
  }

  static _SourceResolution _resolveMediaSource(String raw, {bool? isWindows}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || _controlCharsPattern.hasMatch(trimmed)) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }

    if (_windowsDrivePathPattern.hasMatch(trimmed)) {
      return _normalizeLiteralWindowsPath(trimmed);
    }

    if (trimmed.startsWith(r'\\')) {
      return _normalizeLiteralWindowsUncPath(trimmed);
    }

    if (trimmed.startsWith('/') && !trimmed.startsWith('//')) {
      return _normalizeLiteralUnixPath(trimmed);
    }

    if (trimmed.startsWith('//')) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }

    // Uri normalizes an empty user-info (https://@host) away. Reject it
    // before parsing so the credential-free URL contract also covers that case.
    final authority = RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*://([^/?#]*)').firstMatch(trimmed)?.group(1);
    if (authority?.contains('@') ?? false) {
      return const _SourceResolution.invalid(_msgCredentialsNotAllowed);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      if (uri.userInfo.isNotEmpty || uri.authority.contains('@')) {
        return const _SourceResolution.invalid(_msgCredentialsNotAllowed);
      }
      if (!uri.hasAuthority || uri.host.isEmpty || trimmed.contains('\\')) {
        return const _SourceResolution.invalid(_msgInvalidSource);
      }
      return _SourceResolution.valid(
        _ResolvedMediaSource(uri: uri.toString(), title: _safeUrlTitle(uri), isLocal: false),
      );
    }

    if (scheme == 'file') {
      return _normalizeFileUri(uri, rawTrimmed: trimmed, isWindows: isWindows);
    }

    return const _SourceResolution.invalid(_msgUnsupportedScheme);
  }

  static _SourceResolution _normalizeLiteralWindowsPath(String rawPath) {
    if (_hasTrailingDirectorySuffix(rawPath)) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }
    final normalized = p.windows.normalize(rawPath);
    if (_controlCharsPattern.hasMatch(normalized) ||
        !p.windows.isAbsolute(normalized) ||
        normalized == p.windows.rootPrefix(normalized)) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }
    return _SourceResolution.valid(
      _ResolvedMediaSource(uri: normalized, title: _safeBasename(normalized, isWindows: true), isLocal: true),
    );
  }

  static _SourceResolution _normalizeLiteralWindowsUncPath(String rawPath) {
    if (rawPath == r'\\.' || rawPath.startsWith(r'\\.\') || _hasTrailingDirectorySuffix(rawPath)) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }
    if (rawPath.startsWith(r'\\?\')) {
      if (_windowsExtendedDrivePattern.hasMatch(rawPath)) {
        final normalized = p.windows.normalize(rawPath);
        if (!_windowsExtendedDrivePattern.hasMatch(normalized) ||
            normalized == p.windows.rootPrefix(normalized)) {
          return const _SourceResolution.invalid(_msgInvalidSource);
        }
        return _SourceResolution.valid(
          _ResolvedMediaSource(uri: normalized, title: _safeBasename(normalized, isWindows: true), isLocal: true),
        );
      }
      if (_windowsExtendedUncPattern.hasMatch(rawPath)) {
        final normalized = p.windows.normalize(rawPath);
        if (!_windowsExtendedUncPattern.hasMatch(normalized)) {
          return const _SourceResolution.invalid(_msgInvalidSource);
        }
        return _SourceResolution.valid(
          _ResolvedMediaSource(uri: normalized, title: _safeBasename(normalized, isWindows: true), isLocal: true),
        );
      }
      return const _SourceResolution.invalid(_msgInvalidSource);
    }

    if (!_windowsUncPathPattern.hasMatch(rawPath)) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }
    final normalized = p.windows.normalize(rawPath);
    if (!p.windows.isAbsolute(normalized) || normalized == p.windows.rootPrefix(normalized)) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }
    return _SourceResolution.valid(
      _ResolvedMediaSource(uri: normalized, title: _safeBasename(normalized, isWindows: true), isLocal: true),
    );
  }

  static _SourceResolution _normalizeLiteralUnixPath(String rawPath) {
    if (rawPath.endsWith('/') || rawPath.endsWith('/.')) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }
    final normalized = p.posix.normalize(rawPath);
    if (_controlCharsPattern.hasMatch(normalized) || !p.posix.isAbsolute(normalized) || normalized == '/') {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }
    return _SourceResolution.valid(
      _ResolvedMediaSource(uri: normalized, title: _safeBasename(normalized, isWindows: false), isLocal: true),
    );
  }

  static _SourceResolution _normalizeFileUri(Uri uri, {required String rawTrimmed, bool? isWindows}) {
    if (uri.userInfo.isNotEmpty || uri.authority.contains('@')) {
      return const _SourceResolution.invalid(_msgCredentialsNotAllowed);
    }
    if (uri.hasQuery || uri.hasFragment || rawTrimmed.contains('\\')) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }

    final hostLower = uri.host.toLowerCase();
    final isLocalHost = uri.host.isEmpty || hostLower == 'localhost';

    if (_fileUriDrivePrefixPattern.hasMatch(uri.path)) {
      if (!isLocalHost) {
        return const _SourceResolution.invalid(_msgInvalidSource);
      }
      final cleanUri = uri.host.isEmpty ? uri : Uri.parse('file://${uri.path}');
      final String extracted;
      try {
        extracted = p.windows.fromUri(cleanUri);
      } on Object catch (_) {
        return const _SourceResolution.invalid(_msgInvalidSource);
      }
      if (_controlCharsPattern.hasMatch(extracted) || _hasTrailingDirectorySuffix(extracted)) {
        return const _SourceResolution.invalid(_msgInvalidSource);
      }
      return _normalizeLiteralWindowsPath(extracted);
    }

    if (!isLocalHost) {
      final useWindows = isWindows ?? Platform.isWindows;
      if (!useWindows || uri.host == '.' || uri.host == '?') {
        return const _SourceResolution.invalid(_msgInvalidSource);
      }
      if (uri.pathSegments.where((segment) => segment.isNotEmpty).length < 2) {
        return const _SourceResolution.invalid(_msgInvalidSource);
      }
      final String extracted;
      try {
        extracted = p.windows.fromUri(uri);
      } on Object catch (_) {
        return const _SourceResolution.invalid(_msgInvalidSource);
      }
      if (_controlCharsPattern.hasMatch(extracted) || _hasTrailingDirectorySuffix(extracted)) {
        return const _SourceResolution.invalid(_msgInvalidSource);
      }
      return _normalizeLiteralWindowsUncPath(extracted);
    }

    final cleanUri = uri.host.isEmpty ? uri : Uri.parse('file://${uri.path}');
    final String extracted;
    try {
      extracted = p.posix.fromUri(cleanUri);
    } on Object catch (_) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }
    if (_controlCharsPattern.hasMatch(extracted)) {
      return const _SourceResolution.invalid(_msgInvalidSource);
    }
    return _normalizeLiteralUnixPath(extracted);
  }

  static bool _hasTrailingDirectorySuffix(String path) {
    return path.endsWith('\\') || path.endsWith('/') || path.endsWith('\\.') || path.endsWith('/.');
  }

  static String? _safeBasename(String normalizedPath, {required bool isWindows}) {
    final base = isWindows ? p.windows.basename(normalizedPath) : p.posix.basename(normalizedPath);
    return base.isEmpty ? null : base;
  }

  static String? _safeUrlTitle(Uri uri) {
    for (var i = uri.pathSegments.length - 1; i >= 0; i--) {
      final segment = uri.pathSegments[i].trim();
      if (segment.isNotEmpty) return segment;
    }
    return null;
  }
}
