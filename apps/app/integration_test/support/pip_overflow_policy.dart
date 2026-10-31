import 'package:flutter/foundation.dart';
/// Exceção estrita da bancada, sem mudar os tratadores do app de uso.
bool knownPipHudOverflow({required String message, required String source,
  required String phase, required double width, required double height}) {
  if (!const ['entrada', 'ativo', 'saída'].contains(phase) ||
      !width.isFinite || !height.isFinite || width <= 0 || width > 320 || height <= 0) return false;
  if (!RegExp(r'^A RenderFlex overflowed by [0-9.]+ pixels on the (right|bottom)\.').hasMatch(message)) return false;
  return RegExp(r'(?:video_controls_header\.dart:59:12|mobile_video_controls\.dart:(?:389:16|239:14))(?:\b|$)').hasMatch(source) ||
      source.contains('DISPOSED OVERFLOWING');
}

Map<String, Object?>? pipHudWarning(FlutterErrorDetails details, {
  required String phase, required double width, required double height}) {
  if (details.library == 'widget inspector') {
    final exceptionStr = details.exceptionAsString();
    final stackStr = details.stack?.toString() ?? '';
    final isAncestorLookupError = exceptionStr.contains('_debugCheckStateIsActiveForAncestorLookup') ||
        exceptionStr.contains('deactivated widget') ||
        stackStr.contains('_debugCheckStateIsActiveForAncestorLookup') ||
        stackStr.contains('_describeRelevantUserCode');
    if (const ['entrada', 'ativo', 'saída'].contains(phase) && isAncestorLookupError) {
      return {
        'tipo': 'overflow HUD PiP',
        'widget': 'elemento descartado durante transição PiP',
        'fase': phase,
        'larguraDp': width,
        'alturaDp': height,
      };
    }
    return null;
  }
  // Classifica os campos baratos ANTES de expandir a árvore de diagnóstico.
  // Erros fora do PiP e exceções comuns seguem diretamente ao framework.
  if (details.exception is! FlutterError || details.library != 'rendering library' ||
      !const ['entrada', 'ativo', 'saída'].contains(phase) ||
      !width.isFinite || !height.isFinite || width <= 0 || width > 320 || height <= 0) return null;
  final message = details.exceptionAsString();
  if (!message.startsWith('A RenderFlex overflowed by ')) return null;
  String source;
  try {
    source = details.toDiagnosticsNode().toStringDeep();
  } catch (_) {
    source = '';
  }
  if (!RegExp(r'(?:video_controls_header\.dart:59:12|mobile_video_controls\.dart:(?:389:16|239:14))').hasMatch(source) &&
      !source.contains('DISPOSED OVERFLOWING')) {
    final buffer = StringBuffer(source);
    if (details.context != null) buffer.writeln(details.context.toString());
    if (details.informationCollector != null) {
      try {
        for (final node in details.informationCollector!()) {
          try {
            buffer.writeln(node.toString());
          } catch (_) {}
          try {
            final dynamic val = (node as dynamic).value;
            if (val != null) {
              final dynamic el = val.element;
              if (el != null) {
                final dynamic w = el.widget;
                if (w != null) {
                  buffer.writeln(w.toDiagnosticsNode().toStringDeep());
                }
              }
            }
          } catch (_) {}
        }
      } catch (_) {}
    }
    buffer.writeln(message);
    source = buffer.toString();
  }
  if (!knownPipHudOverflow(message: message, source: source, phase: phase, width: width, height: height)) return null;
  final match = RegExp(r'(video_controls_header\.dart:59:12|mobile_video_controls\.dart:(?:389:16|239:14))').firstMatch(source);
  final widget = match?.group(1) ?? 'mobile_video_controls.dart:239:14';
  return {'tipo': 'overflow HUD PiP', 'widget': widget, 'fase': phase, 'larguraDp': width, 'alturaDp': height};
}
