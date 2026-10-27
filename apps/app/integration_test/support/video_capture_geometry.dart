import 'package:flutter/material.dart';

/// A ponte nativa lê MPV_FORMAT_STRING: subpropriedades numéricas não dependem
/// da representação textual que o motor escolheria para um mapa completo.
Future<Map<String, dynamic>> readVideoParamsForCapture(Future<String?> Function(String) read) async {
  final params = <String, dynamic>{};
  for (final key in ['w', 'h', 'dw', 'dh', 'par', 'rotate']) {
    final raw = await read('video-params/$key');
    if (raw == null) continue;
    final value = num.tryParse(raw);
    if (value == null || !value.isFinite) throw StateError('O motor não informou $key numérico para a captura.');
    params[key] = value;
  }
  return params;
}

/// Metadados do motor e da superfície real, em pixels da captura do Android.
Map<String, Object?> videoCaptureGeometry({
  required Size window,
  required Rect surface,
  required EdgeInsets systemBars,
  required Map<String, dynamic> videoParams,
  required int boxFitMode,
  required double zoom,
  required bool hudHidden,
}) {
  double positive(Object? value) {
    if (value is! num || !value.isFinite || value <= 0) {
      throw StateError('O motor não informou dimensões válidas para medir o vídeo.');
    }
    return value.toDouble();
  }
  if (!hudHidden) throw StateError('O HUD ainda está visível na captura do vídeo.');
  var width = videoParams['dw'];
  var height = videoParams['dh'];
  if (width == null || height == null) {
    // PAR vem do motor: nunca supõe pixels quadrados para um arquivo anamórfico.
    width = positive(videoParams['w']) * positive(videoParams['par']);
    height = positive(videoParams['h']);
  }
  var displayWidth = positive(width);
  var displayHeight = positive(height);
  final rotation = videoParams['rotate'] ?? 0;
  if (rotation is! num || !rotation.isFinite || rotation % 90 != 0) {
    throw StateError('O motor não informou uma rotação mensurável para o vídeo.');
  }
  if (rotation % 180 != 0) {
    final before = displayWidth;
    displayWidth = displayHeight;
    displayHeight = before;
  }
  final mode = switch (boxFitMode) {
    0 => 'conter', 1 => 'cobrir', 2 => 'esticar',
    _ => throw StateError('Modo de proporção desconhecido na captura do vídeo.'),
  };
  if (!window.isFinite || window.isEmpty || !surface.isFinite || surface.isEmpty || !zoom.isFinite || zoom <= 0) {
    throw StateError('A janela do vídeo não pode ser medida.');
  }
  return {
    'janela': {'largura': window.width, 'altura': window.height},
    'superficie': {'x': surface.left, 'y': surface.top, 'largura': surface.width, 'altura': surface.height},
    'video': {'largura': displayWidth, 'altura': displayHeight, 'modo': mode, 'zoom': zoom},
    'barrasSistema': {'topo': systemBars.top, 'base': systemBars.bottom,
      'esquerda': systemBars.left, 'direita': systemBars.right},
    'hudOculto': true, 'exclusoesHud': <Object?>[],
    'parametrosMotor': videoParams,
  };
}
