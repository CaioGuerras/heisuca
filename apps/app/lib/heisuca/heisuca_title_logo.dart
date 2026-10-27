import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../providers/multi_server_provider.dart';
import '../services/jellyfin_client.dart';
import '../services/plex_client.dart';
import '../widgets/optimized_media_image.dart';
import 'heisuca_plex_home_repository.dart';

class HeisucaResolvedLogo {
  const HeisucaResolvedLogo(this.client, this.path);
  final MediaServerClient client;
  final String path;
}

class _LogoRequest {
  _LogoRequest(this.candidates, this.future);
  final List<JellyfinClient> candidates;
  final Future<HeisucaResolvedLogo?> future;
  final at = DateTime.now();
}

/// Cache por instância autenticada da fonte, título e conexões do perfil.
/// Um mesmo nome nunca prova identidade; só TMDB/TVDB/IMDb confirmados.
class HeisucaLogoResolver {
  static final shared = HeisucaLogoResolver();
  final _cache = Expando<Map<String, _LogoRequest>>();

  Future<HeisucaResolvedLogo?> resolve(MediaItem item, MediaServerClient source,
      List<JellyfinClient> candidates) {
    final own = item.clearLogoPath;
    if (own != null && own.isNotEmpty) return Future.value(HeisucaResolvedLogo(source, own));
    if (source is! PlexClient || ![MediaKind.movie, MediaKind.show].contains(item.kind) || candidates.isEmpty) {
      return Future.value(null);
    }
    final cache = _cache[source] ??= {};
    final key = '${item.kind.name}:${item.id}';
    final saved = cache[key];
    if (saved != null && listEquals(saved.candidates, candidates) &&
        DateTime.now().difference(saved.at) < const Duration(minutes: 10)) return saved.future;
    final future = _find(item, source, candidates);
    cache[key] = _LogoRequest(List.unmodifiable(candidates), future);
    return future;
  }

  Future<HeisucaResolvedLogo?> _find(MediaItem item, PlexClient source, List<JellyfinClient> candidates) async {
    try {
      final ids = await source.fetchExternalIds(item.id);
      if (!ids.hasCatalogIds) return null;
      for (final jf in candidates) {
        try {
          var linked = false;
          for (final path in ['/cgflix/emalta.json', '/cgflix/embreve.json']) {
            try {
              if (heisucaFeedLinksPlex(await jf.cgflixGetJson(path), source.serverId.value)) {
                linked = true; break;
              }
            } catch (_) { /* O outro feed ainda pode declarar o vínculo. */ }
          }
          if (!linked) continue;
          final matches = await jf.findByExternalIds(ids, kind: item.kind,
            titles: [item.displayTitle], year: item.year);
          for (final match in matches ?? <MediaItem>[]) {
            final path = match.clearLogoPath;
            if (path != null && path.isNotEmpty) return HeisucaResolvedLogo(jf, path);
          }
        } catch (_) { /* Mantém o texto, sem afirmar que existe logo. */ }
      }
    } catch (_) { /* IDs indisponíveis: não compara apenas pelo nome. */ }
    return null;
  }
}

/// Mesma reserva visual da imagem existente, em destaque, ficha e player.
class HeisucaTitleLogo extends StatelessWidget {
  const HeisucaTitleLogo({super.key, required this.item, required this.client,
    required this.width, required this.height, required this.fallbackWidth,
    required this.fallbackBuilder, this.alignment = Alignment.centerLeft, this.logoToneTarget, this.compactFallback = false});
  final MediaItem item;
  final MediaServerClient? client;
  final double width, height, fallbackWidth;
  final WidgetBuilder fallbackBuilder;
  final Alignment alignment;
  final Color? logoToneTarget;
  final bool compactFallback;
  Widget _image(BuildContext context, HeisucaResolvedLogo? logo) {
    if (compactFallback && logo == null) return fallbackBuilder(context);
    return ClearLogoImage(client: logo?.client ?? client,
    logoPath: logo?.path, width: width, height: height, fallbackWidth: fallbackWidth,
    fallbackBuilder: fallbackBuilder, placeholderBuilder: compactFallback ? fallbackBuilder : null,
    alignment: alignment, logoToneTarget: logoToneTarget);
  }

  @override
  Widget build(BuildContext context) {
    final source = client;
    final own = item.clearLogoPath;
    if (source == null || (own != null && own.isNotEmpty)) {
      return _image(context, own == null || source == null ? null : HeisucaResolvedLogo(source, own));
    }
    final servers = context.watch<MultiServerProvider?>();
    final candidates = servers?.serverManager.visibleOnlineClients.values.whereType<JellyfinClient>().toList() ?? <JellyfinClient>[];
    if (source is! PlexClient || candidates.isEmpty) return _image(context, null);
    final future = HeisucaLogoResolver.shared.resolve(item, source, candidates);
    return FutureBuilder<HeisucaResolvedLogo?>(key: ObjectKey(future), future: future,
      builder: (_, snapshot) => _image(context, snapshot.data));
  }
}
