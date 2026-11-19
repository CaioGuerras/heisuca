import 'package:flutter/material.dart';
import '../../media/media_server_client.dart';
import 'desktop_session_artwork.dart';

/// Alguns Plex recusam o redimensionamento sem as duas dimensões.
/// Mantém uma saída direta quando o servidor não consegue processar a imagem.
List<String> desktopArtworkUrls(MediaServerClient client, Iterable<String?> paths,
    {required int width, required int height}) {
  final urls = <String>{};
  for (final path in paths) {
    if (path == null || path.isEmpty) continue;
    try { final url = client.thumbnailUrl(path, width: width, height: height); if (url.isNotEmpty) urls.add(url); } on Object { /* tentar original */ }
    try { final url = client.thumbnailUrl(path); if (url.isNotEmpty) urls.add(url); } on Object { /* tentar próximo caminho */ }
  }
  return urls.toList(growable: false);
}

class DesktopArtwork extends StatelessWidget {
  const DesktopArtwork({super.key, required this.urls, required this.headers,
    required this.session, required this.fallback, this.providerBuilder});
  final List<String> urls;
  final Map<String,String> headers;
  final Object session;
  final Widget fallback;
  @visibleForTesting
  final ImageProvider Function(String)? providerBuilder;
  Widget _attempt(int index) {
    if (index >= urls.length) return fallback;
    return Image(
      image: providerBuilder?.call(urls[index]) ?? DesktopSessionArtwork(urls[index], headers, session),
      fit: BoxFit.cover, excludeFromSemantics: true, gaplessPlayback: false,
      errorBuilder: (_, _, _) => _attempt(index + 1),
    );
  }
  @override
  Widget build(BuildContext context) => _attempt(0);
}
