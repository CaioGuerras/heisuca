import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cgflix/cgflix_palette.dart';
import 'heisuca_theme.dart';
import 'heisuca_brand_colors.dart';

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

    if (apenasSelo) {
      return SvgPicture.asset(
        palette.emblemAsset,
        colorMapper: HeisucaBrandColors(palette),
        width: width ?? h,
        height: h,
        fit: BoxFit.contain,
        semanticsLabel: 'Heisuca',
      );
    }
    final brand = SvgPicture.asset(
      isLight ? 'assets/heisuca/marca_site_hisui.svg' : 'assets/heisuca/marca_site_shikkoku.svg',
      width: width,
      height: h,
      fit: BoxFit.contain,
      colorMapper: HeisucaBrandColors(palette),
      semanticsLabel: 'Heisuca',
    );
    if (siteHeader || !comSlogan) return brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        brand,
        const SizedBox(height: 8),
        Text('Nada entre você e o filme.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: HeisucaTheme.fonteTexto,
            fontSize: 10.5, fontWeight: FontWeight.w400,
            color: palette.textOn(palette.background, preferred: palette.textMuted))),
      ],
    );
  }
}
