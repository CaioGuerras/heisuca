import 'package:flutter/material.dart';

import '../../design/componentes/cabecalho_de_fileira.dart';
import '../../design/componentes/pilula_de_escolha.dart';
import '../../design/forma.dart';
import 'modelo.dart';

/// Os gêneros do título, em pílulas que quebram de linha. Sem gênero, a seção some.
class Generos extends StatelessWidget {
  const Generos({super.key, required this.generos, this.titulo = 'Gêneros'});

  final List<GeneroDoTitulo> generos;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    if (generos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Forma.espaco4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CabecalhoDeFileira(titulo: titulo),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
            child: Wrap(
              spacing: Forma.espaco2,
              children: [for (final genero in generos) PilulaDeEscolha(texto: genero.nome, aoTocar: genero.aoTocar)],
            ),
          ),
        ],
      ),
    );
  }
}
