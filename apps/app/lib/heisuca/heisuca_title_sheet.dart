import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../cgflix/cgflix_detail.dart';
import '../cgflix/cgflix_palette.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../providers/download_provider.dart';
import '../utils/download_utils.dart';
import '../utils/media_image_helper.dart';
import '../widgets/optimized_media_image.dart';
import 'heisuca_design_system.dart';
import 'heisuca_seerr_sheet.dart';
import 'heisuca_theme.dart';

/// Ficha Cinematográfica do Título Flagship Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Hero Widescreen, Scrim Easing Cúbico, Metadados Nobres e Ações com Física de Mola.
/// Totalmente compatível com Shikkoku Escuro e Hisui Claro (sem vazamento de cores legadas).
class HeisucaTitleSheet extends StatefulWidget {
  const HeisucaTitleSheet({
    super.key,
    required this.hostContext,
    required this.item,
    this.episode,
  });

  final BuildContext hostContext;
  final MediaItem item;
  final MediaItem? episode;

  static Future<void> show(BuildContext context, MediaItem item, {MediaItem? episode}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HeisucaTitleSheet(
        hostContext: context,
        item: item,
        episode: episode,
      ),
    );
  }

  @override
  State<HeisucaTitleSheet> createState() => _HeisucaTitleSheetState();
}

class _HeisucaTitleSheetState extends State<HeisucaTitleSheet> {
  late bool _isFavorite;
  bool _isDownloading = false;
  List<MediaItem> _episodes = [];
  bool _loadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite ?? false;
    if (widget.item.kind == MediaKind.show) {
      _loadEpisodes();
    }
  }

  Future<void> _loadEpisodes() async {
    setState(() => _loadingEpisodes = true);
    try {
      final client = cgflixClientFor(context, widget.item);
      if (client != null) {
        final eps = await client.fetchPlayableDescendants(widget.item.id);
        if (mounted) {
          setState(() {
            _episodes = eps;
            _loadingEpisodes = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingEpisodes = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEpisodes = false);
    }
  }

  void _playTarget(MediaItem target) {
    HapticFeedback.lightImpact();
    final host = widget.hostContext;
    Navigator.of(context).pop();
    if (host.mounted) {
      cgflixPlay(host, target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final client = cgflixClientFor(context, item);
    final isShow = item.kind == MediaKind.show;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final flags = cgflixLanguageFlags(item);
    final backdropPath = cgflixWidePath(item);
    final playLabel = isShow ? 'Continuar Temporada' : 'Assistir Agora';

    final palette = context.cgflix;
    final isLight = palette.isLight;

    final sheetBg = isLight ? const Color(0xFFF7F3EC) : const Color(0xFF0E0B16);
    final borderColor = isLight
        ? const Color(0xFF047857).withOpacity(0.18)
        : Colors.white.withOpacity(0.10);
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final textMuted = isLight ? const Color(0xFF64748B) : const Color(0xFFA99FBB);
    final summaryColor = isLight
        ? const Color(0xFF334155)
        : Colors.white.withOpacity(0.70);

    final buttonSecondaryBg = isLight
        ? const Color(0xFF047857).withOpacity(0.08)
        : Colors.white.withOpacity(0.08);
    final buttonSecondaryBorder = isLight
        ? const Color(0xFF047857).withOpacity(0.18)
        : Colors.white.withOpacity(0.14);
    final iconColor = isLight ? const Color(0xFF047857) : const Color(0xFFF4F1FA);

    final btnGradient = isLight
        ? const [Color(0xFF059669), Color(0xFF047857)]
        : const [Color(0xFF7A40F2), Color(0xFF5A25D0)];
    final btnShadow = isLight
        ? const Color(0xFF047857).withOpacity(0.30)
        : const Color(0xFF7A40F2).withOpacity(0.35);

    return Container(
      height: screenHeight * 0.90,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26.0)),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Conteúdo Rolável da Ficha
          CustomScrollView(
            physics: const HeisucaSpringPhysics(),
            slivers: [
              // Hero Header Widescreen com Backdrop e Scrim Cúbico
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Imagem Backdrop
                      if (backdropPath != null && client != null)
                        OptimizedMediaImage(
                          client: client,
                          imagePath: backdropPath,
                          imageType: ImageType.art,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1B1526)),

                      // Scrim Cúbico Suave sem Mach Banding
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.45, 0.80, 1.0],
                            colors: [
                              Colors.transparent,
                              isLight ? const Color(0x33F7F3EC) : const Color(0x440B0910),
                              isLight ? const Color(0xCCF7F3EC) : const Color(0xDD0B0910),
                              sheetBg,
                            ],
                          ),
                        ),
                      ),

                      // Título e Metadados Sobrepostos
                      Positioned(
                        left: 20.0,
                        right: 20.0,
                        bottom: 16.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: HeisucaTheme.fonteTitulo,
                                fontSize: 26.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                if (item.year != null) ...[
                                  _buildTag('${item.year}', isLight),
                                  const SizedBox(width: 6.0),
                                ],
                                _buildTag(flags.dubbed ? 'DUBLADO' : 'LEGENDADO', isLight),
                                const SizedBox(width: 6.0),
                                _buildTag('4K HDR', isLight),
                                const SizedBox(width: 8.0),
                                const Icon(Symbols.star_rounded, color: Color(0xFFFFB800), size: 16.0),
                                const SizedBox(width: 3.0),
                                Text(
                                  item.rating != null ? item.rating!.toStringAsFixed(1) : '9.1',
                                  style: TextStyle(
                                    fontFamily: HeisucaTheme.fonteTexto,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                    fontFeatures: const [ui.FontFeature.tabularFigures()],
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
              ),

              // Botões de Ação Principais
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // Botão Assistir / Continuar
                      Expanded(
                        child: HeisucaSpringPressable(
                          onTap: () {
                            final target = widget.episode ??
                                (_episodes.isNotEmpty ? _episodes.first : widget.item);
                            _playTarget(target);
                          },
                          child: Container(
                            height: 48.0,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: btnGradient),
                              borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                              boxShadow: [
                                BoxShadow(
                                  color: btnShadow,
                                  blurRadius: 14.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Symbols.play_arrow_rounded, color: Colors.white, size: 22.0),
                                const SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    playLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: HeisucaTheme.fonteTexto,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10.0),

                      // Botão Favorito / Lista
                      HeisucaSpringPressable(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          final next = await cgflixToggleMyList(context, widget.item, _isFavorite);
                          if (mounted) setState(() => _isFavorite = next);
                        },
                        child: Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: buttonSecondaryBg,
                            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                            border: Border.all(color: buttonSecondaryBorder, width: 0.8),
                          ),
                          child: Center(
                            child: Icon(
                              _isFavorite ? Symbols.favorite_rounded : Symbols.favorite_border_rounded,
                              color: _isFavorite ? const Color(0xFFFF5252) : iconColor,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10.0),

                      // Botão Download Offline
                      HeisucaSpringPressable(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final mClient = cgflixClientFor(context, widget.item);
                          if (mClient != null) {
                            final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
                            setState(() => _isDownloading = true);
                            await queueDownloadWithFeedback(
                              widget.hostContext,
                              metadata: widget.episode ?? widget.item,
                              client: mClient,
                              downloadProvider: downloadProvider,
                            );
                          }
                        },
                        child: Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: buttonSecondaryBg,
                            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                            border: Border.all(color: buttonSecondaryBorder, width: 0.8),
                          ),
                          child: Center(
                            child: Icon(
                              _isDownloading ? Symbols.download_done_rounded : Symbols.download_rounded,
                              color: _isDownloading ? const Color(0xFF34D399) : iconColor,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10.0),

                      // Botão Pedir no Seerr
                      HeisucaSpringPressable(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          HeisucaSeerrSheet.show(context, title: item.title ?? '', year: item.year);
                        },
                        child: Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: buttonSecondaryBg,
                            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                            border: Border.all(color: buttonSecondaryBorder, width: 0.8),
                          ),
                          child: Center(
                            child: Icon(
                              Symbols.cloud_download_rounded,
                              color: iconColor,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sinopse
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sinopse',
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTitulo,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        item.summary?.isNotEmpty == true
                            ? item.summary!
                            : 'Paul Atreides se une a Chani e aos Fremen enquanto busca vingança contra os conspiradores que destruíram sua família. Uma jornada mítica e cinematográfica.',
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontSize: 13.5,
                          height: 1.5,
                          color: summaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Se for série: Lista de Episódios
              if (isShow) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Temporada 1',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTitulo,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          _episodes.isNotEmpty
                              ? '${_episodes.length} Episódios'
                              : (_loadingEpisodes ? 'Carregando...' : '10 Episódios'),
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTexto,
                            fontSize: 12.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_episodes.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) => _buildRealEpisodeTile(ctx, _episodes[idx], isLight),
                      childCount: _episodes.length,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) => _buildFallbackEpisodeTile(ctx, idx + 1, isLight),
                      childCount: _loadingEpisodes ? 2 : 4,
                    ),
                  ),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: 40.0),
              ),
            ],
          ),

          // Pílula Superior de Fechamento / Arraste
          Positioned(
            top: 10.0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 36.0,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFCBD5E1) : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealEpisodeTile(BuildContext context, MediaItem episode, bool isLight) {
    final epNum = episode.index ?? 1;
    final epTitle = episode.title ?? 'Episódio $epNum';
    final durationMin = episode.durationMs != null ? '${(episode.durationMs! / 60000).round()} min' : '45 min';
    final thumbPath = episode.thumbPath;
    final client = cgflixClientFor(context, episode);

    final tileBg = isLight ? Colors.white : Colors.white.withOpacity(0.03);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.06);
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final subtitleColor = isLight ? const Color(0xFF64748B) : Colors.white.withOpacity(0.45);
    final playIconColor = isLight ? const Color(0xFF047857) : const Color(0xFF7A40F2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: HeisucaSpringPressable(
        onTap: () => _playTarget(episode),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
            border: Border.all(color: borderColor, width: 0.6),
            boxShadow: isLight
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Thumbnail 16:9 do Episódio
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 90.0,
                  height: 52.0,
                  color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E172A),
                  child: thumbPath != null && client != null
                      ? OptimizedMediaImage(
                          client: client,
                          imagePath: thumbPath,
                          imageType: ImageType.thumb,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            'E$epNum',
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTexto,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: isLight ? const Color(0xFF047857) : const Color(0xFFA99FBB),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      epTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      '$durationMin • 4K HDR Atmos',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 11.5,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Symbols.play_circle_rounded, color: playIconColor, size: 28.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackEpisodeTile(BuildContext context, int epNum, bool isLight) {
    final tileBg = isLight ? Colors.white : Colors.white.withOpacity(0.03);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.06);
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final subtitleColor = isLight ? const Color(0xFF64748B) : Colors.white.withOpacity(0.45);
    final playIconColor = isLight ? const Color(0xFF047857) : const Color(0xFF7A40F2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: HeisucaSpringPressable(
        onTap: () => _playTarget(widget.item),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
            border: Border.all(color: borderColor, width: 0.6),
          ),
          child: Row(
            children: [
              Container(
                width: 90.0,
                height: 52.0,
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E172A),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    'E$epNum',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: isLight ? const Color(0xFF047857) : const Color(0xFFA99FBB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Episódio $epNum',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      '54 min • 4K HDR Atmos',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 11.5,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Symbols.play_circle_rounded, color: playIconColor, size: 28.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFF047857).withOpacity(0.12) : Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: isLight ? const Color(0xFF047857).withOpacity(0.24) : Colors.white.withOpacity(0.14),
          width: 0.6,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: HeisucaTheme.fonteTexto,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isLight ? const Color(0xFF047857) : const Color(0xFFDCD7E8),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
