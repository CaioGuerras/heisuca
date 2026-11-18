import 'dart:async';
import 'desktop_session_artwork.dart';
import 'package:flutter/material.dart';
import '../../design/tema.dart';
import '../../design/componentes/toque.dart';
import '../../heisuca/heisuca_logo.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../desktop_home_actions.dart';
import '../desktop_preferences.dart';
import '../remote/desktop_cinema_controller.dart';
import '../remote/desktop_servers_controller.dart';

typedef CinemaArtworkBuilder = Widget Function(DesktopServerConnection, MediaItem, bool landscape);
typedef CinemaBrowse = void Function(DesktopServerConnection? source, MediaItem? item, MediaKind? kind, String? search);

/// Direção A: a biblioteca ocupa a Início; arquivos locais continuam a um gesto.
class DesktopCinemaHome extends StatefulWidget {
  const DesktopCinemaHome({super.key, required this.catalog, required this.preferences, required this.actions,
    required this.onBrowse, required this.onPlay, this.artworkBuilder});
  final DesktopCinemaController catalog;
  final DesktopPreferences preferences;
  final DesktopHomeActions actions;
  final CinemaBrowse onBrowse;
  final Future<void> Function(DesktopServerConnection, MediaItem) onPlay;
  final CinemaArtworkBuilder? artworkBuilder;
  @override
  State<DesktopCinemaHome> createState() => _DesktopCinemaHomeState();
}
class _DesktopCinemaHomeState extends State<DesktopCinemaHome> {
  final _search = TextEditingController();
  bool _starting = false;
  String? _playError;
  Object? _playErrorSession, _playClient;
  String? _playSourceId;
  int _playEpoch = 0;
  bool get _samePlaySource => source != null && source!.id == _playSourceId && identical(source!.client, _playClient) && identical(source!.client.authenticationSessionId, _playErrorSession);
  bool get _startingHere => _starting && _samePlaySource;
  TemaHeisuca get p => Theme.of(context).extension<TemaHeisuca>()!;
  DesktopServerConnection? get source => widget.catalog.source;
  @override
  void initState() {
    super.initState();
    // A tela é recriada ao voltar do player: buscar o progresso atual do servidor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.catalog.synchronize();
      if (source != null && !widget.catalog.loading) unawaited(widget.catalog.refresh());
    });
  }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Text text(String value, {double size = 14, bool bold = false, Color? color, int? lines, double? spacing}) => Text(value,
    maxLines: lines, overflow: lines == null ? null : TextOverflow.ellipsis,
    style: TextStyle(fontFamily: 'Inter', fontSize: size, color: color ?? p.texto,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400, height: 1.35, letterSpacing: spacing));
  Widget touch(Widget child, VoidCallback? action, {String? label, double radius = 12}) => Toque(
    forma: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)), aoTocar: action, rotulo: label, child: child);
  Widget glyph(IconData icon, String label, VoidCallback action) => Tooltip(message: label, child: touch(
    SizedBox(width: 42, height: 42, child: Icon(icon, size: 21, color: p.texto)), action, label: label));
  Widget button(String title, IconData icon, VoidCallback? action, {bool primary = false}) => touch(Container(
    constraints: const BoxConstraints(minHeight: 46), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
    decoration: BoxDecoration(color: primary ? p.botaoFundo : p.fundo.withValues(alpha: .68), borderRadius: BorderRadius.circular(11),
      border: primary ? null : Border.all(color: p.texto.withValues(alpha: .26))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 20, color: primary ? p.botaoTexto : p.texto),
      const SizedBox(width: 8), text(title, bold: true, color: primary ? p.botaoTexto : p.texto)])), action);
  void browse({MediaItem? item, MediaKind? kind, String? search}) => widget.onBrowse(source, item, kind, search);
  Future<void> play(MediaItem item) async {
    final server = source;
    if (server == null || _startingHere) return;
    final epoch = ++_playEpoch;
    _playClient = server.client; _playSourceId = server.id;
    setState(() { _starting = true; _playError = null; _playErrorSession = server.client.authenticationSessionId; });
    try { await widget.onPlay(server, item); }
    on Object { if (mounted && epoch == _playEpoch) setState(() => _playError = 'Não foi possível iniciar este título. Abra os detalhes para tentar outra versão.'); }
    finally { if (mounted && epoch == _playEpoch) setState(() => _starting = false); }
  }
  Widget artwork(MediaItem item, {bool landscape = false, bool large = false}) {
    final server = source;
    if (server == null) return const SizedBox.shrink();
    final builder = widget.artworkBuilder;
    if (builder != null) return builder(server, item, landscape);
    final candidates = landscape ? item.heroArtCandidates(containerAspectRatio: 2.6) : const <String>[];
    final path = candidates.isNotEmpty ? candidates.first : item.thumbPath;
    if (path == null || path.isEmpty) return ColoredBox(color: p.superficie);
    try {
      final url = server.client.thumbnailUrl(path, width: landscape ? (large ? 1600 : 640) : 400);
      return Image(image: DesktopSessionArtwork(url, server.client.streamHeaders, server.client.authenticationSessionId),
        fit: BoxFit.cover, errorBuilder: (_, _, _) => ColoredBox(color: p.superficie),
        excludeFromSemantics: true, gaplessPlayback: false);
    } on Object { return ColoredBox(color: p.superficie); }
  }
  Widget navigation() => Row(mainAxisSize: MainAxisSize.min, children: [
    nav('Início', () {} , selected: true), nav('Filmes', source == null ? null : () => browse(kind: MediaKind.movie)),
    nav('Séries', source == null ? null : () => browse(kind: MediaKind.show)), nav('Bibliotecas', widget.actions.openLibrary),
  ]);
  Widget nav(String title, VoidCallback? onTap, {bool selected = false}) => touch(Padding(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13), child: Column(mainAxisSize: MainAxisSize.min, children: [
      text(title, size: 13, bold: selected, color: selected ? p.texto : p.texto2), const SizedBox(height: 7),
      Container(height: 2, width: 15, color: selected ? p.acento : Colors.transparent),
    ])), onTap);
  Widget header(double width) {
    final compact = width < 1200 || MediaQuery.textScalerOf(context).scale(14) > 20;
    return Column(children: [Padding(padding: EdgeInsets.symmetric(horizontal: width < 900 ? 24 : 44, vertical: 15),
      child: Row(children: [const HeisucaLogo(width: 156, height: 34, siteHeader: true), const SizedBox(width: 26),
        if (!compact) navigation(), const Spacer(),
        if (width >= 800) SizedBox(width: compact ? 200 : 238, height: 40, child: TextField(controller: _search,
          enabled: source != null, onSubmitted: (value) {if(value.trim().isNotEmpty) browse(search: value.trim());},
          style: TextStyle(fontSize: 12, color: p.texto),
          decoration: InputDecoration(hintText: 'Buscar na biblioteca', hintStyle: TextStyle(fontSize: 12, color: p.texto2),
            prefixIcon: Icon(Icons.search, size: 18, color: p.texto2), contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: p.borda))))),
        const SizedBox(width: 10), PopupMenuButton<String>(tooltip: 'Abrir vídeo', icon: Icon(Icons.add, color: p.texto),
          onSelected: (value) => value == 'file' ? widget.actions.openFile() : widget.actions.openUrl(),
          itemBuilder: (_) => [const PopupMenuItem(value: 'file', child: Text('Abrir arquivo')), const PopupMenuItem(value: 'url', child: Text('Abrir URL'))]),
        glyph(Icons.tune, 'Ajustes', widget.actions.openSettings),
      ])), if (compact) SingleChildScrollView(scrollDirection: Axis.horizontal, child: navigation()),
    ]);
  }
  Widget sourcePicker() => PopupMenuButton<String>(tooltip: 'Escolher biblioteca', onSelected: widget.catalog.selectServer,
    itemBuilder: (_) => widget.catalog.servers.connections.map((s) => PopupMenuItem(value: s.id, child: Text(s.name))).toList(),
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10), decoration: BoxDecoration(color: p.superficie,
      border: Border.all(color: p.borda), borderRadius: BorderRadius.circular(11)), child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.dns_outlined, size: 16, color: p.texto2), const SizedBox(width: 9),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 240), child: text(source?.name ?? 'Sua biblioteca', size: 12, bold: true, lines: 1)),
      const SizedBox(width: 12), Icon(Icons.expand_more, size: 16, color: p.texto2),
    ])));
  Widget hero(MediaItem item, double width) {
    final pad = width < 900 ? 24.0 : 48.0;
    final narrow = width < 900 || MediaQuery.textScalerOf(context).scale(14) > 20;
    return ConstrainedBox(constraints: BoxConstraints(minHeight: narrow ? 440 : 360), child: Stack(children: [
      Positioned(right: 0, top: 0, bottom: 0, width: width * .84, child: artwork(item, landscape: true, large: true)),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        colors: [p.fundo, p.fundo.withValues(alpha: .94), p.fundo.withValues(alpha: .35), p.fundo.withValues(alpha: .06)],
        stops: const [0,.26,.6,1])))),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent,p.fundo], stops: const [.4,1])))),
      Padding(padding: EdgeInsets.fromLTRB(pad, 24, pad, 34), child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: narrow ? width - pad * 2 : 490, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sourcePicker(), const SizedBox(height: 20), text(item.displayTitle, size: narrow ? 34 : 47, bold: true, lines: 2),
        const SizedBox(height: 12), text([if(item.year != null) '${item.year}', if((item.durationMs ?? 0) > 0) duration(item.durationMs!),
          if(item.kind == MediaKind.show) 'Série'].join('   ·   '), size: 12, color: p.texto2), const SizedBox(height: 13),
        if ((item.summary ?? '').isNotEmpty) text(item.summary!, size: 13, color: p.texto2, lines: 2),
        const SizedBox(height: 22), Wrap(spacing: 10, runSpacing: 10, children: [
          button(_startingHere ? 'Abrindo…' : 'Assistir', Icons.play_arrow_rounded, _startingHere ? null : () => unawaited(play(item)), primary: true),
          button('Ver detalhes', Icons.info_outline, () => browse(item: item)),
        ]),
      ])))),
    ]));
  }
  String duration(int ms) {
    final minutes = Duration(milliseconds: ms).inMinutes;
    return minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}min' : '${minutes}min';
  }
  Widget heading(String title, VoidCallback? onAll) => Row(children: [Expanded(child: text(title, size: 20, bold: true, lines: 2)),
    if (onAll != null) touch(Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Row(children: [
      text('Ver todos', size: 11, color: p.texto2), Icon(Icons.chevron_right, size: 16, color: p.texto2)])), onAll)]);
  Widget row(String title, List<MediaItem> items, double width, {bool resume = false}) {
    final pad = width < 900 ? 24.0 : 48.0;
    final itemWidth = resume ? (width < 1000 ? 260.0 : 310.0) : (width < 1000 ? 145.0 : 157.0);
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return Padding(padding: EdgeInsets.fromLTRB(pad, 5, 0, 24), child: Column(children: [
      Padding(padding: EdgeInsets.only(right: pad), child: heading(title, null)), const SizedBox(height: 8),
      SizedBox(height: (resume ? 145 : 280) + (scale - 1).clamp(0, 2) * 48, child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: items.length, padding: EdgeInsets.only(right: pad),
        separatorBuilder: (_, _) => const SizedBox(width: 18), itemBuilder: (_, index) {
          final item = items[index]; final total = item.durationMs ?? 0; final position = item.viewOffsetMs ?? 0;
          return SizedBox(width: itemWidth, child: _CinemaHover(onTap: () => resume ? unawaited(play(item)) : browse(item: item),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(9), child: SizedBox(width: itemWidth, height: resume ? 100 : 232,
                child: Stack(fit: StackFit.expand, children: [artwork(item, landscape: resume),
                  if (resume) ...[Center(child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle,
                    color: p.fundo.withValues(alpha: .55), border: Border.all(color: p.texto.withValues(alpha: .6))),
                    child: Icon(Icons.play_arrow_rounded, size: 20, color: p.texto))),
                    if(total > 0) Positioned(left: 0, right: 0, bottom: 0, child: LinearProgressIndicator(minHeight: 3,
                      value: (position / total).clamp(0,1), color: p.acento, backgroundColor: p.fundo.withValues(alpha: .5)))],
                ]))), const SizedBox(height: 8), text(item.displayTitle, size: 12, bold: true, lines: 1),
              if (item.displaySubtitle != null) text(item.displaySubtitle!, size: 10, color: p.texto2, lines: 1)
              else if(item.year != null) text('${item.year}', size: 10, color: p.texto2),
            ])));
        })),
    ]));
  }
  Widget message(String value, {VoidCallback? retry, VoidCallback? dismiss}) => Padding(padding: const EdgeInsets.fromLTRB(24,8,24,10),
    child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: p.superficie, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Expanded(child: text(value, size: 13)), if(retry != null) TextButton(onPressed: retry, child: const Text('Tentar novamente')),
        if(dismiss != null) glyph(Icons.close, 'Fechar aviso', dismiss)])));
  Widget empty(double width) {
    final pad = width < 900 ? 24.0 : 48.0;
    return Padding(padding: EdgeInsets.fromLTRB(pad, 42, pad, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      text('SEU CINEMA, NO SEU TEMPO', size: 11, spacing: 2, color: p.texto2), const SizedBox(height: 22),
      text(source == null ? 'Uma tela inteira\npara suas histórias.' : 'Sua próxima história\ncomeça aqui.', size: width < 900 ? 36 : 55, bold: true),
      const SizedBox(height: 20), ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: text(
        source == null ? 'Conecte sua biblioteca Plex ou Jellyfin. Ou abra um vídeo do computador e dê o play.'
          : 'Este servidor ainda não mostrou títulos na Início. Abra as bibliotecas para explorar seu conteúdo.', size: 15, color: p.texto2)),
      const SizedBox(height: 30), Wrap(spacing: 12, runSpacing: 12, children: [button(source == null ? 'Conectar biblioteca' : 'Explorar bibliotecas',
        Icons.video_library_outlined, widget.actions.openLibrary, primary: true), button('Abrir arquivo', Icons.folder_open_outlined, widget.actions.openFile)]),
      const SizedBox(height: 55), if(source == null) text('Plex  /  Jellyfin  /  Seus arquivos', size: 12, spacing: 1.3, color: p.texto2),
    ]));
  }
  Widget skeleton(double width) {
    final pad = width < 900 ? 24.0 : 48.0;
    Widget block(double w, double h) => Container(width: w, height: h,
      decoration: BoxDecoration(color: p.superficie, borderRadius: BorderRadius.circular(10)));
    return Semantics(label: 'Carregando sua biblioteca', child: Padding(padding: EdgeInsets.fromLTRB(pad, 30, pad, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        block(170,35), const SizedBox(height: 35), block(width < 900 ? 290 : 430, 55),
        const SizedBox(height: 18), block(260,15), const SizedBox(height: 15), block(width < 900 ? 290 : 440,14),
        const SizedBox(height: 30), block(140,44), const SizedBox(height: 66), block(230,22), const SizedBox(height: 20),
        SizedBox(height: 120, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 5,
          itemBuilder: (_, _) => block(290,120), separatorBuilder: (_, _) => const SizedBox(width: 18))),
      ])));
  }
  Widget recents(double width) => Padding(padding: EdgeInsets.symmetric(horizontal: width < 900 ? 24 : 48, vertical: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading('No seu computador', null), const SizedBox(height: 12),
      for(final entry in widget.preferences.recents.take(5)) Padding(padding: const EdgeInsets.only(bottom: 8), child: touch(
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: p.superficie, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [Icon(Icons.play_arrow_outlined, color: p.texto2), const SizedBox(width: 14),
            Expanded(child: text(entry.title, size: 13, lines: 2)), const SizedBox(width: 12),
            if(entry.resumePositionMs > 0) text('Continuar em ${duration(entry.resumePositionMs)}', size: 11, color: p.texto2)])),
        () => widget.actions.openRecent(entry))),
    ]));
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: Listenable.merge([widget.catalog,widget.preferences]),
    builder: (context, _) => ColoredBox(color: p.fundo, child: LayoutBuilder(builder: (_, bounds) => Column(children: [header(bounds.maxWidth),
      Expanded(child: ListView(children: [
        if(widget.actions.error != null) message(widget.actions.error!, dismiss: widget.actions.dismissError),
        if(_playError != null && _samePlaySource) message(_playError!, dismiss: () => setState(() => _playError = null)),
        if(widget.catalog.error != null) message(widget.catalog.error!, retry: () => unawaited(widget.catalog.refresh())),
        if(widget.catalog.featured == null && source != null)
          Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 0), child: Align(alignment: Alignment.centerLeft, child: sourcePicker())),
        if(widget.catalog.loading && widget.catalog.rows.isEmpty) skeleton(bounds.maxWidth) else ...[
          if(widget.catalog.featured case final item?) hero(item, bounds.maxWidth) else if(widget.catalog.rows.isEmpty) empty(bounds.maxWidth),
          for(final hub in widget.catalog.rows.take(7)) row(hub.isContinueWatchingHub ? 'Continue de onde parou' : hub.title,
            hub.items, bounds.maxWidth, resume: hub.isContinueWatchingHub),
          if(widget.preferences.recents.isNotEmpty) recents(bounds.maxWidth),
        ], const SizedBox(height: 30),
      ])),
    ]))));
}

/// A chave inclui a sessão: a mesmaURL com headers de outro perfil não reutiliza arte privada do anterior.
class _CinemaHover extends StatefulWidget {
  const _CinemaHover({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<_CinemaHover> createState() => _CinemaHoverState();
}
class _CinemaHoverState extends State<_CinemaHover> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => hover = true), onExit: (_) => setState(() => hover = false),
    child: AnimatedScale(scale: hover && !MediaQuery.disableAnimationsOf(context) ? 1.025 : 1,
      duration: const Duration(milliseconds: 180), curve: Curves.easeOutCubic,
      child: Toque(forma: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), aoTocar: widget.onTap, child: widget.child)));
}
