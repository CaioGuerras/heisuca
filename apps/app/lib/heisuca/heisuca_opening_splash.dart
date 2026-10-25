import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cgflix/cgflix_palette.dart';
import 'heisuca_logo.dart';
import '../services/device_performance.dart';
import 'heisuca_theme.dart';

/// Tela de Abertura Única Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Animação cinematográfica em 144Hz com halo radial, selo carmim e caligrafia sumi-e.
class HeisucaOpeningSplash extends StatefulWidget {
  const HeisucaOpeningSplash({
    super.key,
    required this.onAnimationFinished,
    this.duration = const Duration(milliseconds: 2200),
  });

  final VoidCallback onAnimationFinished;
  final Duration duration;

  @override
  State<HeisucaOpeningSplash> createState() => _HeisucaOpeningSplashState();
}

class _HeisucaOpeningSplashState extends State<HeisucaOpeningSplash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _haloFade;
  late Animation<double> _sealScale;
  late Animation<double> _textFade;
  late Animation<double> _sloganFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _haloFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
    );

    _sealScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutBack),
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.80, curve: Curves.easeOutCubic),
    );

    _sloganFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
    );
  }

  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (DevicePerformance.isReduced || MediaQuery.disableAnimationsOf(context)) {
      _controller.duration = Duration.zero;
    }
    _controller.forward().then((_) {
      if (!mounted) return;
      if (!DevicePerformance.isReduced && !MediaQuery.disableAnimationsOf(context)) HapticFeedback.lightImpact();
      widget.onAnimationFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final isLight = palette.isLight;

    final bg = isLight ? const Color(0xFFF7F3EC) : const Color(0xFF0E0B16);
    final accent = isLight ? const Color(0xFF047857) : const Color(0xFF9D74FF);
    final glowColor = isLight ? const Color(0xFF059669) : const Color(0xFF7444E0);
    final sloganColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFCBC0DE);

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // 1. Halo Radial Luminoso Dinâmico
              Opacity(
                opacity: _haloFade.value * 0.12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [accent.withOpacity(0.40), glowColor.withOpacity(0.15), Colors.transparent],
                      stops: const [0.0, 0.50, 1.0],
                    ),
                  ),
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _sealScale.value,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: .10 * _sealScale.value.clamp(0, 1)),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Opacity(opacity: _textFade.value, child: const HeisucaLogo(height: 72, siteHeader: true)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Opacity(
                      opacity: _sloganFade.value,
                      child: Text(
                        'Nada entre você e o filme.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: .4,
                          color: sloganColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
