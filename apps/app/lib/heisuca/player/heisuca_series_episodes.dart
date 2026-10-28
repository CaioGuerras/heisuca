import '../heisuca_motion.dart';
import '../heisuca_title_logo.dart';
import 'package:flutter/material.dart';
import '../../cgflix/home/cgflix_actions.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../services/settings_service.dart';
import '../../utils/media_image_helper.dart';
import '../../widgets/optimized_media_image.dart';

String? heisucaPlayerSeriesId(MediaItem item) => item.kind == MediaKind.episode ? item.grandparentId : null;
String heisucaPlayerEpisodeLine(MediaItem item) => [
  if (item.parentIndex != null) 'T${item.parentIndex}',
  if (item.index != null) 'E${item.index}',
  if (item.title?.isNotEmpty == true) item.title!,
].join(' · ');

Future<MediaItem?> showHeisucaSeriesEpisodes(BuildContext context, MediaItem current) {
  return showModalBottomSheet<MediaItem>(sheetAnimationStyle: HeisucaMotion.sheetStyle(context), context: context, isScrollControlled: true,
    backgroundColor: const Color(0xff141018), showDragHandle: true,
    builder: (_) => HeisucaSeriesEpisodes(current: current));
}

/// A fonte é a da reprodução, não a fonte escolhida para navegar pela Home.
class HeisucaSeriesEpisodes extends StatefulWidget {
  const HeisucaSeriesEpisodes({super.key, required this.current});
  final MediaItem current;
  @override State<HeisucaSeriesEpisodes> createState() => _HeisucaSeriesEpisodesState();
}
class _HeisucaSeriesEpisodesState extends State<HeisucaSeriesEpisodes> with TickerProviderStateMixin {
  MediaServerClient? _client;
  List<MediaItem> _seasons = [], _episodes = [];
  TabController? _tabs;
  final _scroll = ScrollController();
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _tabs?.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _client = cgflixClientFor(context, widget.current);
      final seriesId = heisucaPlayerSeriesId(widget.current);
      if (_client == null || seriesId == null) throw StateError('sem fonte');
      final seasons = (await _client!.fetchChildren(seriesId)).where((item) => item.kind == MediaKind.season).toList()
        ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
      if (!mounted) return;
      if (seasons.isEmpty) throw StateError('sem temporadas');
      final selected = seasons.indexWhere((season) => season.id == widget.current.parentId ||
        (season.index != null && season.index == widget.current.parentIndex));
      _tabs?.dispose();
      _tabs = TabController(length: seasons.length, vsync: this, initialIndex: selected < 0 ? 0 : selected);
      _tabs!.addListener(_tabChanged);
      setState(() => _seasons = seasons);
      await _loadEpisodes(_tabs!.index);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Não foi possível carregar as temporadas.'; });
    }
  }
  void _tabChanged() {
    final tabs = _tabs;
    if (tabs != null && !tabs.indexIsChanging && _seasons.isNotEmpty) _loadEpisodes(tabs.index);
  }
  Future<void> _loadEpisodes(int index) async {
    final request = ++_request;
    setState(() { _loading = true; _error = null; _episodes = []; });
    try {
      final episodes = (await _client!.fetchChildren(_seasons[index].id))
        .where((item) => item.kind == MediaKind.episode).toList()
        ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
      if (!mounted || request != _request) return;
      final active = episodes.indexWhere((item) => item.id == widget.current.id);
      setState(() { _episodes = episodes; _loading = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || request != _request || !_scroll.hasClients) return;
        final target = active < 0 ? 0.0 : active * 104.0;
        _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
        _loading = false; _error = 'Não foi possível carregar os episódios.';
      });
      }
    }
  }
  @override Widget build(BuildContext context) {
    return SafeArea(child: SizedBox(height: MediaQuery.sizeOf(context).height * .78, child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(widget.current.grandparentTitle ?? 'Episódios',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
        if (_tabs != null) TabBar(controller: _tabs, isScrollable: true, tabAlignment: TabAlignment.start,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: [for (final season in _seasons) Tab(text: season.index == 0 ? 'Especiais' :
            season.title?.isNotEmpty == true && season.title != widget.current.grandparentTitle
              ? season.title : 'Temporada ${season.index ?? ""}')]),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Text(_error!, style: const TextStyle(color: Colors.white70)),
          TextButton(onPressed: _seasons.isEmpty ? _load : () => _loadEpisodes(_tabs!.index),
            child: const Text('Tentar novamente')),
        ])),
        Expanded(child: ListView.builder(controller: _scroll, itemExtent: 104,
          itemCount: _episodes.length, itemBuilder: (context, index) {
            final item = _episodes[index];
            final current = item.id == widget.current.id;
            final hideSpoilers = SettingsService.instanceOrNull?.read(SettingsService.hideSpoilers) ?? true;
            final hidden = hideSpoilers && !current && !item.isWatched && !item.hasActiveProgress;
            final duration = item.durationMs ?? 0;
            final position = item.viewOffsetMs ?? 0;
            final progress = item.isWatched ? 1.0 : duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;
            return Semantics(selected: current, child: ListTile(
              selected: current, selectedTileColor: Colors.white12,
              onTap: current ? null : () => Navigator.pop(context, item),
              leading: SizedBox(width: 104, height: 64, child: ClipRRect(borderRadius: BorderRadius.circular(8),
                child: hidden ? const ColoredBox(color: Colors.black26, child: Icon(Icons.play_arrow_rounded, color: Colors.white54))
                  : OptimizedMediaImage(client: _client, imagePath: item.thumbPath, imageType: ImageType.thumb, fit: BoxFit.cover))),
              title: Text(hidden ? 'Episódio ${item.index ?? ""}' : '${item.index ?? ""}. ${item.title ?? "Episódio"}', maxLines: 2,
                overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
              subtitle: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (duration > 0) Text('${(duration / 60000).round()} min', style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 4), LinearProgressIndicator(value: progress, minHeight: 3),
              ]),
              trailing: current ? const Icon(Icons.play_arrow_rounded, color: Colors.white) : null,
            ));
          })),
        if (!_loading && _error == null && _episodes.isEmpty) const Padding(
          padding: EdgeInsets.all(16), child: Text('Nenhum episódio disponível.', style: TextStyle(color: Colors.white70))),
      ])));
  }
}

/// Logo real da série/filme, sem atrasar a abertura do player enquanto busca metadados.
class HeisucaPlayerTitle extends StatefulWidget {
  const HeisucaPlayerTitle({super.key, required this.metadata, this.onEpisodes});
  final MediaItem metadata;
  final VoidCallback? onEpisodes;
  @override State<HeisucaPlayerTitle> createState() => _HeisucaPlayerTitleState();
}
class _HeisucaPlayerTitleState extends State<HeisucaPlayerTitle> {
  MediaItem? _owner;
  int _generation = 0;
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _loadOwner(); });
  }
  @override void didUpdateWidget(HeisucaPlayerTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (heisucaPlayerSeriesId(oldWidget.metadata) != heisucaPlayerSeriesId(widget.metadata) ||
        oldWidget.metadata.serverId != widget.metadata.serverId) { _owner = null; _loadOwner(); }
  }
  Future<void> _loadOwner() async {
    final generation = ++_generation;
    final id = heisucaPlayerSeriesId(widget.metadata);
    if (id == null) return;
    final client = cgflixClientFor(context, widget.metadata);
    if (client == null) return;
    try {
      final owner = await client.fetchItem(id);
      if (mounted && generation == _generation && owner?.kind == MediaKind.show) setState(() => _owner = owner);
    } catch (_) { /* Reserva em texto continua disponível. */ }
  }
  @override Widget build(BuildContext context) {
    final item = widget.metadata;
    final episode = item.kind == MediaKind.episode;
    final owner = _owner ?? item;
    final title = item.grandparentTitle ?? item.title ?? 'Heisuca';
    final fallback = Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16));
    return Semantics(button: episode && widget.onEpisodes != null, label: episode ? 'Episódios de $title' : title,
      child: InkWell(onTap: episode ? widget.onEpisodes : null, borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            LayoutBuilder(builder: (context, constraints) => HeisucaTitleLogo(
              item: owner, client: cgflixClientFor(context, item), width: constraints.maxWidth,
              height: 40, compactFallback: true, fallbackWidth: constraints.maxWidth, alignment: Alignment.centerLeft,
              fallbackBuilder: (_) => Align(alignment: Alignment.centerLeft, child: fallback))),
            if (episode) Text(heisucaPlayerEpisodeLine(item), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]))));
  }
}
