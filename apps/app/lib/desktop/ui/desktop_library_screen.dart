import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../heisuca/heisuca_design_system.dart';
import '../../heisuca/heisuca_theme.dart';
import '../../media/library_query.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../media/media_server_client.dart';
import '../../media/media_version.dart';
import '../../utils/media_server_http_client.dart' show AbortController;
import '../remote/desktop_servers_controller.dart';

/// Tela desktop M2 de gerenciamento de conexões e navegação em bibliotecas remotas.
class DesktopLibraryScreen extends StatefulWidget {
  const DesktopLibraryScreen({
    super.key,
    required this.servers,
    required this.onPlay,
  });

  final DesktopServersController servers;
  final Future<void> Function(DesktopServerConnection, MediaItem, int?) onPlay;

  @override
  State<DesktopLibraryScreen> createState() => _DesktopLibraryScreenState();
}

class _DesktopLibraryScreenState extends State<DesktopLibraryScreen> {
  static const int _pageSize = 50;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 280);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridScrollController = ScrollController();

  String? _selectedServerId;
  MediaServerClient? _activeClient;
  Set<String> _knownServerIds = <String>{};

  int _librariesEpoch = 0;
  AbortController? _librariesAbort;
  List<MediaLibrary> _libraries = const <MediaLibrary>[];
  MediaLibrary? _selectedLibrary;
  bool _loadingLibraries = false;
  String? _librariesError;

  int _itemsEpoch = 0;
  AbortController? _itemsAbort;
  List<MediaItem> _items = const <MediaItem>[];
  final Set<String> _loadedItemKeys = <String>{};
  int _totalCount = 0;
  int _nextOffset = 0;
  bool _hasMore = false;
  bool _loadingItems = false;
  bool _loadingMore = false;
  String? _itemsError;
  String _searchQuery = '';
  bool _searchAllServer = false;
  Timer? _searchDebounce;

  int _detailEpoch = 0;
  AbortController? _detailAbort;
  MediaItem? _detailItem;
  final List<MediaItem> _detailBreadcrumbs = <MediaItem>[];
  MediaItem? _onDeckEpisode;
  List<MediaItem> _children = const <MediaItem>[];
  final Set<String> _childrenKeys = <String>{};
  int _childrenTotalCount = 0;
  int _childrenOffset = 0;
  bool _childrenHasMore = false;
  bool _loadingChildren = false;
  bool _loadingMoreChildren = false;
  String? _childrenError;
  int _selectedVersionIndex = 0;
  bool _startingPlayback = false;
  String? _playbackError;

  @override
  void initState() {
    super.initState();
    widget.servers.addListener(_onServersChanged);
    _knownServerIds = widget.servers.connections.map((c) => c.id).toSet();
    _syncSelectedServer(forceReload: true, allowSetState: false);
  }

  @override
  void didUpdateWidget(covariant DesktopLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.servers, widget.servers)) {
      oldWidget.servers.removeListener(_onServersChanged);
      widget.servers.addListener(_onServersChanged);
      _knownServerIds = widget.servers.connections.map((c) => c.id).toSet();
      _syncSelectedServer(forceReload: true);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _librariesAbort?.abort();
    _itemsAbort?.abort();
    _detailAbort?.abort();
    _searchController.dispose();
    _gridScrollController.dispose();
    widget.servers.removeListener(_onServersChanged);
    super.dispose();
  }

  DesktopServerConnection? get _selectedServer {
    final id = _selectedServerId;
    if (id == null) return null;
    for (final conn in widget.servers.connections) {
      if (conn.id == id) return conn;
    }
    return null;
  }

  void _onServersChanged() {
    if (!mounted) return;
    _syncSelectedServer();
    setState(() {});
  }

  void _syncSelectedServer({bool forceReload = false, bool allowSetState = true}) {
    final connections = widget.servers.connections;
    final currentIds = connections.map((c) => c.id).toSet();
    final addedIds = currentIds.difference(_knownServerIds);
    _knownServerIds = currentIds;

    if (connections.isEmpty) {
      _abortAllPending();
      _selectedServerId = null;
      _activeClient = null;
      _resetLibrariesState();
      _resetItemsState();
      _resetDetailState();
      if (allowSetState && mounted) {
        setState(() {});
      }
      return;
    }

    DesktopServerConnection? target;
    if (!widget.servers.restoring && addedIds.isNotEmpty) {
      for (final conn in connections) {
        if (addedIds.contains(conn.id)) {
          target = conn;
          break;
        }
      }
    }
    target ??= _selectedServer ?? connections.first;

    final changedServer = target.id != _selectedServerId || !identical(target.client, _activeClient);
    if (!changedServer && !forceReload) {
      return;
    }

    _selectServer(target, allowSetState: allowSetState);
  }

  void _selectServer(DesktopServerConnection server, {bool allowSetState = true}) {
    _searchDebounce?.cancel();
    _abortAllPending();
    _selectedServerId = server.id;
    _activeClient = server.client;
    _resetLibrariesState(loading: true);
    _resetItemsState();
    _resetDetailState();
    if (allowSetState && mounted) {
      setState(() {});
    }
    final epoch = _librariesEpoch;
    unawaited(_fetchLibrariesFor(server, epoch));
  }

  void _abortAllPending() {
    _librariesAbort?.abort();
    _itemsAbort?.abort();
    _detailAbort?.abort();
    _librariesEpoch++;
    _itemsEpoch++;
    _detailEpoch++;
  }

  void _resetLibrariesState({bool loading = false}) {
    _libraries = const <MediaLibrary>[];
    _selectedLibrary = null;
    _loadingLibraries = loading;
    _librariesError = null;
  }

  void _resetItemsState() {
    _items = const <MediaItem>[];
    _loadedItemKeys.clear();
    _totalCount = 0;
    _nextOffset = 0;
    _hasMore = false;
    _loadingItems = false;
    _loadingMore = false;
    _itemsError = null;
  }

  void _resetDetailState() {
    _detailItem = null;
    _detailBreadcrumbs.clear();
    _onDeckEpisode = null;
    _children = const <MediaItem>[];
    _childrenKeys.clear();
    _childrenTotalCount = 0;
    _childrenOffset = 0;
    _childrenHasMore = false;
    _loadingChildren = false;
    _loadingMoreChildren = false;
    _childrenError = null;
    _selectedVersionIndex = 0;
    _startingPlayback = false;
    _playbackError = null;
  }

  Future<void> _fetchLibrariesFor(DesktopServerConnection server, int epoch) async {
    final abort = AbortController();
    _librariesAbort = abort;
    try {
      final rawLibraries = await server.client.fetchLibraries();
      if (!mounted || epoch != _librariesEpoch || abort.isAborted) return;
      final visible = rawLibraries.where((lib) => !lib.hidden).toList(growable: false);
      setState(() {
        _libraries = visible;
        _loadingLibraries = false;
        _librariesError = null;
        _selectedLibrary = visible.isNotEmpty ? visible.first : null;
      });
      if (visible.isNotEmpty) {
        unawaited(_loadItems(reset: true));
      }
    } on Object {
      if (!mounted || epoch != _librariesEpoch || abort.isAborted) return;
      setState(() {
        _loadingLibraries = false;
        _librariesError = 'Não foi possível carregar as bibliotecas deste servidor.';
      });
    }
  }

  void _retryLibraries() {
    final server = _selectedServer;
    if (server == null) return;
    _librariesAbort?.abort();
    _librariesEpoch++;
    setState(() {
      _resetLibrariesState(loading: true);
      _resetItemsState();
      _resetDetailState();
    });
    unawaited(_fetchLibrariesFor(server, _librariesEpoch));
  }

  void _selectLibrary(MediaLibrary library) {
    if (_selectedLibrary?.id == library.id && _itemsError == null) return;
    _itemsAbort?.abort();
    _detailAbort?.abort();
    _itemsEpoch++;
    _detailEpoch++;
    setState(() {
      _selectedLibrary = library;
      _resetItemsState();
      _resetDetailState();
    });
    unawaited(_loadItems(reset: true));
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      _searchQuery = trimmed;
      if (_searchQuery.isEmpty) {
        _searchAllServer = false;
      }
      unawaited(_loadItems(reset: true));
    });
    setState(() {});
  }

  void _applySearchImmediate() {
    _searchDebounce?.cancel();
    final trimmed = _searchController.text.trim();
    setState(() {
      _searchQuery = trimmed;
      if (_searchQuery.isEmpty) {
        _searchAllServer = false;
      }
    });
    unawaited(_loadItems(reset: true));
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchAllServer = false;
    });
    unawaited(_loadItems(reset: true));
  }

  void _toggleSearchScope(bool allServer) {
    if (_searchAllServer == allServer) return;
    setState(() {
      _searchAllServer = allServer;
    });
    unawaited(_loadItems(reset: true));
  }

  Future<void> _loadItems({required bool reset}) async {
    final server = _selectedServer;
    final library = _selectedLibrary;
    if (server == null) return;
    if (!_searchAllServer && library == null) return;

    final int epoch;
    final AbortController abort;
    if (reset) {
      _itemsAbort?.abort();
      epoch = ++_itemsEpoch;
      abort = AbortController();
      _itemsAbort = abort;
      if (!mounted) return;
      setState(() {
        _loadingItems = true;
        _loadingMore = false;
        _itemsError = null;
        _items = const <MediaItem>[];
        _loadedItemKeys.clear();
        _totalCount = 0;
        _nextOffset = 0;
        _hasMore = false;
      });
    } else {
      if (_loadingItems || _loadingMore || !_hasMore || _searchAllServer) return;
      epoch = _itemsEpoch;
      abort = _itemsAbort ?? AbortController();
      _itemsAbort = abort;
      if (!mounted) return;
      setState(() {
        _loadingMore = true;
        _itemsError = null;
      });
    }

    try {
      final trimmedSearch = _searchQuery.trim();
      final useGlobal = _searchAllServer && trimmedSearch.isNotEmpty;
      if (useGlobal) {
        final results = await server.client.searchItems(
          trimmedSearch,
          limit: _pageSize,
          abort: abort,
        );
        if (!mounted || epoch != _itemsEpoch || abort.isAborted) return;
        final deduped = <MediaItem>[];
        _loadedItemKeys.clear();
        for (final item in results) {
          if (_loadedItemKeys.add(_itemIdentityKey(server, item))) {
            deduped.add(item);
          }
        }
        setState(() {
          _items = List<MediaItem>.unmodifiable(deduped);
          _totalCount = deduped.length;
          _nextOffset = deduped.length;
          _hasMore = false;
          _loadingItems = false;
          _loadingMore = false;
          _itemsError = null;
        });
        return;
      }

      final selectedLib = library!;
      final includeKinds = selectedLib.defaultBrowseKinds.isNotEmpty
          ? selectedLib.defaultBrowseKinds
          : (selectedLib.kind != MediaKind.unknown ? <MediaKind>[selectedLib.kind] : const <MediaKind>[]);
      final queryKind = selectedLib.kind != MediaKind.unknown && includeKinds.length <= 1 ? selectedLib.kind : null;
      final libraryKind = selectedLib.kind != MediaKind.unknown ? selectedLib.kind : null;
      final query = LibraryQuery(
        kind: queryKind,
        includeKinds: includeKinds,
        offset: reset ? 0 : _nextOffset,
        limit: _pageSize,
        search: trimmedSearch.isEmpty ? null : trimmedSearch,
      );

      final page = await server.client.fetchLibraryPagedContent(
        selectedLib.id,
        query: query,
        libraryKind: libraryKind,
        abort: abort,
      );
      if (!mounted || epoch != _itemsEpoch || abort.isAborted) return;

      final updatedItems = reset ? <MediaItem>[] : List<MediaItem>.of(_items);
      if (reset) {
        _loadedItemKeys.clear();
      }
      var addedCount = 0;
      for (final item in page.items) {
        if (_loadedItemKeys.add(_itemIdentityKey(server, item))) {
          updatedItems.add(item);
          addedCount++;
        }
      }
      final nextOffset = page.offset + page.items.length;
      final hasMore = page.items.isNotEmpty &&
          addedCount > 0 &&
          nextOffset < page.totalCount &&
          updatedItems.length < page.totalCount;

      setState(() {
        _items = List<MediaItem>.unmodifiable(updatedItems);
        _totalCount = page.totalCount;
        _nextOffset = nextOffset;
        _hasMore = hasMore;
        _loadingItems = false;
        _loadingMore = false;
        _itemsError = null;
      });
    } on Object {
      if (!mounted || epoch != _itemsEpoch || abort.isAborted) return;
      setState(() {
        _loadingItems = false;
        _loadingMore = false;
        _itemsError = reset
            ? 'Não foi possível carregar os itens desta biblioteca.'
            : 'Não foi possível carregar mais itens.';
      });
    }
  }

  void _openItemDetail(MediaItem item, {bool pushBreadcrumb = false}) {
    final server = _selectedServer;
    if (server == null) return;
    _detailAbort?.abort();
    final epoch = ++_detailEpoch;
    final abort = AbortController();
    _detailAbort = abort;

    setState(() {
      if (pushBreadcrumb && _detailItem != null) {
        _detailBreadcrumbs.add(_detailItem!);
      } else if (!pushBreadcrumb) {
        _detailBreadcrumbs.clear();
      }
      _detailItem = item;
      _onDeckEpisode = null;
      _children = const <MediaItem>[];
      _childrenKeys.clear();
      _childrenTotalCount = 0;
      _childrenOffset = 0;
      _childrenHasMore = false;
      _childrenError = null;
      _loadingChildren = _shouldFetchChildren(item);
      _loadingMoreChildren = false;
      _selectedVersionIndex = _defaultPlayableVersionIndex(item.mediaVersions);
      _playbackError = null;
    });

    unawaited(_loadItemWithOnDeck(server, item, epoch, abort));
    if (_shouldFetchChildren(item)) {
      unawaited(_loadChildrenPage(server, item, epoch, abort, reset: true));
    }
  }

  void _popDetailBreadcrumb() {
    if (_detailBreadcrumbs.isEmpty) {
      _closeDetail();
      return;
    }
    final parent = _detailBreadcrumbs.removeLast();
    final server = _selectedServer;
    if (server == null) return;
    _detailAbort?.abort();
    final epoch = ++_detailEpoch;
    final abort = AbortController();
    _detailAbort = abort;

    setState(() {
      _detailItem = parent;
      _onDeckEpisode = null;
      _children = const <MediaItem>[];
      _childrenKeys.clear();
      _childrenTotalCount = 0;
      _childrenOffset = 0;
      _childrenHasMore = false;
      _childrenError = null;
      _loadingChildren = _shouldFetchChildren(parent);
      _loadingMoreChildren = false;
      _selectedVersionIndex = _defaultPlayableVersionIndex(parent.mediaVersions);
      _playbackError = null;
    });

    unawaited(_loadItemWithOnDeck(server, parent, epoch, abort));
    if (_shouldFetchChildren(parent)) {
      unawaited(_loadChildrenPage(server, parent, epoch, abort, reset: true));
    }
  }

  void _closeDetail() {
    _detailAbort?.abort();
    _detailEpoch++;
    setState(() {
      _resetDetailState();
    });
  }

  Future<void> _loadItemWithOnDeck(
    DesktopServerConnection server,
    MediaItem item,
    int epoch,
    AbortController abort,
  ) async {
    try {
      final result = await server.client.fetchItemWithOnDeck(item.id);
      if (!mounted || epoch != _detailEpoch || abort.isAborted) return;
      final fetchedItem = result.item;
      setState(() {
        if (fetchedItem != null) {
          _detailItem = fetchedItem;
          final versions = fetchedItem.mediaVersions ?? const <MediaVersion>[];
          if (_selectedVersionIndex >= versions.length) {
            _selectedVersionIndex = _defaultPlayableVersionIndex(versions);
          }
        }
        _onDeckEpisode = result.onDeckEpisode;
      });
    } on Object {
      // Falha em detalhes complementares preserva os metadados básicos já obtidos.
    }
  }

  Future<void> _loadChildrenPage(
    DesktopServerConnection server,
    MediaItem parent,
    int epoch,
    AbortController abort, {
    required bool reset,
  }) async {
    if (!reset && (_loadingChildren || _loadingMoreChildren || !_childrenHasMore)) return;
    if (!reset) {
      if (!mounted) return;
      setState(() {
        _loadingMoreChildren = true;
        _childrenError = null;
      });
    }
    try {
      final page = await server.client.fetchChildrenPage(
        parent.id,
        start: reset ? 0 : _childrenOffset,
        size: _pageSize,
        abort: abort,
      );
      if (!mounted || epoch != _detailEpoch || abort.isAborted) return;

      final nextChildren = reset ? <MediaItem>[] : List<MediaItem>.of(_children);
      if (reset) {
        _childrenKeys.clear();
      }
      var addedCount = 0;
      for (final child in page.items) {
        if (_childrenKeys.add(_itemIdentityKey(server, child))) {
          nextChildren.add(child);
          addedCount++;
        }
      }
      final nextOffset = page.offset + page.items.length;
      final hasMore = page.items.isNotEmpty &&
          addedCount > 0 &&
          nextOffset < page.totalCount &&
          nextChildren.length < page.totalCount;

      setState(() {
        _children = List<MediaItem>.unmodifiable(nextChildren);
        _childrenTotalCount = page.totalCount;
        _childrenOffset = nextOffset;
        _childrenHasMore = hasMore;
        _loadingChildren = false;
        _loadingMoreChildren = false;
        _childrenError = null;
      });
    } on Object {
      if (!mounted || epoch != _detailEpoch || abort.isAborted) return;
      setState(() {
        _loadingChildren = false;
        _loadingMoreChildren = false;
        _childrenError = 'Não foi possível carregar os itens relacionados.';
      });
    }
  }

  Future<void> _playItem(MediaItem item, {int? versionIndex}) async {
    final server = _selectedServer;
    if (server == null || _startingPlayback) return;
    setState(() {
      _startingPlayback = true;
      _playbackError = null;
    });
    try {
      await widget.onPlay(server, item, versionIndex);
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _startingPlayback = false;
        });
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _startingPlayback = false;
        _playbackError = 'Não foi possível iniciar a reprodução neste momento.';
      });
    }
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _openPlexModal() {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _PlexSignInDialog(servers: widget.servers),
      ),
    );
  }

  void _openJellyfinModal() {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _JellyfinSignInDialog(servers: widget.servers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _LibraryPalette.of(context);
    final server = _selectedServer;
    final connections = widget.servers.connections;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _HeaderBar(
              palette: palette,
              selectedServer: server,
              onBack: _handleBackNavigation,
              onConnectPlex: _openPlexModal,
              onConnectJellyfin: _openJellyfinModal,
            ),
            _StatusBanners(palette: palette, servers: widget.servers),
            if (connections.isNotEmpty)
              _ServersBar(
                palette: palette,
                connections: connections,
                selectedServerId: server?.id,
                onSelectServer: _selectServer,
                onDisconnect: (id) => unawaited(widget.servers.disconnect(id)),
              ),
                ]),
              ),
            ),
            Expanded(
              child: connections.isEmpty
                  ? _EmptyConnectionsView(
                      palette: palette,
                      restoring: widget.servers.restoring,
                      persistentSessions: widget.servers.persistentSessions,
                      onConnectPlex: _openPlexModal,
                      onConnectJellyfin: _openJellyfinModal,
                    )
                  : _buildBrowserBody(palette, server),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowserBody(_LibraryPalette palette, DesktopServerConnection? server) {
    if (server == null) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1040.0;
        if (!isWide && _detailItem != null) {
          return _buildDetailPanel(palette, server, fullWidth: true);
        }
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 240.0,
                child: _LibrariesSidebar(
                  palette: palette,
                  libraries: _libraries,
                  selectedLibrary: _selectedLibrary,
                  loading: _loadingLibraries,
                  error: _librariesError,
                  onSelect: _selectLibrary,
                  onRetry: _retryLibraries,
                ),
              ),
              Expanded(child: _buildMainGridColumn(palette, server)),
              if (_detailItem != null)
                SizedBox(
                  width: 370.0,
                  child: _buildDetailPanel(palette, server, fullWidth: false),
                ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LibrariesStrip(
              palette: palette,
              libraries: _libraries,
              selectedLibrary: _selectedLibrary,
              loading: _loadingLibraries,
              error: _librariesError,
              onSelect: _selectLibrary,
              onRetry: _retryLibraries,
            ),
            Expanded(child: _buildMainGridColumn(palette, server)),
          ],
        );
      },
    );
  }

  Widget _buildMainGridColumn(_LibraryPalette palette, DesktopServerConnection server) {
    if (_loadingLibraries && _libraries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_librariesError != null && _libraries.isEmpty) {
      return _CenteredMessageState(
        palette: palette,
        icon: Icons.error_outline,
        title: 'Falha ao carregar bibliotecas',
        message: _librariesError!,
        actionLabel: 'Tentar novamente',
        onAction: _retryLibraries,
      );
    }
    if (!_loadingLibraries && _libraries.isEmpty) {
      return _CenteredMessageState(
        palette: palette,
        icon: Icons.video_library_outlined,
        title: 'Nenhuma biblioteca disponível',
        message: 'Este servidor não retornou bibliotecas acessíveis para esta conta.',
        actionLabel: 'Atualizar',
        onAction: _retryLibraries,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchBar(
          palette: palette,
          controller: _searchController,
          hasSearchText: _searchQuery.isNotEmpty || _searchController.text.isNotEmpty,
          searchAllServer: _searchAllServer,
          showScopeToggle: _searchQuery.isNotEmpty,
          onChanged: _onSearchChanged,
          onSubmitted: _applySearchImmediate,
          onClear: _clearSearch,
          onToggleScope: _toggleSearchScope,
        ),
        Expanded(child: _buildItemsContent(palette, server)),
      ],
    );
  }

  Widget _buildItemsContent(_LibraryPalette palette, DesktopServerConnection server) {
    if (_loadingItems && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_itemsError != null && _items.isEmpty) {
      return _CenteredMessageState(
        palette: palette,
        icon: Icons.cloud_off_outlined,
        title: 'Erro ao carregar acervo',
        message: _itemsError!,
        actionLabel: 'Tentar novamente',
        onAction: () => unawaited(_loadItems(reset: true)),
      );
    }
    if (!_loadingItems && _itemsError == null && _items.isEmpty) {
      final hasQuery = _searchQuery.isNotEmpty;
      return _CenteredMessageState(
        palette: palette,
        icon: hasQuery ? Icons.search_off : Icons.movie_filter_outlined,
        title: hasQuery ? 'Nenhum resultado encontrado' : 'Acervo vazio',
        message: hasQuery
            ? 'Nenhum item corresponde ao termo pesquisado.'
            : 'Nenhum item encontrado nesta biblioteca.',
      );
    }

    final textScaler = MediaQuery.textScalerOf(context);
    final cardExtent = 216.0 + textScaler.scale(68.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
          child: Text(
            _totalCount > 0 ? 'Exibindo ${_items.length} de $_totalCount' : 'Exibindo ${_items.length}',
            style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted),
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _gridScrollController,
            padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 230.0,
              mainAxisSpacing: 14.0,
              crossAxisSpacing: 14.0,
              mainAxisExtent: cardExtent,
            ),
            itemCount: _items.length + (_hasMore || _itemsError != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _items.length) {
                return _LoadMoreTile(
                  palette: palette,
                  loadingMore: _loadingMore,
                  error: _itemsError,
                  hasMore: _hasMore,
                  onLoadMore: () => unawaited(_loadItems(reset: false)),
                );
              }
              final item = _items[index];
              final rawThumb = item.thumbPath;
              final thumbUrl = (rawThumb != null && rawThumb.isNotEmpty)
                  ? server.client.thumbnailUrl(rawThumb)
                  : null;
              return _MediaGridCard(
                palette: palette,
                item: item,
                imageUrl: thumbUrl,
                headers: server.client.streamHeaders,
                selected: _detailItem?.id == item.id,
                onTap: () => _openItemDetail(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPanel(
    _LibraryPalette palette,
    DesktopServerConnection server, {
    required bool fullWidth,
  }) {
    final item = _detailItem!;
    return _MediaDetailPanel(
      palette: palette,
      item: item,
      parentBreadcrumbTitle: _detailBreadcrumbs.isNotEmpty ? _detailBreadcrumbs.last.displayTitle : null,
      onDeckEpisode: _onDeckEpisode,
      children: _children,
      childrenTotalCount: _childrenTotalCount,
      childrenHasMore: _childrenHasMore,
      loadingChildren: _loadingChildren,
      loadingMoreChildren: _loadingMoreChildren,
      childrenError: _childrenError,
      selectedVersionIndex: _selectedVersionIndex,
      startingPlayback: _startingPlayback,
      playbackError: _playbackError,
      fullWidth: fullWidth,
      onClose: _closeDetail,
      onBackBreadcrumb: _popDetailBreadcrumb,
      onSelectVersion: (index) => setState(() => _selectedVersionIndex = index),
      onPlayItem: (target, versionIndex) => unawaited(_playItem(target, versionIndex: versionIndex)),
      onOpenChild: (child) => _openItemDetail(child, pushBreadcrumb: true),
      onRetryChildren: () {
        final abort = _detailAbort ?? AbortController();
        _detailAbort = abort;
        setState(() {
          _loadingChildren = true;
          _childrenError = null;
        });
        unawaited(_loadChildrenPage(server, item, _detailEpoch, abort, reset: true));
      },
      onLoadMoreChildren: () {
        final abort = _detailAbort ?? AbortController();
        _detailAbort = abort;
        unawaited(_loadChildrenPage(server, item, _detailEpoch, abort, reset: false));
      },
    );
  }
}

class _LibraryPalette {
  const _LibraryPalette({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.seal,
    required this.text,
    required this.textMuted,
    required this.error,
    required this.errorContainer,
  });

  final Color background;
  final Color surface;
  final Color elevated;
  final Color line;
  final Color primary;
  final Color onPrimary;
  final Color seal;
  final Color text;
  final Color textMuted;
  final Color error;
  final Color errorContainer;

  factory _LibraryPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _LibraryPalette(
      background: isDark ? HeisucaTheme.roxoFundo : theme.scaffoldBackgroundColor,
      surface: isDark ? HeisucaTheme.roxoSuperficie : scheme.surface,
      elevated: isDark ? HeisucaTheme.roxoSuperficieElevada : scheme.surfaceContainerHighest,
      line: isDark ? HeisucaTheme.roxoLinha : scheme.outlineVariant,
      primary: isDark ? HeisucaTheme.roxoPrimaria : scheme.primary,
      onPrimary: isDark ? Colors.white : scheme.onPrimary,
      seal: HeisucaTheme.roxoSelo,
      text: isDark ? Colors.white : scheme.onSurface,
      textMuted: isDark ? const Color(0xFFB7B4C4) : scheme.onSurfaceVariant,
      error: scheme.error,
      errorContainer: scheme.errorContainer,
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.palette,
    required this.selectedServer,
    required this.onBack,
    required this.onConnectPlex,
    required this.onConnectJellyfin,
  });

  final _LibraryPalette palette;
  final DesktopServerConnection? selectedServer;
  final VoidCallback onBack;
  final VoidCallback onConnectPlex;
  final VoidCallback onConnectJellyfin;

  @override
  Widget build(BuildContext context) {
    final server = selectedServer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 10.0,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 12.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18.0),
                label: const Text('Voltar'),
              ),
              Text(
                'Bibliotecas',
                style: HeisucaTypography.titleHero.copyWith(color: palette.text),
              ),
              if (server != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: palette.elevated,
                    borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioPilula)),
                    border: Border.fromBorderSide(BorderSide(color: palette.line)),
                  ),
                  child: Text(
                    '${_backendLabel(server.backend)} · ${server.name} · ${_healthLabel(server.health)}',
                    style: HeisucaTypography.bodyMetadata.copyWith(color: palette.text),
                  ),
                ),
            ],
          ),
          Wrap(
            spacing: 10.0,
            runSpacing: 8.0,
            children: [
              OutlinedButton.icon(
                onPressed: onConnectPlex,
                icon: const Icon(Icons.cast_connected, size: 18.0),
                label: const Text('Conectar Plex'),
              ),
              FilledButton.icon(
                onPressed: onConnectJellyfin,
                icon: const Icon(Icons.dns_outlined, size: 18.0),
                label: const Text('Conectar Jellyfin'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanners extends StatelessWidget {
  const _StatusBanners({required this.palette, required this.servers});

  final _LibraryPalette palette;
  final DesktopServersController servers;

  @override
  Widget build(BuildContext context) {
    final hasBanner = !servers.persistentSessions || servers.restoring || servers.error != null;
    if (!hasBanner) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!servers.persistentSessions)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: palette.elevated,
              border: Border(bottom: BorderSide(color: palette.line)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16.0, color: palette.textMuted),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Sessão temporária: a sessão termina ao fechar o aplicativo.',
                    style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted),
                  ),
                ),
              ],
            ),
          ),
        if (servers.restoring)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(bottom: BorderSide(color: palette.line)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 14.0,
                  height: 14.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'Restaurando conexões...',
                    style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted),
                  ),
                ),
              ],
            ),
          ),
        if (servers.error != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: palette.errorContainer,
              border: Border(bottom: BorderSide(color: palette.line)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18.0, color: palette.error),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    servers.error!,
                    style: HeisucaTypography.bodyMetadata.copyWith(color: palette.text),
                  ),
                ),
                TextButton(
                  onPressed: servers.clearError,
                  child: const Text('Dispensar'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ServersBar extends StatelessWidget {
  const _ServersBar({
    required this.palette,
    required this.connections,
    required this.selectedServerId,
    required this.onSelectServer,
    required this.onDisconnect,
  });

  final _LibraryPalette palette;
  final List<DesktopServerConnection> connections;
  final String? selectedServerId;
  final ValueChanged<DesktopServerConnection> onSelectServer;
  final ValueChanged<String> onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Fontes:',
            style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted),
          ),
          for (final conn in connections)
            _ServerChip(
              palette: palette,
              connection: conn,
              selected: conn.id == selectedServerId,
              onSelect: () => onSelectServer(conn),
              onDisconnect: () => onDisconnect(conn.id),
            ),
        ],
      ),
    );
  }
}

class _ServerChip extends StatelessWidget {
  const _ServerChip({
    required this.palette,
    required this.connection,
    required this.selected,
    required this.onSelect,
    required this.onDisconnect,
  });

  final _LibraryPalette palette;
  final DesktopServerConnection connection;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? palette.primary.withValues(alpha: 0.22) : palette.elevated,
        borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioPilula)),
        border: Border.fromBorderSide(BorderSide(color: selected ? palette.primary : palette.line)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onSelect,
            borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioPilula)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Text(
                '${_backendLabel(connection.backend)}: ${connection.name}',
                style: HeisucaTypography.bodyMetadata.copyWith(
                  color: palette.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onDisconnect,
            tooltip: 'Desconectar ${connection.name}',
            visualDensity: VisualDensity.compact,
            iconSize: 16.0,
            icon: Icon(Icons.close, color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _EmptyConnectionsView extends StatelessWidget {
  const _EmptyConnectionsView({
    required this.palette,
    required this.restoring,
    required this.persistentSessions,
    required this.onConnectPlex,
    required this.onConnectJellyfin,
  });

  final _LibraryPalette palette;
  final bool restoring;
  final bool persistentSessions;
  final VoidCallback onConnectPlex;
  final VoidCallback onConnectJellyfin;

  @override
  Widget build(BuildContext context) {
    if (restoring) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioCard)),
              border: Border.fromBorderSide(BorderSide(color: palette.line)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.library_books_outlined, size: 44.0, color: palette.textMuted),
                const SizedBox(height: 14.0),
                Text(
                  'Nenhum servidor conectado',
                  textAlign: TextAlign.center,
                  style: HeisucaTypography.titleSection.copyWith(color: palette.text),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Conecte uma conta Plex ou um servidor Jellyfin para navegar e reproduzir seu acervo.',
                  textAlign: TextAlign.center,
                  style: HeisucaTypography.bodySynopsis.copyWith(color: palette.textMuted),
                ),
                if (!persistentSessions) ...[
                  const SizedBox(height: 10.0),
                  Text(
                    'Neste sistema, a sessão termina ao fechar o aplicativo.',
                    textAlign: TextAlign.center,
                    style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted),
                  ),
                ],
                const SizedBox(height: 20.0),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 10.0,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onConnectPlex,
                      icon: const Icon(Icons.cast_connected, size: 18.0),
                      label: const Text('Conectar Plex'),
                    ),
                    FilledButton.icon(
                      onPressed: onConnectJellyfin,
                      icon: const Icon(Icons.dns_outlined, size: 18.0),
                      label: const Text('Conectar Jellyfin'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibrariesSidebar extends StatelessWidget {
  const _LibrariesSidebar({
    required this.palette,
    required this.libraries,
    required this.selectedLibrary,
    required this.loading,
    required this.error,
    required this.onSelect,
    required this.onRetry,
  });

  final _LibraryPalette palette;
  final List<MediaLibrary> libraries;
  final MediaLibrary? selectedLibrary;
  final bool loading;
  final String? error;
  final ValueChanged<MediaLibrary> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(right: BorderSide(color: palette.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 8.0),
            child: Text(
              'Acervos',
              style: HeisucaTypography.labelBadge.copyWith(color: palette.textMuted),
            ),
          ),
          if (loading && libraries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null && libraries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error!, style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted)),
                  const SizedBox(height: 8.0),
                  TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                itemCount: libraries.length,
                itemBuilder: (context, index) {
                  final lib = libraries[index];
                  final selected = selectedLibrary?.id == lib.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Material(type: MaterialType.transparency, child: ListTile(
                      selected: selected,
                      selectedTileColor: palette.primary.withValues(alpha: 0.18),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(HeisucaTheme.raioSquircle)),
                      ),
                      title: Text(
                        lib.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: HeisucaTypography.bodyMetadata.copyWith(
                          color: palette.text,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: lib.kind == MediaKind.unknown
                          ? null
                          : Text(
                              _kindLabel(lib.kind),
                              style: HeisucaTypography.labelBadge.copyWith(color: palette.textMuted),
                            ),
                      onTap: () => onSelect(lib),
                    )),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LibrariesStrip extends StatelessWidget {
  const _LibrariesStrip({
    required this.palette,
    required this.libraries,
    required this.selectedLibrary,
    required this.loading,
    required this.error,
    required this.onSelect,
    required this.onRetry,
  });

  final _LibraryPalette palette;
  final List<MediaLibrary> libraries;
  final MediaLibrary? selectedLibrary;
  final bool loading;
  final String? error;
  final ValueChanged<MediaLibrary> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && libraries.isEmpty) {
      return const SizedBox.shrink();
    }
    if (error != null && libraries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Wrap(
          spacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(error!, style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted)),
            TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (libraries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final lib in libraries)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(lib.title),
                  selected: selectedLibrary?.id == lib.id,
                  onSelected: (_) => onSelect(lib),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.palette,
    required this.controller,
    required this.hasSearchText,
    required this.searchAllServer,
    required this.showScopeToggle,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onToggleScope,
  });

  final _LibraryPalette palette;
  final TextEditingController controller;
  final bool hasSearchText;
  final bool searchAllServer;
  final bool showScopeToggle;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;
  final ValueChanged<bool> onToggleScope;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por título na biblioteca',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: hasSearchText
                        ? IconButton(
                            onPressed: onClear,
                            tooltip: 'Limpar busca',
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    filled: true,
                    fillColor: palette.elevated,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(HeisucaTheme.raioInput)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              FilledButton(
                onPressed: onSubmitted,
                child: const Text('Buscar'),
              ),
            ],
          ),
          if (showScopeToggle)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: [
                  ChoiceChip(
                    label: const Text('Nesta biblioteca'),
                    selected: !searchAllServer,
                    onSelected: (_) => onToggleScope(false),
                  ),
                  ChoiceChip(
                    label: const Text('Todo o servidor'),
                    selected: searchAllServer,
                    onSelected: (_) => onToggleScope(true),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaGridCard extends StatefulWidget {
  const _MediaGridCard({
    required this.palette,
    required this.item,
    required this.imageUrl,
    required this.headers,
    required this.selected,
    required this.onTap,
  });

  final _LibraryPalette palette;
  final MediaItem item;
  final String? imageUrl;
  final Map<String, String> headers;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MediaGridCard> createState() => _MediaGridCardState();
}

class _MediaGridCardState extends State<_MediaGridCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final palette = widget.palette;
    final borderColor = _focused || widget.selected ? palette.primary : palette.line;
    final borderWidth = _focused || widget.selected ? 2.0 : 1.0;
    final metaParts = <String>[
      _kindLabel(item.kind),
      if (item.year != null) '${item.year}',
    ];

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioCard)),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _CardArtwork(
                imageUrl: widget.imageUrl,
                headers: widget.headers,
                kind: item.kind,
                elevatedColor: palette.elevated,
                mutedColor: palette.textMuted,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.displayTitle.isNotEmpty ? item.displayTitle : 'Sem título',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: HeisucaTypography.bodyMetadata.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    metaParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HeisucaTypography.labelBadge.copyWith(color: palette.textMuted),
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

class _CardArtwork extends StatelessWidget {
  const _CardArtwork({
    required this.imageUrl,
    required this.headers,
    required this.kind,
    required this.elevatedColor,
    required this.mutedColor,
  });

  final String? imageUrl;
  final Map<String, String> headers;
  final MediaKind kind;
  final Color elevatedColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _ArtworkFallback(kind: kind, elevatedColor: elevatedColor, mutedColor: mutedColor);
    }
    return ColoredBox(
      color: elevatedColor,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        headers: headers,
        errorBuilder: (context, error, stackTrace) {
          return _ArtworkFallback(kind: kind, elevatedColor: elevatedColor, mutedColor: mutedColor);
        },
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({
    required this.kind,
    required this.elevatedColor,
    required this.mutedColor,
  });

  final MediaKind kind;
  final Color elevatedColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: elevatedColor,
      child: Center(
        child: Icon(_kindIcon(kind), size: 36.0, color: mutedColor),
      ),
    );
  }
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({
    required this.palette,
    required this.loadingMore,
    required this.error,
    required this.hasMore,
    required this.onLoadMore,
  });

  final _LibraryPalette palette;
  final bool loadingMore;
  final String? error;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioCard)),
        border: Border.fromBorderSide(BorderSide(color: palette.line)),
      ),
      child: Center(
        child: loadingMore
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null) ...[
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: HeisucaTypography.bodyMetadata.copyWith(color: palette.error),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                  if (hasMore)
                    OutlinedButton(
                      onPressed: onLoadMore,
                      child: Text(error != null ? 'Tentar novamente' : 'Carregar mais'),
                    ),
                ],
              ),
      ),
    );
  }
}

class _CenteredMessageState extends StatelessWidget {
  const _CenteredMessageState({
    required this.palette,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final _LibraryPalette palette;
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40.0, color: palette.textMuted),
              const SizedBox(height: 12.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: HeisucaTypography.titleSection.copyWith(color: palette.text),
              ),
              const SizedBox(height: 8.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: HeisucaTypography.bodySynopsis.copyWith(color: palette.textMuted),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16.0),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaDetailPanel extends StatelessWidget {
  const _MediaDetailPanel({
    required this.palette,
    required this.item,
    required this.parentBreadcrumbTitle,
    required this.onDeckEpisode,
    required this.children,
    required this.childrenTotalCount,
    required this.childrenHasMore,
    required this.loadingChildren,
    required this.loadingMoreChildren,
    required this.childrenError,
    required this.selectedVersionIndex,
    required this.startingPlayback,
    required this.playbackError,
    required this.fullWidth,
    required this.onClose,
    required this.onBackBreadcrumb,
    required this.onSelectVersion,
    required this.onPlayItem,
    required this.onOpenChild,
    required this.onRetryChildren,
    required this.onLoadMoreChildren,
  });

  final _LibraryPalette palette;
  final MediaItem item;
  final String? parentBreadcrumbTitle;
  final MediaItem? onDeckEpisode;
  final List<MediaItem> children;
  final int childrenTotalCount;
  final bool childrenHasMore;
  final bool loadingChildren;
  final bool loadingMoreChildren;
  final String? childrenError;
  final int selectedVersionIndex;
  final bool startingPlayback;
  final String? playbackError;
  final bool fullWidth;
  final VoidCallback onClose;
  final VoidCallback onBackBreadcrumb;
  final ValueChanged<int> onSelectVersion;
  final void Function(MediaItem target, int? versionIndex) onPlayItem;
  final ValueChanged<MediaItem> onOpenChild;
  final VoidCallback onRetryChildren;
  final VoidCallback onLoadMoreChildren;

  @override
  Widget build(BuildContext context) {
    final versions = item.mediaVersions ?? const <MediaVersion>[];
    final hasMultipleVersions = versions.length > 1;
    final safeVersionIndex = versions.isEmpty ? 0 : selectedVersionIndex.clamp(0, versions.length - 1);
    final canPlaySelectedVersion = !hasMultipleVersions || versions[safeVersionIndex].isPlayable;
    final canPlayDirect = item.kind.isPlayable || item.kind == MediaKind.show;
    final metadata = _collectMetadataBadges(item);
    final hasChildrenSection = _shouldFetchChildren(item);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onClose,
      },
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          border: fullWidth ? null : Border(left: BorderSide(color: palette.line)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (parentBreadcrumbTitle != null)
                    TextButton.icon(
                      onPressed: onBackBreadcrumb,
                      icon: const Icon(Icons.chevron_left),
                      label: Text('Voltar para $parentBreadcrumbTitle'),
                    )
                  else
                    Text(
                      _kindLabel(item.kind),
                      style: HeisucaTypography.labelBadge.copyWith(color: palette.textMuted),
                    ),
                  OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 16.0),
                    label: Text(fullWidth ? 'Voltar à grade' : 'Fechar'),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                item.displayTitle.isNotEmpty ? item.displayTitle : (item.title ?? 'Sem título'),
                style: HeisucaTypography.titleHero.copyWith(color: palette.text),
              ),
              if (item.displaySubtitle != null && item.displaySubtitle!.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Text(
                  item.displaySubtitle!,
                  style: HeisucaTypography.titleSection.copyWith(color: palette.textMuted),
                ),
              ],
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: [
                    for (final entry in metadata)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: palette.elevated,
                          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                          border: Border.fromBorderSide(BorderSide(color: palette.line)),
                        ),
                        child: Text(
                          entry,
                          style: HeisucaTypography.bodyMetadata.copyWith(color: palette.text),
                        ),
                      ),
                  ],
                ),
              ],
              if (item.genres != null && item.genres!.isNotEmpty) ...[
                const SizedBox(height: 10.0),
                Text(
                  item.genres!.join(' · '),
                  style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted),
                ),
              ],
              if (item.summary != null && item.summary!.trim().isNotEmpty) ...[
                const SizedBox(height: 14.0),
                Text(
                  item.summary!.trim(),
                  style: HeisucaTypography.bodySynopsis.copyWith(color: palette.text),
                ),
              ],
              if (hasMultipleVersions) ...[
                const SizedBox(height: 16.0),
                Text(
                  'Versões disponíveis',
                  style: HeisucaTypography.titleSection.copyWith(color: palette.text),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    for (var i = 0; i < versions.length; i++)
                      ChoiceChip(
                        label: Text(
                          versions[i].isPlayable
                              ? _formatMediaVersionLabel(versions[i], i)
                              : '${_formatMediaVersionLabel(versions[i], i)} (Indisponível)',
                        ),
                        selected: safeVersionIndex == i,
                        onSelected: versions[i].isPlayable ? (_) => onSelectVersion(i) : null,
                      ),
                  ],
                ),
              ],
              if (playbackError != null) ...[
                const SizedBox(height: 12.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: palette.errorContainer,
                    borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioInput)),
                    border: Border.fromBorderSide(BorderSide(color: palette.error)),
                  ),
                  child: Text(
                    playbackError!,
                    style: HeisucaTypography.bodyMetadata.copyWith(color: palette.text),
                  ),
                ),
              ],
              if (canPlayDirect || (item.kind == MediaKind.show && onDeckEpisode != null)) ...[
                const SizedBox(height: 16.0),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    if (item.kind == MediaKind.show && onDeckEpisode != null)
                      FilledButton.icon(
                        onPressed: startingPlayback ? null : () => onPlayItem(onDeckEpisode!, null),
                        icon: const Icon(Icons.play_arrow),
                        label: Text('Continuar: ${_formatEpisodeSummary(onDeckEpisode!)}'),
                      ),
                    if (canPlayDirect)
                      FilledButton.icon(
                        onPressed: startingPlayback || !canPlaySelectedVersion
                            ? null
                            : () => onPlayItem(
                                  item,
                                  hasMultipleVersions ? safeVersionIndex : null,
                                ),
                        icon: startingPlayback
                            ? const SizedBox(
                                width: 16.0,
                                height: 16.0,
                                child: CircularProgressIndicator(strokeWidth: 2.0),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(
                          item.kind == MediaKind.show
                              ? 'Assistir série'
                              : (item.hasActiveProgress ? 'Continuar' : 'Assistir'),
                        ),
                      ),
                  ],
                ),
              ],
              if (hasChildrenSection) ...[
                const SizedBox(height: 20.0),
                Text(
                  _childrenSectionTitle(item.kind, childrenTotalCount),
                  style: HeisucaTypography.titleSection.copyWith(color: palette.text),
                ),
                const SizedBox(height: 10.0),
                if (loadingChildren && children.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (childrenError != null && children.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childrenError!,
                        style: HeisucaTypography.bodyMetadata.copyWith(color: palette.error),
                      ),
                      const SizedBox(height: 8.0),
                      OutlinedButton(onPressed: onRetryChildren, child: const Text('Tentar novamente')),
                    ],
                  )
                else if (children.isEmpty)
                  Text(
                    _emptyChildrenMessage(item.kind),
                    style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final child in children)
                        _ChildMediaRow(
                          palette: palette,
                          child: child,
                          startingPlayback: startingPlayback,
                          onOpen: () => onOpenChild(child),
                          onPlay: child.kind.isPlayable ? () => onPlayItem(child, null) : null,
                        ),
                      if (childrenError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            childrenError!,
                            style: HeisucaTypography.bodyMetadata.copyWith(color: palette.error),
                          ),
                        ),
                      if (childrenHasMore)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: OutlinedButton(
                            onPressed: loadingMoreChildren ? null : onLoadMoreChildren,
                            child: Text(loadingMoreChildren ? 'Carregando...' : 'Carregar mais'),
                          ),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildMediaRow extends StatelessWidget {
  const _ChildMediaRow({
    required this.palette,
    required this.child,
    required this.startingPlayback,
    required this.onOpen,
    this.onPlay,
  });

  final _LibraryPalette palette;
  final MediaItem child;
  final bool startingPlayback;
  final VoidCallback onOpen;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final duration = child.durationMs != null ? _formatDuration(child.durationMs!) : null;
    final subtitleParts = <String>[
      if (child.kind == MediaKind.episode) _formatEpisodeIndex(child),
      ?duration,
      if (child.kind == MediaKind.season && child.leafCount != null) '${child.leafCount} episódios',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: palette.elevated,
        borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioSquircle)),
        border: Border.fromBorderSide(BorderSide(color: palette.line)),
      ),
      child: Material(type: MaterialType.transparency, child: ListTile(
        onTap: onOpen,
        title: Text(
          child.title?.isNotEmpty == true ? child.title! : child.displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: HeisucaTypography.bodyMetadata.copyWith(color: palette.text, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitleParts.isNotEmpty
            ? Text(
                subtitleParts.join(' · '),
                style: HeisucaTypography.labelBadge.copyWith(color: palette.textMuted),
              )
            : null,
        trailing: onPlay != null
            ? IconButton(
                onPressed: startingPlayback ? null : onPlay,
                tooltip: 'Assistir',
                icon: const Icon(Icons.play_circle_outline),
              )
            : const Icon(Icons.chevron_right),
      )),
    );
  }
}

class _PlexSignInDialog extends StatefulWidget {
  const _PlexSignInDialog({required this.servers});

  final DesktopServersController servers;

  @override
  State<_PlexSignInDialog> createState() => _PlexSignInDialogState();
}

class _PlexSignInDialogState extends State<_PlexSignInDialog> {
  bool _dismissedByUser = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startAuth());
    });
  }

  Future<void> _startAuth() async {
    widget.servers.clearError();
    await widget.servers.signInPlex(
      openBrowser: (uri) async {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw StateError('browser');
        }
      },
    );
    if (!mounted || _dismissedByUser) return;
    if (widget.servers.error == null && !widget.servers.busy) {
      _completed = true;
      Navigator.of(context).pop();
    }
  }

  void _cancelAndClose() {
    _dismissedByUser = true;
    widget.servers.cancelAuthentication();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _LibraryPalette.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_completed && !_dismissedByUser) {
          _dismissedByUser = true;
          widget.servers.cancelAuthentication();
        }
      },
      child: AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          'Conectar conta Plex',
          style: HeisucaTypography.titleSection.copyWith(color: palette.text),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440.0),
          child: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: widget.servers,
              builder: (context, child) {
                final code = widget.servers.plexCode;
                final error = widget.servers.error;
                final busy = widget.servers.busy;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Confirme o acesso na janela do navegador usando o código exibido abaixo.',
                      style: HeisucaTypography.bodySynopsis.copyWith(color: palette.textMuted),
                    ),
                    const SizedBox(height: 16.0),
                    if (busy && code == null)
                      const Center(child: CircularProgressIndicator()),
                    if (code != null && code.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        decoration: BoxDecoration(
                          color: palette.elevated,
                          borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioInput)),
                          border: Border.fromBorderSide(BorderSide(color: palette.primary)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Código Plex',
                              style: HeisucaTypography.labelBadge.copyWith(color: palette.textMuted),
                            ),
                            const SizedBox(height: 6.0),
                            SelectableText(
                              code,
                              textAlign: TextAlign.center,
                              style: HeisucaTypography.titleHero.copyWith(
                                color: palette.text,
                                letterSpacing: 4.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (busy) ...[
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            const SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(strokeWidth: 2.0),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                'Aguardando confirmação...',
                                style: HeisucaTypography.bodyMetadata.copyWith(color: palette.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12.0),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: palette.errorContainer,
                          borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioInput)),
                          border: Border.fromBorderSide(BorderSide(color: palette.error)),
                        ),
                        child: Text(
                          error,
                          style: HeisucaTypography.bodyMetadata.copyWith(color: palette.text),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cancelAndClose,
            child: const Text('Cancelar'),
          ),
          ListenableBuilder(
            listenable: widget.servers,
            builder: (context, child) {
              if (widget.servers.busy || widget.servers.error == null) {
                return const SizedBox.shrink();
              }
              return FilledButton(
                onPressed: () => unawaited(_startAuth()),
                child: const Text('Tentar novamente'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JellyfinSignInDialog extends StatefulWidget {
  const _JellyfinSignInDialog({required this.servers});

  final DesktopServersController servers;

  @override
  State<_JellyfinSignInDialog> createState() => _JellyfinSignInDialogState();
}

class _JellyfinSignInDialogState extends State<_JellyfinSignInDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _validationError;
  bool _submitting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    widget.servers.clearError();
  }

  @override
  void dispose() {
    _passwordController.clear();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty || rawUrl.runes.any((r) => r <= 0x20)) {
      return 'Informe um endereço HTTP ou HTTPS válido.';
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return 'O endereço deve iniciar com http:// ou https://.';
    }
    if (_usernameController.text.trim().isEmpty) {
      return 'Informe o nome de usuário.';
    }
    if (_passwordController.text.isEmpty) {
      return 'Informe a senha.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || widget.servers.busy) return;
    final validation = _validateInputs();
    if (validation != null) {
      setState(() => _validationError = validation);
      return;
    }

    final baseUrl = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _validationError = null;
      _submitting = true;
    });
    widget.servers.clearError();

    try {
      await widget.servers.signInJellyfin(
        baseUrl: baseUrl,
        username: username,
        password: password,
      );
    } finally {
      _passwordController.clear();
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    if (widget.servers.error == null && !widget.servers.busy) {
      _completed = true;
      Navigator.of(context).pop();
    }
  }

  void _cancelAndClose() {
    if (_submitting || widget.servers.busy) {
      widget.servers.cancelAuthentication();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _LibraryPalette.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_completed && (_submitting || widget.servers.busy)) {
          widget.servers.cancelAuthentication();
        }
      },
      child: AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          'Conectar servidor Jellyfin',
          style: HeisucaTypography.titleSection.copyWith(color: palette.text),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460.0),
          child: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: widget.servers,
              builder: (context, child) {
                final busy = _submitting || widget.servers.busy;
                final controllerError = widget.servers.error;
                final displayedError = _validationError ?? controllerError;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _urlController,
                      enabled: !busy,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Endereço do servidor',
                        hintText: 'https://servidor:8096',
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: _usernameController,
                      enabled: !busy,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Usuário'),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: _passwordController,
                      enabled: !busy,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => unawaited(_submit()),
                      decoration: const InputDecoration(labelText: 'Senha'),
                    ),
                    if (displayedError != null) ...[
                      const SizedBox(height: 12.0),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: palette.errorContainer,
                          borderRadius: const BorderRadius.all(Radius.circular(HeisucaTheme.raioInput)),
                          border: Border.fromBorderSide(BorderSide(color: palette.error)),
                        ),
                        child: Text(
                          displayedError,
                          style: HeisucaTypography.bodyMetadata.copyWith(color: palette.text),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cancelAndClose,
            child: const Text('Cancelar'),
          ),
          ListenableBuilder(
            listenable: widget.servers,
            builder: (context, child) {
              final busy = _submitting || widget.servers.busy;
              return FilledButton(
                onPressed: busy ? null : () => unawaited(_submit()),
                child: busy
                    ? const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Text('Entrar'),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _itemIdentityKey(DesktopServerConnection server, MediaItem item) => '${server.id}:${item.id}';

bool _shouldFetchChildren(MediaItem item) {
  return switch (item.kind) {
    MediaKind.show ||
    MediaKind.season ||
    MediaKind.artist ||
    MediaKind.album ||
    MediaKind.collection ||
    MediaKind.playlist ||
    MediaKind.folder => true,
    _ => false,
  };
}

int _defaultPlayableVersionIndex(List<MediaVersion>? versions) {
  if (versions == null || versions.isEmpty) return 0;
  for (var i = 0; i < versions.length; i++) {
    if (versions[i].isPlayable) return i;
  }
  return 0;
}

String _backendLabel(MediaBackend backend) {
  return switch (backend) {
    MediaBackend.plex => 'Plex',
    MediaBackend.jellyfin => 'Jellyfin',
    MediaBackend.emby => 'Emby',
  };
}

String _healthLabel(HealthStatus health) {
  return switch (health) {
    HealthStatus.online => 'Online',
    HealthStatus.offline => 'Offline',
    HealthStatus.authError => 'Autenticação necessária',
    HealthStatus.accessDenied => 'Acesso negado',
  };
}

String _kindLabel(MediaKind kind) {
  return switch (kind) {
    MediaKind.movie => 'Filme',
    MediaKind.show => 'Série',
    MediaKind.season => 'Temporada',
    MediaKind.episode => 'Episódio',
    MediaKind.artist => 'Artista',
    MediaKind.album => 'Álbum',
    MediaKind.track => 'Faixa',
    MediaKind.collection => 'Coleção',
    MediaKind.playlist => 'Playlist',
    MediaKind.clip => 'Clipe',
    MediaKind.photo => 'Foto',
    MediaKind.folder => 'Pasta',
    MediaKind.unknown => 'Mídia',
  };
}

IconData _kindIcon(MediaKind kind) {
  return switch (kind) {
    MediaKind.movie || MediaKind.clip => Icons.movie_outlined,
    MediaKind.show || MediaKind.season || MediaKind.episode => Icons.tv_outlined,
    MediaKind.artist || MediaKind.album || MediaKind.track => Icons.music_note_outlined,
    MediaKind.collection || MediaKind.playlist => Icons.collections_bookmark_outlined,
    MediaKind.photo => Icons.photo_outlined,
    MediaKind.folder => Icons.folder_outlined,
    MediaKind.unknown => Icons.video_library_outlined,
  };
}

String _childrenSectionTitle(MediaKind kind, int totalCount) {
  final base = switch (kind) {
    MediaKind.show => 'Temporadas',
    MediaKind.season => 'Episódios',
    MediaKind.album => 'Faixas',
    MediaKind.artist => 'Álbuns',
    _ => 'Itens relacionados',
  };
  return totalCount > 0 ? '$base ($totalCount)' : base;
}

String _emptyChildrenMessage(MediaKind kind) {
  return switch (kind) {
    MediaKind.show => 'Nenhuma temporada encontrada.',
    MediaKind.season => 'Nenhum episódio encontrado.',
    _ => 'Nenhum item relacionado encontrado.',
  };
}

List<String> _collectMetadataBadges(MediaItem item) {
  final badges = <String>[_kindLabel(item.kind)];
  if (item.year != null) badges.add('${item.year}');
  final ratingText = item.contentRating?.trim();
  if (ratingText != null && ratingText.isNotEmpty) badges.add(ratingText);
  if (item.durationMs != null && item.durationMs! > 0) {
    badges.add(_formatDuration(item.durationMs!));
  }
  if (item.rating != null && item.rating! > 0.0) {
    badges.add('Nota ${item.rating!.toStringAsFixed(1)}');
  }
  final studio = item.studio?.trim();
  if (studio != null && studio.isNotEmpty) badges.add(studio);
  if (item.kind == MediaKind.episode) {
    final epIdx = _formatEpisodeIndex(item);
    if (epIdx.isNotEmpty) badges.add(epIdx);
  }
  return badges;
}

String _formatDuration(int durationMs) {
  final totalMinutes = (durationMs / 60000.0).round();
  if (totalMinutes < 60) return '${totalMinutes < 1 ? 1 : totalMinutes} min';
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  return mins == 0 ? '${hours}h' : '${hours}h ${mins}min';
}

String _formatEpisodeIndex(MediaItem episode) {
  final s = episode.parentIndex;
  final e = episode.index;
  if (s != null && e != null) return 'T$s E$e';
  if (e != null) return 'Episódio $e';
  return '';
}

String _formatEpisodeSummary(MediaItem episode) {
  final prefix = _formatEpisodeIndex(episode);
  final title = episode.title?.trim() ?? '';
  if (prefix.isNotEmpty && title.isNotEmpty) return '$prefix · $title';
  if (title.isNotEmpty) return title;
  if (prefix.isNotEmpty) return prefix;
  return 'Próximo episódio';
}

String _formatMediaVersionLabel(MediaVersion version, int index) {
  final details = <String>[];
  final resolution = version.videoResolution?.trim();
  if (resolution != null && resolution.isNotEmpty) {
    final lower = resolution.toLowerCase();
    if (lower == '4k' || lower == '8k' || lower == 'sd' || lower == 'hd') {
      details.add(resolution.toUpperCase());
    } else if (int.tryParse(resolution) != null) {
      details.add('${resolution}p');
    } else {
      details.add(resolution);
    }
  } else if (version.height != null && version.height! > 0) {
    details.add('${version.height}p');
  }

  final codec = version.videoCodec?.trim();
  if (codec != null && codec.isNotEmpty) {
    details.add(codec.toUpperCase());
  }

  final container = version.container?.trim();
  if (container != null && container.isNotEmpty) {
    details.add(container.toUpperCase());
  }

  final kbps = bitrateKbpsFromBps(version.bitrate);
  if (kbps != null) {
    if (kbps >= 1000) {
      details.add('${(kbps / 1000.0).toStringAsFixed(1)} Mbps');
    } else {
      details.add('$kbps kbps');
    }
  }

  var totalBytes = 0;
  for (final part in version.parts) {
    if (part.sizeBytes != null && part.sizeBytes! > 0) {
      totalBytes += part.sizeBytes!;
    }
  }
  if (totalBytes > 0) {
    const oneGb = 1024 * 1024 * 1024;
    const oneMb = 1024 * 1024;
    if (totalBytes >= oneGb) {
      details.add('${(totalBytes / oneGb).toStringAsFixed(1)} GB');
    } else {
      details.add('${(totalBytes / oneMb).round()} MB');
    }
  }

  final summary = details.isNotEmpty ? details.join(' · ') : 'Versão ${index + 1}';
  final name = version.name?.trim();
  if (name != null && name.isNotEmpty) {
    return details.isEmpty ? name : '$name · $summary';
  }
  return summary;
}
