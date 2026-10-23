import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cgflix/cgflix_palette.dart';
import 'heisuca_theme.dart';

/// Renderizador oficial da marca Heisuca (炳素華)
/// Adapta-se automaticamente ao tema ativo (Shikkoku / Hisui)
class HeisucaLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool comSlogan;
  final bool apenasSelo;
  final bool siteHeader;

  const HeisucaLogo({
    super.key,
    this.width,
    this.height = 36,
    this.comSlogan = false,
    this.apenasSelo = false,
    this.siteHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final isLight = palette.isLight;
    final h = height ?? 36.0;

    if (siteHeader) {
      return SvgPicture.asset(
        isLight ? 'assets/heisuca/marca_site_hisui.svg' : 'assets/heisuca/marca_site_shikkoku.svg',
        height: h,
      );
    }

    final seloAsset = isLight
        ? 'assets/heisuca/selo_pequeno_hisui.svg'
        : 'assets/heisuca/selo_pequeno_shikkoku.svg';

    final textColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final sloganColor = isLight ? const Color(0xFF047857) : Colors.white.withOpacity(0.60);

    final selo = ClipRRect(
      borderRadius: BorderRadius.circular(h * 0.22),
      child: SvgPicture.asset(
        seloAsset,
        width: h,
        height: h,
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
                fontSize: h * 0.48,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: textColor,
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
                  color: sloganColor,
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

