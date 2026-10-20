import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renderizador oficial da marca Heisuca (炳素華)
class HeisucaLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool comSlogan;

  const HeisucaLogo({
    super.key,
    this.width,
    this.height = 42,
    this.comSlogan = false,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/heisuca/abertura.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
