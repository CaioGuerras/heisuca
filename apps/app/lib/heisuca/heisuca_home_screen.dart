import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../cgflix/cgflix_palette.dart';
import '../cgflix/cgflix_style.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../cgflix/home/cgflix_cards.dart';
import '../cgflix/home/cgflix_home_logic.dart';
import '../cgflix/home/cgflix_home_repository.dart';
import '../cgflix/home/cgflix_preview_sheet.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../providers/active_profile_provider.dart';
import '../providers/multi_server_provider.dart';
import '../utils/app_logger.dart';
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const HeisucaUserSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<CgflixHomeRepository>();
    final highlight = repo.highlight;
    final rows = repo.rows;

    return Scaffold(
      backgroundColor: HeisucaTheme.shikkoku,
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
                  onPlay: (item) => cgflixOpenItem(context, item, playDirectly: true),
                  onDetails: (item) => cgflixOpenItem(context, item),
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
        color: HeisucaTheme.shikkoku.withOpacity(_headerOpacity * 0.88),
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
                        color: Color(0xFF34D399), // Verde suave online
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
                  // Navegação rápida para busca se disponível
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
                  } else {
                    // Seleciona filtro
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
                      color: HeisucaTheme.vermelhoSelo.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: HeisucaTheme.vermelhoSelo.withOpacity(0.4), width: 0.6),
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
    final client = context.read<MultiServerProvider>().getClientForServer(item.serverId);
    final cardWidth = isContinueWatching ? 220.0 : 116.0;

    return HeisucaSpringPressable(
      onTap: () {
        HapticFeedback.lightImpact();
        cgflixOpenItem(context, item);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        cgflixOpenPreviewSheet(context, item);
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
                    child: client == null
                        ? Container(color: HeisucaTheme.superficieElevada)
                        : OptimizedMediaImage(
                            imageUrl: isContinueWatching
                                ? (item.backdropUrl(client) ?? item.posterUrl(client))
                                : item.posterUrl(client),
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
                  if (isContinueWatching && item.playbackPositionTicks != null)
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
                          value: (item.playbackPositionTicks! / (item.runtimeTicks ?? 1)).clamp(0.05, 0.98),
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
              item.title,
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
  // Cor ambiente padrão (Roxo Heisuca) quando ainda não extraído
  Color _ambientHaloColor = const Color(0xFF7A40F2);

  @override
  Widget build(BuildContext context) {
    final highlight = widget.highlight;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.58).clamp(380.0, 540.0);
    final client = highlight != null
        ? context.read<MultiServerProvider>().getClientForServer(highlight.serverId)
        : null;

    final backdropUrl = (highlight != null && client != null)
        ? highlight.backdropUrl(client)
        : null;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Halo Dinâmico OKLCH (Iluminação volumétrica ambiente atrás da imagem)
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
          if (backdropUrl != null)
            Image.network(
              backdropUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: HeisucaTheme.shikkoku),
            )
          else
            Container(color: HeisucaTheme.shikkoku),

          // 3. Scrim Cúbico sem Mach Banding (Gradiente de profundidade suave para o preto)
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
                  HeisucaTheme.shikkoku,
                ],
              ),
            ),
          ),

          // 4. Conteúdo Sobreposto (Título, Badges, Botões de Ação)
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
                      children: const [
                        Icon(Symbols.star_rounded, color: Color(0xFFFFB800), size: 16.0),
                        SizedBox(width: 3.0),
                        Text(
                          '9.4',
                          style: TextStyle(
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
                    // Botão Assistir (Primário Roxo Flagship)
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

                    // Botão Detalhes / Ficha (Secundário Vidro Fosco)
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

/// Menu do Usuário (Bottom Sheet Deslizante com Blur e Vidro Fosco)
class HeisucaUserSheet extends StatelessWidget {
  const HeisucaUserSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ActiveProfileProvider>().activeProfile;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13101C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.8),
      ),
      padding: EdgeInsets.only(
        top: 14.0,
        bottom: MediaQuery.paddingOf(context).bottom + 20.0,
        left: 20.0,
        right: 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pílula central de arraste
          Center(
            child: Container(
              width: 38.0,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(3.0),
              ),
            ),
          ),

          const SizedBox(height: 20.0),

          // Header do Perfil Ativo
          Row(
            children: [
              Container(
                width: 52.0,
                height: 52.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: HeisucaTheme.roxoPrimaria, width: 2.0),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF382C4D), Color(0xFF1E172A)],
                  ),
                ],
                child: const Center(
                  child: Icon(Symbols.person_rounded, color: Colors.white, size: 28.0),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? 'Caio Guerras',
                      style: const TextStyle(
                        fontFamily: HeisucaTheme.fonteTitulo,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF4F1FA),
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Row(
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
                          'CGFLIX Pro • 12ms',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTexto,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFA99FBB),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22.0),

          // Card de Armazenamento Local / Offline
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
              border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Armazenamento Offline',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDCD7E8),
                      ),
                    ),
                    Text(
                      '18.4 GB usados',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 11.5,
                        color: Color(0xFFA99FBB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: 0.28,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    color: HeisucaTheme.roxoPrimaria,
                    minHeight: 5.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18.0),

          // Ações do Menu
          _buildMenuAction(
            icon: Symbols.settings_rounded,
            title: 'Configurações do App',
            subtitle: 'Calibração de hardware, vídeo e áudio',
            onTap: () {
              Navigator.pop(context);
              // Abrir aba ou tela de configurações
            },
          ),
          _buildMenuAction(
            icon: Symbols.switch_account_rounded,
            title: 'Trocar Perfil',
            subtitle: 'Alternar usuário ou gerenciar contas',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildMenuAction(
            icon: Symbols.logout_rounded,
            title: 'Desconectar do Servidor',
            subtitle: 'Voltar para a tela de conexão inicial',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildMenuAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: HeisucaSpringPressable(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
            border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.6),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? const Color(0xFFFF6E6E) : const Color(0xFFF4F1FA),
                size: 22.0,
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? const Color(0xFFFF8B8B) : const Color(0xFFF4F1FA),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.chevron_right_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 18.0,
              ),
            ],
          ),
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
