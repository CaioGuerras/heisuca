import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../cgflix/cgflix_detail.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../utils/media_image_helper.dart';
import '../widgets/optimized_media_image.dart';
import 'heisuca_design_system.dart';
import 'heisuca_seerr_sheet.dart';
import 'heisuca_theme.dart';

/// Ficha Cinematográfica do Título Flagship Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Hero Widescreen, Scrim Easing Cúbico, Metadados Nobres e Ações com Física de Mola.
class HeisucaTitleSheet extends StatefulWidget {
  const HeisucaTitleSheet({
    super.key,
    required this.item,
    this.episode,
  });

  final MediaItem item;
  final MediaItem? episode;

  static Future<void> show(BuildContext context, MediaItem item, {MediaItem? episode}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HeisucaTitleSheet(item: item, episode: episode),
    );
  }

  @override
  State<HeisucaTitleSheet> createState() => _HeisucaTitleSheetState();
}

class _HeisucaTitleSheetState extends State<HeisucaTitleSheet> {
  bool _isFavorite = false;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final client = cgflixClientFor(context, item);
    final isShow = item.kind == MediaKind.show;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final flags = cgflixLanguageFlags(item);
    final backdropPath = cgflixWidePath(item);
    final playLabel = isShow ? 'Continuar Temporada' : 'Assistir Agora';

    return Container(
      height: screenHeight * 0.90,
      decoration: BoxDecoration(
        color: HeisucaTheme.roxoFundo,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26.0)),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.8),
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
                        Container(color: const Color(0xFF1B1526)),

                      // Scrim Cúbico Suave sem Mach Banding
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.45, 0.80, 1.0],
                            colors: [
                              Colors.transparent,
                              const Color(0x440B0910),
                              const Color(0xDD0B0910),
                              HeisucaTheme.roxoFundo,
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
                              style: const TextStyle(
                                fontFamily: HeisucaTheme.fonteTitulo,
                                fontSize: 26.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: Color(0xFFF4F1FA),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                if (item.year != null) ...[
                                  _buildTag('${item.year}'),
                                  const SizedBox(width: 6.0),
                                ],
                                _buildTag(flags.dubbed ? 'DUBLADO' : 'LEGENDADO'),
                                const SizedBox(width: 6.0),
                                _buildTag('4K HDR'),
                                const SizedBox(width: 8.0),
                                const Icon(Symbols.star_rounded, color: Color(0xFFFFB800), size: 16.0),
                                const SizedBox(width: 3.0),
                                Text(
                                  item.rating != null ? item.rating!.toStringAsFixed(1) : '9.1',
                                  style: const TextStyle(
                                    fontFamily: HeisucaTheme.fonteTexto,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF4F1FA),
                                    fontFeatures: [ui.FontFeature.tabularFigures()],
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
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            cgflixPlay(context, item);
                          },
                          child: Container(
                            height: 48.0,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7A40F2), Color(0xFF5A25D0)],
                              ),
                              borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7A40F2).withOpacity(0.35),
                                  blurRadius: 14.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Symbols.play_arrow_rounded, color: Colors.white, size: 22.0),
                                const SizedBox(width: 8.0),
                                Text(
                                  playLabel,
                                  style: const TextStyle(
                                    fontFamily: HeisucaTheme.fonteTexto,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isFavorite = !_isFavorite);
                        },
                        child: Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                            border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.8),
                          ),
                          child: Center(
                            child: Icon(
                              _isFavorite ? Symbols.favorite_rounded : Symbols.favorite_border_rounded,
                              color: _isFavorite ? const Color(0xFFFF5252) : const Color(0xFFF4F1FA),
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10.0),

                      // Botão Download Offline
                      HeisucaSpringPressable(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isDownloading = true);
                        },
                        child: Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                            border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.8),
                          ),
                          child: Center(
                            child: Icon(
                              _isDownloading ? Symbols.download_done_rounded : Symbols.download_rounded,
                              color: _isDownloading ? const Color(0xFF34D399) : const Color(0xFFF4F1FA),
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
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                            border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.8),
                          ),
                          child: const Center(
                            child: Icon(
                              Symbols.cloud_download_rounded,
                              color: Color(0xFFF4F1FA),
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
                      const Text(
                        'Sinopse',
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTitulo,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF4F1FA),
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
                          color: Colors.white.withOpacity(0.70),
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
                      children: const [
                        Text(
                          'Temporada 1',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTitulo,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF4F1FA),
                          ),
                        ),
                        Text(
                          '10 Episódios',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTexto,
                            fontSize: 12.5,
                            color: Color(0xFFA99FBB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, idx) => _buildEpisodeTile(ctx, idx + 1),
                    childCount: 4,
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
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(BuildContext context, int epNum) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: HeisucaSpringPressable(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
            border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.6),
          ),
          child: Row(
            children: [
              // Thumbnail 16:9 do Episódio
              Container(
                width: 90.0,
                height: 52.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E172A),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    'E$epNum',
                    style: const TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA99FBB),
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
                      style: const TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF4F1FA),
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      '54 min • 4K HDR Atmos',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Symbols.play_circle_rounded, color: Color(0xFF7A40F2), size: 28.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: HeisucaTheme.fonteTexto,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFDCD7E8),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
