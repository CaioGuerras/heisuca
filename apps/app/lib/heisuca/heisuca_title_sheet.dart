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
import 'heisuca_state_store.dart';
import 'heisuca_theme.dart';

/// Tela Flagship de Informações / Ficha Técnica do Título Heisuca (炳素華) — Esboço 04
/// Abre em tela cheia com botão flutuante de voltar [←] no topo esquerdo.
/// Sem badges falsos de 4K HDR. Sem "Pedir no Seerr".
/// Alternância imediata e reativa de Favoritos com [HeisucaStateStore].
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

  /// Abre a ficha técnica em tela cheia com transição suave cinematográfica.
  static Future<void> show(BuildContext context, MediaItem item, {MediaItem? episode}) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (ctx, animation, secondaryAnimation) => HeisucaTitleSheet(
          hostContext: context,
          item: item,
          episode: episode,
        ),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<HeisucaTitleSheet> createState() => _HeisucaTitleSheetState();
}

class _HeisucaTitleSheetState extends State<HeisucaTitleSheet> {
  bool _isDownloading = false;
  List<MediaItem> _episodes = [];
  bool _loadingEpisodes = false;

  @override
  void initState() {
    super.initState();
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
    cgflixPlay(context, target);
  }

  String? _extractRealResolution(MediaItem item) {
    final versions = item.mediaVersions;
    if (versions != null && versions.isNotEmpty) {
      final v = versions.first;
      final res = v.videoResolution?.toUpperCase() ?? '';
      final h = v.height ?? 0;
      if (res.contains('4K') || res.contains('2160') || h >= 2160) {
        return '4K UHD';
      } else if (res.contains('1080') || h >= 1080) {
        return '1080p';
      } else if (res.contains('720') || h >= 720) {
        return '720p';
      }
    }
    return null;
  }

  String? _extractAudioChannels(MediaItem item) {
    final versions = item.mediaVersions;
    if (versions != null && versions.isNotEmpty) {
      for (final part in versions.first.parts) {
        for (final stream in part.streams) {
          final ch = stream.channels;
          if (ch != null) {
            if (ch >= 8) return '7.1';
            if (ch >= 6) return '5.1';
            if (ch == 2) return 'Stereo';
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final client = cgflixClientFor(context, item);
    final isShow = item.kind == MediaKind.show;
    final flags = cgflixLanguageFlags(item);
    final backdropPath = cgflixWidePath(item);
    final playLabel = isShow ? 'Continuar Temporada' : 'Assistir Agora';

    final palette = context.cgflix;
    final isLight = palette.isLight;

    final sheetBg = isLight ? const Color(0xFFF7F3EC) : const Color(0xFF0E0B16);
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final textMuted = isLight ? const Color(0xFF64748B) : const Color(0xFFA99FBB);
    final summaryColor = isLight ? const Color(0xFF334155) : Colors.white.withOpacity(0.75);

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

    final realRes = _extractRealResolution(item);
    final realAudio = _extractAudioChannels(item);
    final store = HeisucaStateStore.instance;

    return Scaffold(
      backgroundColor: sheetBg,
      body: Stack(
        children: [
          // 1. Conteúdo Rolável Completo da Ficha Técnica
          CustomScrollView(
            physics: const HeisucaSpringPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Hero Header Widescreen com Backdrop e Scrim Cúbico
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 360.0,
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

                      // Scrim Cúbico Suave
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.40, 0.75, 1.0],
                            colors: [
                              Colors.transparent,
                              isLight ? const Color(0x33F7F3EC) : const Color(0x440B0910),
                              isLight ? const Color(0xCCF7F3EC) : const Color(0xDD0B0910),
                              sheetBg,
                            ],
                          ),
                        ),
                      ),

                      // Informações no fundo do Backdrop
                      Positioned(
                        left: 20.0,
                        right: 20.0,
                        bottom: 12.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.displayTitle,
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
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 4.0,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (item.year != null)
                                  _buildTag('${item.year}', isLight),
                                if (flags.dubbed)
                                  _buildTag('DUBLADO', isLight)
                                else if (flags.subtitled)
                                  _buildTag('LEGENDADO', isLight),
                                if (realRes != null)
                                  _buildTag(realRes, isLight),
                                if (realAudio != null)
                                  _buildTag(realAudio, isLight),
                                if (item.rating != null) ...[
                                  const SizedBox(width: 2.0),
                                  const Icon(Symbols.star_rounded, color: Color(0xFFFFB800), size: 16.0),
                                  const SizedBox(width: 2.0),
                                  Text(
                                    item.rating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontFamily: HeisucaTheme.fonteTexto,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botões de Ação Imediata
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
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
                              children: [
                                const Icon(Symbols.play_arrow_rounded, color: Colors.white, size: 24.0),
                                const SizedBox(width: 8.0),
                                Text(
                                  playLabel,
                                  style: const TextStyle(
                                    fontFamily: HeisucaTheme.fonteTexto,
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10.0),

                      // Botão Favorito / Lista (Reativo com HeisucaStateStore)
                      ListenableBuilder(
                        listenable: store,
                        builder: (ctx, _) {
                          final isFav = store.isFavorite(widget.item);
                          return HeisucaSpringPressable(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              store.toggleFavorite(context, widget.item);
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
                                  Symbols.favorite_rounded,
                                  fill: isFav ? 1.0 : 0.0,
                                  color: isFav ? const Color(0xFFFF5252) : iconColor,
                                  size: 22.0,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 10.0),

                      // Botão Download Offline
                      HeisucaSpringPressable(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final mClient = cgflixClientFor(context, widget.item);
                          if (mClient != null) {
                            final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
                            await queueDownloadWithFeedback(
                              context,
                              metadata: widget.item,
                              client: mClient,
                              downloadProvider: downloadProvider,
                            );
                            if (mounted) setState(() => _isDownloading = true);
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
                              size: 22.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sinopse Real
              if (item.summary?.isNotEmpty == true)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sinopse',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTitulo,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          item.summary!,
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

              // Se for série: Lista Real de Episódios
              if (isShow) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Episódios',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTitulo,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          _episodes.isNotEmpty
                              ? '${_episodes.length} Episódios'
                              : (_loadingEpisodes ? 'Carregando...' : ''),
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
                else if (_loadingEpisodes)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: SizedBox(
                          width: 24.0,
                          height: 24.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: isLight ? const Color(0xFF047857) : const Color(0xFF7A40F2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],

              // Espaçamento de Rodapé
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 40.0),
              ),
            ],
          ),

          // 2. Botão Flutuante de Voltar [←] no Canto Superior Esquerdo
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8.0,
            left: 16.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.0),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(22.0),
                  child: Container(
                    width: 44.0,
                    height: 44.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(22.0),
                      border: Border.all(
                        color: isLight ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isLight ? 0.08 : 0.35),
                          blurRadius: 12.0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Symbols.arrow_back_rounded,
                      color: isLight ? const Color(0xFF134E4A) : Colors.white,
                      size: 24.0,
                    ),
                  ),
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
    final durationMin = episode.durationMs != null ? '${(episode.durationMs! / 60000).round()} min' : null;
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: SizedBox(
                  width: 90.0,
                  height: 52.0,
                  child: thumbPath != null && client != null
                      ? OptimizedMediaImage(
                          client: client,
                          imagePath: thumbPath,
                          imageType: ImageType.thumb,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E172A),
                          child: Center(
                            child: Text(
                              'E$epNum',
                              style: TextStyle(
                                fontFamily: HeisucaTheme.fonteTexto,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: isLight ? const Color(0xFF047857) : const Color(0xFFA99FBB),
                              ),
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
                    if (durationMin != null) ...[
                      const SizedBox(height: 3.0),
                      Text(
                        durationMin,
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontSize: 11.5,
                          color: subtitleColor,
                        ),
                      ),
                    ],
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
