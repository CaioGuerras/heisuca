import 'heisuca_theme.dart';
import 'heisuca_home_chrome.dart';
import '../cgflix/cgflix_navigation.dart';
import 'heisuca_motion.dart';
import 'dart:collection';
import 'package:flutter/material.dart';
import '../screens/actor_media_screen.dart';
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
import '../media/media_role.dart';
import '../media/media_server_client.dart';
import '../media/media_stream.dart';
import 'heisuca_home_style.dart';
import 'heisuca_poster_tile.dart';
import 'heisuca_title_parts.dart';
import 'heisuca_state_store.dart';

/// Série dona de um episódio/temporada; null para filmes e séries.
String? heisucaSeriesIdFor(MediaItem item) => switch (item.kind) {
  MediaKind.episode => item.grandparentId,
  MediaKind.season => item.grandparentId ?? item.parentId,
  _ => null,
};

/// Rótulo próprio da temporada. `displayTitle` devolve o nome da SÉRIE para temporadas
/// e episódios (é título de cabeçalho), por isso nunca serve de rótulo aqui.
String heisucaSeasonLabel(MediaItem season) {
  if (season.index == 0) return 'Especiais';
  final own = season.title?.trim();
  if (own != null && own.isNotEmpty && own != season.grandparentTitle && own != season.parentTitle) return own;
  return season.index != null ? 'Temporada ${season.index}' : 'Temporada';
}

/// Nome próprio do episódio; cai em "Episódio N" quando o servidor só repete o nome da série.
String heisucaEpisodeLabel(MediaItem episode) {
  final own = episode.title?.trim();
  if (own != null && own.isNotEmpty && own != episode.grandparentTitle) return own;
  return episode.index != null ? 'Episódio ${episode.index}' : 'Episódio';
}

/// Ficha ligada ao acervo e ao player reais; nunca escolhe um episódio pelo índice visual.
/// Episódio ou temporada recebidos (Home, Em breve, novidades) abrem a ficha da SÉRIE,
/// com aquele episódio como alvo ou aquela temporada selecionada.
class HeisucaTitleSheet extends StatefulWidget {
  const HeisucaTitleSheet({super.key, required this.hostContext, required this.item, this.episode, this.heroTag});
  final BuildContext hostContext;
  final MediaItem item;
  final MediaItem? episode;
  final String? heroTag;
  static Future<void> show(BuildContext context, MediaItem item, {MediaItem? episode}) async {
    final tag = cgflixDetailHeroTag(item);
    try {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => HeisucaTitleSheet(hostContext: context, item: item, episode: episode, heroTag: tag)));
    } finally {
      cgflixForgetHeroTag(item);
    }
  }
  @override
  State<HeisucaTitleSheet> createState() => _HeisucaTitleSheetState();
}

// Cache curto em memória, pertencente ao cliente autenticado: nunca compartilha dados
// entre sessões/servidores. A tela revalida progresso ao abrir e ao voltar do player.
final _titleSnapshots = Expando<LinkedHashMap<String, _TitleSnapshot>>();
class _TitleSnapshot {
  _TitleSnapshot(this.item, this.target, this.seasons, this.season, this.episodes, this.group);
  final DateTime at = DateTime.now();
  final MediaItem item;
  final MediaItem? target, season;
  final List<MediaItem> seasons, episodes;
  final int group;
}

class _HeisucaTitleSheetState extends State<HeisucaTitleSheet> {
  late MediaItem _item = widget.item;
  MediaItem? _target;
  List<MediaItem> _seasons = [], _episodes = [];
  MediaItem? _season;
  String? _preferredSeasonId;
  bool _entryApplied = false;
  bool _loading = true, _loadingEpisodes = false, _queuing = false;
  String? _error, _episodeError;
  int _episodeGeneration = 0, _loadGeneration = 0, _group = 0;
  final _scroll = ScrollController();
  final _logoAnchor = GlobalKey();
  bool _docked = false;
  Future<MediaFileInfo?>? _fileInfo;
  Future<List<MediaItem>>? _extras, _related;
  int _versionIndex = 0;

  @override
  void initState() {
    super.initState();
    final client = cgflixClientFor(context, widget.item);
    final key = heisucaSeriesIdFor(widget.item) ?? widget.item.id;
    final cached = client == null ? null : _titleSnapshots[client]?[key];
    final entry = widget.item;
    final sameSeason = entry.kind != MediaKind.season || cached?.season?.id == entry.id;
    if (cached != null && sameSeason && DateTime.now().difference(cached.at) < const Duration(minutes: 2)) {
      _item = cached.item;
      // Um toque explícito em episódio vence o alvo antigo do cache imediatamente.
      _target = widget.episode ?? (entry.kind == MediaKind.episode ? entry : cached.target);
      _seasons = cached.seasons;
      _season = cached.season; _episodes = cached.episodes; _group = cached.group;
    }
    _load();
  }
  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  Future<void> _load({bool refresh = false}) async {
    final generation = ++_loadGeneration;
    ++_episodeGeneration;
    // Recarga (volta do player, marcar visto) é silenciosa: o conteúdo fica na tela, sem barra.
    final silent = refresh || _seasons.isNotEmpty || _episodes.isNotEmpty;
    setState(() { _loading = !silent; _error = null; });
    try {
      final client = cgflixClientFor(context, _item);
      if (client == null) throw StateError('offline');
      final entry = widget.item;
      final seriesId = _item.kind == MediaKind.show ? null : heisucaSeriesIdFor(entry);
      // Em paralelo com o item (antes era tudo em fila: item → ancestrais → próximo → temporadas →
      // episódios, ~5 idas ao servidor). Temporadas e a temporada já conhecida começam agora.
      final knownSeries = seriesId ?? (_item.kind == MediaKind.show ? _item.id : null);
      final seasonsFuture = knownSeries == null || (refresh && _seasons.isNotEmpty) ? null
          : Future.sync(() => client.fetchChildren(knownSeries));
      final knownSeasonId = _season?.id ?? (entry.kind == MediaKind.season ? entry.id
          : entry.kind == MediaKind.episode ? entry.parentId : null);
      if (knownSeasonId != null && knownSeries != null) {
        _prefetchedEpisodes = (knownSeasonId, Future.sync(() => client.fetchChildren(knownSeasonId)));
      }
      seasonsFuture?.ignore();
      _prefetchedEpisodes?.$2.ignore();
      final result = await client.fetchItemWithOnDeck(seriesId ?? _item.id, onItemReady: (ready) {
        if (!mounted || generation != _loadGeneration) return;
        if (seriesId == null || ready.kind == MediaKind.show) setState(() => _item = ready);
      });
      if (!mounted || generation != _loadGeneration) return;
      final fetched = result.item;
      // Só troca para a série se o servidor confirmou que é uma série; senão mantém o item recebido.
      final asSeries = seriesId != null && fetched?.kind == MediaKind.show;
      if (seriesId != null && !asSeries) {
        final own = await client.fetchItemWithOnDeck(entry.id);
        if (!mounted || generation != _loadGeneration) return;
        setState(() { _item = own.item ?? entry; _target = _item; _fileInfo = null; });
        return;
      }
      final previousTarget = _target?.id;
      setState(() {
        _item = fetched ?? _item;
        _target = widget.episode ??
            // Primeira abertura: o episódio tocado. Recargas (após assistir/marcar) seguem o on-deck.
            (_item.kind == MediaKind.show && entry.kind == MediaKind.episode && !_entryApplied ? entry : null) ??
            result.onDeckEpisode ?? (_item.kind == MediaKind.show ? null : _item);
        if (_item.kind == MediaKind.show && entry.kind == MediaKind.season && !_entryApplied) _preferredSeasonId = entry.id;
        _entryApplied = true;
        if (previousTarget != _target?.id) _fileInfo = null;
      });
      if (_item.kind == MediaKind.show) {
        final seasons = refresh && _seasons.isNotEmpty ? _seasons
            : await (seasonsFuture != null && knownSeries == _item.id ? seasonsFuture : client.fetchChildren(_item.id));
        if (!mounted || generation != _loadGeneration) return;
        _seasons = seasons.where((s) => s.kind == MediaKind.season).toList()
          ..sort((a,b) => (a.index ?? 0).compareTo(b.index ?? 0));
        final preferred = _preferredSeasonId;
        _preferredSeasonId = null; // só vale para a primeira abertura
        final selected = (refresh ? _season : null) ?? _seasons.where((s) => s.id == preferred).firstOrNull ??
            _seasons.where((s) => s.id == _target?.parentId ||
            (_target != null && s.index == _target!.parentIndex)).firstOrNull ??
            _seasons.where((s) => (s.index ?? 0) > 0).firstOrNull ?? _seasons.firstOrNull;
        if (selected != null) await _loadSeason(selected, retain: selected.id == _season?.id && _episodes.isNotEmpty);
      }
    } catch (_) { if (mounted && generation == _loadGeneration) setState(() => _error = 'Não foi possível atualizar o título. Tente novamente.'); }
    finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _loading = false);
        final client = cgflixClientFor(context, _item);
        if (client != null && _error == null) {
          final cache = _titleSnapshots[client] ??= LinkedHashMap<String, _TitleSnapshot>();
          cache.remove(_item.id);
          cache[_item.id] = _TitleSnapshot(_item, _target, List.of(_seasons), _season, List.of(_episodes), _group);
          while (cache.length > 12) { cache.remove(cache.keys.first); }
        }
      }
    }
  }

  (String, Future<List<MediaItem>>)? _prefetchedEpisodes;

  Future<void> _loadSeason(MediaItem season, {bool retain = false}) async {
    final generation = ++_episodeGeneration;
    setState(() { _season = season; if (!retain) { _episodes = []; _group = 0; } _loadingEpisodes = true; _episodeError = null; });
    try {
      final client = cgflixClientFor(context, _item);
      if (client == null) throw StateError('offline');
      // Usa a busca antecipada do _load quando é a mesma temporada (não pede duas vezes).
      final prefetched = _prefetchedEpisodes;
      _prefetchedEpisodes = null;
      final episodes = await (prefetched != null && prefetched.$1 == season.id ? prefetched.$2 : client.fetchChildren(season.id));
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

  void _play() { final target = _target; if (target != null) _playEpisode(target); }
  Future<void> _playEpisode(MediaItem target) async {
    await cgflixPlay(context, target);
    if (mounted) await _load(refresh: true);
  }
  Future<void> _markWatched() async {
    await HeisucaStateStore.instance.toggleWatched(context, _target ?? _item);
    if (mounted) await _load(refresh: true);
  }
  /// Regra do site (Caio, 19/10): "Continuar" só quando há posição salva; senão "Assistir T1:E3".
  String get _playLabel {
    final target = _target;
    if (_item.kind == MediaKind.show) {
      if (target == null) return 'Assistir';
      final code = cgflixEpisodeCode(target);
      final verb = (target.viewOffsetMs ?? 0) > 0 ? 'Continuar' : 'Assistir';
      return code.isEmpty ? verb : '$verb $code';
    }
    return (_item.viewOffsetMs ?? 0) > 0 ? 'Continuar' : 'Assistir';
  }
  bool get _hideSpoilers => SettingsService.instanceOrNull?.read(SettingsService.hideSpoilers) ?? true;
  bool _hidden(MediaItem ep) => _hideSpoilers && !ep.isWatched && !ep.hasActiveProgress;

  Future<void> _chooseSeason() async {
    final season = await showModalBottomSheet<MediaItem>(sheetAnimationStyle: HeisucaMotion.sheetStyle(context), context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => SafeArea(child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .7),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const HeisucaSheetHeader('Temporadas'),
          Flexible(child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 12), children: [
            for (final s in _seasons) HeisucaSeasonOption(label: heisucaSeasonLabel(s), detail: heisucaSeasonDetail(s),
              selected: s.id == _season?.id, onTap: () => Navigator.pop(ctx, s)),
          ])),
        ]))));
    if (season != null && mounted) await _loadSeason(season);
  }

  Future<void> _download() async {
    MediaItem? target = _item;
    if (_item.kind == MediaKind.show) {
      target = await showModalBottomSheet<MediaItem>(sheetAnimationStyle: HeisucaMotion.sheetStyle(context), context: context, showDragHandle: true, isScrollControlled: true,
        builder: (ctx) => SafeArea(child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .75),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const HeisucaSheetHeader('Baixar', subtitle: 'Para assistir sem internet'),
            Flexible(child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 12), children: [
              if (_season != null) HeisucaSeasonOption(label: '${heisucaSeasonLabel(_season!)} inteira',
                detail: heisucaSeasonDetail(_season!), selected: false, onTap: () => Navigator.pop(ctx, _season)),
              for (final episode in _episodes) ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.download_rounded),
                title: Text(_episodeTitle(episode), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: _episodeMeta(episode).isEmpty ? null : Text(_episodeMeta(episode)),
                onTap: () => Navigator.pop(ctx, episode)),
            ])),
          ]))));
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

  HeisucaTitleColors _colors(BuildContext context) {
    final isLight = context.cgflix.isLight;
    return HeisucaTitleColors(page: heisucaPageColor(_item, isLight: isLight),
      text: isLight ? const Color(0xff133c33) : Colors.white, accent: context.cgflix.accent, isLight: isLight);
  }

  /// Botão de vidro do site (.titulo-play): translúcido sobre a cor da página, sem branco chapado.
  Widget _playButton(HeisucaTitleColors c, {bool compact = false}) {
    final enabled = _target != null;
    return Semantics(button: true, enabled: enabled, label: _playLabel, child: Material(
      color: c.isLight ? Colors.white.withValues(alpha: .62) : Colors.white.withValues(alpha: .16),
      shape: StadiumBorder(side: BorderSide(color: c.isLight ? Colors.white.withValues(alpha: .7) : Colors.white.withValues(alpha: .14))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: enabled ? _play : null, child: SizedBox(height: compact ? 44 : 48, child: Center(child: Row(
        mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.play_arrow_rounded, size: 24, color: c.text.withValues(alpha: enabled ? 1 : .4)),
          const SizedBox(width: 6),
          Flexible(child: Text(_playLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w600, letterSpacing: .3, color: c.text.withValues(alpha: enabled ? 1 : .4)))),
        ])))),
    ));
  }

  String _episodeTitle(MediaItem ep) {
    final name = _hidden(ep) ? 'Episódio ${ep.index ?? ''}'.trim() : heisucaEpisodeLabel(ep);
    return ep.index != null && !name.startsWith('Episódio') ? '${ep.index}. $name' : name;
  }
  String _episodeMeta(MediaItem ep) => [
    if ((ep.durationMs ?? 0) >= 60000) '${ep.durationMs! ~/ 60000} min',
    if (ep.isWatched) 'Visto' else if (ep.hasActiveProgress) 'Em andamento',
  ].join(' · ');

  /// 「Re:ZERO·Temp. 4·EP 19」 + sinopse do episódio-alvo (site), salvo quando ocultar spoilers vale.
  ({String? mark, String text})? get _synopsis {
    final t = _target;
    if (_item.kind == MediaKind.show && t != null && t.kind == MediaKind.episode &&
        (t.summary?.trim().isNotEmpty ?? false) && !_hidden(t)) {
      final season = t.parentIndex == 0 ? 'Especial' : 'Temp. ${t.parentIndex ?? '?'}';
      return (mark: '${_item.displayTitle}·$season·EP ${t.index ?? '?'}', text: t.summary!);
    }
    final summary = _item.summary?.trim();
    return summary == null || summary.isEmpty ? null : (mark: null, text: summary);
  }

  String? get _metaLine {
    final date = _item.originallyAvailableAt;
    String? shortDate;
    if (date != null && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(date)) {
      shortDate = '${date.substring(8, 10)}/${date.substring(5, 7)}/${date.substring(0, 4)}';
    }
    final parts = [
      if (_item.rating != null) '★ ${_item.rating!.toStringAsFixed(1).replaceAll('.', ',')}',
      shortDate ?? (_item.year != null ? '${_item.year}' : null),
      if (_item.studio?.isNotEmpty == true) _item.studio!,
      if (_item.contentRating?.isNotEmpty == true) _item.contentRating!,
    ].nonNulls.toList();
    return parts.isEmpty ? null : parts.join('  |  ');
  }

  String? _techLine(MediaFileVersion? version) {
    final seasons = _seasons.where((s) => (s.index ?? 1) > 0).length;
    final duration = _target?.durationMs ?? _item.durationMs;
    final video = version == null ? null : [for (final p in version.parts) ...p.streams]
        .where((s) => s.kind == MediaStreamKind.video).firstOrNull;
    final parts = [
      if (_item.kind == MediaKind.show && seasons > 0) seasons == 1 ? '1 temporada' : '$seasons temporadas',
      if (duration != null && duration >= 60000) '${duration ~/ 60000} min',
      ?_resolution(version?.videoResolutionLabel, video?.height ?? version?.height),
      if (version != null) ...heisucaMediaInfoCards(version).first.rows
          .where((r) => r.$1 == 'Faixa dinâmica').map((r) => r.$2),
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  /// "1080" → "1080p", "4k" → "4K"; cai na altura real se o rótulo não vier.
  String? _resolution(String? label, int? height) {
    final l = label?.trim().toLowerCase();
    if (l != null && l.isNotEmpty) {
      if (l == '4k' || l == '8k') return l.toUpperCase();
      return RegExp(r'^\d+$').hasMatch(l) ? '${l}p' : label;
    }
    return height == null ? null : '${height}p';
  }

  void _ensureFileInfo() {
    final target = _target;
    if (_fileInfo != null || target == null) return;
    final client = cgflixClientFor(context, target);
    // Future.sync: um erro síncrono do cliente vira estado de erro da seção, nunca derruba a ficha.
    if (client != null) _fileInfo = Future.sync(() => client.getFileInfo(target));
  }

  void _ensureSupplements() {
    _related ??= Future.sync(() => _loadSupplement(false));
    if (_item.kind == MediaKind.movie) _extras ??= Future.sync(() => _loadSupplement(true));
  }

  @override
  Widget build(BuildContext context) {
    final client = cgflixClientFor(context, _item);
    final c = _colors(context);
    final isShow = _item.kind == MediaKind.show;
    final size = MediaQuery.sizeOf(context);
    final height = (size.height * .72).clamp(440.0, 760.0);
    final art = cgflixWidePath(_item) ?? _item.thumbPath;
    final store = HeisucaStateStore.instance;
    if (!_loading) { _ensureFileInfo(); _ensureSupplements(); }
    final synopsis = _synopsis;
    final meta = _metaLine;
    return Theme(data: Theme.of(context).copyWith(textTheme: Theme.of(context).textTheme.apply(bodyColor: c.text, displayColor: c.text)),
      child: Scaffold(backgroundColor: c.page, body: Stack(children: [
        CustomScrollView(controller: _scroll, physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), slivers: [
          SliverToBoxAdapter(child: SizedBox(height: height, child: Stack(fit: StackFit.expand, children: [
            if (art != null && client != null) HeisucaArtworkMask(
              child: HeisucaParallax(controller: _scroll, child: widget.heroTag == null
                ? OptimizedMediaImage(client: client, imagePath: art, imageType: ImageType.art, fit: BoxFit.cover)
                : Hero(tag: widget.heroTag!, child: OptimizedMediaImage(client: client, imagePath: art, imageType: ImageType.art, fit: BoxFit.cover)))),
            Positioned(bottom: 8, left: 24, right: 24, child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(key: _logoAnchor, height: 104, width: size.width - 48),
              if (meta != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(meta, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.5, color: c.text))),
              FutureBuilder<MediaFileInfo?>(future: _fileInfo, builder: (_, snap) {
                final versions = snap.data?.versions ?? const <MediaFileVersion>[];
                final tech = _techLine(versions.isEmpty ? null : versions.first);
                return tech == null ? const SizedBox(height: 4) : Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(tech, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.text2,
                    fontFeatures: const [FontFeature.tabularFigures()])));
              }),
              const SizedBox(height: 4),
              Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: cgflixLanguageBadges(_target ?? _item)),
            ])),
          ]))),
          SliverList.list(children: [
            Padding(padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
              child: _playButton(c)),
            const SizedBox(height: 6),
            ListenableBuilder(listenable: store, builder: (_, __) => Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 22, children: [
              IconButton(tooltip: store.isFavorite(_item) ? 'Remover dos favoritos' : 'Favoritar',
                icon: Icon(store.isFavorite(_item) ? Icons.favorite_rounded : Icons.favorite_border_rounded), color: c.text,
                onPressed: client?.capabilities.userFavorites == true ? () => store.toggleFavorite(context, _item) : null),
              IconButton(tooltip: store.isWatched(_target ?? _item) ? 'Marcar como não visto' : 'Marcar como visto',
                icon: Icon(store.isWatched(_target ?? _item) ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded),
                color: c.text, onPressed: _markWatched),
              IconButton(tooltip: _queuing ? 'Adicionando à fila' : 'Baixar',
                icon: Icon(_queuing ? Icons.hourglass_top_rounded : Icons.download_rounded),
                color: c.text, onPressed: _queuing ? null : _download),
            ])),
            if (_error != null) ListTile(title: Text(_error!), trailing: TextButton(onPressed: _load, child: const Text('Tentar novamente'))),
            if (_loading) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: LinearProgressIndicator(minHeight: 2)),
            if (synopsis != null) Padding(padding: const EdgeInsets.only(top: 6),
              child: HeisucaSynopsis(key: ValueKey(synopsis.text), text: synopsis.text, mark: synopsis.mark, colors: c)),
            if (isShow) ..._seasonSection(c),
            if (_item.roles?.isNotEmpty == true) ...[
              HeisucaSectionTitle('Elenco', colors: c),
              SizedBox(height: 152, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _item.roles!.length,
                padding: const EdgeInsets.symmetric(horizontal: HeisucaTitleMetrics.margin),
                separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, i) => _person(c, client, _item.roles![i]))),
            ],
            if (_item.genres?.isNotEmpty == true) ...[
              HeisucaSectionTitle('Gêneros', colors: c),
              Padding(padding: const EdgeInsets.symmetric(horizontal: HeisucaTitleMetrics.margin),
                child: Wrap(spacing: 10, runSpacing: 10, children: [for (final genre in _item.genres!) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)),
                  child: Text(genre, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: c.text)))])),
            ],
            if (!isShow) _extrasSection(c),
            _relatedSection(c),
            _mediaInfoSection(c),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 40),
          ]),
        ]),
        Positioned.fill(child: HeisucaHomeChrome(
          scrollController: _scroll, logoAnchor: _logoAnchor, pageColor: c.page,
          item: _item, client: client, expandedLogoWidth: size.width - 48,
          expandedLogoHeight: 104, expandedTitleSize: 32, titleFontFamily: HeisucaTheme.fonteTitulo,
          belowHeaderAction: _docked ? _playButton(c, compact: true) : null,
          onSearch: () => cgflixOpenSearch(context),
          onHome: () => _scroll.animateTo(0, duration: HeisucaMotion.durationFor(context), curve: HeisucaMotion.curve),
          onTitleTap: () => _scroll.animateTo(0, duration: HeisucaMotion.durationFor(context), curve: HeisucaMotion.curve),
          onBack: () => Navigator.pop(context),
          onDockedChanged: (value) { if (mounted && value != _docked) setState(() => _docked = value); },
        )),
      ])));
  }

  List<Widget> _seasonSection(HeisucaTitleColors c) {
    final page = _episodes.skip(_group * 10).take(10).toList();
    final groups = (_episodes.length / 10).ceil();
    return [
      HeisucaSeasonHeader(label: _season != null ? heisucaSeasonLabel(_season!) : 'Temporadas', colors: c,
        onChoose: _seasons.length > 1 ? _chooseSeason : null, onSeeAll: _episodes.isEmpty ? null : _allEpisodes),
      if (_loadingEpisodes) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: LinearProgressIndicator(minHeight: 2)),
      if (_episodeError != null) TextButton(onPressed: _season == null ? null : () => _loadSeason(_season!),
        child: Text('$_episodeError Tentar novamente')),
      if (!_loadingEpisodes && _episodes.isEmpty && _episodeError == null) Padding(
        padding: const EdgeInsets.symmetric(horizontal: HeisucaTitleMetrics.margin),
        child: Text('Nenhum episódio disponível nesta temporada.', style: TextStyle(color: c.text2))),
      if (page.isNotEmpty) SizedBox(height: HeisucaTitleMetrics.landscapeCard * 9 / 16 + 62, child: _EpisodeStrip(
        key: ValueKey('${_season?.id}:$_group'),
        initialIndex: page.indexWhere((ep) => ep.id == _target?.id),
        children: page.map((ep) => _episodeCard(c, ep)).toList())),
      if (groups > 1) Padding(padding: const EdgeInsets.fromLTRB(HeisucaTitleMetrics.margin, 10, HeisucaTitleMetrics.margin, 0),
        child: Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < groups; i++) _pageChip(c, i)])),
    ];
  }

  Widget _pageChip(HeisucaTitleColors c, int i) {
    final selected = _group == i;
    return Material(
      color: selected ? c.line : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: selected ? c.text.withValues(alpha: .22) : c.line)),
      child: InkWell(customBorder: const StadiumBorder(), onTap: () => setState(() => _group = i),
        child: ConstrainedBox(constraints: const BoxConstraints(minWidth: 56, minHeight: 34), child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14), child: Center(widthFactor: 1, child: Text(
            '${i * 10 + 1}–${((i + 1) * 10).clamp(0, _episodes.length)}',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? c.text : c.text2,
              fontFeatures: const [FontFeature.tabularFigures()])))))));
  }

  Widget _person(HeisucaTitleColors c, MediaServerClient? client, MediaRole role) => SizedBox(width: 78, child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: role.id == null || role.id!.isEmpty || client == null ? null : () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ActorMediaScreen(actorName: role.tag, personId: role.id!,
        actorThumb: role.thumbPath, characterName: role.role, serverId: client.serverId.value,
        serverName: client.serverName, backend: client.backend))),
    child: Column(children: [
    ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(width: 76, height: 76, child: ColoredBox(color: c.line,
      child: role.thumbPath != null && client != null
        ? OptimizedMediaImage(client: client, imagePath: role.thumbPath!, imageType: ImageType.thumb, fit: BoxFit.cover)
        : Align(alignment: Alignment.bottomCenter, child: Icon(Icons.person_rounded, size: 60, color: c.text2.withValues(alpha: .45)))))),
    const SizedBox(height: 6),
    Text(role.tag, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.2, color: c.text)),
    if (role.role?.isNotEmpty == true) Text(role.role!.replaceAll('(voice)', '(voz)'), textAlign: TextAlign.center, maxLines: 2,
      overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, height: 1.2, color: c.text2)),
  ])));

  Widget _episodeCard(HeisucaTitleColors c, MediaItem ep) {
    final client = cgflixClientFor(context, ep);
    final hidden = _hidden(ep);
    final current = ep.id == _target?.id;
    final progress = (ep.durationMs ?? 0) > 0 ? ((ep.viewOffsetMs ?? 0) / ep.durationMs!).clamp(0.0, 1.0) : 0.0;
    final meta = _episodeMeta(ep);
    return SizedBox(width: HeisucaTitleMetrics.landscapeCard, child: GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: () => _playEpisode(ep),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(HeisucaTitleMetrics.cardRadius + 3),
            border: Border.all(color: current ? c.text : Colors.transparent, width: 2)),
          child: ClipRRect(borderRadius: BorderRadius.circular(HeisucaTitleMetrics.cardRadius), child: AspectRatio(aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: c.line),
              if (!hidden && ep.thumbPath != null && client != null) OptimizedMediaImage(client: client,
                imagePath: ep.thumbPath!, imageType: ImageType.thumb, fit: BoxFit.cover)
              else Center(child: Icon(Icons.play_circle_outline_rounded, size: 34, color: c.text2)),
              if (ep.isWatched) const Positioned(top: 6, right: 6, child: CircleAvatar(radius: 10, backgroundColor: Colors.black54,
                child: Icon(Icons.check_rounded, size: 14, color: Colors.white))),
              if (progress > 0) Positioned(left: 8, right: 8, bottom: 6, child: ClipRRect(borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(value: progress, minHeight: 3, color: Colors.white, backgroundColor: Colors.white30))),
            ]))),
        ),
        const SizedBox(height: 6),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text(_episodeTitle(ep), maxLines: 2,
          overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.25, color: c.text))),
        if (meta.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
          child: Text(meta, style: TextStyle(fontSize: 11.5, color: c.text2))),
      ])));
  }

  Future<void> _allEpisodes() => showModalBottomSheet<void>(sheetAnimationStyle: HeisucaMotion.sheetStyle(context), context: context, isScrollControlled: true, showDragHandle: true,
    builder: (ctx) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(ctx).height * .8, child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HeisucaSheetHeader(_season != null ? heisucaSeasonLabel(_season!) : 'Episódios',
          subtitle: _episodes.length == 1 ? '1 episódio' : '${_episodes.length} episódios'),
        Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(12, 0, 12, 16), itemCount: _episodes.length,
          itemBuilder: (_, i) {
            final ep = _episodes[i];
            final client = cgflixClientFor(context, ep);
            final hidden = _hidden(ep);
            final scheme = Theme.of(ctx).colorScheme;
            return Material(
              color: ep.id == _target?.id ? scheme.onSurface.withValues(alpha: .07) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(borderRadius: BorderRadius.circular(14), onTap: () { Navigator.pop(ctx); _playEpisode(ep); },
                child: Padding(padding: const EdgeInsets.all(8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 128, height: 72, child: Stack(fit: StackFit.expand, children: [
                    ColoredBox(color: scheme.onSurface.withValues(alpha: .08)),
                    if (!hidden && ep.thumbPath != null && client != null) OptimizedMediaImage(client: client,
                      imagePath: ep.thumbPath!, imageType: ImageType.thumb, fit: BoxFit.cover),
                    if (ep.isWatched) const Positioned(top: 4, right: 4, child: Icon(Icons.check_circle_rounded, size: 18, color: Colors.white)),
                  ]))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_episodeTitle(ep), maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (_episodeMeta(ep).isNotEmpty) Text(_episodeMeta(ep),
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurface.withValues(alpha: .65))),
                    if (!hidden && ep.summary?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 2), child: Text(ep.summary!,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, height: 1.35, color: scheme.onSurface.withValues(alpha: .65)))),
                  ])),
                ]))));
          })),
      ]))));

  Future<List<MediaItem>> _loadSupplement(bool extras) async {
    final client = cgflixClientFor(context, _item);
    if (client == null) throw StateError('Fonte indisponível');
    if (extras) return client.fetchExtras(_item.id);
    final hubs = await client.fetchRelatedHubs(_item.id);
    final items = <String, MediaItem>{};
    for (final hub in hubs) { for (final item in hub.items) { if (item.id != _item.id) items[item.globalKey] = item; } }
    return items.values.toList();
  }

  /// Relacionados como fileira de pôsteres da Home (mesmo cartão), não lista de nomes.
  Widget _relatedSection(HeisucaTitleColors c) => FutureBuilder<List<MediaItem>>(future: _related, builder: (context, snap) {
    final items = snap.data ?? const <MediaItem>[];
    if (snap.connectionState == ConnectionState.done && items.isEmpty) return const SizedBox.shrink();
    const width = 104.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      HeisucaSectionTitle('Títulos relacionados', colors: c),
      SizedBox(height: width * 1.5 + HeisucaPosterTile.textBlock + 10, child: snap.connectionState != ConnectionState.done
        ? ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4,
            padding: const EdgeInsets.symmetric(horizontal: HeisucaTitleMetrics.margin),
            separatorBuilder: (_, __) => const SizedBox(width: HeisucaTitleMetrics.gap),
            itemBuilder: (_, __) => Align(alignment: Alignment.topCenter, child: Container(width: width, height: width * 1.5,
              decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(HeisucaTitleMetrics.cardRadius)))))
        : ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: HeisucaTitleMetrics.margin),
            separatorBuilder: (_, __) => const SizedBox(width: HeisucaTitleMetrics.gap),
            itemBuilder: (context, i) => HeisucaPosterTile(width: width, item: items[i], client: cgflixClientFor(context, items[i]),
              onTap: () { HapticFeedback.lightImpact(); HeisucaTitleSheet.show(context, items[i]); }))),
    ]);
  });

  Widget _extrasSection(HeisucaTitleColors c) => FutureBuilder<List<MediaItem>>(future: _extras, builder: (context, snap) {
    final items = snap.data ?? const <MediaItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      HeisucaSectionTitle('Extras e trailers', colors: c),
      SizedBox(height: HeisucaTitleMetrics.landscapeCard * 9 / 16 + 44, child: ListView.separated(scrollDirection: Axis.horizontal,
        itemCount: items.length, padding: const EdgeInsets.symmetric(horizontal: HeisucaTitleMetrics.margin),
        separatorBuilder: (_, __) => const SizedBox(width: HeisucaTitleMetrics.gap),
        itemBuilder: (context, i) {
          final item = items[i];
          final client = cgflixClientFor(context, item);
          final thumb = cgflixWidePath(item) ?? item.thumbPath;
          return SizedBox(width: HeisucaTitleMetrics.landscapeCard, child: GestureDetector(onTap: () => cgflixPlay(context, item),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(HeisucaTitleMetrics.cardRadius), child: AspectRatio(aspectRatio: 16 / 9,
                child: Stack(fit: StackFit.expand, children: [
                  ColoredBox(color: c.line),
                  if (thumb != null && client != null) OptimizedMediaImage(client: client, imagePath: thumb, imageType: ImageType.thumb, fit: BoxFit.cover),
                  const Center(child: Icon(Icons.play_circle_fill_rounded, size: 36, color: Colors.white70)),
                ]))),
              const SizedBox(height: 6),
              Text(item.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.text)),
            ])));
        })),
    ]);
  });

  Widget _mediaInfoSection(HeisucaTitleColors c) => FutureBuilder<MediaFileInfo?>(future: _fileInfo, builder: (context, snap) {
    if (_fileInfo == null) return const SizedBox.shrink();
    if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
    if (snap.hasError) return Padding(padding: const EdgeInsets.only(top: 20), child: Center(child: TextButton(
      onPressed: () => setState(() { _fileInfo = null; _ensureFileInfo(); }), child: const Text('Informações da mídia: tentar novamente'))));
    final versions = snap.data?.versions ?? const <MediaFileVersion>[];
    if (versions.isEmpty) return const SizedBox.shrink();
    final version = versions[_versionIndex.clamp(0, versions.length - 1)];
    final cards = heisucaMediaInfoCards(version);
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      HeisucaSectionTitle(_item.kind == MediaKind.show && _target != null
        ? 'Info mídia · ${cgflixEpisodeCode(_target!)}' : 'Info mídia', colors: c),
      if (versions.length > 1) Padding(padding: const EdgeInsets.fromLTRB(HeisucaTitleMetrics.margin, 0, HeisucaTitleMetrics.margin, 10),
        child: Wrap(spacing: 8, children: [for (var i = 0; i < versions.length; i++) ChoiceChip(
          label: Text(versions[i].title ?? versions[i].videoResolutionLabel ?? 'Versão ${i + 1}'),
          selected: i == _versionIndex, onSelected: (_) => setState(() => _versionIndex = i))])),
      HeisucaMediaInfo(cards: cards, colors: c),
    ]);
  });
}

/// Cada página começa no episódio de continuação; o controller pertence ao widget.
/// Faixa de ponta a ponta (o cartão anterior desliza sob a borda, sem corte seco na margem) e encaixe por cartão.
class _EpisodeStrip extends StatefulWidget {
  const _EpisodeStrip({super.key, required this.initialIndex, required this.children});
  final int initialIndex;
  final List<Widget> children;
  @override
  State<_EpisodeStrip> createState() => _EpisodeStripState();
}
class _EpisodeStripState extends State<_EpisodeStrip> {
  static const _extent = HeisucaTitleMetrics.landscapeCard + HeisucaTitleMetrics.gap;
  late final _controller = ScrollController(initialScrollOffset: _extent * (widget.initialIndex < 0 ? 0 : widget.initialIndex));
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView.separated(controller: _controller, scrollDirection: Axis.horizontal,
    physics: const HeisucaSnapPhysics(itemExtent: _extent),
    padding: const EdgeInsets.symmetric(horizontal: HeisucaTitleMetrics.margin),
    itemCount: widget.children.length, separatorBuilder: (_, __) => const SizedBox(width: HeisucaTitleMetrics.gap),
    itemBuilder: (_, i) => widget.children[i]);
}
