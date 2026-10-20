import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'heisuca_theme.dart';

/// Renderizador oficial da marca Heisuca (炳素華)
class HeisucaLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool comSlogan;
  final bool apenasSelo;

  const HeisucaLogo({
    super.key,
    this.width,
    this.height = 36,
    this.comSlogan = false,
    this.apenasSelo = false,
  });

  @override
  Widget build(BuildContext context) {
    final selo = ClipRRect(
      borderRadius: BorderRadius.circular((height ?? 36) * 0.22),
      child: SvgPicture.asset(
        'assets/heisuca/selo_pequeno_shikkoku.svg',
        width: height,
        height: height,
        fit: BoxFit.contain,
      ),
    );

    if (apenasSelo) return selo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        selo,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HEISUCA',
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTitulo,
                fontSize: (height ?? 36) * 0.48,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: const Color(0xFFF4F1FA),
              ),
            ),
            if (comSlogan) ...[
              const SizedBox(height: 1),
              Text(
                'Nada entre você e o filme.',
                style: TextStyle(
                  fontFamily: HeisucaTheme.fonteTexto,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.60),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
