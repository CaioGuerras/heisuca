// Início Flagship Heisuca (Esboço 03B) no celular Android:
// - Topo oficial com logo 炳 HEISUCA colado à esquerda e busca à direita
// - Hero Cinematográfico Edge-to-Edge com Scrim Easing Cúbico (sem faixas divisórias)
//   e ZERO botões de cápsula sobre a arte (toque no hero abre a Ficha Técnica)
// - Fileira 1: Continuar Assistindo em proporção 16:9 com barra de progresso e play
// - Fileira 2: Em alta no Brasil (Top 10) com números grandes vazados no canto inferior esquerdo
// - Fileiras de Acervo: Lançamentos, Novidades em Filmes, Séries, Animes ou Hubs do Plex
// - Suporte unificado: Jellyfin e Plex operam com visual 100% Heisuca (zero telas legadas)
// - Menu de Toque Longo (500ms + haptics) para ações rápidas (Esboço 04B)
// - Espaçamento inferior calibrado para a Ilha Flutuante (HeisucaFloatingIsland)
import 'dart:async';
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../cgflix/cgflix_detail.dart';
import '../cgflix/cgflix_layout.dart';
import '../cgflix/cgflix_navigation.dart';
import '../cgflix/cgflix_palette.dart';
import '../cgflix/cgflix_style.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../cgflix/home/cgflix_cards.dart';
import '../cgflix/home/cgflix_home_logic.dart';
import '../cgflix/home/cgflix_home_repository.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../mixins/refreshable.dart';
import '../mixins/tab_visibility_aware.dart';
import '../providers/discover_provider.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../services/jellyfin_client.dart';
import '../services/watch_actions.dart';
import '../utils/download_utils.dart';
import '../utils/media_image_helper.dart';
import '../widgets/optimized_media_image.dart';
import 'heisuca_context_menu.dart';
import 'heisuca_design_system.dart';
import 'heisuca_logo.dart';
import 'heisuca_theme.dart';
import 'heisuca_title_sheet.dart';

class HeisucaHomeScreen extends StatefulWidget {
  const HeisucaHomeScreen({super.key});

  @override
  State<HeisucaHomeScreen> createState() => _HeisucaHomeScreenState();
}

class _HeisucaHomeScreenState extends State<HeisucaHomeScreen>
    with Refreshable, FullRefreshable, TabVisibilityAware, WidgetsBindingObserver {
  final _scrollController = ScrollController();
  late final DiscoverProvider _discover;
  late final MultiServerProvider _servers;

  JellyfinClient? _client;
  CgflixHomeRepository? _repository;
  bool _tabVisible = true;
  bool _appActive = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _discover = context.read<DiscoverProvider>();
    _servers = context.read<MultiServerProvider>();
    _discover.addListener(_onChanged);
    _servers.addListener(_onServersChanged);
    _onServersChanged();
    unawaited(_discover.load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _discover.removeListener(_onChanged);
    _servers.removeListener(_onServersChanged);
    _repository?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onServersChanged() {
    final client = _servers.serverManager.visibleOnlineClients.values
        .whereType<JellyfinClient>()
        .firstOrNull;
    final same = client != null &&
        _client != null &&
        client.serverId == _client!.serverId &&
        client.cgflixUserId == _client!.cgflixUserId;

    if (same || (client == null && _client == null)) {
      _onChanged();
      return;
    }

    _repository?.dispose();
    _client = client;
    _repository = client == null ? null : CgflixHomeRepository(client);
    _onChanged();
  }

  @override
  void refresh() {
    if (_discover.refreshIfStale()) return;
    unawaited(_discover.refreshContinueWatching());
  }

  @override
  void fullRefresh() {
    unawaited(_discover.load());
    if (mounted) setState(() => _generation++);
  }

  @override
  void primeRefresh() {
    if (_discover.isLoadInFlight) return;
    fullRefresh();
  }

  @override
  void onTabShown() {
    setState(() => _tabVisible = true);
    _discover.refreshIfStale();
  }

  @override
  void onTabHidden() {
    setState(() => _tabVisible = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active != _appActive) setState(() => _appActive = active);
    if (active) unawaited(_discover.refreshContinueWatching());
  }

  Future<void> _pullToRefresh() async {
    _repository?.forgetMemory();
    setState(() => _generation++);
    await Future.wait([
      _discover.refreshNow(),
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final heroHeight = (media.size.height * 0.54).clamp(380.0, 560.0);
    final repo = _repository;

    return Scaffold(
      backgroundColor: context.cgflix.background,
      body: Stack(
        children: [
          // Conteúdo rolável com indicador de atualização e física ProMotion
          RefreshIndicator(
            color: context.cgflix.accent,
            backgroundColor: context.cgflix.surface,
            edgeOffset: media.padding.top + 56,
            onRefresh: _pullToRefresh,
            child: CustomScrollView(
              key: const PageStorageKey('heisuca-home-scroll'),
              controller: _scrollController,
              physics: const ProMotionScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: repo != null
                  ? _buildJellyfinSlivers(repo, heroHeight)
                  : _buildDiscoverSlivers(heroHeight),
            ),
          ),

          // Topo oficial Heisuca (Logo à esquerda, Busca à direita)
          _HeisucaTopBar(scrollController: _scrollController),
        ],
      ),
    );
  }

  // --- Construção do acervo Jellyfin -----------------------------------------

  List<Widget> _buildJellyfinSlivers(CgflixHomeRepository repo, double heroHeight) {
    final key = '${repo.client.serverId.value}:$_generation';
    return [
      // 1. Hero Cinematográfico (Esboço 03B)
      SliverToBoxAdapter(
        child: _StreamSection<CgflixRowData>(
          key: ValueKey('hero:$key'),
          stream: () => repo.watchHero(),
          loading: _HeroSkeleton(height: heroHeight),
          failed: const _HomeLoadFailed(),
          builder: (data) => data.items.isEmpty
              ? SizedBox(height: MediaQuery.paddingOf(context).top + 72)
              : _HeisucaHero(
                  items: data.items,
                  height: heroHeight,
                  paused: !_tabVisible || !_appActive,
                ),
        ),
      ),

      // 2. Fileira 1: Continuar Assistindo (16:9 Widescreen)
      SliverToBoxAdapter(
        child: _ContinueWatchingStreamRow(
          key: ValueKey('continue:$key'),
          discover: _discover,
          repository: repo,
        ),
      ),

      // 3. Fileira 2: Em alta no Brasil (Top 10)
      SliverToBoxAdapter(
        child: _StreamSection<CgflixRowData>(
          key: ValueKey('trending:$key'),
          stream: () => repo.watchTrending(),
          loading: const CgflixSkeletonRow(),
          builder: (data) => _HeisucaTop10Row(items: data.items),
        ),
      ),

      // 4. Fileiras Fixas do Acervo Heisuca (Lançamentos, Filmes, Séries, Animes)
      for (final kind in cgflixFixedRowOrder.skip(2))
        SliverToBoxAdapter(
          child: _StreamSection<CgflixRowData>(
            key: ValueKey('${kind.name}:$key'),
            stream: () => repo.watchRow(kind),
            loading: const CgflixSkeletonRow(),
            builder: (data) => _HeisucaShelfRow(
              title: cgflixRowTitle(kind),
              items: data.items,
              storageKey: kind.name,
            ),
          ),
        ),

      // 5. Linhas por Gênero sob demanda
      _GenreRows(key: ValueKey('genres:$key'), repository: repo),

      // Folga no rodapé para não ficar sob a Ilha Flutuante (64dp + 14dp)
      SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 96)),
    ];
  }

  // --- Construção do acervo Plex / DiscoverProvider ---------------------------

  List<Widget> _buildDiscoverSlivers(double heroHeight) {
    final heroItems = _discover.onDeck.isNotEmpty
        ? _discover.onDeck.take(5).toList()
        : (_discover.hubs.isNotEmpty ? _discover.hubs.first.items.take(5).toList() : <MediaItem>[]);

    // Hubs adicionais (excluindo o Continue Watching se presente nos hubs)
    final otherHubs = _discover.hubs.where((h) => !h.isContinueWatchingHub).toList();
    final top10Items = otherHubs.isNotEmpty ? otherHubs.first.items.take(10).toList() : <MediaItem>[];
    final remainingHubs = otherHubs.length > 1 ? otherHubs.skip(1).toList() : const [];

    return [
      // 1. Hero Cinematográfico (Esboço 03B)
      if (heroItems.isNotEmpty)
        SliverToBoxAdapter(
          child: _HeisucaHero(
            items: heroItems,
            height: heroHeight,
            paused: !_tabVisible || !_appActive,
          ),
        )
      else if (_discover.isLoading)
        SliverToBoxAdapter(child: _HeroSkeleton(height: heroHeight)),

      // 2. Fileira 1: Continuar Assistindo (16:9 Widescreen)
      if (_discover.onDeck.isNotEmpty)
        SliverToBoxAdapter(
          child: _HeisucaContinueWatchingRow(items: _discover.onDeck),
        ),

      // 3. Fileira 2: Em alta no Brasil (Top 10)
      if (top10Items.isNotEmpty)
        SliverToBoxAdapter(
          child: _HeisucaTop10Row(items: top10Items),
        ),

      // 4. Fileiras das Bibliotecas / Hubs do Plex
      for (final hub in remainingHubs)
        if (hub.items.isNotEmpty)
          SliverToBoxAdapter(
            child: _HeisucaShelfRow(
              title: _cleanHubTitle(hub.title),
              items: hub.items,
              storageKey: 'hub_${hub.id}',
            ),
          ),

      if (_discover.isLoading && _discover.hubs.isEmpty && _discover.onDeck.isEmpty) ...[
        SliverToBoxAdapter(child: _HeroSkeleton(height: heroHeight)),
        const SliverToBoxAdapter(child: CgflixSkeletonRow(wide: true)),
        const SliverToBoxAdapter(child: CgflixSkeletonRow()),
      ],

      // Folga no rodapé para não ficar sob a Ilha Flutuante (64dp + 14dp)
      SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 96)),
    ];
  }

  /// Limpa e humaniza títulos brutos de hubs do Plex
  String _cleanHubTitle(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('recently added movies') || lower == 'filmes recentes') {
      return 'Novidades em filmes';
    }
    if (lower.contains('recently added television') || lower.contains('recently added shows') || lower == 'séries recentes') {
      return 'Novidades em séries';
    }
    if (lower.contains('recently released movies')) {
      return 'Lançamentos';
    }
    return raw;
  }
}

// -----------------------------------------------------------------------------
// TopBar Heisuca (Esboço 03B: 炳 HEISUCA à esquerda, Busca à direita)

class _HeisucaTopBar extends StatefulWidget {
  const _HeisucaTopBar({required this.scrollController});
  final ScrollController scrollController;

  @override
  State<_HeisucaTopBar> createState() => _HeisucaTopBarState();
}

class _HeisucaTopBarState extends State<_HeisucaTopBar> {
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_HeisucaTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final offset = widget.scrollController.offset;
    if ((offset - _scrollOffset).abs() > 4.0) {
      setState(() => _scrollOffset = offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final isScrolled = _scrollOffset > 24.0;
    final palette = context.cgflix;
    final isLight = palette.isLight;

    final bgColor = isScrolled
        ? (isLight
            ? const Color(0xFFF7F3EC).withValues(alpha: 0.88)
            : const Color(0xFF0E0B14).withValues(alpha: 0.82))
        : Colors.transparent;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: isScrolled
              ? ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0)
              : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: bgColor,
            padding: EdgeInsets.fromLTRB(16.0 + padding.left, padding.top + 6.0, 16.0 + padding.right, 10.0),
            child: Row(
              children: [
                // Marca HEISUCA colada ao selo carmim no canto superior esquerdo
                const HeisucaLogo(height: 28, comSlogan: false),
                const Spacer(),
                // Ícone de Busca discreto à direita
                IconButton(
                  icon: Icon(
                    Symbols.search_rounded,
                    color: isLight ? const Color(0xFF164E3E) : const Color(0xFFF4F1FA),
                    size: 24.0,
                  ),
                  tooltip: 'Buscar',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    cgflixOpenSearch(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Hero Cinematográfico Heisuca (Esboço 03B)
// ZERO botões de cápsula sobre a arte. Toque abre a Ficha Técnica.
// Título centralizado, metadados nobres, sinopse de 2 linhas iniciada por 「Título」.

class _HeisucaHero extends StatefulWidget {
  const _HeisucaHero({
    required this.items,
    required this.height,
    this.paused = false,
  });

  final List<MediaItem> items;
  final double height;
  final bool paused;

  @override
  State<_HeisucaHero> createState() => _HeisucaHeroState();
}

class _HeisucaHeroState extends State<_HeisucaHero> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_HeisucaHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.items.length) _currentIndex = 0;
    if (oldWidget.paused != widget.paused || oldWidget.items.length != widget.items.length) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.paused || widget.items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && widget.items.isNotEmpty) {
        setState(() => _currentIndex = (_currentIndex + 1) % widget.items.length);
      }
    });
  }

  void _onSlideChanged(int delta) {
    if (widget.items.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = (_currentIndex + delta + widget.items.length) % widget.items.length;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return SizedBox(height: widget.height);
    final item = widget.items[_currentIndex % widget.items.length];
    final client = cgflixClientFor(context, item);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final palette = context.cgflix;
    final isLight = palette.isLight;
    final artCandidates = item.heroArtCandidates(containerAspectRatio: screenWidth / widget.height);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        HeisucaTitleSheet.show(context, item);
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -200) _onSlideChanged(1);
        if (velocity > 200) _onSlideChanged(-1);
      },
      child: SizedBox(
        height: widget.height,
        width: screenWidth,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Imagem de Fundo com Transição Suave
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey('hero_art_${item.globalKey}'),
                child: OptimizedMediaImage(
                  client: client,
                  imagePath: artCandidates.isNotEmpty ? artCandidates.first : null,
                  width: screenWidth,
                  height: widget.height,
                  imageType: ImageType.art,
                  fadeInDuration: const Duration(milliseconds: 300),
                ),
              ),
            ),

            // 2. Scrim Zenital Superior (protege o topo oficial)
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 120.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.background.withValues(alpha: isLight ? 0.70 : 0.85),
                        palette.background.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Scrim Easing Cúbico de 9 paradas (Hermite Smoothstep - zero faixas duras)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: CubicScrimGradient.create(
                    baseColor: palette.background,
                    begin: const Alignment(0.0, -0.05),
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 4. Halo Atmosférico em OKLCH na base
            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 180.0,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 0.95),
                      radius: 1.2,
                      colors: [
                        OklchColor.fromColor(palette.accent)
                            .toCalibratedAmbientColor(isDarkTheme: !isLight)
                            .withValues(alpha: isLight ? 0.18 : 0.30),
                        palette.background.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 5. Informações Nobres Centralizadas (Esboço 03B)
            Positioned(
              left: 20.0,
              right: 20.0,
              bottom: 18.0,
              child: _HeroInformationBlock(
                item: item,
                client: client,
                totalDots: widget.items.length,
                activeDotIndex: _currentIndex,
                onDotSelected: (idx) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = idx);
                  _startTimer();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroInformationBlock extends StatelessWidget {
  const _HeroInformationBlock({
    required this.item,
    required this.client,
    required this.totalDots,
    required this.activeDotIndex,
    required this.onDotSelected,
  });

  final MediaItem item;
  final dynamic client;
  final int totalDots;
  final int activeDotIndex;
  final ValueChanged<int> onDotSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final isLight = palette.isLight;
    final year = item.year?.toString() ?? '';
    final rating = item.rating != null && item.rating! > 0 ? item.rating!.toStringAsFixed(1) : '';
    final genres = (item.genres ?? const <String>[]).take(2).join(' · ');
    final badges = _extractBadges(item);

    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final textMutedColor = isLight ? const Color(0xFF334155) : const Color(0xFFA99FBB);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ClearLogo ou Título estilizado em Sora bold
        ClearLogoImage(
          client: client,
          logoPath: item.clearLogoPath,
          width: 260.0,
          height: 72.0,
          fallbackWidth: 320.0,
          alignment: Alignment.bottomCenter,
          logoToneTarget: isLight ? const Color(0xFF134E4A) : null,
          fallbackBuilder: (ctx) => Text(
            item.displayTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: HeisucaTheme.fonteTitulo,
              fontSize: 24.0,
              fontWeight: FontWeight.w800,
              color: titleColor,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(height: 8.0),

        // Linha Única de Metadados: ★ 8,9 · Ano · Gênero · Classificação
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rating.isNotEmpty) ...[
              const Icon(Icons.star_rounded, size: 16.0, color: Color(0xFFFFC107)),
              const SizedBox(width: 3.0),
              Text(
                rating,
                style: TextStyle(
                  fontFamily: HeisucaTheme.fonteTexto,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              _buildBullet(textMutedColor),
            ],
            if (year.isNotEmpty) ...[
              Text(
                year,
                style: TextStyle(
                  fontFamily: HeisucaTheme.fonteTexto,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: textMutedColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (genres.isNotEmpty || badges.isNotEmpty) _buildBullet(textMutedColor),
            ],
            if (genres.isNotEmpty) ...[
              Flexible(
                child: Text(
                  genres,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textMutedColor,
                  ),
                ),
              ),
            ],
            for (final b in badges.take(1)) ...[
              _buildBullet(textMutedColor),
              HeisucaNobleBadge(label: b),
            ],
          ],
        ),

        const SizedBox(height: 8.0),

        // Sinopse de 2 linhas iniciando por 「Título」 em negrito
        if (item.summary != null && item.summary!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '「${item.displayTitle}」 ',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTitulo,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: titleColor,
                    ),
                  ),
                  TextSpan(
                    text: item.summary!.replaceAll('\n', ' ').trim(),
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontWeight: FontWeight.w400,
                      fontSize: 12.0,
                      height: 1.35,
                      color: textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 14.0),

        // Indicador de Carrossel (Page Indicator Dots)
        if (totalDots > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalDots, (index) {
              final isSelected = index == activeDotIndex;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onDotSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3.5),
                  width: isSelected ? 18.0 : 6.0,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isSelected ? palette.accent : (isLight ? Colors.black26 : Colors.white24),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  static Widget _buildBullet(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Text('·', style: TextStyle(color: color, fontSize: 13.0, fontWeight: FontWeight.bold)),
    );
  }

  List<String> _extractBadges(MediaItem item) {
    final badges = <String>[];
    final res = item.mediaVersions?.firstOrNull?.videoResolution?.toUpperCase() ?? '';
    if (res.contains('4K') || res.contains('2160')) {
      badges.add('4K UHD');
    } else if (res.contains('1080')) {
      badges.add('1080p');
    }
    return badges;
  }
}

// -----------------------------------------------------------------------------
// Fileira 1: Continuar Assistindo (Proporção 16:9 Widescreen)

class _HeisucaContinueWatchingRow extends StatelessWidget {
  const _HeisucaContinueWatchingRow({required this.items});
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
            child: Text(
              'Continuar assistindo',
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTitulo,
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: context.cgflix.isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA),
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(
            height: cgflixWideHeight + CgflixWideCard.titleBlockHeight,
            child: ListView.separated(
              key: const PageStorageKey('heisuca-continue-watching-list'),
              physics: const ProMotionScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12.0),
              itemBuilder: (ctx, index) {
                final item = items[index];
                return CgflixWideCard(
                  item: item,
                  client: cgflixClientFor(ctx, item),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    cgflixPlay(ctx, item);
                  },
                  onLongPress: () {
                    HeisucaContextMenu.show(
                      ctx,
                      item: item,
                      isContinueRow: true,
                      onPlay: () => cgflixPlay(ctx, item),
                      onOpenDetails: () => HeisucaTitleSheet.show(ctx, item),
                      onToggleWatched: () => WatchActions.setWatched(ctx, item, watched: !item.isWatched),
                      onToggleFavorite: () => cgflixToggleMyList(ctx, item, item.isFavorite ?? false),
                      onDownload: () {
                        final mClient = cgflixClientFor(ctx, item);
                        if (mClient != null) {
                          queueDownloadWithFeedback(
                            ctx,
                            metadata: item,
                            client: mClient,
                            downloadProvider: Provider.of<DownloadProvider>(ctx, listen: false),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueWatchingStreamRow extends StatelessWidget {
  const _ContinueWatchingStreamRow({super.key, required this.discover, required this.repository});
  final DiscoverProvider discover;
  final CgflixHomeRepository repository;

  @override
  Widget build(BuildContext context) {
    return _StreamSection<CgflixRowData>(
      key: const ValueKey('continue_stream'),
      stream: () => repository.watchRow(CgflixRowKind.continueWatching),
      loading: const CgflixSkeletonRow(wide: true),
      builder: (data) => _HeisucaContinueWatchingRow(
        items: data.items.isNotEmpty ? data.items : discover.onDeck,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Fileira 2: Em alta no Brasil (Top 10 com grandes números outline)

class _HeisucaTop10Row extends StatelessWidget {
  const _HeisucaTop10Row({required this.items});
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
            child: Row(
              children: [
                Text(
                  'Em alta no Brasil',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: context.cgflix.isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: context.cgflix.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: context.cgflix.accent.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    'TOP 10',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTitulo,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w800,
                      color: context.cgflix.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cgflixPosterHeight,
            child: ListView.separated(
              key: const PageStorageKey('heisuca-top10-list'),
              physics: const ProMotionScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: items.take(10).length,
              separatorBuilder: (_, __) => const SizedBox(width: 10.0),
              itemBuilder: (ctx, index) {
                final item = items[index];
                return CgflixTop10Card(
                  rank: index + 1,
                  item: item,
                  client: cgflixClientFor(ctx, item),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    HeisucaTitleSheet.show(ctx, item);
                  },
                  onLongPress: () {
                    HeisucaContextMenu.show(
                      ctx,
                      item: item,
                      onPlay: () => cgflixPlay(ctx, item),
                      onOpenDetails: () => HeisucaTitleSheet.show(ctx, item),
                      onToggleWatched: () => WatchActions.setWatched(ctx, item, watched: !item.isWatched),
                      onToggleFavorite: () => cgflixToggleMyList(ctx, item, item.isFavorite ?? false),
                      onDownload: () {
                        final mClient = cgflixClientFor(ctx, item);
                        if (mClient != null) {
                          queueDownloadWithFeedback(
                            ctx,
                            metadata: item,
                            client: mClient,
                            downloadProvider: Provider.of<DownloadProvider>(ctx, listen: false),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Fileira Padrão de Acervo (Pôsteres 2:3)

class _HeisucaShelfRow extends StatelessWidget {
  const _HeisucaShelfRow({
    required this.title,
    required this.items,
    required this.storageKey,
  });

  final String title;
  final List<MediaItem> items;
  final String storageKey;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 11.0),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTitulo,
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: context.cgflix.isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA),
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(
            height: cgflixPosterHeight,
            child: ListView.separated(
              key: PageStorageKey<String>('heisuca-shelf:$storageKey'),
              physics: const ProMotionScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8.0),
              itemBuilder: (ctx, index) {
                final item = items[index];
                return CgflixPosterCard(
                  item: item,
                  client: cgflixClientFor(ctx, item),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    HeisucaTitleSheet.show(ctx, item);
                  },
                  onLongPress: () {
                    HeisucaContextMenu.show(
                      ctx,
                      item: item,
                      onPlay: () => cgflixPlay(ctx, item),
                      onOpenDetails: () => HeisucaTitleSheet.show(ctx, item),
                      onToggleWatched: () => WatchActions.setWatched(ctx, item, watched: !item.isWatched),
                      onToggleFavorite: () => cgflixToggleMyList(ctx, item, item.isFavorite ?? false),
                      onDownload: () {
                        final mClient = cgflixClientFor(ctx, item);
                        if (mClient != null) {
                          queueDownloadWithFeedback(
                            ctx,
                            metadata: item,
                            client: mClient,
                            downloadProvider: Provider.of<DownloadProvider>(ctx, listen: false),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Auxiliares, Streams e Gêneros

class _StreamSection<T> extends StatelessWidget {
  const _StreamSection({
    super.key,
    required this.stream,
    required this.loading,
    required this.builder,
    this.failed,
  });

  final Stream<T> Function() stream;
  final Widget loading;
  final Widget Function(T data) builder;
  final Widget? failed;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return failed ?? const SizedBox.shrink();
        if (snapshot.hasData) return builder(snapshot.data as T);
        return loading;
      },
    );
  }
}

class _GenreRows extends StatefulWidget {
  const _GenreRows({super.key, required this.repository});
  final CgflixHomeRepository repository;

  @override
  State<_GenreRows> createState() => _GenreRowsState();
}

class _GenreRowsState extends State<_GenreRows> {
  StreamSubscription<List<String>>? _subscription;
  List<String> _genres = const [];

  @override
  void initState() {
    super.initState();
    _subscription = widget.repository.watchGenres().listen((genres) {
      if (mounted) setState(() => _genres = genres);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: _genres.length,
      itemBuilder: (context, index) {
        final genre = _genres[index];
        return _StreamSection<CgflixRowData>(
          key: ValueKey('genre:$genre'),
          stream: () => widget.repository.watchRow(CgflixRowKind.genre, genre: genre),
          loading: const CgflixSkeletonRow(),
          builder: (data) => _HeisucaShelfRow(
            title: cgflixRowTitle(CgflixRowKind.genre, genre: genre),
            items: data.items,
            storageKey: 'genre:$genre',
          ),
        );
      },
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return CgflixShimmer(
      child: Container(height: height, color: context.cgflix.surface),
    );
  }
}

class _HomeLoadFailed extends StatelessWidget {
  const _HomeLoadFailed();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 96, 24, 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Symbols.cloud_off_rounded, size: 48, color: Colors.white30),
              const SizedBox(height: 12),
              Text(
                'Não foi possível conectar ao acervo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: HeisucaTheme.fonteTitulo,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.cgflix.isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Verifique a conexão ou puxe para atualizar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: HeisucaTheme.fonteTexto,
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      );
}
