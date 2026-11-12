import 'package:flutter/material.dart';

import '../forma.dart';
import '../tema.dart';
import '../tipo.dart';
import 'botao.dart';
import 'toque.dart';

/// A pílula do topo: o avatar e o nome de quem está usando o app. Abre "Você".
///
/// Fica no canto de cima das telas, sobre a arte ou sobre o fundo. Sem avatar, mostra a inicial do nome.
/// O nome longo é cortado com reticências; a letra grande faz a pílula crescer, sem cortar a altura.
class PilulaDePerfil extends StatelessWidget {
  const PilulaDePerfil({
    super.key,
    required this.nome,
    required this.aoTocar,
    this.avatar,
    this.sobreArte = false,
    this.soAvatar = false,
  });

  /// Nome mostrado ao lado do avatar. Vazio, a pílula mostra só o avatar.
  final String nome;

  /// Só o avatar, sem o nome ao lado (o lugar é pouco). O leitor de tela continua dizendo o nome.
  final bool soAvatar;

  /// O avatar, já do tamanho [tamanhoDoAvatar]. A pílula recorta em círculo.
  final Widget? avatar;
  final VoidCallback? aoTocar;

  /// Sobre a arte, a pílula fica translúcida como o [BotaoDeIcone].
  final bool sobreArte;

  /// Altura mínima: a área de toque.
  static const double altura = Forma.toqueMinimo;

  static const double tamanhoDoAvatar = 36;

  /// Largura máxima da pílula; o nome que não couber ganha reticências.
  static const double larguraMaxima = 200;

  /// Como o leitor de tela anuncia a pílula de um nome.
  static String rotuloDe(String nome) {
    final limpo = nome.trim();
    return limpo.isEmpty ? 'Você' : 'Você, $limpo';
  }

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final limpo = nome.trim();
    final comNome = limpo.isNotEmpty && !soAvatar;
    const folga = (altura - tamanhoDoAvatar) / 2;
    return Toque(
      forma: Forma.pilula(),
      rotulo: rotuloDe(nome),
      excluirSemantica: true,
      aoTocar: aoTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: altura, minWidth: altura, maxWidth: larguraMaxima),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: tema.superficie.withValues(alpha: sobreArte ? BotaoDeIcone.opacidadeSobreArte : 1),
            shape: Forma.pilula(),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(folga, folga, comNome ? Forma.espaco3 : folga, folga),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: tamanhoDoAvatar,
                  child: ClipOval(child: avatar ?? _Inicial(nome: limpo)),
                ),
                if (comNome) ...[
                  const SizedBox(width: Forma.espaco2),
                  Flexible(
                    child: Text(
                      limpo,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: Tipo.texto(tema).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O lugar do avatar quando não há foto: a inicial do nome, ou o ícone de pessoa.
class _Inicial extends StatelessWidget {
  const _Inicial({required this.nome});

  final String nome;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return ColoredBox(
      color: tema.acentoSuave,
      child: Center(
        child: nome.isEmpty
            ? Icon(Icons.person_rounded, size: Forma.espaco6, color: tema.texto)
            : Text(
                nome.characters.first.toUpperCase(),
                textScaler: TextScaler.noScaling,
                style: Tipo.texto(tema).copyWith(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
