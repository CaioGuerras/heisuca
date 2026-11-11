import 'package:flutter/material.dart';

import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';

/// Aviso de tela: um ícone, o que aconteceu, o que fazer e, se houver, as ações.
///
/// Serve à falha de carga e à fonte fora do ar. O leitor de tela lê o título e o texto
/// como uma frase só; as ações continuam separadas. Não rola sozinho: a tela que o usa é que rola.
class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.icone, required this.titulo, this.texto, this.acoes = const []});

  final IconData icone;
  final String titulo;
  final String? texto;

  /// Ações abaixo do texto (botões, o seletor de fonte), de cima para baixo.
  final List<Widget> acoes;

  /// Tamanho do ícone do aviso.
  static const double tamanhoDoIcone = 48;

  /// Largura máxima do aviso em tela larga.
  static const double larguraMaxima = 420;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: larguraMaxima),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Forma.espaco6, vertical: Forma.espaco4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(icone, size: tamanhoDoIcone, color: tema.texto2),
              ),
              const SizedBox(height: Forma.espaco3),
              MergeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(titulo, textAlign: TextAlign.center, style: Tipo.subtitulo(tema)),
                    if (texto != null) ...[
                      const SizedBox(height: Forma.espaco1),
                      Text(texto!, textAlign: TextAlign.center, style: Tipo.pequeno(tema)),
                    ],
                  ],
                ),
              ),
              for (final acao in acoes) ...[const SizedBox(height: Forma.espaco4), acao],
            ],
          ),
        ),
      ),
    );
  }
}
