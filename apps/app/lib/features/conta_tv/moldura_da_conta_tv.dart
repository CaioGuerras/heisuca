import 'package:flutter/material.dart';

import '../../cgflix/cgflix_palette.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../heisuca/theme/heisuca_base.dart';
import '../../heisuca/tv/heisuca_tv_area_segura.dart';
import '../../heisuca/tv/heisuca_tv_canvas.dart';
import '../navegacao_tv/trilho_da_tv.dart';
import '../tema_da_v2.dart';

/// Conta e Sobre usam a mesma margem, escala e tema escuro das outras telas da TV.
class MolduraDaContaTv extends StatelessWidget {
  const MolduraDaContaTv({super.key, required this.titulo, required this.conteudo});

  final String titulo;
  final WidgetBuilder conteudo;

  @override
  Widget build(BuildContext context) {
    final paleta = context.cgflix;
    final escura = switch (paleta.variant) {
      CgflixThemeVariant.sumi => CgflixPalette.sumi,
      CgflixThemeVariant.ichigo => CgflixPalette.ichigoNoite,
      CgflixThemeVariant.sorairo => CgflixPalette.sorairoNoite,
      _ => CgflixPalette.isis,
    };
    final tema = TrilhoDaTv.escuroDaTv(temaDaPaleta(escura));
    final atual = Theme.of(context);
    return HeisucaTvCanvas(
      child: Theme(
        data: temaDaV2(atual, tema).copyWith(
          extensions: [...atual.extensions.values.where((e) => e is! CgflixPalette && e is! TemaHeisuca), tema, escura],
        ),
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: tema.fundo,
            body: HeisucaTvAreaSegura(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(titulo, style: Tipo.destaque(tema).copyWith(fontSize: HeisucaBase.tamanhoTvTitulo)),
                  ),
                  const SizedBox(height: Forma.espaco6),
                  Expanded(
                    child: FocusTraversalGroup(
                      policy: ReadingOrderTraversalPolicy(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(HeisucaBase.espaco8),
                        child: conteudo(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
