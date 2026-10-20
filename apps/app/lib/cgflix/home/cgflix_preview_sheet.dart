// Prévia de um título (painel inferior), como no site: fundo, logo, ano · classificação ·
// duração/temporadas · ★ nota, gêneros, sinopse curta e Assistir / Minha lista / Detalhes.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../utils/media_image_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/optimized_media_image.dart';
import '../cgflix_navigation.dart';
import '../cgflix_palette.dart';
import '../cgflix_style.dart';
import 'cgflix_actions.dart';

/// Duração legível: "1h 52min", "48min".
String cgflixDuration(int? durationMs) {
  if (durationMs == null || durationMs <= 0) return '';
  final minutes = (durationMs / 60000).round();
  if (minutes < 60) return '${minutes}min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}min';
}

/// Linha curta de metadados: 2023 · 14 · 1h 52min · ★ 7,8 (série: "3 temporadas").
List<String> cgflixMetaParts(MediaItem item) {
  final parts = <String>[];
  if (item.year != null) parts.add('${item.year}');
  final rating = item.contentRating?.trim();
  if (rating != null && rating.isNotEmpty) parts.add(rating);
  if (item.kind == MediaKind.show) {
    final seasons = item.childCount;
    if (seasons != null && seasons > 0) parts.add(seasons == 1 ? '1 temporada' : '$seasons temporadas');
  } else {
    final duration = cgflixDuration(item.durationMs);
    if (duration.isNotEmpty) parts.add(duration);
  }
  final score = item.rating;
  if (score != null && score > 0) parts.add('★ ${score.toStringAsFixed(1).replaceAll('.', ',')}');
  return parts;
}

Future<void> showCgflixPreview(BuildContext context, MediaItem item, {String? heroTag}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.cgflix.surface,
    clipBehavior: Clip.antiAlias,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => _CgflixPreview(item: item, hostContext: context, heroTag: heroTag),
  );
}

class _CgflixPreview extends StatefulWidget {
  const _CgflixPreview({required this.item, required this.hostContext, this.heroTag});
  final MediaItem item;

  /// Contexto da tela de baixo: as navegações saem dele depois que o painel fecha.
  final BuildContext hostContext;
  final String? heroTag;

  @override
  State<_CgflixPreview> createState() => _CgflixPreviewState();
}

class _CgflixPreviewState extends State<_CgflixPreview> {
  late MediaItem _item = widget.item;
  MediaServerClient? _client;
  bool? _favorite;

  @override
  void initState() {
    super.initState();
    _client = cgflixClientFor(widget.hostContext, widget.item);
    _favorite = widget.item.isFavorite;
    _loadFull();
  }

  /// Os cartões vêm com poucos campos; a prévia busca o item completo sem travar a tela.
  Future<void> _loadFull() async {
    final client = _client;
    if (client == null) return;
    try {
      final full = await client.fetchItem(widget.item.id);
      if (full != null && mounted) {
        setState(() {
          _item = full;
          _favorite = full.isFavorite ?? _favorite;
        });
      }
    } catch (_) {
      // Fica com o que o cartão já tinha.
    }
  }

  void _closeThen(Future<void> Function(BuildContext host) action) {
    final host = widget.hostContext;
    Navigator.of(context).pop();
    if (host.mounted) action(host);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = _item;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final artHeight = (width * 9 / 16).clamp(160.0, 300.0);
    final backdrop = cgflixWidePath(item);
    final isShow = item.kind == MediaKind.show || item.kind == MediaKind.season;
    final meta = cgflixMetaParts(item);
    final genres = (item.genres ?? const <String>[]).take(3).join(' • ');
    final overview = item.summary?.trim() ?? '';
    final title = item.kind == MediaKind.episode ? (item.grandparentTitle ?? item.displayTitle) : item.displayTitle;
    final episodeLine = item.kind == MediaKind.episode
        ? [cgflixEpisodeLabel(item), item.title ?? ''].where((s) => s.isNotEmpty).join(' · ')
        : '';

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: artHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OptimizedMediaImage(
                    client: _client,
                    imagePath: backdrop,
                    width: width,
                    height: artHeight,
                    imageType: ImageType.art,
                    fadeInDuration: CgflixMotion.medium,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: context.cgflix.sheetVeil,
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 64,
                    bottom: 8,
                    child: ClearLogoImage(
                      client: _client,
                      logoPath: item.kind == MediaKind.episode ? null : item.clearLogoPath,
                      width: 220,
                      height: 72,
                      fallbackWidth: width - 80,
                      fallbackBuilder: (context) => Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Fechar',
                      style: IconButton.styleFrom(
                        backgroundColor: context.cgflix.photoButton,
                        foregroundColor: context.cgflix.onPhotoButton,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: AppIcon(Symbols.close_rounded, fill: 1, color: context.cgflix.onPhotoButton),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (episodeLine.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(episodeLine, style: theme.textTheme.titleSmall),
                    ),
                  if (meta.isNotEmpty)
                    Text(
                      meta.join('  ·  '),
                      style: theme.textTheme.bodyMedium?.copyWith(color: context.cgflix.textMuted),
                    ),
                  if (genres.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(genres, style: theme.textTheme.bodySmall?.copyWith(color: context.cgflix.accentSoft)),
                  ],
                  if (overview.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    AnimatedSize(
                      duration: CgflixMotion.medium,
                      curve: CgflixMotion.curve,
                      alignment: Alignment.topCenter,
                      child: Text(
                        overview,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            // Roxo #9333ea (Isis) ou verde #006e28 (Heitor), texto branco (≥ 5,4:1).
                            backgroundColor: context.cgflix.action,
                            foregroundColor: context.cgflix.onAction,
                            minimumSize: const Size.fromHeight(48),
                          ).copyWith(overlayColor: cgflixPressedOverlay(context)),
                          onPressed: () => _closeThen(
                            (host) => isShow
                                ? cgflixOpenDetails(host, item, heroTag: widget.heroTag)
                                : cgflixPlay(host, item),
                          ),
                          icon: AppIcon(isShow ? Symbols.list_rounded : Symbols.play_arrow_rounded, fill: 1),
                          label: Text(isShow ? 'Ver episódios' : 'Assistir'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryAction(
                          icon: (_favorite ?? false) ? Symbols.check_rounded : Symbols.add_rounded,
                          // Leitor de tela: o rótulo diz se já está na lista (o ícone ✓/+ só se vê).
                          label: (_favorite ?? false) ? 'Na Minha lista' : 'Minha lista',
                          onTap: () async {
                            final updated = await cgflixToggleMyList(widget.hostContext, item, _favorite ?? false);
                            if (mounted) setState(() => _favorite = updated);
                          },
                        ),
                      ),
                      Expanded(
                        child: _SecondaryAction(
                          icon: Symbols.info_rounded,
                          label: 'Detalhes',
                          onTap: () => _closeThen((host) => cgflixOpenDetails(host, item, heroTag: widget.heroTag)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: CgflixMotion.fast,
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: AppIcon(icon, key: ValueKey(icon), fill: 1, size: 26),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
