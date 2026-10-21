import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../cgflix/cgflix_user_menu.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../cgflix/home/cgflix_cards.dart';
import '../cgflix/home/cgflix_home_logic.dart';
import '../cgflix/home/cgflix_home_repository.dart';
import '../cgflix/home/cgflix_preview_sheet.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../providers/multi_server_provider.dart';
import '../utils/media_image_helper.dart';
import '../widgets/optimized_media_image.dart';
import 'heisuca_design_system.dart';
import 'heisuca_logo.dart';
import 'heisuca_theme.dart';

/// Tela Inicial Flagship do Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Calibrada para OLED 144Hz, Efeito Halo OKLCH Dinâmico, Física de Mola e Menu do Usuário.
class HeisucaHomeScreen extends StatefulWidget {
  const HeisucaHomeScreen({super.key});

  @override
  State<HeisucaHomeScreen> createState() => _HeisucaHomeScreenState();
}

class _HeisucaHomeScreenState extends State<HeisucaHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _headerOpacity = 0.0;
  CgflixHomeFilter? _currentFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final targetOpacity = (offset / 180.0).clamp(0.0, 1.0);
    if ((targetOpacity - _headerOpacity).abs() > 0.02) {
      setState(() => _headerOpacity = targetOpacity);
    }
  }

  void _openUserMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showCgflixUserMenu(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<CgflixHomeRepository>();
    final highlight = repo.highlight;
    final rows = repo.rows;

    return Scaffold(
      backgroundColor: HeisucaTheme.roxoFundo,
      body: Stack(
        children: [
          // 1. Conteúdo Rolável Principal com Física de Mola
          CustomScrollView(
            controller: _scrollController,
            physics: const HeisucaSpringPhysics(),
            slivers: [
              // Hero Carousel com Halo Dinâmico
              SliverToBoxAdapter(
                child: HeisucaHeroCarousel(
                  highlight: highlight,
                  onPlay: (item) => cgflixPlay(context, item),
                  onDetails: (item) => cgflixOpenDetails(context, item),
                ),
              ),

              // Chips de Filtro Rápido
              SliverToBoxAdapter(
                child: _buildFilterChips(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12.0)),

              // Linhas de Catálogo
              if (rows.isEmpty && repo.isLoading)
                const SliverToBoxAdapter(child: _HeisucaHomeSkeleton())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      final row = rows[index];
                      return _buildCatalogRow(ctx, row);
                    },
                    childCount: rows.length,
                  ),
                ),

              // Espaçamento para não colidir com a Ilha Flutuante
              const SliverToBoxAdapter(
                child: SizedBox(height: 110.0),
              ),
            ],
          ),

          // 2. Header Superior Dockable com Blur de Vidro e Selo Heisuca
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildDockableHeader(),
          ),
        ],
      ),
    );
  }

  Widget _buildDockableHeader() {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 6.0,
        bottom: 10.0,
        left: 20.0,
        right: 20.0,
      ),
      decoration: BoxDecoration(
        color: HeisucaTheme.roxoFundo.withOpacity(_headerOpacity * 0.88),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(_headerOpacity * 0.08),
            width: 0.8,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: _headerOpacity * 18.0,
            sigmaY: _headerOpacity * 18.0,
          ),
          child: Row(
            children: [
              // Selo Carmim & Tipografia Heisuca
              const HeisucaLogo(height: 28.0),
              const SizedBox(width: 12.0),

              // Chip de Status Discreto
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    const Text(
                      'ONLINE',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFFC7BED8),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Botão de Pesquisa Rápida
              HeisucaSpringPressable(
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
                  ),
                  child: const Center(
                    child: Icon(Symbols.search_rounded, color: Color(0xFFF4F1FA), size: 20.0),
                  ),
                ),
              ),

              const SizedBox(width: 12.0),

              // Avatar do Usuário (Abre Menu do Usuário)
              HeisucaSpringPressable(
                onTap: () => _openUserMenu(context),
                child: Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: HeisucaTheme.roxoPrimaria.withOpacity(0.8), width: 1.6),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C243B), Color(0xFF1B1526)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Symbols.person_rounded, color: Color(0xFFF4F1FA), size: 20.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = [
      ('Tudo', null),
      ('Filmes', CgflixChipKind.movies),
      ('Séries', CgflixChipKind.shows),
      ('Animes', CgflixChipKind.animes),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const HeisucaSpringPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: chips.map((chip) {
          final isSelected = (_currentFilter == null && chip.$2 == null) ||
              (_currentFilter?.kind == chip.$2);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: HeisucaSpringPressable(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (chip.$2 == null) {
                    _currentFilter = null;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? HeisucaTheme.roxoPrimaria.withOpacity(0.22)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                  border: Border.all(
                    color: isSelected
                        ? HeisucaTheme.roxoPrimaria.withOpacity(0.8)
                        : Colors.white.withOpacity(0.08),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  chip.$1,
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 13.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFFF4F1FA) : const Color(0xFFA99FBB),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCatalogRow(BuildContext context, CgflixRowData row) {
    if (row.items.isEmpty) return const SizedBox.shrink();

    final isContinueWatching = row.kind == CgflixRowKind.continueWatching;
    final isTrending = row.kind == CgflixRowKind.trending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da Seção
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Row(
              children: [
                Text(
                  row.title,
                  style: const TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Color(0xFFF4F1FA),
                  ),
                ),
                if (isTrending) ...[
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: HeisucaTheme.roxoSelo.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: HeisucaTheme.roxoSelo.withOpacity(0.4), width: 0.6),
                    ),
                    child: const Text(
                      'TOP 10',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF8B8B),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista Horizontal de Itens com Spring Physics
          SizedBox(
            height: isContinueWatching ? 148.0 : 185.0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const HeisucaSpringPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              itemCount: row.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12.0),
              itemBuilder: (ctx, idx) {
                final item = row.items[idx];
                return _buildItemCard(ctx, item, isContinueWatching: isContinueWatching, rank: isTrending ? idx + 1 : null);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    MediaItem item, {
    required bool isContinueWatching,
    int? rank,
  }) {
    final client = cgflixClientFor(context, item);
    final cardWidth = isContinueWatching ? 220.0 : 116.0;

    return HeisucaSpringPressable(
      onTap: () {
        HapticFeedback.lightImpact();
        cgflixOpenDetails(context, item);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showCgflixPreview(context, item);
      },
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pôster ou Thumbnail 16:9
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                      border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.75),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 8.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isContinueWatching
                        ? OptimizedMediaImage(
                            client: client,
                            imagePath: cgflixWidePath(item),
                            imageType: ImageType.thumb,
                            fit: BoxFit.cover,
                          )
                        : OptimizedMediaImage.poster(
                            client: client,
                            imagePath: cgflixPosterPath(item),
                            fit: BoxFit.cover,
                          ),
                  ),

                  // Ranking se for Top 10
                  if (rank != null)
                    Positioned(
                      bottom: 4,
                      left: 6,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTitulo,
                          fontSize: 38.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.85),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.9),
                              blurRadius: 8.0,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Barra de Progresso no Continuar Assistindo
                  if (isContinueWatching && item.viewOffsetMs != null && item.durationMs != null && item.durationMs! > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(HeisucaTheme.raioSquircle),
                          bottomRight: Radius.circular(HeisucaTheme.raioSquircle),
                        ),
                        child: LinearProgressIndicator(
                          value: (item.viewOffsetMs! / item.durationMs!).clamp(0.05, 0.98),
                          backgroundColor: Colors.black.withOpacity(0.6),
                          color: HeisucaTheme.roxoPrimaria,
                          minHeight: 3.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6.0),

            // Título do Card
            Text(
              item.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE4DFEE),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carrossel Hero com Efeito Halo Dinâmico OKLCH
class HeisucaHeroCarousel extends StatefulWidget {
  const HeisucaHeroCarousel({
    super.key,
    required this.highlight,
    required this.onPlay,
    required this.onDetails,
  });

  final MediaItem? highlight;
  final ValueChanged<MediaItem> onPlay;
  final ValueChanged<MediaItem> onDetails;

  @override
  State<HeisucaHeroCarousel> createState() => _HeisucaHeroCarouselState();
}

class _HeisucaHeroCarouselState extends State<HeisucaHeroCarousel> {
  Color _ambientHaloColor = const Color(0xFF7A40F2);

  @override
  Widget build(BuildContext context) {
    final highlight = widget.highlight;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.58).clamp(380.0, 540.0);
    final client = highlight != null ? cgflixClientFor(context, highlight) : null;
    final backdropPath = highlight != null ? cgflixWidePath(highlight) : null;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Halo Dinâmico OKLCH
          Positioned(
            top: 40.0,
            left: 20.0,
            right: 20.0,
            bottom: 60.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(120.0),
                boxShadow: [
                  BoxShadow(
                    color: _ambientHaloColor.withOpacity(0.26),
                    blurRadius: 90.0,
                    spreadRadius: 20.0,
                  ),
                ],
              ),
            ),
          ),

          // 2. Imagem Backdrop em Alta Fidelidade
          if (backdropPath != null && client != null)
            OptimizedMediaImage(
              client: client,
              imagePath: backdropPath,
              imageType: ImageType.backdrop,
              fit: BoxFit.cover,
            )
          else
            Container(color: HeisucaTheme.roxoFundo),

          // 3. Scrim Cúbico sem Mach Banding
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 0.75, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x330B0910),
                  Color(0xCC0B0910),
                  HeisucaTheme.roxoFundo,
                ],
              ),
            ),
          ),

          // 4. Conteúdo Sobreposto
          Positioned(
            left: 20.0,
            right: 20.0,
            bottom: 20.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título em Destaque
                Text(
                  highlight?.title ?? 'Destaque Heisuca',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 28.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Color(0xFFF4F1FA),
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 12.0,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10.0),

                // Pílulas de Metadados Técnicos com Números Tabulares
                Row(
                  children: [
                    _buildPill('4K HDR'),
                    const SizedBox(width: 6.0),
                    _buildPill('DOLBY ATMOS'),
                    const SizedBox(width: 6.0),
                    _buildPill('PT-BR'),
                    const SizedBox(width: 8.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.star_rounded, color: Color(0xFFFFB800), size: 16.0),
                        const SizedBox(width: 3.0),
                        Text(
                          highlight?.rating != null ? highlight!.rating!.toStringAsFixed(1) : '9.4',
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

                const SizedBox(height: 18.0),

                // Botões de Ação com Feedback de Mola
                Row(
                  children: [
                    // Botão Assistir
                    Expanded(
                      flex: 6,
                      child: HeisucaSpringPressable(
                        onTap: () {
                          if (highlight != null) widget.onPlay(highlight);
                        },
                        child: Container(
                          height: 46.0,
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
                            children: const [
                              Icon(Symbols.play_arrow_rounded, color: Colors.white, size: 22.0),
                              SizedBox(width: 6.0),
                              Text(
                                'Assistir',
                                style: TextStyle(
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

                    // Botão Detalhes
                    Expanded(
                      flex: 5,
                      child: HeisucaSpringPressable(
                        onTap: () {
                          if (highlight != null) widget.onDetails(highlight);
                        },
                        child: Container(
                          height: 46.0,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.14),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Symbols.info_rounded, color: Color(0xFFF4F1FA), size: 19.0),
                              SizedBox(width: 6.0),
                              Text(
                                'Detalhes',
                                style: TextStyle(
                                  fontFamily: HeisucaTheme.fonteTexto,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF4F1FA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: HeisucaTheme.fonteTexto,
          fontSize: 10.0,
          fontWeight: FontWeight.w700,
          color: Color(0xFFDCD7E8),
          letterSpacing: 0.4,
          fontFeatures: [ui.FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _HeisucaHomeSkeleton extends StatelessWidget {
  const _HeisucaHomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120.0,
                height: 16.0,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(height: 12.0),
              SizedBox(
                height: 160.0,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 12.0),
                  itemBuilder: (_, __) => Container(
                    width: 110.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
