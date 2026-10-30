import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../media/media_item.dart';
import '../../media/media_library.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/jellyfin_client.dart';
import '../../services/plex_client.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/video_player_navigation.dart';
import '../../widgets/optimized_media_image.dart';
import '../../cgflix/home/cgflix_home_logic.dart';
import '../../cgflix/home/cgflix_home_repository.dart';
import '../heisuca_plex_home_repository.dart';
import '../heisuca_theme.dart';
import 'heisuca_tv_header.dart';
import 'heisuca_tv_menu.dart';
import 'heisuca_tv_title_screen.dart';
import 'heisuca_tv_canvas.dart';

/// Início Flagship Heisuca na TV — Modelo A ("Destaque grande", estilo Apple TV).
/// - Destaque em tela cheia com arte de fundo e gradientes laterais/inferiores.
/// - Topo: Avatar e logo Heisuca no canto superior esquerdo (abre menu).
/// - Linha de destaque: "EM ALTA NO BRASIL · Nº 1", título grande, ano · classificação · duração · Dublado/Legendado.
/// - Sinopse curta (até 2 linhas).
/// - Botões de ação em pílula: [▶ Assistir] (foco inicial) e [Detalhes].
/// - Linha "Continuar assistindo" logo abaixo com cartões 16:9 widescreen e progresso.
/// - Demais fileiras do acervo ao rolar para baixo.
/// - Foco: contorno branco (3.5px) + escala ~1.06.
class HeisucaTvHomeScreen extends StatefulWidget {
  const HeisucaTvHomeScreen({
    super.key,
    this.heroItem,
    this.continueWatchingItems,
    this.onOpenMenu,
    this.onSelectDestination,
  });

  final MediaItem? heroItem;
  final List<MediaItem>? continueWatchingItems;
  final VoidCallback? onOpenMenu;
  final ValueChanged<String>? onSelectDestination;

  @override
  State<HeisucaTvHomeScreen> createState() => HeisucaTvHomeScreenState();
}

class HeisucaTvHomeScreenState extends State<HeisucaTvHomeScreen> {
  final _scrollController = ScrollController();
  final FocusNode heroPlayFocusNode = FocusNode();
  final FocusNode heroDetailsFocusNode = FocusNode();
  final FocusNode avatarFocusNode = FocusNode();

  MediaItem? _activeHero;
  List<MediaItem> _continueWatching = const [];
  List<MediaItem> _trending = const [];
  List<MediaLibrary> _libraries = const [];
  final Map<String, List<MediaItem>> _libraryItems = {};

  HeisucaHomeRepository? _repository;

  @override
  void initState() {
    super.initState();
    if (widget.heroItem != null) {
      _activeHero = widget.heroItem;
      _continueWatching = widget.continueWatchingItems ?? const [];
    } else {
      _initRepository();
    }
  }

  @override
  void didUpdateWidget(HeisucaTvHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.heroItem != null) {
      _activeHero = widget.heroItem;
      _continueWatching = widget.continueWatchingItems ?? const [];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    heroPlayFocusNode.dispose();
    heroDetailsFocusNode.dispose();
    avatarFocusNode.dispose();
    _repository?.dispose();
    super.dispose();
  }

  void scrollToDestaqueAndFocus() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    heroPlayFocusNode.requestFocus();
  }

  bool get isAtHeroDestaque {
    return heroPlayFocusNode.hasFocus || heroDetailsFocusNode.hasFocus || avatarFocusNode.hasFocus;
  }

  void _initRepository() {
    final servers = context.read<MultiServerProvider?>();
    final client = servers?.serverManager.navigationOnlineClients.values.firstOrNull;
    final feeds = servers?.serverManager.visibleOnlineClients.values.whereType<JellyfinClient>().toList() ?? const [];

    _repository?.dispose();
    _repository = switch (client) {
      final JellyfinClient jf => CgflixHomeRepository(jf),
      final PlexClient plex => HeisucaPlexHomeRepository(plex, feedClients: feeds),
      _ => null,
    };

    if (_repository != null) {
      _loadData(_repository!);
    }
  }

  Future<void> _loadData(HeisucaHomeRepository repo) async {
    try {
      // 1. Hero
      final heroRow = await repo.watchHero().first.timeout(const Duration(seconds: 4));
      if (mounted && heroRow.items.isNotEmpty) {
        setState(() => _activeHero = heroRow.items.first);
      }

      // 2. Continuar assistindo
      final cwRow = await repo.watchRow(CgflixRowKind.continueWatching).first.timeout(const Duration(seconds: 4));
      if (mounted) setState(() => _continueWatching = cwRow.items);

      // 3. Trending
      final trendingRow = await repo.watchTrending().first.timeout(const Duration(seconds: 4));
      if (mounted) setState(() => _trending = trendingRow.items);

      // 4. Bibliotecas
      final libs = await repo.videoLibraries().timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() => _libraries = libs);
        for (final lib in libs) {
          final libRow = await repo.watchLibrary(lib).first.timeout(const Duration(seconds: 4));
          if (mounted) {
            setState(() => _libraryItems[lib.id] = libRow.items);
          }
        }
      }
    } catch (_) {
      // Ignora falhas de rede em testes/offline
    }
  }

  void _playItem(MediaItem item) {
    navigateToVideoPlayer(context, metadata: item);
  }

  void _openDetails(MediaItem item) {
    HeisucaTvTitleScreen.show(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final hero = _activeHero ?? widget.heroItem;

    return HeisucaTvCanvas(
      child: Scaffold(
      backgroundColor: const Color(0xFF17151C), // BG
      body: Stack(
        children: [
          // 1. Fundo do Destaque (Arte de fundo em tela cheia com gradientes)
          if (hero != null)
            Positioned.fill(
              child: _TvHeroBackdrop(item: hero),
            ),

          // 2. Conteúdo rolável: Hero + Continuar + Fileiras
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 1080,
                  child: Stack(
                    children: [
                      // Header: Avatar e Logo
                      Positioned(
                        top: 0,
                        left: 0,
                        child: HeisucaTvHeader(
                          focusNode: avatarFocusNode,
                          onOpenMenu: widget.onOpenMenu ?? () {
                            HeisucaTvMenu.show(
                              context,
                              onSelectDestination: (dest) {
                                widget.onSelectDestination?.call(dest);
                              },
                            );
                          },
                        ),
                      ),

                      // Informações do Destaque
                      if (hero != null)
                        Positioned(
                          left: 48,
                          bottom: 270,
                          right: 600,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'EM ALTA NO BRASIL · Nº 1',
                                style: TextStyle(
                                  fontFamily: HeisucaTheme.fonteTexto,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.0,
                                  color: const Color(0xFFC7BBD4), // AC
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                hero.displayTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: HeisucaTheme.fonteTitulo,
                                  fontSize: 64,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  color: const Color(0xFFF2EFF5), // TX
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildMetadataLine(hero),
                              const SizedBox(height: 16),
                              if (hero.summary?.isNotEmpty == true)
                                Text(
                                  hero.summary!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: HeisucaTheme.fonteTexto,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                    color: const Color(0xFFE2DDE7),
                                  ),
                                ),
                              const SizedBox(height: 28),
                              // Botões [Assistir] e [Detalhes]
                              Row(
                                children: [
                                  _TvButtonPill(
                                    key: const Key('heisuca-tv-hero-play'),
                                    focusNode: heroPlayFocusNode,
                                    autofocus: true,
                                    text: '▶  Assistir',
                                    isPrimary: true,
                                    onTap: () => _playItem(hero),
                                  ),
                                  const SizedBox(width: 24),
                                  _TvButtonPill(
                                    key: const Key('heisuca-tv-hero-details'),
                                    focusNode: heroDetailsFocusNode,
                                    text: 'Detalhes',
                                    isPrimary: false,
                                    onTap: () => _openDetails(hero),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Fileira Continuar Assistindo (logo abaixo do destaque)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                'Continuar assistindo',
                                style: TextStyle(
                                  fontFamily: HeisucaTheme.fonteTitulo,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF2EFF5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildContinueWatchingRow(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Demais Fileiras do Acervo ao rolar para baixo
              if (_trending.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 36, bottom: 20),
                    child: _TvMediaRow(
                      title: 'Em alta no Heisuca',
                      items: _trending,
                      onItemTap: _openDetails,
                    ),
                  ),
                ),

              for (final lib in _libraries)
                if ((_libraryItems[lib.id]?.isNotEmpty ?? false))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 20),
                      child: _TvMediaRow(
                        title: lib.title,
                        items: _libraryItems[lib.id]!,
                        onItemTap: _openDetails,
                      ),
                    ),
                  ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildMetadataLine(MediaItem item) {
    final parts = <String>[];
    if (item.year != null) parts.add('${item.year}');
    if (item.rating != null) parts.add('${item.rating}');
    if (item.durationMs != null && item.durationMs! > 0) {
      final totalMin = item.durationMs! ~/ 60000;
      final h = totalMin ~/ 60;
      final m = totalMin % 60;
      parts.add(h > 0 ? '$h h ${m.toString().padLeft(2, '0')}' : '$m min');
    }
    parts.add('Dublado');

    return Text(
      parts.join(' · '),
      style: TextStyle(
        fontFamily: HeisucaTheme.fonteTexto,
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFCFC8D8), // TX2
      ),
    );
  }

  Widget _buildContinueWatchingRow() {
    final items = _continueWatching.isNotEmpty
        ? _continueWatching
        : (widget.continueWatchingItems ?? const []);

    if (items.isEmpty) {
      return Container(
        key: const Key('heisuca-tv-continue-row'),
        height: 225,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Text(
          'Nenhum item em andamento',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return SizedBox(
      key: const Key('heisuca-tv-continue-row'),
      height: 225,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final item = items[index];
          return _TvContinueCard(
            item: item,
            onTap: () => _playItem(item),
          );
        },
      ),
    );
  }
}

/// Cartão 16:9 Widescreen para Continuar Assistindo na TV
class _TvContinueCard extends StatefulWidget {
  const _TvContinueCard({
    required this.item,
    required this.onTap,
  });

  final MediaItem item;
  final VoidCallback onTap;

  @override
  State<_TvContinueCard> createState() => _TvContinueCardState();
}

class _TvContinueCardState extends State<_TvContinueCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final progress = (item.durationMs != null && item.durationMs! > 0 && item.viewOffsetMs != null)
        ? (item.viewOffsetMs! / item.durationMs!).clamp(0.0, 1.0)
        : 0.35;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _focused ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 400,
            height: 225,
            decoration: BoxDecoration(
              color: const Color(0xFF292531),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused ? Colors.white : Colors.white.withValues(alpha: 0.1),
                width: _focused ? 3.5 : 1.0,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.thumbPath != null || item.artPath != null)
                  OptimizedMediaImage(
                    imagePath: item.thumbPath ?? item.artPath,
                    imageType: ImageType.thumb,
                    fit: BoxFit.cover,
                  )
                else
                  Container(color: const Color(0xFF3B3346)),

                // Gradiente escuro inferior para leitura
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                      stops: [0.5, 1.0],
                    ),
                  ),
                ),

                // Título e Temporada/Episódio
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE2DDE7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Barra de Progresso
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC7BBD4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fundo em tela cheia com arte e gradientes escuros
class _TvHeroBackdrop extends StatelessWidget {
  const _TvHeroBackdrop({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final imagePath = item.artPath ?? item.thumbPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath != null)
          OptimizedMediaImage(
            imagePath: imagePath,
            imageType: ImageType.art,
            fit: BoxFit.cover,
          )
        else
          Container(color: const Color(0xFF3A3346)),

        // Gradiente da esquerda (escurece onde fica o texto e botões)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xF717151C), // 97% opacidade
                Color(0xBF17151C), // 75%
                Color(0x0D17151C), // 5%
              ],
              stops: [0.0, 0.45, 0.85],
            ),
          ),
        ),

        // Gradiente de baixo (funde com a área de rolagem inferior)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xFF17151C),
                Color(0x0017151C),
              ],
              stops: [0.0, 0.5],
            ),
          ),
        ),
      ],
    );
  }
}

/// Botão em pílula com contorno branco e escala no foco
class _TvButtonPill extends StatefulWidget {
  const _TvButtonPill({
    super.key,
    required this.text,
    required this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.isPrimary = true,
  });

  final String text;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isPrimary;

  @override
  State<_TvButtonPill> createState() => _TvButtonPillState();
}

class _TvButtonPillState extends State<_TvButtonPill> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _focused;

    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: active ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : widget.isPrimary
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: active ? Colors.white : Colors.transparent,
                width: 3.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 26,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? const Color(0xFF17151C) : const Color(0xFFF2EFF5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fileira horizontal de itens do acervo para TV
class _TvMediaRow extends StatelessWidget {
  const _TvMediaRow({
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  final String title;
  final List<MediaItem> items;
  final ValueChanged<MediaItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: HeisucaTheme.fonteTitulo,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF2EFF5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final item = items[index];
              return _TvPosterCard(
                item: item,
                onTap: () => onItemTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TvPosterCard extends StatefulWidget {
  const _TvPosterCard({
    required this.item,
    required this.onTap,
  });

  final MediaItem item;
  final VoidCallback onTap;

  @override
  State<_TvPosterCard> createState() => _TvPosterCardState();
}

class _TvPosterCardState extends State<_TvPosterCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _focused ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 180,
            height: 270,
            decoration: BoxDecoration(
              color: const Color(0xFF292531),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused ? Colors.white : Colors.transparent,
                width: _focused ? 3.5 : 0.0,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: (item.thumbPath != null || item.artPath != null)
                ? OptimizedMediaImage(
                    imagePath: item.thumbPath ?? item.artPath,
                    imageType: ImageType.poster,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: const Color(0xFF3B3346),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      item.displayTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
