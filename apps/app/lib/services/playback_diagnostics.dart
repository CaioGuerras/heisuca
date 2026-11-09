// Diagnóstico privado e limitado. Só consulta o player local; nunca recebe URLs de mídia.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../media/media_stream.dart';
import '../media/media_version.dart';
import '../mpv/mpv.dart';
import '../utils/app_logger.dart';
import '../utils/log_redaction_manager.dart';

/// Dois arquivos JSONL, com fila única e limitada. Falha de disco não falha o play.
class PlaybackDiagnosticStore {
  PlaybackDiagnosticStore({Future<Directory> Function()? directory, this.maxBytes = 512 * 1024})
    : _directory = directory ?? getApplicationSupportDirectory;

  static final instance = PlaybackDiagnosticStore();
  final Future<Directory> Function() _directory;
  final int maxBytes;
  Future<void> _tail = Future<void>.value();
  int _pending = 0;
  int droppedRecords = 0;
  int writeFailures = 0;

  static const _numbers = {
    'elapsedMs',
    'bitDepth',
    'width',
    'height',
    'outputWidth',
    'outputHeight',
    'renderedFrames',
    'frameDropCount',
    'decoderFrameDropCount',
    'cacheSeconds',
    'cacheBytes',
    'cacheSpeed',
    'bufferEndMs',
    'positionMs',
    'fps',
    'estimatedFps',
    'firstFrameMs',
    'openToFirstFrameMs',
    'bufferingTotalMs',
    'bufferingDurationMs',
    'fromMs',
    'toMs',
    'watchdogElapsedMs',
    'watchdogFrameDropCount',
    'watchdogFps',
    'watchdogTimePos',
    'watchdogExpectedFrames',
    'statsElapsedMs',
    'statsReadDurationMs',
  };
  static const _booleans = {'buffering', 'playing', 'hasRendered', 'statsAvailable', 'watchdogDisarmed'};
  static const _labels = {
    'abi',
    'event',
    'session',
    'engine',
    'engineSource',
    'codec',
    'profile',
    'hwdec',
    'renderedFramesAvailability',
    'phase',
    'decision',
    'jumpKind',
    'bufferingSource',
  };

  static String? _technicalLabel(Object? value) {
    if (value is! String) return null;
    if (value.contains('://') || RegExp(r'token|authorization|password|bearer', caseSensitive: false).hasMatch(value)) {
      return null;
    }
    final redacted = LogRedactionManager.redact(value);
    if (redacted != value || !RegExp(r'^[A-Za-z0-9 ._,()/+\-]*$').hasMatch(value)) return null;
    return value.length > 96 ? value.substring(0, 96) : value;
  }

  Future<File> get currentFile async {
    final directory = Directory('${(await _directory()).path}/logs');
    await directory.create(recursive: true);
    return File('${directory.path}/playback.jsonl');
  }

  Future<void> append(Map<String, Object?> fields) {
    if (_pending >= 64) {
      droppedRecords++;
      return Future<void>.value();
    }
    final record = <String, Object?>{
      'at': DateTime.now().toUtc().toIso8601String(),
      'droppedRecords': droppedRecords,
      'writeFailures': writeFailures,
    };
    // Lista positiva: nem um campo desconhecido nem mapas brutos chegam ao arquivo.
    for (final entry in fields.entries) {
      final value = entry.value;
      if (_numbers.contains(entry.key)) {
        record[entry.key] = value is num && value.isFinite ? value : null;
      } else if (_booleans.contains(entry.key)) {
        record[entry.key] = value is bool ? value : null;
      } else if (_labels.contains(entry.key)) {
        record[entry.key] = _technicalLabel(value);
      }
    }
    final line = '${jsonEncode(record)}\n';
    final bytes = utf8.encode(line).length;
    if (bytes > maxBytes) {
      droppedRecords++;
      return Future<void>.value();
    }
    _pending++;
    return _tail = _tail.then((_) async {
      try {
        final file = await currentFile;
        if (await file.exists() && await file.length() + bytes > maxBytes) {
          // A rotação substitui apenas os próprios slots; nunca remove outros arquivos.
          await file.copy('${file.parent.path}/playback.previous.jsonl');
          await file.writeAsString('');
        }
        await file.writeAsString(line, mode: FileMode.append);
      } catch (_) {
        writeFailures++;
        if (writeFailures == 1) appLogger.w('Não foi possível gravar o diagnóstico local de reprodução.');
      } finally {
        _pending--;
      }
    });
  }

  Future<void> flush() => _tail;
}

/// Uma tentativa, com relógio monotônico. Nenhuma ação de pause/play/seek é emitida.
class PlaybackDiagnostics {
  PlaybackDiagnostics({required this.player, PlaybackDiagnosticStore? store, Duration Function()? elapsed})
    : _store = store ?? PlaybackDiagnosticStore.instance {
    _clock.start();
    _elapsed = elapsed ?? () => _clock.elapsed;
    try {
      _engine = _engineName(player.playerType);
    } catch (_) {
      /* Um diagnóstico indisponível não impede a reprodução. */
    }
    unawaited(_record('start'));
  }

  final Player player;
  final PlaybackDiagnosticStore _store;
  final _clock = Stopwatch();
  late final Duration Function() _elapsed;
  static int _sequence = 0;
  final String _session = '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Timer? _timer;
  Future<void>? _samplePending;
  bool _closed = false;
  bool _loaded = false;
  bool _buffering = false;
  String _phase = 'preparing';
  String _engine = 'unknown';
  String _engineSource = 'configured';
  int? _openAt;
  int? _firstFrameAt;
  int? _bufferAt;
  int _bufferTotal = 0;
  int? _position;
  int _positionAt = 0;
  Map<String, Object?> _metadata = {};
  Map<String, Object?> _lastSample = {};
  int get _ms => _elapsed().inMilliseconds;

  static String _engineName(Object? value) => value == 'mpv' || value == 'exoplayer' ? '$value' : 'unknown';
  static num? _number(Object? value) {
    final parsed = value is num
        ? value
        : value is String
        ? num.tryParse(value)
        : null;
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  static int? _integer(Object? value) {
    final n = _number(value);
    return n != null && n >= 0 ? n.toInt() : null;
  }

  static num? _cacheBytes(Object? raw) {
    try {
      final state = raw is String ? jsonDecode(raw) : raw;
      return state is Map ? _number(state['fw-bytes']) : null;
    } catch (_) {
      return null;
    }
  }

  void setVersion(MediaVersion? version) {
    if (_closed) return;
    final streams = version?.parts.expand((part) => part.streams) ?? const <MediaStream>[];
    final video = streams.where((stream) => stream.kind == MediaStreamKind.video).firstOrNull;
    _metadata = {
      'codec': video?.codec ?? version?.videoCodec,
      'profile': video?.profile,
      'bitDepth': video?.bitDepth,
      'width': version?.width,
      'height': version?.height,
    };
    unawaited(_record('source'));
  }

  void opening() {
    if (_closed) return;
    _openAt ??= _ms;
    _phase = 'opening';
    if (_timer != null) {
      unawaited(_record('opening'));
      return;
    }
    try {
      final state = player.state;
      _onBuffering(state.buffering, source: 'snapshot');
      _subscriptions.add(player.streams.buffering.listen(_onBuffering));
      _subscriptions.add(player.streams.position.listen(_onPosition));
      _subscriptions.add(
        player.streams.playheadJump.listen((target) {
          unawaited(_record('jump', {'jumpKind': 'requested', 'fromMs': _position, 'toMs': target?.inMilliseconds}));
        }),
      );
    } catch (_) {
      unawaited(_record('statsUnavailable', {'statsAvailable': false}));
    }
    unawaited(_record('opening'));
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(sample()));
  }

  // Só o outcome qualificado pela fonte/geração chama estes dois métodos.
  void fileLoaded() {
    if (_closed) return;
    _loaded = true;
    _phase = 'loaded';
    unawaited(_record('loaded'));
    unawaited(sample());
  }

  void firstFrame() {
    if (_closed || _firstFrameAt != null) return;
    _firstFrameAt = _ms;
    _phase = 'rendered';
    unawaited(_record('firstFrame'));
  }

  void _onBuffering(bool value, {String source = 'event'}) {
    if (_closed || value == _buffering) return;
    final now = _ms;
    int? duration;
    if (value) {
      _bufferAt = now;
    } else if (_bufferAt != null) {
      duration = now - _bufferAt!;
      _bufferTotal += duration;
      _bufferAt = null;
    }
    _buffering = value;
    unawaited(_record('buffering', {'bufferingDurationMs': duration, 'bufferingSource': source}));
  }

  void _onPosition(Duration position) {
    if (_closed || !_loaded) return;
    final now = _ms;
    final current = position.inMilliseconds;
    final previous = _position;
    if (previous != null) {
      final state = player.state;
      final expectedAdvance = state.playing ? (now - _positionAt) * state.rate : 0;
      final delta = current - previous;
      final lower = expectedAdvance < 0 ? expectedAdvance : 0;
      final upper = expectedAdvance > 0 ? expectedAdvance : 0;
      // Falta de avanço é stall, não salto. Apenas observa; nunca corrige o playhead.
      if (delta < lower - 1500 || delta > upper + 1500) {
        unawaited(_record('jump', {'jumpKind': 'observed', 'fromMs': previous, 'toMs': current}));
      }
    }
    _position = current;
    _positionAt = now;
  }

  Future<void> sample() {
    if (_closed) return Future<void>.value();
    return _samplePending ??= _collect().whenComplete(() => _samplePending = null);
  }

  Future<void> _collect() async {
    if (!_loaded) {
      await _record('sample', {'statsAvailable': false});
      return;
    }
    final readAt = _ms;
    try {
      final stats = await player.getStats();
      if (_closed) return;
      final runtime = await player.runtimePlayerType();
      if (_closed) return;
      _engine = _engineName(stats['playerType'] ?? runtime);
      _engineSource = 'runtime';
      final state = player.state;
      _onBuffering(state.buffering, source: 'snapshot');
      final rendered = _integer(stats['videoRenderedFrames']);
      _lastSample = {
        'statsAvailable': stats.isNotEmpty,
        'statsElapsedMs': readAt, 'statsReadDurationMs': _ms - readAt,
        'codec': _metadata['codec'] ?? stats['video-codec'] ?? stats['videoCodec'],
        'outputWidth': _integer(stats['video-params/w'] ?? stats['videoWidth']),
        'outputHeight': _integer(stats['video-params/h'] ?? stats['videoHeight']),
        'hwdec': stats['hwdec-current'] ?? stats['videoDecoderName'],
        'renderedFrames': rendered,
        // mpv não reporta esse contador. Posição × FPS NÃO é contagem real.
        // https://mpv.io/manual/stable/#property-list (estimated-frame-number).
        'renderedFramesAvailability': rendered == null ? 'notReported' : 'reported',
        'frameDropCount': _integer(stats['videoDroppedFrames'] ?? stats['frame-drop-count']),
        'decoderFrameDropCount': _integer(stats['decoder-frame-drop-count']),
        'cacheSeconds':
            _number(stats['demuxer-cache-duration']) ??
            (_number(stats['totalBufferedDurationMs']) == null
                ? null
                : _number(stats['totalBufferedDurationMs'])! / 1000),
        'cacheBytes': _cacheBytes(stats['demuxer-cache-state']),
        'cacheSpeed': _number(stats['cache-speed']),
        'bufferEndMs': state.buffer.inMilliseconds, 'positionMs': state.position.inMilliseconds,
        'fps': _number(stats['container-fps'] ?? stats['videoFps']),
        'estimatedFps': _number(stats['estimated-vf-fps']),
        'playing': state.playing, 'hasRendered': state.hasRenderedFrame,
      };
      await _record('sample');
    } catch (_) {
      if (!_closed) await _record('statsUnavailable', {'statsAvailable': false});
    }
  }

  Future<void> watchdog({required String decision, Map<String, Object?> inputs = const {}}) =>
      _record('watchdog', {'decision': decision, ...inputs});

  Future<void> _record(String event, [Map<String, Object?> fields = const {}]) {
    if (_closed) return Future<void>.value();
    final now = _ms;
    return _store.append({
      ..._metadata,
      ..._lastSample,
      'engine': _engine,
      'engineSource': _engineSource,
      'phase': _phase,
      'buffering': _buffering,
      'elapsedMs': now,
      'firstFrameMs': _firstFrameAt,
      'openToFirstFrameMs': _firstFrameAt != null && _openAt != null ? _firstFrameAt! - _openAt! : null,
      'bufferingTotalMs': _bufferTotal + (_bufferAt == null ? 0 : now - _bufferAt!),
      ...fields,
      'event': event,
      'session': _session,
    });
  }

  Future<void> close() async {
    if (_closed) return;
    final end = _record('end', {'bufferingDurationMs': _bufferAt == null ? null : _ms - _bufferAt!});
    _closed = true;
    _clock.stop();
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      try {
        await subscription.cancel();
      } catch (_) {
        /* Limpeza sem efeito na reprodução. */
      }
    }
    await end;
  }
}
