import 'package:flutter/material.dart';

import '../forma.dart';
import '../tema.dart';
import '../tipo.dart';
import 'toque.dart';

/// Uma pílula pequena de texto: a faixa de episódios ("1-10"), um gênero.
///
/// A pílula desenhada tem [altura]; a área de toque é sempre de 48.
/// Com [selecionado] preenchido ela é uma escolha (uma de várias) e o leitor de tela diz se está marcada.
class PilulaDeEscolha extends StatelessWidget {
  const PilulaDeEscolha({
    super.key,
    required this.texto,
    this.rotulo,
    this.selecionado,
    this.algarismos = false,
    this.aoTocar,
  });

  final String texto;

  /// Como o leitor de tela anuncia; por padrão, o próprio texto.
  final String? rotulo;

  /// `null` quando a pílula não é uma escolha (só leva a algum lugar).
  final bool? selecionado;

  /// Texto só de números: usa algarismos de largura igual.
  final bool algarismos;
  final VoidCallback? aoTocar;

  /// Altura da pílula desenhada.
  static const double altura = 36;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final marcada = selecionado ?? false;
    final base = algarismos ? Tipo.tempo(tema) : Tipo.pequeno(tema);
    return Toque(
      forma: Forma.pilula(),
      rotulo: rotulo ?? texto,
      selecionado: selecionado,
      excluirSemantica: true,
      aoTocar: aoTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Forma.toqueMinimo, minWidth: Forma.toqueMinimo),
        child: Center(
          widthFactor: 1,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: marcada ? tema.superficie2 : null,
              shape: Forma.pilula(lado: BorderSide(color: marcada ? tema.superficie2 : tema.borda)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: altura, minWidth: Forma.toqueMinimo),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Forma.espaco3),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: base.copyWith(color: marcada ? tema.texto : tema.texto2, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
