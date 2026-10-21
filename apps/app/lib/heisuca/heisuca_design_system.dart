import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Design System Flagship do Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Calibrado para telas OLED de 120Hz/144Hz, motor Impeller (Vulkan) e fidelidade cinematográfica.

/// Coordenadas de cor no espaço perceptualmente uniforme OKLCH.
/// Garante que halos e gradientes não sofram dessaturação cinzenta ("zonas mortas") no centro.
class OklchColor {
  final double l; // Lightness [0.0, 1.0]
  final double c; // Chroma [0.0, ~0.4]
  final double h; // Hue em graus [0.0, 360.0]

  const OklchColor(this.l, this.c, this.h);

  /// Converte Color (sRGB) para OKLCH.
  factory OklchColor.fromColor(Color color) {
    double toLinear(double v) =>
        v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

    final rLin = toLinear(color.red / 255.0);
    final gLin = toLinear(color.green / 255.0);
    final bLin = toLinear(color.blue / 255.0);

    // Linear sRGB -> CIE XYZ (D65)
    final x = 0.4122214708 * rLin + 0.3575799056 * gLin + 0.1804239236 * bLin;
    final y = 0.2126729000 * rLin + 0.7151522000 * gLin + 0.0721750000 * bLin;
    final z = 0.0193329000 * rLin + 0.1191942000 * gLin + 0.9503041000 * bLin;

    // XYZ -> LMS
    final lPrime = 0.8189330101 * x + 0.3618667424 * y - 0.1288597137 * z;
    final mPrime = 0.0329845436 * x + 0.9293118715 * y + 0.0361456387 * z;
    final sPrime = 0.0482003018 * x + 0.2643662691 * y + 0.6338517070 * z;

    // Raiz cúbica
    double cbrt(double v) => v < 0 ? -math.pow(-v, 1.0 / 3.0).toDouble() : math.pow(v, 1.0 / 3.0).toDouble();
    final l_ = cbrt(lPrime);
    final m_ = cbrt(mPrime);
    final s_ = cbrt(sPrime);

    // LMS -> Oklab
    final labL = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
    final labA = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
    final labB = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;

    // Oklab -> OKLCH
    final chroma = math.sqrt(labA * labA + labB * labB);
    var hue = math.atan2(labB, labA) * 180.0 / math.pi;
    if (hue < 0) hue += 360.0;

    return OklchColor(labL, chroma, hue);
  }

  /// Retorna cor calibrada para o halo cinematográfico Heisuca (Chroma clamped a 0.075).
  Color toCalibratedAmbientColor({bool isDarkTheme = true}) {
    final targetL = isDarkTheme ? 0.20 : 0.83;
    final clampedC = math.min(c, 0.075);
    return _oklchToColor(targetL, clampedC, h);
  }

  static Color _oklchToColor(double l, double c, double h) {
    final hRad = h * math.pi / 180.0;
    final a = c * math.cos(hRad);
    final b = c * math.sin(hRad);

    final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
    final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
    final s_ = l - 0.0894841775 * a - 1.2914855480 * b;

    final l3 = l_ * l_ * l_;
    final m3 = m_ * m_ * m_;
    final s3 = s_ * s_ * s_;

    final x = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
    final y = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
    final z = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

    double fromLinear(double v) =>
        v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1.0 / 2.4).toDouble() - 0.055;

    final r = (fromLinear(3.2404542 * x - 1.5371385 * y - 0.4985314 * z) * 255).clamp(0.0, 255.0).round();
    final g = (fromLinear(-0.9692660 * x + 1.8760108 * y + 0.0415560 * z) * 255).clamp(0.0, 255.0).round();
    final bVal = (fromLinear(0.0556434 * x - 0.2040259 * y + 1.0572252 * z) * 255).clamp(0.0, 255.0).round();

    return Color.fromARGB(255, r, g, bVal);
  }
}

/// Scrim Easing Cúbico com 9 paradas Hermite Smoothstep.
/// Elimina descontinuidades na primeira derivada da opacidade, acabando com faixas pretas nítidas (Mach bands).
class CubicScrimGradient {
  CubicScrimGradient._();

  static LinearGradient create({
    required Color baseColor,
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    const stops = [0.00, 0.15, 0.30, 0.45, 0.60, 0.72, 0.84, 0.93, 1.00];
    const opacities = [0.00, 0.018, 0.082, 0.215, 0.440, 0.660, 0.845, 0.950, 1.00];

    return LinearGradient(
      begin: begin,
      end: end,
      stops: stops,
      colors: opacities.map((alpha) => baseColor.withOpacity(alpha)).toList(),
    );
  }
}

/// Halo de Luz Dinâmico sob a arte Hero, suave e cinematográfico.
class DynamicAmbientHalo extends StatelessWidget {
  const DynamicAmbientHalo({
    super.key,
    required this.ambientColor,
    required this.child,
    this.haloHeight = 420.0,
  });

  final Color ambientColor;
  final Widget child;
  final double haloHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: haloHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.4),
                  radius: 1.15,
                  colors: [
                    ambientColor.withOpacity(0.35),
                    ambientColor.withOpacity(0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Tipografia Cinematográfica Heisuca: Sora + Inter.
/// Todos os números de tempo e contadores usam [tabularFigures] para eliminar o "layout jitter".
abstract final class HeisucaTypography {
  static const fontBrand = 'Sora';
  static const fontInterface = 'Inter';
  static const fontKanji = 'Shippori Mincho';

  static const displayCinematic = TextStyle(
    fontFamily: fontBrand,
    fontWeight: FontWeight.w700,
    fontSize: 34.0,
    height: 1.15,
    letterSpacing: -0.85,
    color: Color(0xFFF4F1FA),
  );

  static const titleHero = TextStyle(
    fontFamily: fontBrand,
    fontWeight: FontWeight.w600,
    fontSize: 24.0,
    height: 1.20,
    letterSpacing: -0.36,
    color: Color(0xFFF4F1FA),
  );

  static const titleSection = TextStyle(
    fontFamily: fontBrand,
    fontWeight: FontWeight.w500,
    fontSize: 18.0,
    height: 1.25,
    letterSpacing: -0.18,
    color: Color(0xFFF4F1FA),
  );

  static const bodySynopsis = TextStyle(
    fontFamily: fontInterface,
    fontWeight: FontWeight.w400,
    fontSize: 15.0,
    height: 1.50,
    letterSpacing: 0.0,
    color: Color(0xFFA99FBB),
  );

  static const bodyMetadata = TextStyle(
    fontFamily: fontInterface,
    fontWeight: FontWeight.w500,
    fontSize: 13.0,
    height: 1.35,
    letterSpacing: 0.13,
    color: Color(0xFFA99FBB),
  );

  static const labelBadge = TextStyle(
    fontFamily: fontInterface,
    fontWeight: FontWeight.w600,
    fontSize: 10.5,
    height: 1.20,
    letterSpacing: 0.74,
    color: Color(0xFFFFFFFF),
  );

  /// Estilo numérico tabular à prova de layout jitter.
  static const tabularTimestamp = TextStyle(
    fontFamily: fontInterface,
    fontWeight: FontWeight.w500,
    fontSize: 12.5,
    height: 1.0,
    letterSpacing: 0.0,
    fontFeatures: [
      ui.FontFeature.tabularFigures(),
    ],
    color: Color(0xFFF4F1FA),
  );
}

/// Badge Técnico Nobre e Monocromático (4K UHD, HDR10+, DOLBY VISION, DOLBY ATMOS).
/// Substitui caixas berrantes por micro-vidro chanfrado de alta sofisticação.
class HeisucaNobleBadge extends StatelessWidget {
  const HeisucaNobleBadge({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18.0,
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: HeisucaTypography.fontInterface,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.74,
          color: Color(0xFFF4F1FA),
        ),
      ),
    );
  }
}

/// Física de Rolagem Orgânica (Estilo iOS ProMotion).
/// Calibrada para 120Hz/144Hz com mola criticamente amortecida (mass: 1.0, stiffness: 115.0, damping: 18.5)
/// e limiar de arranque imediato para painéis LTPO de alta taxa de atualização.
class ProMotionScrollPhysics extends BouncingScrollPhysics {
  const ProMotionScrollPhysics({
    super.parent,
    super.decelerationRate = ScrollDecelerationRate.normal,
  });

  @override
  ProMotionScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ProMotionScrollPhysics(
      parent: buildParent(ancestor),
      decelerationRate: decelerationRate,
    );
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 1.0,
        stiffness: 115.0,
        damping: 18.5,
      );

  @override
  double get minFlingVelocity => 50.0;

  @override
  double get maxFlingVelocity => 9000.0;

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

/// ScrollBehavior global do Heisuca: ativa ProMotionScrollPhysics em todas as listas a 120Hz/144Hz.
class HeisucaScrollBehavior extends MaterialScrollBehavior {
  const HeisucaScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ProMotionScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

/// Wrapper de física de mola tátil para Cartões de Pôster, 16:9 e Top 10 (120Hz Spring Micro-interaction).
class HeisucaSpringPressable extends StatefulWidget {
  const HeisucaSpringPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.pressedScale = 0.955,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double pressedScale;

  @override
  State<HeisucaSpringPressable> createState() => _HeisucaSpringPressableState();
}

class _HeisucaSpringPressableState extends State<HeisucaSpringPressable> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v || !mounted) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onSecondaryTap: widget.onSecondaryTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: _pressed ? const Duration(milliseconds: 110) : const Duration(milliseconds: 340),
        curve: _pressed ? Curves.easeOutCubic : const ElasticOutCurve(0.85),
        child: widget.child,
      ),
    );
  }
}
