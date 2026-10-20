// Destaque do topo da Início: fundo + logo + "Assistir" e "Detalhes", trocando a cada
// ~8 s com transição cruzada suave. Sem vídeo automático. Arrastar para o lado troca na hora.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../media/media_item.dart';
import '../../utils/media_image_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/optimized_media_image.dart';
import '../cgflix_layout.dart';
import '../cgflix_navigation.dart';
import '../cgflix_palette.dart';
import '../cgflix_style.dart';
import 'cgflix_actions.dart';
import 'cgflix_home_logic.dart';
import 'cgflix_preview_sheet.dart';

class CgflixHero extends StatefulWidget {
  const CgflixHero({super.key, required this.items, required this.height, this.paused = false});

  final List<MediaItem> items;
  final double height;

  /// Aba escondida ou app em segundo plano: o relógio do destaque para.
  final bool paused;

  @override
  State<CgflixHero> createState() => _CgflixHeroState();
}

class _CgflixHeroState extends State<CgflixHero> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(CgflixHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.items.length) _index = 0;
    if (oldWidget.paused != widget.paused || oldWidget.items.length != widget.items.length) _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Leitor de tela ou "remover animações" ligados: o destaque não troca sozinho (arrastar
  /// para o lado continua trocando).
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context) || MediaQuery.accessibleNavigationOf(context);
    if (still != _still) {
      _still = still;
      _restartTimer();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.paused || _still || widget.items.length < 2) return;
    _timer = Timer.periodic(cgflixHeroInterval, (_) => _go(1));
  }

  void _go(int delta) {
    if (!mounted || widget.items.isEmpty) return;
    setState(() => _index = (_index + delta) % widget.items.length);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return SizedBox(height: widget.height);
    final item = widget.items[_index % widget.items.length];
    final client = cgflixClientFor(context, item);
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    // Deitado: informação à esquerda, numa coluna estreita, para não cobrir a arte toda.
    final compact = cgflixHeroCompact(size);
    final padding = MediaQuery.paddingOf(context);
    final infoWidth = compact ? (width * 0.45).clamp(280.0, 440.0) : width - 32;
    final art = item.heroArtCandidates(containerAspectRatio: width / widget.height);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() < 200) return;
        _go(v < 0 ? 1 : widget.items.length - 1);
        _restartTimer();
      },
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fundo: troca cruzada entre um título e o próximo.
            AnimatedSwitcher(
              duration: CgflixMotion.crossFade,
              switchInCurve: CgflixMotion.curve,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
              child: KeyedSubtree(
                key: ValueKey('bg:${item.globalKey}'),
                child: OptimizedMediaImage(
                  client: client,
                  imagePath: art.isNotEmpty ? art.first : null,
                  width: width,
                  height: widget.height,
                  imageType: ImageType.art,
                  fadeInDuration: CgflixMotion.slow,
                ),
              ),
            ),
            // Véus: em cima para a barra de status, embaixo para o texto e a Início (escuro na
            // Isis, claro no Heitor, para o texto do tema continuar legível sobre a foto).
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: context.cgflix.heroVeil,
                    stops: const [0, 0.22, 0.45, 0.85, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: compact ? 24 + padding.left : 16,
              right: compact ? null : 16,
              width: compact ? infoWidth : null,
              bottom: compact ? 20 : 12,
              child: AnimatedSwitcher(
                duration: CgflixMotion.slow,
                switchInCurve: CgflixMotion.curve,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: _HeroInfo(
                  key: ValueKey('info:${item.globalKey}'),
                  item: item,
                  width: infoWidth,
                  compact: compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroInfo extends StatelessWidget {
  const _HeroInfo({super.key, required this.item, required this.width, this.compact = false});
  final MediaItem item;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = cgflixClientFor(context, item);
    final genres = (item.genres ?? const <String>[]).take(3).join(' • ');
    final logoWidth = (width * 0.7).clamp(160.0, 340.0);
    final align = compact ? Alignment.bottomLeft : Alignment.bottomCenter;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        ClearLogoImage(
          client: client,
          logoPath: item.clearLogoPath,
          width: logoWidth,
          height: compact ? 64 : 96,
          fallbackWidth: width,
          alignment: align,
          fadeInDuration: CgflixMotion.medium,
          fallbackBuilder: (context) => Align(
            alignment: align,
            child: Text(
              item.displayTitle,
              textAlign: compact ? TextAlign.start : TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        if (genres.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(genres, style: theme.textTheme.bodyMedium?.copyWith(color: context.cgflix.textMuted)),
        ],
        const SizedBox(height: 14),
        // Wrap: com fonte grande (até 200%) os botões descem de linha em vez de cortar.
        Wrap(
          alignment: compact ? WrapAlignment.start : WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                // Isis: roxo #9333ea com branco (5,4:1); Heitor: verde #006e28 com branco (6,1:1).
                backgroundColor: context.cgflix.action,
                foregroundColor: context.cgflix.onAction,
                minimumSize: const Size(132, 48),
              ).copyWith(overlayColor: cgflixPressedOverlay(context)),
              onPressed: () => cgflixPlay(context, item),
              icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1),
              label: const Text('Assistir'),
            ),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: context.cgflix.secondaryAction,
                foregroundColor: context.cgflix.onSecondaryAction,
                minimumSize: const Size(132, 48), // mesma altura do "Assistir"
              ),
              onPressed: () => showCgflixPreview(context, item),
              icon: const AppIcon(Symbols.info_rounded, fill: 1),
              label: const Text('Detalhes'),
            ),
          ],
        ),
      ],
    );
  }
}
