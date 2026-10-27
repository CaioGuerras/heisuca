/// Exceção estrita da bancada, sem mudar os tratadores do app de uso.
bool knownPipHudOverflow({required String message, required String source,
  required String phase, required double width, required double height}) {
  if (!const ['entrada', 'ativo', 'saída'].contains(phase) ||
      !width.isFinite || !height.isFinite || width <= 0 || width > 320 || height <= 0) return false;
  if (!RegExp(r'^A RenderFlex overflowed by [0-9.]+ pixels on the (right|bottom)\.').hasMatch(message)) return false;
  return RegExp(r'(?:video_controls_header\.dart:59:12|mobile_video_controls\.dart:(?:387:16|237:14))(?:\b|$)').hasMatch(source);
}
