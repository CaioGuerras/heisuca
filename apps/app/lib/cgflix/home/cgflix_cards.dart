// Cartões e linhas da Início do CGFLIX: pôster, cartão largo com progresso, Top 10 e
// esqueletos com brilho discreto (no lugar dos círculos de carregamento).
import 'package:flutter/material.dart';

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../utils/media_image_helper.dart';
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(cgflixRowSidePadding, 4, cgflixRowSidePadding, 10),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            height: height,
            child: ListView.separated(
              key: PageStorageKey<String>('cgflix-row:$storageKey'),
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

/// Encolhe um pouco ao tocar (resposta imediata, sem corte seco).
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

  /// Refino 2b: teclado, mouse e controle (Chromebook, TV box que não se diz TV) também abrem o
  /// cartão; o foco aparece como um contorno de 3 dp na cor do anel de foco do tema.
  bool _focused = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      // Leitor de tela: avisa que tocar e segurar abre mais opções.
      onLongPressHint: widget.onLongPress == null ? null : 'mais opções',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
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
            scale: _pressed ? 0.95 : 1,
            duration: CgflixMotion.fast,
            curve: CgflixMotion.curve,
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
    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
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
    // Heitor: sombra suave no lugar do brilho roxo (na Isis a lista é vazia).
    image = DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: context.cgflix.cardShadow),
      child: image,
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
  });

  final MediaItem item;
  final MediaServerClient? client;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showProgress;

  static const double titleBlockHeight = 50;

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
        width: cgflixWideWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: context.cgflix.cardShadow),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: cgflixWideWidth,
                  height: cgflixWideHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: context.cgflix.surface,
                        child: OptimizedMediaImage(
                          client: client,
                          imagePath: cgflixWidePath(item),
                          width: cgflixWideWidth,
                          height: cgflixWideHeight,
                          imageType: ImageType.thumb,
                          fadeInDuration: CgflixMotion.fast,
                        ),
                      ),
                      if (progress != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            color: context.cgflix.accent,
                            backgroundColor: context.cgflix.progressTrack,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: titleBlockHeight - 6,
              // Fonte grande do sistema não estoura o cartão (no máximo 1,2×).
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: context.cgflix.textMuted),
                        ),
                    ],
                  ),
                ),
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
  });

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
    const baseStyle = TextStyle(fontSize: 128, height: 1, fontWeight: FontWeight.w900, letterSpacing: -10);
    final strokeStyle = baseStyle.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = context.cgflix.rankStroke,
    );
    return Semantics(
      // O número grande não é lido; a posição vai junto do nome do título.
      label: 'Em alta, posição $rank',
      child: SizedBox(
        width: widthFor(rank),
        height: cgflixPosterHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: -10,
              child: ExcludeSemantics(
                child: Stack(
                  children: [
                    // Preenchimento da cor do fundo por baixo do contorno: o número "vaza" o fundo.
                    Text(number, style: baseStyle.copyWith(color: context.cgflix.background)),
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
