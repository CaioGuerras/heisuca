import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../design/vibracao.dart';
import '../fundo_tingido.dart';
import '../veu_do_topo.dart';

/// Uma linha da tela Você: ícone, nome, uma frase de apoio e o que o toque faz.
class ItemDaVoce {
  const ItemDaVoce({
    required this.chave,
    required this.icone,
    required this.titulo,
    required this.aoTocar,
    this.subtitulo,
    this.perigoso = false,
  });

  /// Identifica o item (testes e semântica); não aparece na tela.
  final String chave;
  final IconData icone;
  final String titulo;
  final String? subtitulo;

  /// Sair e afins: o texto e o ícone ficam na cor de erro do tema.
  final bool perigoso;
  final VoidCallback? aoTocar;
}

/// A tela Você da V2: quem está usando o app e, abaixo, os cartões da conta, do app e da saída.
///
/// Não conhece servidor nem perfis: recebe o cabeçalho e os grupos prontos. Cada grupo é uma
/// sequência de cartões; entre um grupo e outro o espaço é maior.
class TelaVoce extends StatelessWidget {
  const TelaVoce({
    super.key,
    required this.nome,
    required this.grupos,
    this.avatar,
    this.aoVoltar,
    this.folgaInferior = Forma.espaco6,
  });

  /// Nome de quem usa o app, no cabeçalho.
  final String nome;

  /// A foto de quem usa o app; sem ela, o cabeçalho mostra só o nome.
  final Widget? avatar;

  /// Os grupos de cartões, de cima para baixo. Grupo vazio não aparece.
  final List<List<ItemDaVoce>> grupos;

  /// Voltar para a tela de onde a Você foi aberta; sem isto o botão não aparece.
  final VoidCallback? aoVoltar;

  /// Espaço no fim da lista.
  final double folgaInferior;

  /// Altura reservada no topo para o botão de voltar.
  static const double topo = Forma.toqueMinimo + Forma.espaco6;

  /// Lado da foto no cabeçalho.
  static const double ladoDoAvatar = Forma.toqueMinimo + Forma.espaco4;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final comItens = [
      for (final grupo in grupos)
        if (grupo.isNotEmpty) grupo,
    ];

    final lista = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: media.padding.top + topo)),
        SliverToBoxAdapter(
          child: _Cabecalho(nome: nome, avatar: avatar),
        ),
        for (final grupo in comItens)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Forma.espaco4, Forma.espaco4, Forma.espaco4, 0),
            sliver: SliverList.separated(
              itemCount: grupo.length,
              separatorBuilder: (_, _) => const SizedBox(height: Forma.espaco2),
              itemBuilder: (_, i) => _CartaoDaVoce(item: grupo[i]),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: media.padding.bottom + folgaInferior)),
      ],
    );

    return FundoTingido(
      hash: null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          lista,
          const VeuDoTopo(),
          if (aoVoltar != null)
            PositionedDirectional(
              top: media.padding.top + Forma.espaco2,
              start: Forma.espaco4,
              child: BotaoDeIcone(icone: Symbols.arrow_back_rounded, rotulo: 'Voltar', aoTocar: aoVoltar!),
            ),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.nome, this.avatar});

  final String nome;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
      child: Row(
        children: [
          if (avatar != null) ...[
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: TelaVoce.ladoDoAvatar,
                child: ClipOval(child: avatar),
              ),
            ),
            const SizedBox(width: Forma.espaco4),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                nome.isEmpty ? 'Você' : nome,
                style: Tipo.titulo(tema),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoDaVoce extends StatelessWidget {
  const _CartaoDaVoce({required this.item});

  final ItemDaVoce item;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final forma = Forma.superelipse(Forma.raioMedio);
    final corDoTitulo = item.perigoso ? tema.erro : tema.texto;
    final rotulo = [item.titulo, ?item.subtitulo].join(', ');

    return Toque(
      forma: forma,
      rotulo: rotulo,
      excluirSemantica: true,
      aoTocar: item.aoTocar,
      vibracao: item.perigoso ? Vibracao.confirmar : null,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: tema.superficie, shape: forma),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Forma.toqueMinimo),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4, vertical: Forma.espaco3),
            child: Row(
              children: [
                Icon(item.icone, color: item.perigoso ? tema.erro : tema.acento),
                const SizedBox(width: Forma.espaco4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.titulo,
                        style: Tipo.texto(tema).copyWith(color: corDoTitulo, fontWeight: FontWeight.w600),
                      ),
                      if (item.subtitulo != null) Text(item.subtitulo!, style: Tipo.legenda(tema)),
                    ],
                  ),
                ),
                if (!item.perigoso) Icon(Symbols.chevron_right_rounded, color: tema.texto2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
