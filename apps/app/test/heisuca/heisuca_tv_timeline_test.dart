import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/media/media_source_info.dart';
import 'package:heisuca/mpv/models.dart';
import 'package:heisuca/widgets/video_controls/painters/buffer_range_painter.dart';

void main() {
  testWidgets('linha contínua de 960 dp, inclusive nos capítulos curtos e no buffer', (tester) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    BufferRangePainter(
      duration: const Duration(seconds: 100),
      ranges: [BufferRange(start: Duration.zero, end: const Duration(seconds: 70))],
      chapters: [
        for (final ms in [0, 1000, 1100, 3000, 50000, 50500, 90000]) MediaChapter(id: ms, startTimeOffset: ms),
      ],
    ).paint(canvas, const ui.Size(960, 48));
    final picture = recorder.endRecording();
    final image = await tester.runAsync(() => picture.toImage(960, 48));
    final bytes = await tester.runAsync(() => image!.toByteData(format: ui.ImageByteFormat.rawRgba));
    // Uma lacuna de capítulo produz alfa zero; linha e buffer não podem ser segmentados.
    for (var x = 4; x < 956; x++) {
      expect(bytes!.getUint8((24 * 960 + x) * 4 + 3), greaterThan(0), reason: 'linha em x=$x');
    }
    final buffer = bytes!.getUint8((24 * 960 + 200) * 4 + 3);
    final fundo = bytes.getUint8((24 * 960 + 800) * 4 + 3);
    expect(buffer, greaterThan(fundo));
    image!.dispose();
    picture.dispose();
  });
}
