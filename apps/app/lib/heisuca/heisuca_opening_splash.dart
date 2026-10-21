import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'heisuca_design_system.dart';
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

class _HeisucaOpeningSplashState extends State<HeisucaOpeningSplash>
    with SingleTickerProviderStateMixin {
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

    _controller.forward().then((_) {
      HapticFeedback.lightImpact();
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
    const bgDark = Color(0xFF0E0B16);
    const accentPurple = Color(0xFF9D74FF);

    return Scaffold(
      backgroundColor: bgDark,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // 1. Halo Radial Luminoso Dinâmico
              Opacity(
                opacity: _haloFade.value * 0.45,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        accentPurple.withOpacity(0.40),
                        const Color(0xFF7444E0).withOpacity(0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.50, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Selo Kanji Tradicional (炳素華)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _sealScale.value,
                    child: Container(
                      width: 88.0,
                      height: 120.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7444E0).withOpacity(0.40 * _sealScale.value),
                            blurRadius: 28.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22.0),
                        child: SvgPicture.asset(
                          'assets/heisuca/selo_pequeno_shikkoku.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28.0),

                  // 3. Marca Nominal HEISUCA
                  Opacity(
                    opacity: _textFade.value,
                    child: Transform.translate(
                      offset: Offset(0, 10.0 * (1.0 - _textFade.value)),
                      child: const Text(
                        'HEISUCA',
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTitulo,
                          fontSize: 28.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4.5,
                          color: Color(0xFFF4F1FA),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10.0),

                  // 4. Slogan Cinematográfico
                  Opacity(
                    opacity: _sloganFade.value,
                    child: Text(
                      'Nada entre você e o filme.',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.4,
                        color: const Color(0xFFA99FBB).withOpacity(0.85),
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
