import 'package:flutter/widgets.dart';

import '../../cgflix/home/cgflix_actions.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../services/jellyfin_client.dart';
import '../../services/jellyfin_playback_warmup_service.dart';
import '../../utils/platform_detector.dart';

/// Ponto de entrada de interface para o pré-aquecimento do Heisuca na TV.
class HeisucaTvPlaybackWarmup {
  HeisucaTvPlaybackWarmup._();

  static void onCardFocused(BuildContext context, MediaItem item) {
    if (!PlatformDetector.isTV()) return;
    if (item.backend != MediaBackend.jellyfin) return;

    final client = cgflixClientFor(context, item);
    if (client is JellyfinClient) {
      JellyfinPlaybackWarmupService.instance.onCardFocused(
        client: client,
        item: item,
      );
    }
  }

  static void onFocusLost() {
    if (!PlatformDetector.isTV()) return;
    JellyfinPlaybackWarmupService.instance.onFocusLost();
  }
}
