// Início Flagship Heisuca (Esboço 03B) no celular Android:
// - Topo oficial com logo 炳 HEISUCA colado à esquerda e busca à direita
// - Hero Cinematográfico Edge-to-Edge com Scrim Easing Cúbico (sem faixas divisórias)
//   e ZERO botões de cápsula sobre a arte (toque no hero abre a Ficha Técnica)
// - Fileira 1: Continuar Assistindo em proporção 16:9 com barra de progresso e play
// - Fileira 2: Em alta no Brasil (Top 10) com números grandes vazados no canto inferior esquerdo
// - Acervo: uma fileira por biblioteca, na ordem do servidor
// - Suporte unificado: Jellyfin e Plex operam com visual 100% Heisuca (zero telas legadas)
// - Menu de Toque Longo (500ms + haptics) para ações rápidas (Esboço 04B)
// - Espaçamento inferior calibrado para a Ilha Flutuante (HeisucaFloatingIsland)
import 'dart:async';
import 'heisuca_motion.dart';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../cgflix/cgflix_navigation.dart';
import '../cgflix/cgflix_palette.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../cgflix/home/cgflix_cards.dart';
import '../cgflix/home/cgflix_home_logic.dart';
import '../cgflix/home/cgflix_home_repository.dart';
import '../media/media_item.dart';
import '../media/media_library.dart';
import '../cgflix/requests/cgflix_requests_ui.dart';
import 'heisuca_home_chrome.dart';
import 'heisuca_home_style.dart';
import 'heisuca_source_scope.dart';
import 'heisuca_upcoming.dart';
import 'kids/heisuca_kids_flow.dart';
import '../mixins/refreshable.dart';
import '../mixins/tab_visibility_aware.dart';
import '../providers/discover_provider.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../services/jellyfin_client.dart';
import '../media/media_server_client.dart';
import '../services/plex_client.dart';
import 'heisuca_plex_home_repository.dart';
import '../utils/download_utils.dart';
import '../utils/media_image_helper.dart';
import '../widgets/optimized_media_image.dart';
import 'heisuca_context_menu.dart';
import 'heisuca_design_system.dart';
import 'heisuca_theme.dart';
import 'heisuca_title_sheet.dart';

class HeisucaHomeScreen extends StatefulWidget {
  const HeisucaHomeScreen({super.key, this.onOpenLibrary});
  final ValueChanged<String>? onOpenLibrary;

  @override
  State<HeisucaHomeScreen> createState() => _HeisucaHomeScreenState();
}

class _HeisucaHomeScreenState extends State<HeisucaHomeScreen>
    with Refreshable, FullRefreshable, TabVisibilityAware, WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _logoAnchor = GlobalKey();
  bool _heroDocked = false;
  late final DiscoverProvider _discover;
  late final MultiServerProvider _servers;

  MediaServerClient? _client;
  List<JellyfinClient> _feedClients = const [];
  HeisucaHomeRepository? _repository;
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
    final client = _servers.serverManager.navigationOnlineClients.values.firstOrNull;
    final feeds = _servers.serverManager.visibleOnlineClients.values.whereType<JellyfinClient>().toList();
    final sameFeeds = feeds.length == _feedClients.length &&
        List.generate(feeds.length, (i) => identical(feeds[i], _feedClients[i])).every((same) => same);
    final same = identical(client, _client) && sameFeeds;

    if (same) {
      _onChanged();
      return;
    }

    _repository?.dispose();
    _generation++;
    _activeHeroItem = null;
    _heroDocked = false;
    _client = client;
    _feedClients = feeds;
    _repository = switch (client) {
      JellyfinClient jf => CgflixHomeRepository(jf),
      PlexClient plex => HeisucaPlexHomeRepository(plex, feedClients: feeds),
      _ => null,
    };
    _onChanged();
  }

  @override
  void refresh() {
    if (_discover.refreshIfStale()) return;
    unawaited(_discover.refreshContinueWatching());
  }

  @override
  void fullRefresh() {
    _repository?.forgetMemory();
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

  MediaItem? _activeHeroItem;

  void _onHeroActiveChanged(MediaItem item) {
    if (!identical(_activeHeroItem, item)) {
      setState(() => _activeHeroItem = item);
    }
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
    final heroHeight = heisucaHeroHeight(media.size.height);
    final repo = _repository;
    final isLight = context.cgflix.isLight;
    final pageColor = heisucaPageColor(_activeHeroItem, isLight: isLight, palette: context.cgflix);

    if (_servers.serverManager.navigationServerId != null &&
        _servers.serverManager.navigationOnlineClients.isEmpty) {
      return Scaffold(backgroundColor: pageColor, body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 48), const SizedBox(height: 16),
          const Text('Esta fonte está indisponível', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), const Text('Tente reconectar ou escolha outro servidor.'),
          const HeisucaSourceTile(),
          TextButton(onPressed: () => _servers.serverManager.reconnectOfflineServers(forceRediscovery: true),
            child: const Text('Tentar novamente')),
        ])))));
    }

    return Scaffold(
      backgroundColor: pageColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 650),
        color: pageColor,
        child: Stack(
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
                  ? _buildHomeSlivers(repo, heroHeight)
                  : [SliverToBoxAdapter(child: SizedBox(height: heroHeight))],
            ),
          ),

          // Topo oficial Heisuca (Logo à esquerda, Busca à direita)
          Positioned.fill(child: HeisucaHomeChrome(
            scrollController: _scrollController, logoAnchor: _logoAnchor, pageColor: pageColor,
            item: _activeHeroItem,
            client: _activeHeroItem == null ? null : cgflixClientFor(context, _activeHeroItem!),
            onSearch: () => cgflixOpenSearch(context),
            onHome: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
            onDockedChanged: (docked) { if (mounted && docked != _heroDocked) setState(() => _heroDocked = docked); },
          )),
        ],
      ),
      ),
    );
  }

  // --- Montagem compartilhada do acervo -----------------------------------------

  List<Widget> _buildHomeSlivers(HeisucaHomeRepository repo, double heroHeight) {
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
                  paused: !_tabVisible || !_appActive || _heroDocked,
                  logoAnchor: _logoAnchor,
                  scrollController: _scrollController,
                  onActiveItemChanged: _onHeroActiveChanged,
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

      // Mesma ordem e mesmos nomes de biblioteca que o site; sem gêneros extras.
      SliverToBoxAdapter(child: _StreamSection<List<MediaLibrary>>(
        key: ValueKey('libraries:$key'), stream: () => repo.videoLibraries().asStream(),
        loading: const CgflixSkeletonRow(), builder: (libraries) => Column(children: [
          for (final library in libraries) _StreamSection<CgflixRowData>(
            key: ValueKey('library:${library.id}:$key'), stream: () => repo.watchLibrary(library),
            loading: const CgflixSkeletonRow(), builder: (data) => _HeisucaShelfRow(
              title: library.title, items: data.items, storageKey: library.id,
              onSeeAll: widget.onOpenLibrary == null ? null : () => widget.onOpenLibrary!(library.globalKey),
            ),
          ),
        ]),
      )),
      // Modo infantil: o calendário vem do Sonarr/Radarr do servidor inteiro (não passa pelo filtro do
      // usuário infantil) e traria pôster de título adulto. Some no kids.
      if (!heisucaKidsActive(context)) SliverToBoxAdapter(child: _StreamSection<List<HeisucaUpcoming>>(
        key: ValueKey('upcoming:$key'), stream: () => repo.upcoming().asStream(),
        loading: const CgflixSkeletonRow(), builder: (items) => _UpcomingRow(repository: repo, items: items),
      )),

      // Folga no rodapé para não ficar sob a Ilha Flutuante (64dp + 14dp)
      SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 96)),
    ];
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
    this.onActiveItemChanged,
    required this.logoAnchor,
    required this.scrollController,
  });

  final ScrollController scrollController;
  final GlobalKey logoAnchor;
  final List<MediaItem> items;
  final double height;
  final bool paused;
  final ValueChanged<MediaItem>? onActiveItemChanged;

  @override
  State<_HeisucaHero> createState() => _HeisucaHeroState();
}

class _HeisucaHeroState extends State<_HeisucaHero> {
  int _currentIndex = 0;
  Timer? _timer;
  final _preloaded = <String>{};

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyActive());
  }

  @override
  void didUpdateWidget(_HeisucaHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.items.length) _currentIndex = 0;
    if (oldWidget.paused != widget.paused || oldWidget.items != widget.items) {
      _startTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyActive());
    }
  }

  void _notifyActive() {
    if (widget.items.isNotEmpty && mounted) {
      widget.onActiveItemChanged?.call(widget.items[_currentIndex % widget.items.length]);
      // Só o próximo destaque: não disputa rede/decodificação com toda a primeira tela.
      if (widget.items.length > 1) {
        final next = widget.items[(_currentIndex + 1) % widget.items.length];
        final client = cgflixClientFor(context, next);
        final width = MediaQuery.sizeOf(context).width;
        final candidates = next.heroArtCandidates(containerAspectRatio: width / widget.height);
        final path = next.artPath ?? candidates.firstOrNull;
        if (client != null && path != null && _preloaded.add(next.globalKey)) {
          final ratio = MediaImageHelper.artworkPixelRatio(context, imageType: ImageType.art);
          final url = MediaImageHelper.getOptimizedImageUrl(client: client, thumbPath: path, maxWidth: width,
            maxHeight: widget.height, pixelRatio: ratio, imageType: ImageType.art);
          final (w, h) = MediaImageHelper.getMemCacheDimensions(displayWidth: (width * ratio).round(),
            displayHeight: (widget.height * ratio).round(), imageType: ImageType.art);
          if (url.isNotEmpty) unawaited(precacheImage(MediaImageHelper.serverArtworkProvider(imageUrl: url, memWidth: w, memHeight: h), context,
            onError: (_, __) {}));
        }
      }
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
        _notifyActive();
      }
    });
  }

  void _onSlideChanged(int delta) {
    if (widget.items.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = (_currentIndex + delta + widget.items.length) % widget.items.length;
    });
    _notifyActive();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return SizedBox(height: widget.height);
    final item = widget.items[_currentIndex % widget.items.length];
    final client = cgflixClientFor(context, item);
    final screenWidth = MediaQuery.sizeOf(context).width;
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
            HeisucaArtworkMask(
              key: const ValueKey('heisuca-hero-mask'),
              child: HeisucaParallax(controller: widget.scrollController, child: AnimatedSwitcher(
                duration: HeisucaMotion.durationFor(context),
                child: OptimizedMediaImage(
                  key: ValueKey('hero_art_${item.globalKey}'), client: client,
                  imagePath: item.artPath ?? (artCandidates.isEmpty ? null : artCandidates.first),
                  width: screenWidth, height: widget.height, imageType: ImageType.art,
                  alignment: const Alignment(0, -0.64), fadeInDuration: HeisucaMotion.durationFor(context),
                ),
              )),
            ),

            // 5. Informações Nobres Centralizadas (Esboço 03B)
            Positioned(
              left: 20.0,
              right: 20.0,
              bottom: 18.0,
              child: _HeroInformationBlock(
                item: item,
                client: client,
                logoAnchor: widget.logoAnchor,
                totalDots: widget.items.length,
                activeDotIndex: _currentIndex,
                onDotSelected: (idx) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = idx);
                  _notifyActive();
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
    required this.logoAnchor,
    required this.totalDots,
    required this.activeDotIndex,
    required this.onDotSelected,
  });

  final MediaItem item;
  final dynamic client;
  final GlobalKey logoAnchor;
  final int totalDots;
  final int activeDotIndex;
  final ValueChanged<int> onDotSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final isLight = palette.isLight;
    final year = item.year?.toString() ?? '';
    final rating = item.rating != null && item.rating! > 0 ? item.rating!.toStringAsFixed(1).replaceAll('.', ',') : '';
    final genres = (item.genres ?? const <String>[]).take(5).join(', ');
    final badges = [if (item.contentRating?.isNotEmpty == true) item.contentRating!];

    final titleColor = context.cgflix.text;
    final textMutedColor = context.cgflix.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(key: logoAnchor, height: 56, width: MediaQuery.sizeOf(context).width * 0.54),

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
              'Continuar',
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTitulo,
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: context.cgflix.text,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(
            height: 180 * 9 / 16 + CgflixWideCard.titleBlockHeight,
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
                  width: 180, siteStyle: true,
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
  final HeisucaHomeRepository repository;

  @override
  Widget build(BuildContext context) {
    // O Discover mantém o progresso Plex atualizado ao voltar do player.
    if (repository.client is PlexClient) {
      return _HeisucaContinueWatchingRow(items: discover.onDeck);
    }
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
                    color: context.cgflix.text,
                    letterSpacing: -0.3,
                  ),
                ),

              ],
            ),
          ),
          SizedBox(
            height: 134.4,
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
                  siteStyle: true,
                  rank: index + 1,
                  item: item,
                  client: cgflixClientFor(ctx, item),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    cgflixRememberHeroTag(item, 'heisuca-home-${ctx.hashCode}-${item.globalKey}');
                    HeisucaTitleSheet.show(ctx, item);
                  },
                  onLongPress: () {
                    HeisucaContextMenu.show(
                      ctx,
                      item: item,
                      onPlay: () => cgflixPlay(ctx, item),
                      onOpenDetails: () => HeisucaTitleSheet.show(ctx, item),
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
    this.onSeeAll,
  });

  final String title;
  final List<MediaItem> items;
  final String storageKey;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 11), child: Row(children: [
            Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 17.5, fontWeight: FontWeight.w700))),
            if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('Ver tudo ›')),
          ])),
          SizedBox(
            height: 180,
            child: ListView.separated(
              key: PageStorageKey<String>('heisuca-shelf:$storageKey'),
              physics: const ProMotionScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8.0),
              itemBuilder: (ctx, index) {
                final item = items[index];
                return _HomePosterWithCaption(
                  item: item,
                  child: CgflixPosterCard(
                  heroTag: 'heisuca-home-${ctx.hashCode}-${item.globalKey}',
                  width: 80,
                  item: item,
                  client: cgflixClientFor(ctx, item),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    cgflixRememberHeroTag(item, 'heisuca-home-${ctx.hashCode}-${item.globalKey}');
                    HeisucaTitleSheet.show(ctx, item);
                  },
                  onLongPress: () {
                    HeisucaContextMenu.show(
                      ctx,
                      item: item,
                      onPlay: () => cgflixPlay(ctx, item),
                      onOpenDetails: () => HeisucaTitleSheet.show(ctx, item),
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
                ),
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

class _StreamSection<T> extends StatefulWidget {
  const _StreamSection({super.key, required this.stream, required this.loading, required this.builder, this.failed});
  final Stream<T> Function() stream;
  final Widget loading;
  final Widget Function(T data) builder;
  final Widget? failed;
  @override
  State<_StreamSection<T>> createState() => _StreamSectionState<T>();
}

class _StreamSectionState<T> extends State<_StreamSection<T>> {
  late final Stream<T> _stream = widget.stream();
  @override
  Widget build(BuildContext context) => StreamBuilder<T>(stream: _stream, builder: (context, snapshot) {
    if (snapshot.hasError) return widget.failed ?? const SizedBox.shrink();
    if (snapshot.hasData) return widget.builder(snapshot.data as T);
    return widget.loading;
  });
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
                  color: context.cgflix.text,
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


class _HomePosterWithCaption extends StatelessWidget {
  const _HomePosterWithCaption({required this.item, required this.child});
  final MediaItem item;
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(width: 80, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Stack(children: [child,
      if (item.rating != null && item.rating! > 0) Positioned(right: 4, bottom: 4,
        child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(item.rating!.toStringAsFixed(1).replaceAll('.', ','), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))))),
    ]),
    const SizedBox(height: 5),
    Text(item.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
    if (item.year != null) Text('${item.year}', style: TextStyle(fontSize: 11, color: context.cgflix.textMuted)),
  ]));
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.repository, required this.items});
  final HeisucaHomeRepository repository;
  final List<HeisucaUpcoming> items;

  Future<void> _open(BuildContext context, HeisucaUpcoming item) async {
    try {
      final matched = await repository.resolveUpcoming(item);
      if (!context.mounted) return;
      if (matched != null) { HeisucaTitleSheet.show(context, matched); return; }
    } catch (_) { /* Oferece o fluxo real de pedidos se o item não puder ser aberto. */ }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(sheetAnimationStyle: HeisucaMotion.sheetStyle(context), context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => SizedBox(height: MediaQuery.sizeOf(context).height * 0.72,
        child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('Confira a disponibilidade e escolha o título para pedir.'),
            CgflixRequestSection(query: item.title),
          ],
        ))));
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(key: const ValueKey('heisuca-upcoming-row'), padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 12), child: Text('Em breve',
          style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700, fontFamily: HeisucaTheme.fonteTitulo))),
        SizedBox(height: 180, child: ListView.separated(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, index) {
            final item = items[index];
            return SizedBox(width: 80, child: InkWell(onTap: () => _open(context, item), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(9), child: Stack(children: [
                  OptimizedMediaImage(client: repository.upcomingImageClient, imagePath: item.imagePath, width: 80, height: 120),
                  Positioned(top: 4, left: 4, right: 4, child: DecoratedBox(
                    decoration: BoxDecoration(color: context.cgflix.accent, borderRadius: BorderRadius.circular(8)),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(item.isMovie ? 'Em breve' : 'Novo episódio', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))))),
                ])),
                const SizedBox(height: 5),
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: context.cgflix.textMuted)),
              ],
            )));
          })),
      ]));
  }
}
