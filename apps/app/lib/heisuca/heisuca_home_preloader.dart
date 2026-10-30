import 'dart:async';
import 'package:flutter/widgets.dart';

import '../cgflix/home/cgflix_home_logic.dart';
import '../cgflix/home/cgflix_home_repository.dart';
import '../providers/multi_server_provider.dart';
import '../services/jellyfin_client.dart';
import '../services/plex_client.dart';
import '../utils/media_image_helper.dart';
import 'heisuca_plex_home_repository.dart';

/// Preload da tela de Início durante a abertura (Heisuca TV-1 G1.7):
/// Busca o destaque, Continuar assistindo e a 1ª fileira ("Em alta no Brasil")
/// e pré-carrega as imagens correspondentes na memória (ImageCache) para que
/// a tela surja pronta e sem engasgos assim que a splash terminar.
/// Responde `true` quando o destaque ou a 1ª fileira vieram do cache (abertura de 1 s).
class HeisucaHomePreloader {
  const HeisucaHomePreloader._();

  static Future<bool> preloadHomeDataAndArt(
    BuildContext context, {
    required MultiServerProvider multiServer,
  }) async {
    HeisucaHomeRepository? repo;
    var comCache = false;
    try {
      final client = multiServer.serverManager.navigationOnlineClients.values.firstOrNull;
      final feeds = multiServer.serverManager.visibleOnlineClients.values.whereType<JellyfinClient>().toList();

      repo = switch (client) {
        final JellyfinClient jf => CgflixHomeRepository(jf),
        final PlexClient plex => HeisucaPlexHomeRepository(plex, feedClients: feeds),
        _ => null,
      };

      if (repo == null) return comCache;

      // 1. Busca Início (destaque, Continuar, 1ª fileira) em paralelo com tratamento de erro
      final heroFuture = repo
          .watchHero()
          .first
          .catchError((_) => const CgflixRowData(items: []))
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => const CgflixRowData(items: []),
          );
      final cwFuture = repo
          .watchRow(CgflixRowKind.continueWatching)
          .first
          .catchError((_) => const CgflixRowData(items: []))
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => const CgflixRowData(items: []),
          );
      final trendingFuture = repo
          .watchTrending()
          .first
          .catchError((_) => const CgflixRowData(items: []))
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => const CgflixRowData(items: []),
          );

      final results = await Future.wait([heroFuture, cwFuture, trendingFuture]);
      final heroItem = results[0].items.firstOrNull;
      final cwItems = results[1].items;
      final trendingItems = results[2].items;
      comCache = results[0].fromCache || results[2].fromCache;

      if (!context.mounted) return comCache;

      // 2. Pré-carrega arte do destaque (backdrop)
      final precacheFutures = <Future<void>>[];
      if (heroItem != null) {
        final backdropPath = heroItem.artPath ?? heroItem.thumbPath;
        if (backdropPath != null && backdropPath.isNotEmpty) {
          final imageUrl = MediaImageHelper.getOptimizedImageUrl(
            client: client,
            thumbPath: backdropPath,
            maxWidth: 1920,
            maxHeight: 1080,
            pixelRatio: 1.0,
            imageType: ImageType.art,
          );
          if (imageUrl.isNotEmpty) {
            final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
              displayWidth: 1920,
              displayHeight: 1080,
              imageType: ImageType.art,
            );
            final provider = MediaImageHelper.serverArtworkProvider(
              imageUrl: imageUrl,
              memWidth: memWidth,
              memHeight: memHeight,
            );
            precacheFutures.add(
              precacheImage(
                provider,
                context,
                onError: (Object exception, StackTrace? stackTrace) {
                  // Precache é uma otimização: falhas não devem ser reportadas como exceções ao framework
                },
              ).catchError((_) {}),
            );
          }
        }
      }

      // 3. Pré-carrega os primeiros cartões visíveis (Continuar assistindo e Em alta)
      for (final item in [...cwItems.take(3), ...trendingItems.take(3)]) {
        if (!context.mounted) break;
        final thumbPath = item.thumbPath ?? item.artPath;
        if (thumbPath != null && thumbPath.isNotEmpty) {
          final imageUrl = MediaImageHelper.getOptimizedImageUrl(
            client: client,
            thumbPath: thumbPath,
            maxWidth: 360,
            maxHeight: 540,
            pixelRatio: 1.0,
            imageType: ImageType.poster,
          );
          if (imageUrl.isNotEmpty) {
            final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
              displayWidth: 360,
              displayHeight: 540,
              imageType: ImageType.poster,
            );
            final provider = MediaImageHelper.serverArtworkProvider(
              imageUrl: imageUrl,
              memWidth: memWidth,
              memHeight: memHeight,
            );
            precacheFutures.add(
              precacheImage(
                provider,
                context,
                onError: (Object exception, StackTrace? stackTrace) {
                  // Precache é uma otimização: falhas não devem ser reportadas como exceções ao framework
                },
              ).catchError((_) {}),
            );
          }
        }
      }

      if (precacheFutures.isNotEmpty) {
        await Future.wait(precacheFutures).timeout(
          const Duration(seconds: 2),
          onTimeout: () => const [],
        );
      }
    } catch (_) {
      // Ignora falhas para nunca travar a inicialização do app
    } finally {
      repo?.dispose();
    }
    return comCache;
  }
}
