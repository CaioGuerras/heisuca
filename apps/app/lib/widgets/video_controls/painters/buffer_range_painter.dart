import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../design/forma.dart';
import '../../../design/tema.dart';
import '../../../media/media_source_info.dart';
import '../../../mpv/models.dart';

/// Fundo e buffer contínuos. Capítulos nunca recortam a linha em segmentos.
class BufferRangePainter extends CustomPainter {
  final List<BufferRange> ranges;
  final Duration duration;
  final List<MediaChapter> chapters;

  BufferRangePainter({required this.ranges, required this.duration, this.chapters = const []});

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = Forma.espaco2;
    final y = (size.height - trackHeight) / 2;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y, size.width, trackHeight),
      const Radius.circular(trackHeight / 2),
    );
    final tinta = TemaHeisuca.shikkoku.texto;
    canvas.drawRRect(track, Paint()..color = tinta.withValues(alpha: 0.3));
    final durationMs = duration.inMilliseconds.toDouble();
    if (durationMs <= 0) return;
    canvas.save();
    canvas.clipRRect(track);
    for (final range in ranges) {
      final left = (range.start.inMilliseconds / durationMs).clamp(0.0, 1.0) * size.width;
      final right = (range.end.inMilliseconds / durationMs).clamp(0.0, 1.0) * size.width;
      if (right <= left) continue;
      canvas.drawRect(Rect.fromLTRB(left, y, right, y + trackHeight), Paint()..color = tinta.withValues(alpha: 0.5));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BufferRangePainter oldDelegate) =>
      oldDelegate.duration != duration || !listEquals(oldDelegate.ranges, ranges);
}

/// Tiques finos por cima do fundo, buffer e progresso, inclusive nos capítulos já vistos.
class ChapterTicksPainter extends CustomPainter {
  const ChapterTicksPainter({required this.duration, required this.chapters});

  final Duration duration;
  final List<MediaChapter> chapters;

  @override
  void paint(Canvas canvas, Size size) {
    final ms = duration.inMilliseconds;
    if (ms <= 0) return;
    final paint = Paint()
      ..color = TemaHeisuca.shikkoku.fundo
      ..strokeWidth = Forma.espaco1 / 4;
    final meio = size.height / 2;
    // Não criar novos "pontos" onde dois capítulos ficam a menos de um tique.
    double? ultimo;
    final inicios = chapters.map((c) => c.startTimeOffset ?? 0).where((t) => t > 0 && t < ms).toSet().toList()..sort();
    for (final inicio in inicios) {
      final x = inicio / ms * size.width;
      if (ultimo != null && x - ultimo < Forma.espaco1) continue;
      canvas.drawLine(Offset(x, meio - Forma.espaco2 / 2), Offset(x, meio + Forma.espaco2 / 2), paint);
      ultimo = x;
    }
  }

  @override
  bool shouldRepaint(ChapterTicksPainter oldDelegate) =>
      oldDelegate.duration != duration || !listEquals(oldDelegate.chapters, chapters);
}
