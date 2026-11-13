import 'package:flutter/material.dart';

import '../../heisuca/theme/heisuca_base.dart';
import '../forma.dart';
import '../tema.dart';
import '../tipo.dart';
import '../vibracao.dart';
import 'toque.dart';

/// Os três pesos de um botão com texto.
enum TipoDeBotao {
  /// A ação da tela ("Assistir"): neutro, nunca da cor do acento.
  principal,

  /// Ação ao lado da principal ("Trailer", "Minha lista").
  secundario,

  /// Ação discreta, sem fundo ("Ver tudo").
  discreto,
}

/// Botão em pílula da V2.
class Botao extends StatelessWidget {
  const Botao({
    super.key,
    required this.rotulo,
    required this.aoTocar,
    this.icone,
    this.tipo = TipoDeBotao.principal,
    this.expandido = false,
    this.vibracao,
  });

  final String rotulo;

  /// `null` deixa o botão inativo.
  final VoidCallback? aoTocar;

  /// Use um ícone de `Symbols`: o preenchimento só existe nessa família.
  final IconData? icone;
  final TipoDeBotao tipo;

  /// Ocupa toda a largura disponível.
  final bool expandido;
  final Vibracao? vibracao;

  static const double altura = Forma.toqueMinimo;
  static const double _icone = 22;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final (fundo, tinta) = switch (tipo) {
      TipoDeBotao.principal => (tema.botaoFundo, tema.botaoTexto),
      TipoDeBotao.secundario => (tema.superficie2, tema.texto),
      TipoDeBotao.discreto => (tema.fundo.withValues(alpha: 0), tema.texto),
    };
    final forma = Forma.pilula();
    final texto = Tipo.texto(tema).copyWith(color: tinta, fontWeight: FontWeight.w600, height: 1.2);
    final icone = this.icone;

    return Toque(
      forma: forma,
      aoTocar: aoTocar,
      vibracao: vibracao,
      child: Container(
        constraints: const BoxConstraints(minHeight: altura, minWidth: altura),
        width: expandido ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: tipo == TipoDeBotao.discreto ? Forma.espaco3 : Forma.espaco6),
        decoration: ShapeDecoration(color: fundo, shape: forma),
        child: Row(
          mainAxisSize: expandido ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icone != null) ...[
              Icon(icone, size: _icone, color: tinta, fill: 1),
              const SizedBox(width: Forma.espaco2),
            ],
            Flexible(
              child: Text(rotulo, style: texto, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão redondo só com ícone (busca, voltar, mais). O [rotulo] é o que o leitor de tela diz.
class BotaoDeIcone extends StatelessWidget {
  const BotaoDeIcone({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.aoTocar,
    this.sobreArte = false,
    this.selecionado,
    this.vibracao,
  });

  /// Use um ícone de `Symbols`: o preenchimento que marca o selecionado só existe nessa família.
  final IconData icone;
  final String rotulo;
  final VoidCallback? aoTocar;

  /// Para botão de liga e desliga (na lista, visto): ligado, o ícone fica cheio. `null` para um botão comum.
  final bool? selecionado;

  /// Fica sobre a arte do título: fundo translúcido, para a arte aparecer por baixo.
  final bool sobreArte;
  final Vibracao? vibracao;

  static const double tamanho = Forma.toqueMinimo;

  /// Opacidade do fundo quando o botão fica sobre a arte.
  static const double opacidadeSobreArte = 0.72;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    const forma = CircleBorder();
    return Tooltip(
      message: rotulo,
      excludeFromSemantics: true,
      child: Toque(
        forma: forma,
        rotulo: rotulo,
        excluirSemantica: true,
        selecionado: selecionado,
        aoTocar: aoTocar,
        vibracao: vibracao,
        escala: 0.92,
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: ShapeDecoration(
            color: tema.superficie.withValues(alpha: sobreArte ? opacidadeSobreArte : 1),
            shape: forma,
          ),
          child: Icon(icone, size: HeisucaBase.espaco6, fill: selecionado == true ? 1 : 0, color: tema.texto),
        ),
      ),
    );
  }
}
