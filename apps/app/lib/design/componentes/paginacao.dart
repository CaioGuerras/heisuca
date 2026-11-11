import 'package:flutter/material.dart';

import '../forma.dart';
import '../movimento.dart';
import '../tema.dart';

/// Pontos de paginação: o ponto da página atual é alongado.
///
/// É só indicador: não recebe toque (a página troca pelo dedo, no conteúdo). O leitor
/// de tela ouve uma frase só ("Destaque 2 de 8"), não um ponto por vez.
class Paginacao extends StatelessWidget {
  const Paginacao({super.key, required this.total, required this.atual, this.rotulo = 'Destaque'});

  /// Quantidade de páginas. Com uma ou nenhuma, o indicador não aparece.
  final int total;

  /// Índice da página atual, a partir de zero.
  final int atual;

  /// Nome do que está sendo paginado, para o leitor de tela.
  final String rotulo;

  static const double ponto = 6;
  static const double pontoAtivo = 18;
  static const double opacidadeInativa = 0.38;

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();
    final tema = TemaHeisuca.de(context);
    final ativo = atual.clamp(0, total - 1);
    return Semantics(
      container: true,
      label: '$rotulo ${ativo + 1} de $total',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                duration: Movimento.tempo(context, Movimento.troca),
                curve: Movimento.padrao,
                width: i == ativo ? pontoAtivo : ponto,
                height: ponto,
                margin: const EdgeInsets.symmetric(horizontal: Forma.espaco1 / 2),
                decoration: ShapeDecoration(
                  shape: Forma.pilula(),
                  color: i == ativo ? tema.texto : tema.texto.withValues(alpha: opacidadeInativa),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
