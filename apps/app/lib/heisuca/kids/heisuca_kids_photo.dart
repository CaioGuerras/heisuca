import 'dart:io';
import 'package:flutter/material.dart';

/// Fotos infantis são privadas do aparelho. Nunca abre uma URL de rede.
class HeisucaKidsPhoto extends StatelessWidget {
  const HeisucaKidsPhoto({super.key, required this.uri, required this.size, required this.fallback});
  final String? uri;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final parsed = Uri.tryParse(uri ?? '');
    if (parsed == null || parsed.scheme != 'file' || parsed.host.isNotEmpty) return fallback;
    return Semantics(label: 'Foto da criança', image: true, child: ClipOval(
      child: Image.file(File.fromUri(parsed), width: size, height: size, fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
        errorBuilder: (_, _, _) => fallback),
    ));
  }
}
