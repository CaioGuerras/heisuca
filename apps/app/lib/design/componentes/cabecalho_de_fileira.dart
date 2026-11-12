import 'package:flutter/material.dart';

import '../forma.dart';
import '../tema.dart';
import '../tipo.dart';
import 'toque.dart';

/// Título de uma fileira, com "Ver tudo" à direita quando há para onde ir.
class CabecalhoDeFileira extends StatelessWidget {
  const CabecalhoDeFileira({
    super.key,
    required this.titulo,
    this.aoVerTudo,
    this.iconeDeVerTudo,
    this.aoTocarTitulo,
    this.iconeDoTitulo,
    this.rotuloDoTitulo,
  });

  final String titulo;

  /// O título vira um seletor (a temporada, por exemplo): o toque abre a escolha.
  final VoidCallback? aoTocarTitulo;

  /// Seta ao lado do título quando ele é um seletor.
  final IconData? iconeDoTitulo;

  /// Como o leitor de tela anuncia o seletor; por padrão, o próprio título.
  final String? rotuloDoTitulo;

  /// Sem destino, o "Ver tudo" não aparece.
  final VoidCallback? aoVerTudo;

  /// Seta ao lado do "Ver tudo". Quem chama escolhe o ícone (a Fundação não fixa ícones).
  final IconData? iconeDeVerTudo;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Forma.toqueMinimo),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: Forma.espaco4, end: Forma.espaco2),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: aoTocarTitulo == null
                    ? Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tipo.subtitulo(tema))
                    : Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Toque(
                          forma: Forma.pilula(),
                          rotulo: rotuloDoTitulo ?? titulo,
                          excluirSemantica: true,
                          aoTocar: aoTocarTitulo,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: Forma.toqueMinimo),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Tipo.subtitulo(tema),
                                  ),
                                ),
                                if (iconeDoTitulo != null) Icon(iconeDoTitulo, size: 24, color: tema.texto2),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (aoVerTudo != null)
              Toque(
                forma: Forma.pilula(),
                rotulo: 'Ver tudo de $titulo',
                excluirSemantica: true,
                aoTocar: aoVerTudo,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: Forma.toqueMinimo, minWidth: Forma.toqueMinimo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Forma.espaco2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ver tudo', style: Tipo.pequeno(tema).copyWith(fontWeight: FontWeight.w600)),
                        if (iconeDeVerTudo != null) Icon(iconeDeVerTudo, size: 18, color: tema.texto2),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
