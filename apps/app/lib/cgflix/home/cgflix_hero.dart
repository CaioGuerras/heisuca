// Destaque Cinematográfico do Topo da Início (Heisuca Flagship):
// - Scrim Easing Cúbico de 9 paradas Hermite Smoothstep (zero faixa preta / Mach banding)
// - Halo Atmosférico Calibrado em OKLCH (Chroma clamped <= 0.075)
// - ClearLogo com elevação suave, Badges Técnicos Nobres, Números Tabulares (tnum)
// - Botões com Física de Mola Tátil (120Hz) e Indicadores de Carrossel em Pílula Viva
import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../heisuca/heisuca_design_system.dart';
import '../../media/media_item.dart';
import '../../utils/media_image_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/optimized_media_image.dart';
import '../cgflix_detail.dart';
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
        if (v.abs() < 180) return;
        HapticFeedback.selectionClick();
        _go(v < 0 ? 1 : widget.items.length - 1);
        _restartTimer();
      },
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fundo: troca cruzada entre um título e o próximo com zoom sutil cinematográfico.
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
            // Scrim Superior Zenital (protege a barra de status com curva suave).
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.cgflix.background.withValues(alpha: 0.72),
                          context.cgflix.background.withValues(alpha: 0.28),
                          context.cgflix.background.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Scrim Easing Cúbico de 9 paradas Hermite Smoothstep (elimina faixa preta / Mach banding).
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: CubicScrimGradient.create(
                    baseColor: context.cgflix.background,
                    begin: const Alignment(0.0, -0.15),
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Halo Atmosférico Calibrado em OKLCH na base do Hero.
            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 0.85),
                      radius: 1.15,
                      colors: [
                        OklchColor.fromColor(context.cgflix.accent)
                            .toCalibratedAmbientColor(isDarkTheme: !context.cgflix.isLight)
                            .withValues(alpha: context.cgflix.isLight ? 0.22 : 0.36),
                        context.cgflix.background.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: compact ? 24 + padding.left : 16,
              right: compact ? null : 16,
              width: compact ? infoWidth : null,
              bottom: compact ? 20 : 14,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: const Cubic(0.22, 1.0, 0.36, 1.0),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: _HeroInfo(
                  key: ValueKey('info:${item.globalKey}'),
                  item: item,
                  width: infoWidth,
                  compact: compact,
                  totalItems: widget.items.length,
                  currentIndex: _index % widget.items.length,
                  onSelectDot: (target) {
                    HapticFeedback.selectionClick();
                    setState(() => _index = target);
                    _restartTimer();
                  },
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
  const _HeroInfo({
    super.key,
    required this.item,
    required this.width,
    this.compact = false,
    this.totalItems = 1,
    this.currentIndex = 0,
    this.onSelectDot,
  });
  final MediaItem item;
  final double width;
  final bool compact;
  final int totalItems;
  final int currentIndex;
  final ValueChanged<int>? onSelectDot;

  List<String> _extractNobleBadges(MediaItem item) {
    final badges = <String>[];
    final flags = cgflixLanguageFlags(item);
    if (flags.dubbed) badges.add('DUBLADO');
    if (flags.subtitled) badges.add('LEGENDADO');
    final res = item.mediaVersions?.firstOrNull?.videoResolution?.toUpperCase() ?? '';
    if (res.contains('4K') || res.contains('2160')) {
      badges.add('4K UHD');
    } else if (res.contains('1080')) {
      badges.add('FULL HD');
    }
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.cgflix;
    final client = cgflixClientFor(context, item);
    final genres = (item.genres ?? const <String>[]).take(3).join(' • ');
    final logoWidth = (width * 0.74).clamp(170.0, 350.0);
    final align = compact ? Alignment.bottomLeft : Alignment.bottomCenter;
    final year = item.year?.toString() ?? '';
    final rating = item.rating != null && item.rating! > 0 ? item.rating!.toStringAsFixed(1) : '';
    final badges = _extractNobleBadges(item);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        ClearLogoImage(
          client: client,
          logoPath: item.clearLogoPath,
          width: logoWidth,
          height: compact ? 68 : 98,
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
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Linha Nobre de Metadados (Ano • Nota Tabular • Gêneros • Badges Monocromáticos)
        Wrap(
          alignment: compact ? WrapAlignment.start : WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            if (year.isNotEmpty)
              Text(
                year,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            if (rating.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFC107)),
                  const SizedBox(width: 2),
                  Text(
                    rating,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            if (genres.isNotEmpty)
              Text(
                genres,
                style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted, fontWeight: FontWeight.w500),
              ),
            for (final b in badges) HeisucaNobleBadge(label: b),
          ],
        ),
        const SizedBox(height: 16),
        // Botões Cinematográficos com Física de Mola Tátil (120Hz)
        Wrap(
          alignment: compact ? WrapAlignment.start : WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            HeisucaSpringPressable(
              onTap: () {
                HapticFeedback.lightImpact();
                cgflixPlay(context, item);
              },
              child: Container(
                constraints: const BoxConstraints(minWidth: 140, minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: palette.action,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.75),
                  boxShadow: [
                    BoxShadow(
                      color: palette.action.withValues(alpha: 0.38),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(Symbols.play_arrow_rounded, fill: 1, size: 22, color: palette.onAction),
                    const SizedBox(width: 8),
                    Text(
                      'Assistir',
                      style: TextStyle(
                        color: palette.onAction,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HeisucaSpringPressable(
              onTap: () {
                HapticFeedback.selectionClick();
                showCgflixPreview(context, item);
              },
              child: Container(
                constraints: const BoxConstraints(minWidth: 136, minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: palette.glass,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.glassBorder, width: 0.75),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(Symbols.info_rounded, fill: 0, size: 20, color: palette.onGlass),
                    const SizedBox(width: 8),
                    Text(
                      'Detalhes',
                      style: TextStyle(
                        color: palette.onGlass,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (totalItems > 1) ...[
          const SizedBox(height: 14),
          // Indicadores de Carrossel em Pílula Viva
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: List.generate(totalItems.clamp(0, 8), (i) {
              final active = i == currentIndex;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelectDot?.call(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: active ? 20.0 : 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: active ? palette.accent : palette.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
