import '../utils/grid_size_calculator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cgflix/cgflix_palette.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../media/library_query.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../mixins/refreshable.dart';
import '../providers/multi_server_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import 'heisuca_media_category.dart';
import 'heisuca_poster_tile.dart';
import 'heisuca_source_scope.dart';
import '../cgflix/you/cgflix_favorites_screen.dart';

/// Biblioteca Heisuca: grade de pôsteres, filtros em pílulas e dados paginados da fonte ativa.
class HeisucaLibraryScreen extends StatefulWidget {
  const HeisucaLibraryScreen({super.key, this.initialLibraryKey, this.onLibrarySelected});
  final String? initialLibraryKey;
  final ValueChanged<String>? onLibrarySelected;
  @override
  State<HeisucaLibraryScreen> createState() => _HeisucaLibraryScreenState();
}
class _LibrarySource {
  const _LibrarySource(this.client, this.library);
  final MediaServerClient client;
  final MediaLibrary library;
  String get key => '${client.serverId.value}:${library.id}';
  HeisucaMediaCategory get category => heisucaAnimeLabel(library.title) ? HeisucaMediaCategory.anime :
    library.kind == MediaKind.movie ? HeisucaMediaCategory.movies : HeisucaMediaCategory.shows;
}
class _HeisucaLibraryScreenState extends State<HeisucaLibraryScreen> with Refreshable, LibraryLoadable {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;
  late final MultiServerProvider _servers = context.read<MultiServerProvider>();
  List<_LibrarySource> _sources = [];
  _LibrarySource? _selected;
  List<MediaItem> _items = [];
  bool _loading = true, _more = false, _hasMore = false;
  String? _error, _pendingKey;
  String _serverSignature = '';
  int _generation = 0, _sourceGeneration = 0;
  LibrarySort _sort = const LibrarySort(field: 'title', direction: LibrarySortDirection.ascending);
  @override
  void initState() { super.initState(); _pendingKey = widget.initialLibraryKey; _scroll.addListener(_nearEnd); _servers.addListener(_serversChanged); _loadSources(); }
  @override
  void dispose() { _debounce?.cancel(); _scroll.dispose(); _search.dispose(); _servers.removeListener(_serversChanged); super.dispose(); }
  @override
  Future<void> refresh() => _reload();
  @override
  void loadLibraryByKey(String key) { _pendingKey = key; _applyPending(); }
  void _applyPending() {
    final found = _sources.where((s) => s.library.globalKey == _pendingKey || s.key == _pendingKey).firstOrNull;
    if (found != null) { _pendingKey = null; _choose(found); }
  }
  void _serversChanged() {
    final signature = _servers.serverManager.navigationOnlineClients.keys.join('|');
    if (signature != _serverSignature) _loadSources();
  }
  Future<void> _loadSources() async {
    final generation = ++_sourceGeneration;
    ++_generation;
    final clients = _servers.serverManager.navigationOnlineClients.values.toList();
    _serverSignature = _servers.serverManager.navigationOnlineClients.keys.join('|');
    setState(() { _loading = true; _error = null; _items = []; _sources = []; _selected = null; });
    try {
      final hidden = context.read<HiddenLibrariesProvider?>();
      await hidden?.ensureInitialized();
      if (!mounted || generation != _sourceGeneration) return;
      final lists = await Future.wait(clients.map((client) async => [
        for (final library in await client.fetchLibraries())
          if (!library.hidden && (!(hidden?.hiddenLibraryKeys.contains(library.globalKey) ?? false) || library.globalKey == _pendingKey) && (library.kind == MediaKind.movie || library.kind == MediaKind.show || library.kind == MediaKind.unknown))
            _LibrarySource(client, library),
      ]));
      if (!mounted || generation != _sourceGeneration) return;
      _sources = lists.expand((x) => x).toList();
      _selected = _sources.where((s) => s.library.globalKey == _pendingKey || s.key == _pendingKey).firstOrNull ?? _sources.firstOrNull;
      _pendingKey = null;
      if (_selected != null) await _reload(); else setState(() => _loading = false);
    } catch (_) { if (mounted && generation == _sourceGeneration) setState(() { _loading = false; _error = 'Não foi possível carregar as bibliotecas.'; }); }
  }
  void _choose(_LibrarySource source) {
    _selected = source; widget.onLibrarySelected?.call(source.library.globalKey);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _reload();
  }
  Future<void> _reload() async {
    ++_generation;
    setState(() { _items = []; _loading = true; _more = false; _error = null; _hasMore = true; });
    await _page();
  }
  void _nearEnd() { if (_scroll.hasClients && _scroll.position.extentAfter < 500 && !_loading && !_more && _hasMore && _error == null) _page(); }
  Future<void> _page() async {
    final source = _selected;
    if (source == null) { if (mounted) setState(() => _loading = false); return; }
    if (_more) return;
    final generation = _generation;
    final offset = _items.length;
    setState(() => _more = true);
    try {
      final page = await source.client.fetchLibraryPagedContent(source.library.id,
        libraryKind: source.library.kind,
        query: LibraryQuery(offset: offset, limit: 60, sort: _sort,
          includeKinds: source.library.defaultBrowseKinds,
          search: _search.text.trim().isEmpty ? null : _search.text.trim()));
      if (!mounted || generation != _generation) return;
      setState(() { _items = [..._items, ...page.items]; _hasMore = page.items.isNotEmpty && _items.length < page.totalCount; _error = null; });
    } catch (_) { if (mounted && generation == _generation) setState(() => _error = 'Não foi possível carregar os títulos. Tente novamente.'); }
    finally { if (mounted && generation == _generation) setState(() { _loading = false; _more = false; }); }
  }
  @override
  Widget build(BuildContext context) {
    final p = context.cgflix;
    return Scaffold(backgroundColor: p.background, appBar: AppBar(title: const Text('Biblioteca'), actions: [
      PopupMenuButton<String>(tooltip: 'Ordenar', icon: const Icon(Icons.sort), onSelected: (field) {
        _sort = LibrarySort(field: field, direction: field == 'title' ? LibrarySortDirection.ascending : LibrarySortDirection.descending); _reload();
      }, itemBuilder: (_) => const [PopupMenuItem(value: 'title', child: Text('Título A–Z')), PopupMenuItem(value: 'addedAt', child: Text('Adicionados recentemente')), PopupMenuItem(value: 'rating', child: Text('Nota'))]),
    ]), body: Column(children: [
      // Caio, 24/10: só botões (sem lista que abre por cima). Um botão por biblioteca da fonte: no CGSERVER
      // são Animes/Filmes/Séries; nos Plex dos amigos, os nomes que cada servidor tiver.
      if (_sources.isNotEmpty) SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          for (final source in _sources) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            label: Text(source.library.title), selected: source == _selected,
            onSelected: (_) { if (source != _selected) _choose(source); })),
          // Caio, 24/10: Favoritos saiu da pílula (virou Baixados) e fica aqui, depois das bibliotecas.
          if (CgflixFavoritesSource.of(context) case final fav?) ActionChip(
            label: const Text('Favoritos'),
            onPressed: () => cgflixOpenFavorites(context, fav)),
        ])),
      Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 10), child: TextField(controller: _search,
        decoration: const InputDecoration(hintText: 'Buscar nesta biblioteca', prefixIcon: Icon(Icons.search)),
        onChanged: (_) { _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 300), _reload); })),
      if (_loading) const LinearProgressIndicator(minHeight: 2),
      if (_error != null) ListTile(title: Text(_error!), trailing: TextButton(onPressed: _sources.isEmpty ? _loadSources : _page, child: const Text('Tentar novamente'))),
      Expanded(child: _items.isEmpty && !_loading ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Nenhum título disponível nesta seleção.'),
        if (_servers.serverManager.navigationOnlineClients.isEmpty) const HeisucaSourceTile(),
       ])) : LayoutBuilder(builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32;
        final columns = GridSizeCalculator.getColumnCount(availableWidth, 160, crossAxisSpacing: 12);
        final width = GridSizeCalculator.getCellWidthForColumnCount(availableWidth, columns, crossAxisSpacing: 12);
        final captionHeight = HeisucaPosterTile.textBlockFor(context);
        final naturalHeight = width * 1.5 + captionHeight;
        return RefreshIndicator(onRefresh: _reload, child: GridView.builder(controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        // Preserva a grade a 100%; fonte maior ganha espaço real para a legenda.
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns,
          mainAxisExtent: naturalHeight > width * 2 ? naturalHeight : width * 2,
          crossAxisSpacing: 12, mainAxisSpacing: 10),
        itemCount: _items.length, itemBuilder: (context, i) => LayoutBuilder(builder: (context, box) => HeisucaPosterTile(
          item: _items[i], client: _selected?.client, width: box.maxWidth, onTap: () => cgflixOpenDetails(context, _items[i])))));
      })),
      if (_more && !_loading) const LinearProgressIndicator(minHeight: 2),
    ]));
  }
}
