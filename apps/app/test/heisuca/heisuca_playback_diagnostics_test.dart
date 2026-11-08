import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/media/media_version.dart';
import 'package:heisuca/media/media_part.dart';
import 'package:heisuca/media/media_stream.dart';
import 'package:heisuca/mpv/mpv.dart';
import 'package:heisuca/mpv/player/player_stream_controllers.dart';
import 'package:heisuca/services/playback_diagnostics.dart';

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Diagnóstico não pode abrir rede');
  }
}

class _Player with PlayerStreamControllersMixin implements Player {
  @override
  late final PlayerStreams streams = createStreams();
  @override
  PlayerState state = const PlayerState(playing: true);
  @override
  String get playerType => engine;
  String engine = 'exoplayer';
  Map<String, dynamic> stats = {
    'playerType': 'exoplayer',
    'videoRenderedFrames': 240,
    'videoDroppedFrames': 2,
    'videoDecoderName': 'c2.mtk.avc.decoder',
    'totalBufferedDurationMs': 3500,
    'url': 'https://privado.invalid/filme?token=nao-gravar',
  };
  Future<Map<String, dynamic>>? delayedStats;
  int statsReads = 0;
  int runtimeReads = 0;
  @override
  Future<Map<String, dynamic>> getStats() async {
    statsReads++;
    return await (delayedStats ?? Future.value(stats));
  }

  @override
  Future<String> runtimePlayerType() async {
    runtimeReads++;
    return engine;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _version = MediaVersion(
  id: 'v',
  width: 1440,
  height: 1080,
  videoCodec: 'h264',
  parts: [
    MediaPart(
      id: 'p',
      file: 'https://privado.invalid/?token=nao-gravar',
      streams: [MediaStream(id: 'video', kind: MediaStreamKind.video, codec: 'h264', profile: 'High', bitDepth: 8)],
    ),
  ],
);
void main() {
  late Directory directory;
  late PlaybackDiagnosticStore store;
  setUp(() async {
    // Somente dados sintéticos; os diretórios são preservados como evidência local.
    directory = await Directory.systemTemp.createTemp('heisuca-playback-diagnostics-test-');
    store = PlaybackDiagnosticStore(directory: () async => directory, maxBytes: 65536);
  });
  Future<List<Map<String, dynamic>>> records() async {
    await store.flush();
    return (await (await store.currentFile).readAsLines())
        .where((line) => line.isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  test('registro por reprodução: campos, primeiro quadro, buffering, salto e vigia; sem rede', () async {
    final guard = _NoNetwork();
    final previous = HttpOverrides.current;
    HttpOverrides.global = guard;
    final player = _Player();
    var elapsed = Duration.zero;
    final diagnostic = PlaybackDiagnostics(player: player, store: store, elapsed: () => elapsed);
    try {
      diagnostic.setVersion(_version);
      diagnostic.opening();
      diagnostic.fileLoaded();
      await diagnostic.sample();
      elapsed = const Duration(milliseconds: 800);
      diagnostic.firstFrame();
      elapsed = const Duration(milliseconds: 900);
      diagnostic.firstFrame();
      player.bufferingController.add(true);
      await Future<void>.delayed(Duration.zero);
      elapsed = const Duration(milliseconds: 2900);
      player.bufferingController.add(false);
      await Future<void>.delayed(Duration.zero);
      elapsed = const Duration(seconds: 3);
      player.positionController.add(const Duration(seconds: 3));
      await Future<void>.delayed(Duration.zero);
      player.playheadJumpController.add(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);
      elapsed = const Duration(milliseconds: 3100);
      player.positionController.add(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);
      await diagnostic.watchdog(
        decision: 'slowDeliveryOrDevice',
        inputs: {
          'watchdogElapsedMs': 8000,
          'hasRendered': false,
          'playing': true,
          'buffering': false,
          'watchdogFrameDropCount': 2,
          'watchdogFps': 29.97,
          'watchdogTimePos': 0.0,
          'watchdogExpectedFrames': 0,
        },
      );
      final rows = await records();
      final sample = rows.lastWhere((r) => r['event'] == 'sample');
      expect(sample, containsPair('engine', 'exoplayer'));
      expect(sample, containsPair('codec', 'h264'));
      expect(sample, containsPair('profile', 'High'));
      expect(sample, containsPair('bitDepth', 8));
      expect(sample, containsPair('width', 1440));
      expect(sample, containsPair('height', 1080));
      expect(sample, containsPair('hwdec', 'c2.mtk.avc.decoder'));
      expect(sample, containsPair('renderedFrames', 240));
      expect(sample, containsPair('frameDropCount', 2));
      expect(sample, containsPair('cacheSeconds', 3.5));
      expect(rows.singleWhere((r) => r['event'] == 'firstFrame')['firstFrameMs'], 800);
      expect(rows.singleWhere((r) => r['event'] == 'firstFrame')['openToFirstFrameMs'], 800);
      expect(rows.where((r) => r['event'] == 'buffering').last['bufferingDurationMs'], 2000);
      expect(rows.singleWhere((r) => r['event'] == 'jump' && r['jumpKind'] == 'requested')['fromMs'], 3000);
      expect(rows.singleWhere((r) => r['event'] == 'jump' && r['jumpKind'] == 'requested')['toMs'], 30000);
      expect(rows.singleWhere((r) => r['event'] == 'jump' && r['jumpKind'] == 'observed')['fromMs'], 3000);
      expect(rows.singleWhere((r) => r['event'] == 'jump' && r['jumpKind'] == 'observed')['toMs'], 30000);
      final verdict = rows.singleWhere((r) => r['event'] == 'watchdog');
      expect(verdict['decision'], 'slowDeliveryOrDevice');
      expect(verdict['watchdogElapsedMs'], 8000);
      expect(verdict['hasRendered'], false);
      expect(verdict['watchdogFps'], 29.97);
      expect(jsonEncode(rows), isNot(contains('privado.invalid')));
      expect(jsonEncode(rows), isNot(contains('nao-gravar')));
      expect(guard.attempts, 0);
    } finally {
      await diagnostic.close();
      await player.closeStreamControllers();
      HttpOverrides.global = previous;
    }
  });
  test('mpv preserva ausência do contador real; cache e perdas não viram estimativa', () async {
    final player = _Player()
      ..engine = 'mpv'
      ..stats = {
        'playerType': 'mpv',
        'hwdec-current': 'mediacodec-copy',
        'frame-drop-count': '4',
        'decoder-frame-drop-count': '1',
        'demuxer-cache-duration': '6.5',
        'cache-speed': '524288',
        'demuxer-cache-state': '{"fw-bytes":1048576}',
      };
    final diagnostic = PlaybackDiagnostics(player: player, store: store);
    try {
      diagnostic.setVersion(_version);
      diagnostic.opening();
      diagnostic.fileLoaded();
      await diagnostic.sample();
      final sample = (await records()).lastWhere((r) => r['event'] == 'sample');
      expect(sample['engine'], 'mpv');
      expect(sample['renderedFrames'], isNull);
      expect(sample['renderedFramesAvailability'], 'notReported');
      expect(sample['frameDropCount'], 4);
      expect(sample['decoderFrameDropCount'], 1);
      expect(sample['cacheSeconds'], 6.5);
      expect(sample['cacheBytes'], 1048576);
      expect(sample['hwdec'], 'mediacodec-copy');
    } finally {
      await diagnostic.close();
      await player.closeStreamControllers();
    }
  });
  test('arquivo gira em dois slots limitados sem fragmentar JSON nem gravar campos privados', () async {
    store = PlaybackDiagnosticStore(directory: () async => directory, maxBytes: 4096);
    for (var i = 0; i < 80; i++) {
      await store.append({
        'event': 'sample',
        'session': 'synthetic',
        'elapsedMs': i,
        'codec': 'h264',
        'profile': 'High',
        'width': 1440,
        'height': 1080,
        'token': 'nao-gravar',
        'url': 'https://privado.invalid',
        'headers': {'Authorization': 'nao-gravar'},
      });
    }
    final files = await Directory('${directory.path}/logs').list().where((f) => f.path.endsWith('.jsonl')).toList();
    expect(files, hasLength(2));
    for (final file in files.cast<File>()) {
      expect(await file.length(), lessThanOrEqualTo(4096));
      for (final line in await file.readAsLines()) {
        expect(jsonDecode(line), isA<Map>());
      }
      expect(await file.readAsString(), isNot(contains('nao-gravar')));
      expect(await file.readAsString(), isNot(contains('privado.invalid')));
    }
    expect((await records()).last['elapsedMs'], 79);
  });
  test('erro de disco fica no diagnóstico e não é propagado para o player', () async {
    final blocked = PlaybackDiagnosticStore(directory: () async => throw const FileSystemException('bloqueado'));
    await blocked.append({'event': 'sample', 'codec': 'h264'});
    await blocked.flush();
    expect(blocked.writeFailures, 1);
  });
  test('leitura em voo é compartilhada e encerrar não consulta o motor já aposentado', () async {
    final pending = Completer<Map<String, dynamic>>();
    final player = _Player()..delayedStats = pending.future;
    final diagnostic = PlaybackDiagnostics(player: player, store: store);
    diagnostic.opening();
    diagnostic.fileLoaded();
    final sameRead = diagnostic.sample();
    expect(player.statsReads, 1);
    await diagnostic.close();
    pending.complete({'playerType': 'exoplayer'});
    await sameRead;
    expect(player.runtimeReads, 0);
    expect((await records()).last['event'], 'end');
    await player.closeStreamControllers();
  });
  test('estado inicial de buffering e recuperação sem evento preservam duração verdadeira', () async {
    final player = _Player()..state = const PlayerState(playing: true, buffering: true);
    var elapsed = Duration.zero;
    final diagnostic = PlaybackDiagnostics(player: player, store: store, elapsed: () => elapsed);
    try {
      diagnostic.opening();
      elapsed = const Duration(seconds: 2);
      diagnostic.fileLoaded();
      await diagnostic.sample();
      final first = (await records()).lastWhere((r) => r['event'] == 'sample');
      expect(first['buffering'], true);
      expect(first['bufferingTotalMs'], 2000);
      elapsed = const Duration(seconds: 5);
      player.state = player.state.copyWith(buffering: false);
      await diagnostic.sample();
      final last = (await records()).lastWhere((r) => r['event'] == 'sample');
      expect(last['buffering'], false);
      expect(last['bufferingTotalMs'], 5000);
    } finally {
      await diagnostic.close();
      await player.closeStreamControllers();
    }
  });
  test('falta de avanço durante buffering não é salto; seek real continua registrado', () async {
    final player = _Player();
    var elapsed = Duration.zero;
    final diagnostic = PlaybackDiagnostics(player: player, store: store, elapsed: () => elapsed);
    try {
      diagnostic.opening();
      diagnostic.fileLoaded();
      await diagnostic.sample();
      player.positionController.add(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      elapsed = const Duration(seconds: 5);
      player.state = player.state.copyWith(buffering: true);
      player.positionController.add(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      expect((await records()).where((r) => r['event'] == 'jump'), isEmpty);
      elapsed = const Duration(seconds: 10);
      player.state = player.state.copyWith(buffering: false);
      player.positionController.add(const Duration(seconds: 6));
      await Future<void>.delayed(Duration.zero);
      elapsed = const Duration(milliseconds: 10100);
      player.positionController.add(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);
      final jump = (await records()).singleWhere((r) => r['event'] == 'jump');
      expect(jump['fromMs'], 6000);
      expect(jump['toMs'], 30000);
    } finally {
      await diagnostic.close();
      await player.closeStreamControllers();
    }
  });
}
