import '../cgflix/home/cgflix_actions.dart';
import 'heisuca_text_metrics.dart';
import 'package:flutter/material.dart';
import '../cgflix/cgflix_palette.dart';
import '../cgflix/home/cgflix_cards.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';

/// Pôster + título + ano, nas medidas das fileiras da Home. O CgflixPosterCard sozinho não tem nome,
/// e muitas capas não trazem o título na arte (Caio, 24/10).
class HeisucaPosterTile extends StatelessWidget {
  const HeisucaPosterTile({super.key, required this.item, required this.client, required this.width, this.onTap});
  final MediaItem item;
  final MediaServerClient? client;
  final double width;
  final VoidCallback? onTap;

  /// Altura do bloco de texto abaixo do pôster (título + ano).
  static const textBlock = 40.0;
  static double textBlockFor(BuildContext context) {
    final measured = 6 + heisucaLineHeight(context, const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))
        + heisucaLineHeight(context, const TextStyle(fontSize: 11));
    return measured > textBlock ? measured : textBlock;
  }

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(children: [
        CgflixPosterCard(item: item, client: client, width: width, heroTag: 'heisuca-poster-${context.hashCode}-${item.globalKey}', onTap: onTap == null ? null : () {
 cgflixRememberHeroTag(item, 'heisuca-poster-${context.hashCode}-${item.globalKey}'); onTap!(); }),
        // Nota no canto, como nas fileiras da Home.
        if (item.rating != null && item.rating! > 0) Positioned(right: 4, bottom: 4, child: IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Text(
            item.rating!.toStringAsFixed(1).replaceAll('.', ','),
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))))),
      ]),
      const SizedBox(height: 6),
      Text(item.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
      if (item.year != null) Text('${item.year}', maxLines: 1, style: TextStyle(fontSize: 11, color: context.cgflix.textMuted)),
    ]));
}
