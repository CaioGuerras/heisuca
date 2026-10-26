import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class HeisucaFrameSample {
  const HeisucaFrameSample({required this.build, required this.raster, required this.total});
  final Duration build;
  final Duration raster;
  final Duration total;
}

class HeisucaFrameResult {
  HeisucaFrameResult(List<HeisucaFrameSample> frames, this.refreshRate) : frames = List.unmodifiable(frames);
  final List<HeisucaFrameSample> frames;
  final double refreshRate;
  double get budgetMs => 1000 / refreshRate;
  // Construção e rasterização são etapas em paralelo. Total inclui a fila.
  double get latePercent => frames.isEmpty
      ? 0
      : 100 *
            frames.where((f) => math.max(f.build.inMicroseconds, f.raster.inMicroseconds) > budgetMs * 1000).length /
            frames.length;
  double percentile(double p, Duration Function(HeisucaFrameSample) value) {
    if (frames.isEmpty) return 0;
    final times = frames.map((f) => value(f).inMicroseconds / 1000).toList()..sort();
    return times[(p * times.length).ceil().clamp(1, times.length).toInt() - 1];
  }

  String get summary => frames.isEmpty
      ? 'Nenhum quadro foi registrado. Use o app durante a medição.'
      : latePercent <= 10
      ? 'Fluidez boa neste uso.'
      : latePercent <= 30
      ? 'A fluidez pode melhorar neste uso.'
      : 'A fluidez ficou baixa neste uso.';
}

/// Tempos do Flutter só na memória. Continua com o popup fechado por 20 s.
/// Nenhuma opção visual muda sozinha e nenhum dado é enviado.
class HeisucaFrameMeasurement extends ChangeNotifier {
  HeisucaFrameMeasurement({SchedulerBinding? scheduler, this.duration = const Duration(seconds: 20)})
    : _scheduler = scheduler ?? SchedulerBinding.instance;
  static final instance = HeisucaFrameMeasurement();
  final SchedulerBinding _scheduler;
  final Duration duration;
  final List<HeisucaFrameSample> _frames = [];
  Timer? _timer;
  bool _measuring = false;
  double _refreshRate = 0;
  bool get measuring => _measuring;
  HeisucaFrameResult? result;

  void start({required double refreshRate}) {
    if (_measuring || !refreshRate.isFinite || refreshRate <= 0) return;
    _refreshRate = refreshRate;
    _frames.clear();
    result = null;
    _measuring = true;
    _scheduler.addTimingsCallback(_onTimings);
    _timer = Timer(duration, _finish);
    notifyListeners();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!_measuring) return;
    for (final t in timings) {
      _frames.add(HeisucaFrameSample(build: t.buildDuration, raster: t.rasterDuration, total: t.totalSpan));
    }
  }

  void _finish() {
    _scheduler.removeTimingsCallback(_onTimings);
    _measuring = false;
    _timer = null;
    result = HeisucaFrameResult(_frames, _refreshRate);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_measuring) _scheduler.removeTimingsCallback(_onTimings);
    super.dispose();
  }
}
