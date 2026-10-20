// Início do CGFLIX no celular ("só o nosso acervo"), na ordem combinada:
// destaque, Continuar assistindo, Em alta no Brasil (Top 10), Lançamentos,
// Novidades em filmes, Novidades em séries e animes e as linhas por gênero.
// Cada linha carrega sozinha (cache do aparelho primeiro). Sem servidor Jellyfin (só Plex),
// mostra a Início original do upstream.
// Etapa 1C: os chips Filmes · Séries · Animes filtram a própria Início (padrão Netflix), com
// "×" para voltar a "Tudo"; o topo some ao rolar para baixo e volta ao rolar para cima.
// Etapa 1D: o topo é a barra única do app (emblema = menu do usuário, chips, Busca e Pedir).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_item.dart';
import '../../mixins/refreshable.dart';
import '../../mixins/tab_visibility_aware.dart';
import '../../providers/discover_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../screens/discover_screen.dart';
import '../../services/jellyfin_client.dart';
import '../../services/watch_actions.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../cgflix_layout.dart';
import '../cgflix_navigation.dart';
import '../cgflix_palette.dart';
import '../cgflix_style.dart';
import 'cgflix_actions.dart';
import 'cgflix_cards.dart';
import 'cgflix_hero.dart';
import 'cgflix_home_logic.dart';
import 'cgflix_home_repository.dart';
import 'cgflix_preview_sheet.dart';

class CgflixHomeScreen extends StatefulWidget {
  const CgflixHomeScreen({super.key});

  @override
  State<CgflixHomeScreen> createState() => _CgflixHomeScreenState();
}

class _CgflixHomeScreenState extends State<CgflixHomeScreen>
    with Refreshable, FullRefreshable, TabVisibilityAware, WidgetsBindingObserver {
  final _fallbackKey = GlobalKey();
  final _scrollController = ScrollController();
  late final DiscoverProvider _discover;
  late final MultiServerProvider _servers;

  JellyfinClient? _client;
  CgflixHomeRepository? _repository;
  bool _tabVisible = true;
  bool _appActive = true;

  /// Muda a cada "puxar para atualizar": as linhas renascem e buscam de novo.
  int _generation = 0;

  /// Chips Filmes · Séries · Animes (bibliotecas do servidor) e o filtro ativo (null = Tudo).
  List<CgflixLibraryChip> _chips = const [];
  CgflixHomeFilter? _filter;

  /// Troca de filtro: some (150 ms), troca as linhas e volta (150 ms).
  bool _fading = false;

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

  /// Usa o primeiro servidor Jellyfin conectado. Trocou de servidor/usuário, troca o repositório.
  void _onServersChanged() {
    final client = _servers.serverManager.visibleOnlineClients.values.whereType<JellyfinClient>().firstOrNull;
    final same =
        client != null &&
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
    _filter = null;
    _chips = const [];
    unawaited(_loadChips());
    _onChanged();
  }

  Future<void> _loadChips() async {
    final repository = _repository;
    if (repository == null) return;
    final chips = await repository.chips();
    if (!mounted || repository != _repository) return;
    setState(() {
      _chips = chips;
      // A biblioteca do filtro sumiu (ex.: escondida): volta para Tudo.
      if (_filter != null && !chips.any((c) => CgflixHomeFilter.fromChip(c) == _filter)) _filter = null;
    });
  }

  /// Toque num chip filtra a Início; tocar no ativo (ou no "×") volta para Tudo.
  Future<void> _setFilter(CgflixHomeFilter? filter) async {
    if (filter == _filter || _fading) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _fading = true);
    await Future<void>.delayed(CgflixMotion.filterFade);
    if (!mounted) return;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() {
      _filter = filter;
      _fading = false;
    });
  }

  bool get _hasOnlineServer => _servers.serverManager.visibleOnlineClients.isNotEmpty;

  /// Sem Jellyfin, mas com Plex: a Início original cuida de tudo.
  bool get _useFallback => _repository == null && _hasOnlineServer;

  // --- ganchos do MainScreen -------------------------------------------------

  @override
  void refresh() {
    if (_useFallback) {
      if (_fallbackKey.currentState case final Refreshable s) s.refresh();
      return;
    }
    if (_discover.refreshIfStale()) return;
    unawaited(_discover.refreshContinueWatching());
  }

  @override
  void fullRefresh() {
    if (_useFallback) {
      if (_fallbackKey.currentState case final FullRefreshable s) s.fullRefresh();
      return;
    }
    unawaited(_discover.load());
    if (mounted) setState(() => _generation++);
    unawaited(_loadChips());
  }

  @override
  void primeRefresh() {
    if (_discover.isLoadInFlight) return;
    fullRefresh();
  }

  @override
  void onTabShown() {
    if (_fallbackKey.currentState case final TabVisibilityAware s) s.onTabShown();
    setState(() => _tabVisible = true);
    _discover.refreshIfStale();
  }

  @override
  void onTabHidden() {
    if (_fallbackKey.currentState case final TabVisibilityAware s) s.onTabHidden();
    setState(() => _tabVisible = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active != _appActive) setState(() => _appActive = active);
    if (active && !_useFallback) unawaited(_discover.refreshContinueWatching());
  }

  Future<void> _pullToRefresh() async {
    _repository?.forgetMemory();
    setState(() => _generation++);
    unawaited(_loadChips());
    await Future.wait([
      _discover.refreshNow(),
      // Dá tempo para o gesto terminar com a animação, mesmo com tudo vindo do cache.
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
  }

  // --- tela ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_useFallback) return DiscoverScreen(key: _fallbackKey);
    final repository = _repository;
    final media = MediaQuery.of(context);
    final heroHeight = cgflixHeroHeight(media.size);

    return Scaffold(
      backgroundColor: context.cgflix.background,
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: _fading ? 0 : 1,
            duration: CgflixMotion.filterFade,
            curve: CgflixMotion.curve,
            child: RefreshIndicator(
              color: context.cgflix.accent,
              backgroundColor: context.cgflix.surface,
              edgeOffset: media.padding.top + 56,
              onRefresh: _pullToRefresh,
              child: CustomScrollView(
                key: const PageStorageKey('cgflix-home'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: repository == null
                    ? [
                        SliverToBoxAdapter(child: _HeroSkeleton(height: heroHeight)),
                        const SliverToBoxAdapter(child: CgflixSkeletonRow(wide: true)),
                        const SliverToBoxAdapter(child: CgflixSkeletonRow()),
                      ]
                    : _buildSlivers(repository, heroHeight),
              ),
            ),
          ),
          _TopBar(scrollController: _scrollController, chips: _chips, filter: _filter, onFilter: _setFilter),
        ],
      ),
    );
  }

  List<Widget> _buildSlivers(CgflixHomeRepository repository, double heroHeight) {
    final filter = _filter;
    final key = '${repository.client.serverId.value}:$_generation${filter?.cacheSuffix ?? ''}';
    return [
      SliverToBoxAdapter(
        child: _StreamSection<CgflixRowData>(
          key: ValueKey('hero:$key'),
          stream: () => repository.watchHero(filter: filter),
          loading: _HeroSkeleton(height: heroHeight),
          // 1.5.0: sem o destaque (servidor fora), a Início diz o que houve em vez de ficar em branco.
          failed: const _HomeLoadFailed(),
          builder: (data) => data.items.isEmpty
              ? SizedBox(height: MediaQuery.paddingOf(context).top + 72)
              : CgflixHero(items: data.items, height: heroHeight, paused: !_tabVisible || !_appActive),
        ),
      ),
      SliverToBoxAdapter(
        child: _ContinueWatchingRow(
          key: ValueKey('continue:$key'),
          discover: _discover,
          repository: repository,
          filter: filter,
        ),
      ),
      SliverToBoxAdapter(
        child: _StreamSection<CgflixRowData>(
          key: ValueKey('trending:$key'),
          stream: () => repository.watchTrending(filter: filter),
          loading: const CgflixSkeletonRow(),
          builder: (data) => _Top10Row(data: data),
        ),
      ),
      for (final kind in cgflixFixedRowOrder.skip(2))
        // Com chip ativo, linha sem sentido para a biblioteca (ex.: séries em Filmes) nem monta.
        if (cgflixRowQuery(kind, filter: filter, genre: '') != null)
          SliverToBoxAdapter(
            child: _StreamSection<CgflixRowData>(
              key: ValueKey('${kind.name}:$key'),
              stream: () => repository.watchRow(kind, filter: filter),
              loading: const CgflixSkeletonRow(),
              builder: (data) => _ItemsRow(
                title: cgflixRowTitle(kind, filter: filter),
                items: data.items,
                storageKey: '${kind.name}${filter?.cacheSuffix ?? ''}',
              ),
            ),
          ),
      _GenreRows(key: ValueKey('genres:$key'), repository: repository, filter: filter),
      // Folga no fim para a última linha não colar na borda.
      SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 32)),
    ];
  }
}

// ---------------------------------------------------------------------------
// Peças

/// A Início não carregou (servidor fora ou sem internet).
class _HomeLoadFailed extends StatelessWidget {
  const _HomeLoadFailed();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 96, 24, 24),
    child: Column(
      children: [
        AppIcon(Symbols.cloud_off_rounded, fill: 1, size: 48, color: context.cgflix.textMuted),
        const SizedBox(height: 16),
        Text(
          'Não deu para carregar a Início.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Confira a internet e puxe a tela para baixo para tentar de novo.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.cgflix.textMuted),
        ),
      ],
    ),
  );
}

/// Assina um fluxo de dados só quando a linha é montada (as linhas de baixo carregam
/// quando chegam perto da tela) e troca o esqueleto pelo conteúdo com fade.
class _StreamSection<T> extends StatefulWidget {
  const _StreamSection({
    super.key,
    required this.stream,
    required this.loading,
    required this.builder,
    this.failed = const SizedBox.shrink(),
  });
  final Stream<T> Function() stream;
  final Widget loading;

  /// O que fica no lugar quando a linha falha (padrão: some).
  final Widget failed;
  final Widget Function(T data) builder;

  @override
  State<_StreamSection<T>> createState() => _StreamSectionState<T>();
}

class _StreamSectionState<T> extends State<_StreamSection<T>> {
  StreamSubscription<T>? _subscription;
  T? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream().listen(
      (data) {
        if (mounted) setState(() => _data = data);
      },
      onError: (Object e) {
        appLogger.w('CGFLIX: linha da Início falhou', error: e);
        // Erro antes de qualquer dado: a linha some em vez de ficar no esqueleto para sempre.
        if (mounted && _data == null) setState(() => _failed = true);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (_failed) return widget.failed;
    return AnimatedSize(
      duration: CgflixMotion.medium,
      curve: CgflixMotion.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: CgflixMotion.medium,
        switchInCurve: CgflixMotion.curve,
        child: KeyedSubtree(
          key: ValueKey(data == null ? 'loading' : 'data'),
          child: data == null ? widget.loading : widget.builder(data),
        ),
      ),
    );
  }
}

/// Tag única por linha + item (o mesmo título pode aparecer em duas linhas).
String _heroTag(String row, MediaItem item) => 'cgflix:$row:${item.globalKey}';

class _ItemsRow extends StatelessWidget {
  const _ItemsRow({required this.title, required this.items, required this.storageKey});
  final String title;
  final List<MediaItem> items;
  final String storageKey;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return CgflixRow(
      title: title,
      storageKey: storageKey,
      height: cgflixPosterHeight,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final tag = _heroTag(storageKey, item);
        return CgflixPosterCard(
          item: item,
          client: cgflixClientFor(context, item),
          heroTag: tag,
          onTap: () => showCgflixPreview(context, item, heroTag: tag),
          onLongPress: () => showCgflixPreview(context, item, heroTag: tag),
        );
      },
    );
  }
}

class _Top10Row extends StatelessWidget {
  const _Top10Row({required this.data});
  final CgflixRowData data;

  @override
  Widget build(BuildContext context) {
    final items = data.items.take(10).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return CgflixRow(
      title: cgflixRowTitle(CgflixRowKind.trending, trendingTitle: data.title),
      storageKey: 'trending',
      height: cgflixPosterHeight,
      spacing: 4,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final tag = _heroTag('trending', item);
        return CgflixTop10Card(
          rank: index + 1,
          item: item,
          client: cgflixClientFor(context, item),
          heroTag: tag,
          onTap: () => showCgflixPreview(context, item, heroTag: tag),
          onLongPress: () => showCgflixPreview(context, item, heroTag: tag),
        );
      },
    );
  }
}

/// Continuar assistindo: vem do DiscoverProvider do upstream (mesma regra de "próximo
/// episódio" e de atualização). Tocar = continua direto; segurar = remover da linha.
/// Etapa 1E: com chip ativo, a lista vem do servidor só daquela biblioteca (ParentId) e é
/// pedida de novo sempre que o "Continuar" geral muda (assistiu algo, removeu um item).
class _ContinueWatchingRow extends StatefulWidget {
  const _ContinueWatchingRow({super.key, required this.discover, required this.repository, this.filter});
  final DiscoverProvider discover;
  final CgflixHomeRepository repository;
  final CgflixHomeFilter? filter;

  @override
  State<_ContinueWatchingRow> createState() => _ContinueWatchingRowState();
}

class _ContinueWatchingRowState extends State<_ContinueWatchingRow> {
  List<MediaItem>? _scoped;
  List<MediaItem>? _seenOnDeck;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _refreshScoped(fresh: false);
  }

  @override
  void didUpdateWidget(_ContinueWatchingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // O "Continuar" geral mudou (o DiscoverProvider troca a lista inteira): pede de novo.
    if (widget.filter != null && !identical(widget.discover.onDeck, _seenOnDeck)) _refreshScoped(fresh: true);
  }

  void _refreshScoped({required bool fresh}) {
    final filter = widget.filter;
    _seenOnDeck = widget.discover.onDeck;
    if (filter == null) return;
    final request = ++_request;
    widget.repository
        .continueWatchingIn(filter, fresh: fresh)
        .then((items) {
          if (mounted && request == _request) setState(() => _scoped = items);
        })
        .catchError((Object e) {
          appLogger.w('CGFLIX: Continuar assistindo da categoria falhou', error: e);
          if (mounted && request == _request) setState(() => _scoped ??= const []);
        });
  }

  Future<void> _confirmRemove(BuildContext context, MediaItem item) async {
    final remove = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.cgflix.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                item.grandparentTitle ?? item.displayTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(cgflixEpisodeLabel(item)),
            ),
            ListTile(
              leading: const AppIcon(Symbols.remove_circle_rounded, fill: 1),
              title: Text(t.mediaMenu.removeFromContinueWatching),
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
            ListTile(
              leading: const AppIcon(Symbols.info_rounded, fill: 1),
              title: const Text('Detalhes'),
              onTap: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || remove == null) return;
    if (!remove) {
      await cgflixOpenDetails(context, item);
      return;
    }
    try {
      await WatchActions.removeFromContinueWatching(context, item);
    } catch (e) {
      appLogger.w('CGFLIX: remover de Continuar assistindo falhou', error: e);
      if (context.mounted) showErrorSnackBar(context, 'Não deu para tirar de Continuar assistindo. Tente de novo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;
    final discover = widget.discover;
    final items = filter == null ? discover.onDeck : (_scoped ?? const <MediaItem>[]);
    final loading = filter == null ? discover.isLoading : _scoped == null;
    final Widget child;
    if (items.isEmpty && loading) {
      child = const CgflixSkeletonRow(key: ValueKey('loading'), wide: true);
    } else if (items.isEmpty) {
      child = const SizedBox.shrink(key: ValueKey('empty'));
    } else {
      child = CgflixRow(
        key: const ValueKey('row'),
        title: cgflixRowTitle(CgflixRowKind.continueWatching),
        storageKey: 'continue',
        height: cgflixWideHeight + CgflixWideCard.titleBlockHeight,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return CgflixWideCard(
            item: item,
            client: cgflixClientFor(context, item),
            onTap: () => cgflixPlay(context, item),
            onLongPress: () => _confirmRemove(context, item),
          );
        },
      );
    }
    return AnimatedSize(
      duration: CgflixMotion.medium,
      curve: CgflixMotion.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(duration: CgflixMotion.medium, child: child),
    );
  }
}

/// Linhas por gênero: a lista de gêneros vem primeiro; cada linha só busca seus títulos
/// quando chega perto da tela (SliverList monta sob demanda).
class _GenreRows extends StatefulWidget {
  const _GenreRows({super.key, required this.repository, this.filter});
  final CgflixHomeRepository repository;
  final CgflixHomeFilter? filter;

  @override
  State<_GenreRows> createState() => _GenreRowsState();
}

class _GenreRowsState extends State<_GenreRows> {
  StreamSubscription<List<String>>? _subscription;
  List<String> _genres = const [];

  @override
  void initState() {
    super.initState();
    _subscription = widget.repository.watchGenres(filter: widget.filter).listen((genres) {
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
        final suffix = widget.filter?.cacheSuffix ?? '';
        return _StreamSection<CgflixRowData>(
          key: ValueKey('genre:$genre$suffix'),
          stream: () => widget.repository.watchRow(CgflixRowKind.genre, genre: genre, filter: widget.filter),
          loading: const CgflixSkeletonRow(),
          builder: (data) => _ItemsRow(
            title: cgflixRowTitle(CgflixRowKind.genre, genre: genre),
            items: data.items,
            storageKey: 'genre:$genre$suffix',
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

/// Topo da Início: a barra única do app ([CgflixTopBar]) sobre um gradiente (nada de barra
/// opaca). Some ao rolar para baixo e volta ao rolar para cima. Com um chip ativo, os outros
/// saem e aparece o "×" para voltar a "Tudo".
class _TopBar extends StatefulWidget {
  const _TopBar({required this.scrollController, required this.chips, required this.filter, required this.onFilter});
  final ScrollController scrollController;
  final List<CgflixLibraryChip> chips;
  final CgflixHomeFilter? filter;
  final ValueChanged<CgflixHomeFilter?> onFilter;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _visible = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
    // Trocou o filtro (a lista volta ao topo): o topo reaparece.
    if (oldWidget.filter != widget.filter && !_visible) setState(() => _visible = true);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (!controller.hasClients || controller.positions.length != 1) return;
    final offset = controller.offset;
    final delta = offset - _lastOffset;
    _lastOffset = offset;
    final visible = switch (delta) {
      _ when offset < 80 => true,
      > 6 => false,
      < -6 => true,
      _ => _visible,
    };
    if (visible != _visible) setState(() => _visible = visible);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final filter = widget.filter;
    final chips = filter == null
        ? widget.chips
        : widget.chips.where((c) => CgflixHomeFilter.fromChip(c) == filter).toList();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, -1),
        duration: CgflixMotion.fast,
        curve: CgflixMotion.curve,
        child: DecoratedBox(
          // Barra do topo translúcida: véu escuro (Isis) ou claro (Heitor).
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: context.cgflix.topVeil,
              stops: const [0, 0.55, 1],
            ),
          ),
          child: Padding(
            // Deitado, respeita o recorte da câmera nas laterais.
            padding: EdgeInsets.fromLTRB(8 + padding.left, padding.top + 4, 8 + padding.right, 16),
            child: CgflixTopBar(
              onClearFilter: filter == null ? null : () => widget.onFilter(null),
              chips: [
                for (final chip in chips)
                  CgflixTopBarChip(
                    label: chip.label,
                    selected: filter != null,
                    onPressed: () {
                      final tapped = CgflixHomeFilter.fromChip(chip);
                      widget.onFilter(tapped == filter ? null : tapped);
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
