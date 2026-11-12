import 'package:flutter/material.dart';

import '../../design/componentes/cabecalho_de_fileira.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import 'modelo.dart';

/// Os dados técnicos da mídia, um cartão por grupo ("Vídeo", "Áudio"), lado a lado.
///
/// Grupo sem linha não aparece; sem nenhum grupo, a seção some.
class InfoDaMidia extends StatelessWidget {
  const InfoDaMidia({super.key, required this.grupos, this.titulo = 'Sobre a mídia'});

  final List<GrupoDeInfo> grupos;
  final String titulo;

  /// Largura de cada cartão: o segundo aparece pela metade e mostra que a fileira rola.
  static const double larguraDoCartao = 232;

  @override
  Widget build(BuildContext context) {
    final comLinhas = [
      for (final grupo in grupos)
        if (grupo.linhas.isNotEmpty) grupo,
    ];
    if (comLinhas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Forma.espaco4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CabecalhoDeFileira(titulo: titulo),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
            // Os cartões ficam da altura do mais alto.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (indice, grupo) in comLinhas.indexed) ...[
                    if (indice > 0) const SizedBox(width: Forma.espaco3),
                    _Grupo(grupo: grupo),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.grupo});

  final GrupoDeInfo grupo;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return SizedBox(
      width: InfoDaMidia.larguraDoCartao,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: tema.superficie, shape: Forma.superelipse(Forma.raioMedio)),
        child: Padding(
          padding: const EdgeInsets.all(Forma.espaco4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (grupo.icone != null) ...[
                    Icon(grupo.icone, size: Forma.espaco6, color: tema.texto),
                    const SizedBox(width: Forma.espaco2),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        grupo.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tipo.texto(tema).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Forma.espaco2),
              for (final (nome, valor) in grupo.linhas)
                Padding(
                  padding: const EdgeInsets.only(top: Forma.espaco1),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$nome: ',
                          style: TextStyle(color: tema.texto2),
                        ),
                        TextSpan(text: valor),
                      ],
                    ),
                    style: Tipo.pequeno(tema).copyWith(color: tema.texto),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
