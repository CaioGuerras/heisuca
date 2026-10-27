import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_device_status.dart';
import 'package:heisuca/heisuca/services/heisuca_device_service.dart';
import 'package:heisuca/heisuca/services/heisuca_frame_measurement.dart';

FrameTiming _frame(int buildUs, int rasterUs) => FrameTiming(
  vsyncStart: 0,
  buildStart: 0,
  buildFinish: buildUs,
  rasterStart: buildUs,
  rasterFinish: buildUs + rasterUs,
  rasterFinishWallTime: buildUs + rasterUs,
);

void main() {
  testWidgets('mede quadros Flutter na taxa real e conserva resultado com popup fechado', (tester) async {
    final measurement = HeisucaFrameMeasurement(duration: const Duration(seconds: 20));
    addTearDown(measurement.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.isis),
        home: HeisucaDeviceStatusDialog(
          profile: const HeisucaDeviceProfile(),
          effectsPreference: 'automática',
          exoPlayer: false,
          hardwareDecoding: true,
          frameMeasurement: measurement,
        ),
      ),
    );
    // 120 Hz: 10 ms excedem 8,33 ms. O botão usa a tela real, não 60 fixos.
    tester.view.display.refreshRate = 120;
    addTearDown(tester.view.display.resetRefreshRate);
    await tester.ensureVisible(find.text('Medir fluidez'));
    await tester.tap(find.text('Medir fluidez'));
    await tester.pump();
    expect(find.text('Medindo fluidez…'), findsOneWidget);
    tester.binding.platformDispatcher.onReportTimings!([_frame(1000, 1000), _frame(10000, 2000)]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 20));
    expect(measurement.measuring, isFalse);
    final result = measurement.result!;
    expect(result.frames, hasLength(2));
    expect(result.refreshRate, 120);
    expect(result.latePercent, 50);
    expect(result.percentile(.5, (f) => f.total), 2);
    expect(result.percentile(.9, (f) => f.total), 12);
    expect(result.percentile(.99, (f) => f.raster), 2);
    expect(result.summary, 'A fluidez ficou baixa neste uso.');
    tester.binding.platformDispatcher.onReportTimings?.call([_frame(100000, 100000)]);
    expect(result.frames, hasLength(2), reason: 'callback removido ao concluir');
  });

  testWidgets('sem quadros não inventa resultado; dispose remove callback', (tester) async {
    final measurement = HeisucaFrameMeasurement(duration: const Duration(seconds: 20));
    measurement.start(refreshRate: double.nan);
    expect(measurement.measuring, isFalse);
    measurement.start(refreshRate: 60);
    await tester.pump(const Duration(seconds: 20));
    expect(measurement.result!.frames, isEmpty);
    expect(measurement.result!.summary, contains('Nenhum quadro'));
    measurement.start(refreshRate: 90);
    measurement.dispose();
    await tester.pump(const Duration(seconds: 21));
    expect(tester.takeException(), isNull);
  });
}
