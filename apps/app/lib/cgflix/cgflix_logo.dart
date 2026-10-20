// Emblema CGFLIX ("C com play") usado nas telas de marca (splash do Flutter,
// entrada, Sobre). Arquivo próprio para os arquivos do upstream só chamarem daqui.
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'cgflix_palette.dart';

/// Emblema do app. O SVG é o de `cgflix-brand/` (ou `cgflix-brand/heitor/` no tema Heitor)
/// sem o filtro de brilho (o flutter_svg não renderiza filtros).
class CgflixEmblem extends StatelessWidget {
  final double size;

  const CgflixEmblem({super.key, required this.size});

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(context.cgflix.emblemAsset, width: size, height: size, semanticsLabel: 'CGFLIX');
}
