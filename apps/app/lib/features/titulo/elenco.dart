import 'package:flutter/material.dart';

import '../../design/componentes/cabecalho_de_fileira.dart';
import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import 'modelo.dart';

/// O elenco na página do título: fotos lado a lado, com o nome e o personagem embaixo.
///
/// Sem ninguém para mostrar, a seção inteira some.
class Elenco extends StatelessWidget {
  const Elenco({super.key, required this.pessoas, this.titulo = 'Elenco'});

  final List<PessoaDoTitulo> pessoas;
  final String titulo;

  /// Largura de cada pessoa; a foto é quadrada, desse lado.
  static const double largura = 88;

  @override
  Widget build(BuildContext context) {
    if (pessoas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Forma.espaco4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CabecalhoDeFileira(titulo: titulo),
          // A altura acompanha o tamanho da letra: rolagem em linha, e não uma lista de altura fixa.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (indice, pessoa) in pessoas.indexed) ...[
                  if (indice > 0) const SizedBox(width: Forma.espaco3),
                  _Pessoa(key: ValueKey('pessoa-${pessoa.chave}'), pessoa: pessoa),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pessoa extends StatelessWidget {
  const _Pessoa({super.key, required this.pessoa});

  final PessoaDoTitulo pessoa;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final forma = Forma.superelipse(Forma.raioMedio);
    final papel = pessoa.papel?.trim() ?? '';
    const lado = Size.square(Elenco.largura);
    return SizedBox(
      width: Elenco.largura,
      child: Toque(
        forma: forma,
        rotulo: pessoa.rotulo,
        excluirSemantica: true,
        aoTocar: pessoa.aoTocar,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.fromSize(
              size: lado,
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: forma),
                child: ColoredBox(
                  color: tema.superficie2,
                  child: pessoa.foto?.call(context, lado) ?? _Inicial(nome: pessoa.nome),
                ),
              ),
            ),
            const SizedBox(height: Forma.espaco2),
            Text(
              pessoa.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Tipo.legenda(tema).copyWith(color: tema.texto, fontWeight: FontWeight.w600),
            ),
            if (papel.isNotEmpty)
              Text(
                papel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Tipo.legenda(tema).copyWith(color: tema.texto2),
              ),
          ],
        ),
      ),
    );
  }
}

/// O lugar da foto quando ela não existe: a inicial do nome.
class _Inicial extends StatelessWidget {
  const _Inicial({required this.nome});

  final String nome;

  @override
  Widget build(BuildContext context) {
    final limpo = nome.trim();
    if (limpo.isEmpty) return const SizedBox.expand();
    final tema = TemaHeisuca.de(context);
    return Center(
      child: Text(
        limpo.characters.first.toUpperCase(),
        textScaler: TextScaler.noScaling,
        style: Tipo.titulo(tema).copyWith(color: tema.texto2),
      ),
    );
  }
}
