import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../cgflix/cgflix_detail.dart';
import '../cgflix/cgflix_palette.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_file_info.dart';
import '../providers/download_provider.dart';
import '../services/settings_service.dart';
import '../utils/download_utils.dart';
import '../utils/media_image_helper.dart';
import '../widgets/optimized_media_image.dart';
import 'heisuca_home_style.dart';
import 'heisuca_state_store.dart';

/// Ficha ligada ao acervo e ao player reais; nunca escolhe um episódio pelo índice visual.
class HeisucaTitleSheet extends StatefulWidget {
  const HeisucaTitleSheet({super.key, required this.hostContext, required this.item, this.episode});
  final BuildContext hostContext;
  final MediaItem item;
  final MediaItem? episode;
  static Future<void> show(BuildContext context, MediaItem item, {MediaItem? episode}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
          HeisucaTitleSheet(hostContext: context, item: item, episode: episode)));
  @override
  State<HeisucaTitleSheet> createState() => _HeisucaTitleSheetState();
}

class _HeisucaTitleSheetState extends State<HeisucaTitleSheet> {
  late MediaItem _item = widget.item;
  MediaItem? _target;
  List<MediaItem> _seasons = [], _episodes = [];
  MediaItem? _season;
  bool _loading = true, _loadingEpisodes = false, _expanded = false, _queuing = false;
  String? _error, _episodeError;
  int _episodeGeneration = 0, _group = 0;
  final _scroll = ScrollController();
  final _playAnchor = GlobalKey();
  bool _docked = false;
  Future<MediaFileInfo?>? _fileInfo;
  Future<List<MediaItem>>? _extras, _related;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }
  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  void _onScroll() {
    final box = _playAnchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final docked = box.localToGlobal(Offset(0, box.size.height)).dy < MediaQuery.paddingOf(context).top + 56;
    if (_docked != docked) setState(() => _docked = docked);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = cgflixClientFor(context, _item);
      if (client == null) throw StateError('offline');
      final result = await client.fetchItemWithOnDeck(_item.id);
      if (!mounted) return;
      setState(() {
        _item = result.item ?? _item;
        _target = widget.episode ?? result.onDeckEpisode ?? (_item.kind == MediaKind.show ? null : _item);
        _fileInfo = null;
      });
      if (_item.kind == MediaKind.show) {
        final seasons = await client.fetchChildren(_item.id);
        if (!mounted) return;
        _seasons = seasons.where((s) => s.kind == MediaKind.season).toList()
          ..sort((a,b) => (a.index ?? 0).compareTo(b.index ?? 0));
        final selected = _seasons.where((s) => s.id == _target?.parentId ||
            (_target != null && s.index == _target!.parentIndex)).firstOrNull ??
            _seasons.where((s) => (s.index ?? 0) > 0).firstOrNull ?? _seasons.firstOrNull;
        if (selected != null) await _loadSeason(selected);
      }
    } catch (_) { if (mounted) setState(() => _error = 'Não foi possível atualizar o título. Tente novamente.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _loadSeason(MediaItem season) async {
    final generation = ++_episodeGeneration;
    setState(() { _season = season; _episodes = []; _group = 0; _loadingEpisodes = true; _episodeError = null; });
    try {
      final client = cgflixClientFor(context, _item);
      if (client == null) throw StateError('offline');
      final episodes = await client.fetchChildren(season.id);
      if (!mounted || generation != _episodeGeneration) return;
      episodes.sort((a,b) => (a.index ?? 0).compareTo(b.index ?? 0));
      setState(() {
        _episodes = episodes.where((e) => e.kind == MediaKind.episode).toList();
        _target ??= _episodes.where((e) => e.isUnwatchedOrInProgress).firstOrNull ?? _episodes.firstOrNull;
        final index = _episodes.indexWhere((e) => e.id == _target?.id);
        _group = index < 0 ? 0 : index ~/ 10;
      });
    } catch (_) { if (mounted && generation == _episodeGeneration) setState(() => _episodeError = 'Não foi possível carregar os episódios.'); }
    finally { if (mounted && generation == _episodeGeneration) setState(() => _loadingEpisodes = false); }
  }

  void _play() { final target = _target; if (target != null) cgflixPlay(context, target); }
  String get _playLabel => cgflixPlayButtonLabel(_item, _target, (item) => item);
  bool get _hideSpoilers => SettingsService.instanceOrNull?.read(SettingsService.hideSpoilers) ?? true;

  Future<void> _chooseSeason() async {
    final season = await showModalBottomSheet<MediaItem>(context: context, showDragHandle: true,
      builder: (ctx) => SafeArea(child: ListView(shrinkWrap: true, children: [
        const ListTile(title: Text('Temporadas')),
        for (final s in _seasons) ListTile(title: Text(s.index == 0 ? 'Especiais' : s.displayTitle),
          trailing: s.id == _season?.id ? const Icon(Icons.check) : null,
          onTap: () => Navigator.pop(ctx, s)),
      ])));
    if (season != null && mounted) await _loadSeason(season);
  }

  Future<void> _download() async {
    MediaItem? target = _item;
    if (_item.kind == MediaKind.show) {
      target = await showModalBottomSheet<MediaItem>(context: context, showDragHandle: true,
        builder: (ctx) => SafeArea(child: ListView(shrinkWrap: true, children: [
          const ListTile(title: Text('Baixar para assistir offline')),
          if (_season != null) ListTile(leading: const Icon(Icons.download), title: Text('Temporada: ${_season!.displayTitle}'),
            onTap: () => Navigator.pop(ctx, _season)),
          for (final episode in _episodes) ListTile(title: Text('${episode.index ?? ""}. ${episode.displayTitle}'),
            onTap: () => Navigator.pop(ctx, episode)),
        ])));
    }
    if (!mounted || target == null) return;
    final client = cgflixClientFor(context, target);
    if (client == null) return;
    setState(() => _queuing = true);
    try {
      await queueDownloadWithFeedback(context, metadata: target, client: client,
        downloadProvider: context.read<DownloadProvider>());
    } finally { if (mounted) setState(() => _queuing = false); }
  }

  Widget _playButton({bool compact = false}) => FilledButton.icon(
    onPressed: _target == null ? null : _play, icon: const Icon(Icons.play_arrow),
    label: Text(_playLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: FilledButton.styleFrom(minimumSize: Size(compact ? 0 : double.infinity, compact ? 44 : 56),
      backgroundColor: context.cgflix.isLight ? Colors.white.withValues(alpha: .88) : Colors.white.withValues(alpha: .92),
      foregroundColor: const Color(0xff202020), shape: const StadiumBorder()));

  @override
  Widget build(BuildContext context) {
    final client = cgflixClientFor(context, _item);
    final bg = heisucaPageColor(_item, isLight: context.cgflix.isLight);
    final fg = context.cgflix.isLight ? const Color(0xff133c33) : Colors.white;
    final isShow = _item.kind == MediaKind.show;
    final height = (MediaQuery.sizeOf(context).height * .72).clamp(440.0, 760.0);
    final art = cgflixWidePath(_item) ?? _item.thumbPath;
    final store = HeisucaStateStore.instance;
    final metadata = <String>[
      if (_item.rating != null) '★ ${_item.rating!.toStringAsFixed(1)}',
      if (_item.originallyAvailableAt != null) _item.originallyAvailableAt!,
      if (_item.studio?.isNotEmpty == true) _item.studio!,
      if (_item.contentRating != null) _item.contentRating!,
      if (isShow && _seasons.isNotEmpty) '${_seasons.length} temporadas',
      if ((_target?.durationMs ?? _item.durationMs) case final duration?) '${duration ~/ 60000} min',
    ];
    return Theme(data: Theme.of(context).copyWith(textTheme: Theme.of(context).textTheme.apply(bodyColor: fg, displayColor: fg)),
      child: Scaffold(backgroundColor: bg, body: Stack(children: [
        CustomScrollView(controller: _scroll, slivers: [
          SliverToBoxAdapter(child: SizedBox(height: height, child: Stack(fit: StackFit.expand, children: [
            if (art != null && client != null) ShaderMask(blendMode: BlendMode.dstIn,
              shaderCallback: heisucaHeroMask.createShader,
              child: OptimizedMediaImage(client: client, imagePath: art, imageType: ImageType.art, fit: BoxFit.cover)),
            Positioned(bottom: 16, left: 24, right: 24, child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_item.clearLogoPath != null && client != null)
                SizedBox(height: 110, child: ClearLogoImage(client: client, logoPath: _item.clearLogoPath,
                  width: MediaQuery.sizeOf(context).width - 48, height: 110,
                  fallbackWidth: MediaQuery.sizeOf(context).width - 48, alignment: Alignment.center,
                  fallbackBuilder: (_) => Text(_item.displayTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))))
              else Text(_item.displayTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Text(metadata.join('  ·  '), textAlign: TextAlign.center, style: TextStyle(color: fg, height: 1.6)),
              const SizedBox(height: 8),
              Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: cgflixLanguageBadges(_target ?? _item)),
            ])),
          ]))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverList.list(children: [
            SizedBox(key: _playAnchor, child: _playButton()),
            ListenableBuilder(listenable: store, builder: (_, __) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(tooltip: 'Favorito', icon: Icon(store.isFavorite(_item) ? Icons.favorite : Icons.favorite_border),
                color: fg, onPressed: client?.capabilities.userFavorites == true ? () => store.toggleFavorite(context, _item) : null),
              IconButton(tooltip: store.isWatched(_target ?? _item) ? 'Marcar como não visto' : 'Marcar como visto',
                icon: Icon(store.isWatched(_target ?? _item) ? Icons.check_circle : Icons.check_circle_outline), color: fg,
                onPressed: () => store.toggleWatched(context, _target ?? _item)),
              IconButton(tooltip: _queuing ? 'Adicionando à fila' : 'Baixar', icon: Icon(_queuing ? Icons.hourglass_top : Icons.download_outlined),
                color: fg, onPressed: _queuing ? null : _download),
            ])),
            if (_error != null) ListTile(title: Text(_error!), trailing: TextButton(onPressed: _load, child: const Text('Tentar novamente'))),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_item.summary?.isNotEmpty == true) ...[
              _heading('Sinopse'),
              Text(_item.summary!, maxLines: _expanded ? null : 4, overflow: _expanded ? null : TextOverflow.ellipsis,
                style: const TextStyle(height: 1.5)),
              Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Menos' : 'Mais'))),
            ],
            if (isShow && _target != null) Text('Próximo: T${_target!.parentIndex ?? 1}:E${_target!.index ?? 1}'
              '${_hideSpoilers && !_target!.isWatched ? "" : " · ${_target!.displayTitle}"}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (_item.ratings?.isNotEmpty == true) Padding(padding: const EdgeInsets.symmetric(vertical: 16),
              child: Wrap(spacing: 16, runSpacing: 8, children: [for (final rating in _item.ratings!)
                Text('${_ratingLabel(rating.source)} ${rating.source.toLowerCase().contains("rotten") ? "${(rating.value * 10).round()}%" : rating.value.toStringAsFixed(1)}')])),
            if (isShow) ...[
              const SizedBox(height: 20),
              Row(children: [Expanded(child: TextButton.icon(onPressed: _seasons.isEmpty ? null : _chooseSeason,
                icon: const Icon(Icons.expand_more), label: Text(_season?.displayTitle ?? 'Temporadas'))),
                TextButton(onPressed: _episodes.isEmpty ? null : _allEpisodes, child: const Text('Ver tudo'))]),
              if (_loadingEpisodes) const LinearProgressIndicator(minHeight: 2),
              if (_episodeError != null) TextButton(onPressed: _season == null ? null : () => _loadSeason(_season!), child: Text('$_episodeError Tentar novamente')),
              if (!_loadingEpisodes && _episodes.isEmpty && _episodeError == null) const Text('Nenhum episódio disponível nesta temporada.'),
              if (_episodes.isNotEmpty) ...[
                SizedBox(height: 210, child: ListView.separated(scrollDirection: Axis.horizontal,
                  key: ValueKey('${_season?.id}:$_group'), itemCount: _episodes.skip(_group * 10).take(10).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _episodeCard(_episodes[_group * 10 + i]))),
                Wrap(spacing: 8, children: [for (var i = 0; i < (_episodes.length / 10).ceil(); i++)
                  ChoiceChip(label: Text('${i * 10 + 1}–${((i + 1) * 10).clamp(0, _episodes.length)}'),
                    selected: _group == i, onSelected: (_) => setState(() => _group = i))]),
              ],
            ],
            if (_item.roles?.isNotEmpty == true) ...[
              _heading('Elenco'),
              SizedBox(height: 180, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _item.roles!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, i) {
                  final role = _item.roles![i];
                  return SizedBox(width: 104, child: Column(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(24), child: SizedBox(width: 96, height: 96,
                      child: role.thumbPath != null && client != null ? OptimizedMediaImage(client: client,
                        imagePath: role.thumbPath!, imageType: ImageType.thumb, fit: BoxFit.cover) :
                        ColoredBox(color: fg.withValues(alpha: .1), child: Center(child: Text(role.tag.isEmpty ? '?' : role.tag[0], style: const TextStyle(fontSize: 28)))))),
                    const SizedBox(height: 6), Text(role.tag, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (role.role != null) Text(role.role!, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: fg.withValues(alpha: .7))),
                  ]));
                })),
            ],
            if (_item.genres?.isNotEmpty == true) ...[_heading('Gêneros'),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final genre in _item.genres!) Chip(label: Text(genre))])],
            if (!isShow) _supplement('Extras e trailers', extras: true),
            _supplement('Títulos relacionados', extras: false),
            _heading('Informações da mídia'),
            ExpansionTile(title: const Text('Vídeo, áudio, legendas e arquivo'),
              onExpansionChanged: (open) { if (open && _fileInfo == null && _target != null) setState(() =>
                _fileInfo = cgflixClientFor(context, _target!)?.getFileInfo(_target!)); },
              children: [if (_fileInfo != null) FutureBuilder<MediaFileInfo?>(future: _fileInfo, builder: (_, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const LinearProgressIndicator(minHeight: 2);
                if (snapshot.hasError) return TextButton(onPressed: () => setState(() => _fileInfo =
                  cgflixClientFor(context, _target!)?.getFileInfo(_target!)), child: const Text('Tentar novamente'));
                final versions = snapshot.data?.versions ?? [];
                if (versions.isEmpty) return const ListTile(title: Text('Informações não fornecidas pelo servidor.'));
                return Column(children: [for (final version in versions) _versionInfo(version)]);
              }) else const ListTile(title: Text('Selecione um episódio disponível.'))]),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 40),
          ])),
        ]),
        Positioned(top: MediaQuery.paddingOf(context).top + 6, left: 12, right: 12,
          child: Row(children: [IconButton.filledTonal(tooltip: 'Voltar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
            const SizedBox(width: 12), if (_docked) Expanded(child: _playButton(compact: true)) else const Spacer(),
            if (!_docked) PopupMenuButton<String>(tooltip: 'Mais opções', iconColor: fg,
              onSelected: (value) { if (value == 'refresh') _load(); else _download(); },
              itemBuilder: (_) => [const PopupMenuItem(value: 'refresh', child: Text('Atualizar informações')),
                const PopupMenuItem(value: 'download', child: Text('Baixar'))]),
          ])),
      ])));
  }

  Widget _heading(String title) => Padding(padding: const EdgeInsets.only(top: 28, bottom: 14),
    child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)));

  Widget _episodeCard(MediaItem ep) {
    final client = cgflixClientFor(context, ep);
    final hidden = _hideSpoilers && !ep.isWatched;
    final progress = (ep.durationMs ?? 0) > 0 ? ((ep.viewOffsetMs ?? 0) / ep.durationMs!).clamp(0.0, 1.0) : 0.0;
    return SizedBox(width: 236, child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () => cgflixPlay(context, ep),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ep.id == _target?.id ? context.cgflix.accent : Colors.transparent, width: 2)),
          padding: const EdgeInsets.all(3), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16/9,
            child: !hidden && ep.thumbPath != null && client != null ? OptimizedMediaImage(client: client,
              imagePath: ep.thumbPath!, imageType: ImageType.thumb, fit: BoxFit.cover) :
              ColoredBox(color: Colors.black26, child: Center(child: Text('E${ep.index ?? ""}')))))),
        if (progress > 0) LinearProgressIndicator(value: progress, minHeight: 3),
        const SizedBox(height: 6), Text('${ep.index ?? ""}. ${hidden ? "Episódio ${ep.index ?? ""}" : ep.displayTitle}',
          maxLines: 2, overflow: TextOverflow.ellipsis),
        Text([if (ep.durationMs != null) '${ep.durationMs! ~/ 60000} min', if (ep.isWatched) 'Visto'].join(' · '), style: const TextStyle(fontSize: 12)),
      ])));
  }

  Future<void> _allEpisodes() => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true,
    builder: (ctx) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(ctx).height * .75,
      child: ListView(children: [ListTile(title: Text(_season?.displayTitle ?? 'Episódios')),
        for (final ep in _episodes) ListTile(leading: Text('${ep.index ?? ""}'),
          title: Text(_hideSpoilers && !ep.isWatched ? 'Episódio ${ep.index ?? ""}' : ep.displayTitle),
          trailing: Icon(ep.isWatched ? Icons.check_circle : Icons.play_circle_outline),
          onTap: () { Navigator.pop(ctx); cgflixPlay(context, ep); }),
      ]))));

  Future<List<MediaItem>> _loadSupplement(bool extras) async {
    final client = cgflixClientFor(context, _item);
    if (client == null) throw StateError('Fonte indisponível');
    if (extras) return client.fetchExtras(_item.id);
    final hubs = await client.fetchRelatedHubs(_item.id);
    final items = <String, MediaItem>{};
    for (final hub in hubs) { for (final item in hub.items) { items[item.globalKey] = item; } }
    return items.values.toList();
  }

  Widget _supplement(String title, {required bool extras}) {
    final future = extras ? _extras : _related;
    void load() => setState(() {
      if (extras) { _extras = _loadSupplement(true); } else { _related = _loadSupplement(false); }
    });
    return ExpansionTile(title: Text(title), onExpansionChanged: (open) { if (open && future == null) load(); },
      children: [if (future != null) FutureBuilder<List<MediaItem>>(future: future, builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const LinearProgressIndicator(minHeight: 2);
        if (snapshot.hasError) return TextButton(onPressed: load, child: const Text('Tentar novamente'));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const ListTile(title: Text('Nenhum item disponível.'));
        return Column(children: [for (final item in items) ListTile(title: Text(item.displayTitle),
          leading: Icon(extras ? Icons.play_circle_outline : Icons.movie_outlined),
          onTap: () { if (extras) { cgflixPlay(context, item); } else { HeisucaTitleSheet.show(context, item); } })]);
      })]);
  }

  Widget _versionInfo(MediaFileVersion version) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    ListTile(title: Text(version.title ?? 'Versão disponível'), subtitle: Text([
      if (version.width != null && version.height != null) '${version.width} × ${version.height}',
      if (version.videoCodec != null) version.videoCodec!, if (version.container != null) version.container!,
      if (version.bitrateKbps != null) '${version.bitrateKbps} kbps',
    ].join(' · '))),
    for (final part in version.parts) ...[
      for (final stream in part.streams) ListTile(title: Text(stream.displayTitle ?? stream.title ?? stream.kind.name), subtitle: Text([
        if (stream.codec != null) 'Codec: ${stream.codec}', if (stream.language != null) 'Idioma: ${stream.language}',
        if (stream.channels != null) 'Canais: ${stream.channels}', if (stream.sampleRate != null) '${stream.sampleRate} Hz',
        if (stream.frameRate != null) '${stream.frameRate} fps', if (stream.bitDepth != null) '${stream.bitDepth} bits',
        if (stream.pixelFormat != null) stream.pixelFormat!, if (stream.isDefault == true) 'Padrão',
        if (stream.isForced == true) 'Forçada',
      ].join(' · '))),
      if (part.filePath != null) ExpansionTile(title: const Text('Caminho do arquivo'), children: [
        Padding(padding: const EdgeInsets.all(16), child: SelectableText(part.filePath!)),
        TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: part.filePath!)),
          icon: const Icon(Icons.copy), label: const Text('Copiar caminho')),
      ]),
    ],
  ]);

  String _ratingLabel(String source) => const {'imdb': 'IMDb', 'tmdb': 'TMDB', 'rottenTomatoesCritic': 'Tomatometer',
    'rottenTomatoesAudience': 'Público', 'mal': 'MyAnimeList', 'anilist': 'AniList', 'trakt': 'Trakt', 'simkl': 'Simkl'}[source] ?? source;
}
