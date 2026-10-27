import 'package:flutter/material.dart';

/// Mede a linha com a mesma fonte e escala que o Text renderiza.
double heisucaLineHeight(BuildContext context, TextStyle style) {
  return heisucaTextHeight(context, 'Ag', style, maxLines: 1);
}

double heisucaTextHeight(BuildContext context, String text, TextStyle style,
    {double maxWidth = double.infinity, int? maxLines}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium!.merge(style)),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: Directionality.of(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);
  final height = painter.height;
  painter.dispose();
  return height;
}
