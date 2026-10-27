import 'package:flutter/foundation.dart';
/// Exceção estrita da bancada, sem mudar os tratadores do app de uso.
bool knownPipHudOverflow({required String message, required String source,
  required String phase, required double width, required double height}) {
  if (!const ['entrada', 'ativo', 'saída'].contains(phase) ||
      !width.isFinite || !height.isFinite || width <= 0 || width > 320 || height <= 0) return false;
  if (!RegExp(r'^A RenderFlex overflowed by [0-9.]+ pixels on the (right|bottom)\.').hasMatch(message)) return false;
  return RegExp(r'(?:video_controls_header\.dart:59:12|mobile_video_controls\.dart:(?:387:16|237:14))(?:\b|$)').hasMatch(source);
}

Map<String, Object?>? pipHudWarning(FlutterErrorDetails details, {
  required String phase, required double width, required double height}) {
  // Classifica os campos baratos ANTES de expandir a árvore de diagnóstico.
  // Erros fora do PiP e exceções comuns seguem diretamente ao framework.
  if (details.exception is! FlutterError || details.library != 'rendering library' ||
      !const ['entrada', 'ativo', 'saída'].contains(phase) ||
      !width.isFinite || !height.isFinite || width <= 0 || width > 320 || height <= 0) return null;
  final message = details.exceptionAsString();
  if (!message.startsWith('A RenderFlex overflowed by ')) return null;
  final source = details.toDiagnosticsNode().toStringDeep();
  if (!knownPipHudOverflow(message: message, source: source, phase: phase, width: width, height: height)) return null;
  final widget = RegExp(r'(video_controls_header\.dart:59:12|mobile_video_controls\.dart:(?:387:16|237:14))').firstMatch(source)!.group(1);
  return {'tipo': 'overflow HUD PiP', 'widget': widget, 'fase': phase, 'larguraDp': width, 'alturaDp': height};
}
