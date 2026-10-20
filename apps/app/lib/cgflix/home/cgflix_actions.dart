// Ações dos cartões do CGFLIX: tocar direto, abrir a página do título, Minha lista.
// Usa os fluxos do upstream (player, detalhes, favoritos) sem duplicar regra nenhuma.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../utils/app_logger.dart';
import '../../utils/media_navigation_helper.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/video_player_navigation.dart';

/// Etiqueta "T2:E5" de um episódio (vazia se faltar número).
String cgflixEpisodeLabel(MediaItem item) {
  final season = item.parentIndex;
  final episode = item.index;
  if (season == null || episode == null) return '';
  return 'T$season:E$episode';
}

/// "T2:E5", como no botão "Continuar T2:E5" (Etapa 1D: mesmo padrão dos cartões; antes "S02E05").
String cgflixEpisodeCode(MediaItem item) => cgflixEpisodeLabel(item);

/// Pôster que representa o item num cartão (episódio usa o da série).
String? cgflixPosterPath(MediaItem item) => switch (item.kind) {
  MediaKind.episode => item.grandparentThumbPath ?? item.parentThumbPath ?? item.thumbPath,
  MediaKind.season => item.parentThumbPath ?? item.thumbPath,
  _ => item.thumbPath,
};

/// Imagem larga (16:9): miniatura do episódio ou fundo do título.
String? cgflixWidePath(MediaItem item) {
  if (item.kind == MediaKind.episode && (item.thumbPath?.isNotEmpty ?? false)) return item.thumbPath;
  final backdrops = item.heroBackdropPaths;
  if (backdrops.isNotEmpty) return backdrops.first;
  return item.thumbPath;
}

MediaServerClient? cgflixClientFor(BuildContext context, MediaItem item) =>
    context.tryGetMediaClientForServer(serverIdOrNull(item.serverId));

// ---------------------------------------------------------------------------
// Transição de elemento compartilhado (pôster -> página do título)

final _pendingHeroTags = <String, String>{};

/// Guarda qual cartão abriu a página deste item, para a página usar a mesma tag no Hero.
void cgflixRememberHeroTag(MediaItem item, String tag) => _pendingHeroTags[item.globalKey] = tag;

/// Tag do Hero da página do título (null quando ela não foi aberta por um cartão do CGFLIX).
String? cgflixDetailHeroTag(MediaItem item) => _pendingHeroTags[item.globalKey];

/// Abre a página do título (com a animação do pôster quando houver [heroTag]).
Future<void> cgflixOpenDetails(BuildContext context, MediaItem item, {String? heroTag}) async {
  if (heroTag != null) {
    cgflixRememberHeroTag(item, heroTag);
  } else {
    _pendingHeroTags.remove(item.globalKey);
  }
  await navigateToMediaItemDetails(context, item);
  // Página fechada: a tag não vale mais (outra tela que abrir este título não "voa" de um cartão escondido).
  if (_pendingHeroTags[item.globalKey] == heroTag) _pendingHeroTags.remove(item.globalKey);
}

/// "Assistir": filme e episódio tocam direto; série toca o próximo episódio quando o
/// servidor sabe qual é, senão abre a página (para escolher a temporada).
Future<void> cgflixPlay(BuildContext context, MediaItem item) async {
  unawaited(HapticFeedback.lightImpact());
  if (item.kind == MediaKind.movie || item.kind == MediaKind.episode || item.kind == MediaKind.clip) {
    await navigateToVideoPlayer(context, metadata: item);
    return;
  }
  if (item.kind == MediaKind.show) {
    final client = cgflixClientFor(context, item);
    if (client != null) {
      try {
        final result = await client.fetchItemWithOnDeck(item.id).timeout(const Duration(seconds: 10));
        final next = result.onDeckEpisode;
        if (next != null && context.mounted) {
          await navigateToVideoPlayer(context, metadata: next);
          return;
        }
      } catch (e) {
        appLogger.w('CGFLIX: próximo episódio não encontrado', error: e);
      }
    }
  }
  if (context.mounted) await cgflixOpenDetails(context, item);
}

/// "Minha lista" = favoritos do Jellyfin/Plex. Devolve o novo estado (ou o antigo, se falhar).
Future<bool> cgflixToggleMyList(BuildContext context, MediaItem item, bool current) async {
  final client = cgflixClientFor(context, item);
  if (client == null) return current;
  try {
    await client.setFavorite(item, !current);
    if (context.mounted) {
      showSuccessSnackBar(context, current ? 'Removido da Minha lista' : 'Adicionado à Minha lista');
    }
    return !current;
  } catch (e) {
    appLogger.w('CGFLIX: Minha lista falhou', error: e);
    if (context.mounted) showErrorSnackBar(context, 'Não deu para atualizar a Minha lista');
    return current;
  }
}
