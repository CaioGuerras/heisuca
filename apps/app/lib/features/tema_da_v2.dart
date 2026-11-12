import 'package:flutter/material.dart';

import '../cgflix/cgflix_palette.dart';
import '../design/tema.dart';

/// O tema da V2 que corresponde à paleta do app.
///
/// O kids usa o claro ou o escuro, conforme o brilho, com o acento do Ichigo ou do Sorairo.
TemaHeisuca temaDaPaleta(CgflixPalette paleta) => switch (paleta.variant) {
  CgflixThemeVariant.sumi => TemaHeisuca.sumi,
  CgflixThemeVariant.ichigo => paleta.isLight ? TemaHeisuca.ichigo : TemaHeisuca.ichigoNoite,
  CgflixThemeVariant.sorairo => paleta.isLight ? TemaHeisuca.sorairo : TemaHeisuca.sorairoNoite,
  _ => paleta.isLight ? TemaHeisuca.hisui : TemaHeisuca.shikkoku,
};

/// O tema Material da V2, guardando as extensões que as folhas e os menus atuais ainda leem.
ThemeData temaDaV2(ThemeData atual, TemaHeisuca tema) => tema.paraMaterial().copyWith(
  extensions: [...atual.extensions.values.where((extensao) => extensao is! TemaHeisuca), tema],
);

/// Põe [child] sob o tema da V2, a partir do tema escolhido no app.
///
/// Enquanto as telas atuais convivem com as da V2, cada pedaço novo entra por aqui.
class SobOTemaDaV2 extends StatelessWidget {
  const SobOTemaDaV2({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Theme(data: temaDaV2(Theme.of(context), temaDaPaleta(context.cgflix)), child: child);
}
