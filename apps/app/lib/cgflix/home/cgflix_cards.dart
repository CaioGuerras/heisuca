// Cartões e linhas da Início do Heisuca Flagship:
// - Física de Mola Tátil (120Hz ElasticOutCurve + HapticFeedback)
// - Pôsteres 2:3 e Cards 16:9 com Squircle 12dp, borda especular hairline (0.75dp) e sombra profunda
// - Números Tabulares (FontFeature.tabularFigures) no Continuar Assistindo
// - Top 10 alinhado na base com gradiente metálico
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../heisuca/heisuca_design_system.dart';
import '../../heisuca/heisuca_text_metrics.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../utils/media_image_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/optimized_media_image.dart';
import '../cgflix_palette.dart';
import '../cgflix_style.dart';
import 'cgflix_actions.dart';

const double cgflixPosterWidth = 112;
const double cgflixPosterHeight = cgflixPosterWidth * 1.5;
const double cgflixWideWidth = 232;
const double cgflixWideHeight = cgflixWideWidth * 9 / 16;
const double cgflixRowSidePadding = 16;

// ---------------------------------------------------------------------------
// Esqueletos

/// Brilho que passa devagar por cima dos blocos cinza.
class CgflixShimmer extends StatefulWidget {
  const CgflixShimmer({super.key, required this.child});
  final Widget child;

  @override
  State<CgflixShimmer> createState() => _CgflixShimmerState();
}

class _CgflixShimmerState extends State<CgflixShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.0 + 3 * t - 1, 0),
            end: Alignment(-1.0 + 3 * t, 0),
            // Heitor: o cartão branco some no fundo claro; o esqueleto usa o tom mais escuro.
            colors: context.cgflix.isLight
                ? [context.cgflix.surfaceHigh, context.cgflix.surface, context.cgflix.surfaceHigh]
                : [context.cgflix.surface, context.cgflix.surfaceHigh, context.cgflix.surface],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class CgflixSkeletonBox extends StatelessWidget {
  const CgflixSkeletonBox({super.key, required this.width, required this.height, this.radius = 8});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.cgflix.isLight ? context.cgflix.surfaceHigh : context.cgflix.surface,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Linha "carregando": título + cartões cinza.
class CgflixSkeletonRow extends StatelessWidget {
  const CgflixSkeletonRow({super.key, this.wide = false});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final w = wide ? cgflixWideWidth : cgflixPosterWidth;
    final h = wide ? cgflixWideHeight : cgflixPosterHeight;
    return CgflixShimmer(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(cgflixRowSidePadding, 4, 0, 10),
              child: CgflixSkeletonBox(width: 160, height: 18, radius: 4),
            ),
            SizedBox(
              height: h,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: cgflixRowSidePadding),
                itemCount: 6,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, _) => CgflixSkeletonBox(width: w, height: h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Linha

/// Título + lista horizontal. A rolagem horizontal fica guardada ([storageKey]) para
/// voltar no mesmo lugar.
class CgflixRow extends StatelessWidget {
  const CgflixRow({
    super.key,
    required this.title,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    required this.storageKey,
    this.spacing = 8,
  });

  final String title;
  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final String storageKey;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(cgflixRowSidePadding, 4, cgflixRowSidePadding, 11),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Sora',
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                  ),
            ),
          ),
          SizedBox(
            height: height,
            child: ListView.separated(
              key: PageStorageKey<String>('cgflix-row:$storageKey'),
              physics: const ProMotionScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: cgflixRowSidePadding),
              itemCount: itemCount,
              separatorBuilder: (_, _) => SizedBox(width: spacing),
              itemBuilder: itemBuilder,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cartões

/// Encolhe com física de mola elástica (120Hz) e disparo tátil sutil ao tocar.
class CgflixPressable extends StatefulWidget {
  const CgflixPressable({super.key, required this.child, this.onTap, this.onLongPress, this.semanticLabel});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  State<CgflixPressable> createState() => _CgflixPressableState();
}

class _CgflixPressableState extends State<CgflixPressable> {
  bool _pressed = false;
  bool _focused = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onLongPressHint: widget.onLongPress == null ? null : 'mais opções',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                _set(false);
                Feedback.forLongPress(context);
                widget.onLongPress!();
              },
        child: FocusableActionDetector(
          enabled: widget.onTap != null,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call())},
          child: AnimatedScale(
            scale: _pressed ? 0.945 : 1.0,
            duration: _pressed ? const Duration(milliseconds: 110) : const Duration(milliseconds: 340),
            curve: _pressed ? Curves.easeOutCubic : const ElasticOutCurve(0.85),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: _focused ? Border.all(color: context.cgflix.focusRing, width: 3) : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class CgflixPosterCard extends StatelessWidget {
  const CgflixPosterCard({
    super.key,
    required this.item,
    required this.client,
    this.heroTag,
    this.onTap,
    this.onLongPress,
    this.width = cgflixPosterWidth,
  });

  final MediaItem item;
  final MediaServerClient? client;
  final String? heroTag;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.5;
    final isLight = context.cgflix.isLight;
    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: context.cgflix.surface,
        child: OptimizedMediaImage.poster(
          client: client,
          imagePath: cgflixPosterPath(item),
          width: width,
          height: height,
          fadeInDuration: CgflixMotion.fast,
        ),
      ),
    );
    image = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.11),
          width: 0.75,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLight
              ? context.cgflix.cardShadow
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.42),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                    spreadRadius: -3,
                  ),
                ],
        ),
        child: image,
      ),
    );
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return CgflixPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: item.displayTitle,
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}

/// Cartão largo (16:9) com título embaixo e, se houver, a barra de progresso.
class CgflixWideCard extends StatelessWidget {
  const CgflixWideCard({
    super.key,
    required this.item,
    required this.client,
    this.onTap,
    this.onLongPress,
    this.showProgress = true,
    this.width = cgflixWideWidth,
    this.siteStyle = false,
  });

  final MediaItem item;
  final MediaServerClient? client;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showProgress;
  final double width;
  final bool siteStyle;
  double get artHeight => width * 9 / 16;

  String _clock(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  static const double titleBlockHeight = 50;

  static double titleBlockHeightFor(BuildContext context, {bool siteStyle = false}) {
    final theme = Theme.of(context).textTheme;
    final title = theme.bodyMedium!.copyWith(fontWeight: FontWeight.w600, fontSize: siteStyle ? 12 : null);
    final subtitle = theme.bodySmall!.copyWith(fontSize: siteStyle ? 10.5 : null);
    final measured = 6 + heisucaLineHeight(context, title) + heisucaLineHeight(context, subtitle);
    return measured > titleBlockHeight ? measured : titleBlockHeight;
  }

  double? get _progress {
    final offset = item.viewOffsetMs;
    final duration = item.durationMs;
    if (offset == null || duration == null || duration <= 0 || offset <= 0) return null;
    return (offset / duration).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEpisode = item.kind == MediaKind.episode;
    final title = isEpisode ? (item.grandparentTitle ?? item.displayTitle) : item.displayTitle;
    final label = cgflixEpisodeLabel(item);
    final subtitle = isEpisode ? [label, item.title ?? ''].where((s) => s.isNotEmpty).join(' · ') : null;
    final progress = showProgress ? _progress : null;

    return CgflixPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: title,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: context.cgflix.isLight
                    ? context.cgflix.cardShadow
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.40),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                          spreadRadius: -3,
                        ),
                      ],
              ),
              child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.cgflix.isLight
                      ? Colors.black.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.11),
                  width: 0.75,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: width,
                  height: artHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: context.cgflix.surface,
                        child: OptimizedMediaImage(
                          client: client,
                          imagePath: cgflixWidePath(item),
                          width: width,
                          height: artHeight,
                          imageType: ImageType.thumb,
                          fadeInDuration: CgflixMotion.fast,
                        ),
                      ),
                      // Scrim sutil inferior e selo de play rápido
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 44,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.0),
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (siteStyle) Align(alignment: Alignment.center, child: Container(
                        width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.black26, border: Border.all(color: Colors.white, width: 2)),
                        child: const AppIcon(Symbols.play_arrow_rounded, fill: 1, size: 30, color: Colors.white),
                      )) else Positioned(left: 8, bottom: progress != null ? 9 : 7,
                        child: Container(width: 26, height: 26, decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                          child: const Center(child: AppIcon(Symbols.play_arrow_rounded, fill: 1, size: 16, color: Colors.white)))),
                      if (siteStyle && (item.viewOffsetMs ?? 0) > 0 && (item.durationMs ?? 0) > 0)
                        Positioned(right: 8, bottom: 12, child: Text('${_clock(item.viewOffsetMs!)} / ${_clock(item.durationMs!)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()]))),
                      if (progress != null)
                        Positioned(
                          left: siteStyle ? 10 : 0,
                          right: siteStyle ? 10 : 0,
                          bottom: siteStyle ? 5 : 0,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3.5,
                            color: siteStyle ? Colors.white : context.cgflix.accent,
                            backgroundColor: siteStyle ? Colors.white38 : context.cgflix.progressTrack,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: titleBlockHeightFor(context, siteStyle: siteStyle) - 6,
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: siteStyle ? 12 : null),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.cgflix.textMuted,
                            fontSize: siteStyle ? 10.5 : null,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
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

/// Top 10: número grande vazado (só contorno) ao lado do pôster.
class CgflixTop10Card extends StatelessWidget {
  const CgflixTop10Card({
    super.key,
    required this.rank,
    required this.item,
    required this.client,
    this.heroTag,
    this.onTap,
    this.onLongPress,
    this.siteStyle = false,
  });

  final bool siteStyle;
  final int rank;
  final MediaItem item;
  final MediaServerClient? client;
  final String? heroTag;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const double numberWidth = 64;
  static double widthFor(int rank) => numberWidth + (rank >= 10 ? 28 : 0) + cgflixPosterWidth;

  @override
  Widget build(BuildContext context) {
    final number = '$rank';
    final baseStyle = TextStyle(fontSize: siteStyle ? 72 : 128, height: siteStyle ? 0.74 : 1, fontWeight: FontWeight.w900, letterSpacing: siteStyle ? -4.3 : -10);
    final strokeStyle = baseStyle.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = siteStyle ? 1.5 : 3
        ..color = context.cgflix.rankStroke,
    );
    return Semantics(
      // O número grande não é lido; a posição vai junto do nome do título.
      label: 'Em alta, posição $rank',
      child: SizedBox(
        width: siteStyle ? 148.8 : widthFor(rank),
        height: siteStyle ? 134.4 : cgflixPosterHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: siteStyle ? 0 : -10,
              child: ExcludeSemantics(
                child: Stack(
                  children: [
                    // Preenchimento da cor do fundo por baixo do contorno: o número "vaza" o fundo.
                    if (!siteStyle) Text(number, style: baseStyle.copyWith(color: context.cgflix.background)),
                    Text(number, style: strokeStyle),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: CgflixPosterCard(
                width: siteStyle ? 89.6 : cgflixPosterWidth,
                item: item,
                client: client,
                heroTag: heroTag,
                onTap: onTap,
                onLongPress: onLongPress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

