import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

// NetworkImage ignora headers na igualdade; a sessão impede reuso entre contas.
class DesktopSessionArtwork extends ImageProvider<DesktopSessionArtwork> {
  DesktopSessionArtwork(String url, Map<String,String> headers, this.session) : source = NetworkImage(url, headers: Map.unmodifiable(headers));
  final NetworkImage source;
  final Object session;
  @override
  Future<DesktopSessionArtwork> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(DesktopSessionArtwork key, ImageDecoderCallback decode) {
    // ignore: deprecated_member_use
    return source.loadImage(source, decode);
  }
  @override
  bool operator ==(Object other) => other is DesktopSessionArtwork && source == other.source && identical(session, other.session);
  @override
  int get hashCode => Object.hash(source, identityHashCode(session));
}
