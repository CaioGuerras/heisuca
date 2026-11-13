import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/cor_poster/cor_poster_cache.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../fundo_tingido.dart';
import '../inicio/fileira.dart';
import '../inicio/modelo.dart';
import '../veu_do_topo.dart';

/// A tela Minha lista da V2: os favoritos em fileiras por tipo, sobre o fundo tingido pelo primeiro pôster.
///
/// Não conhece servidor: recebe as fileiras prontas. Fileira sem cartão não aparece.
class TelaMinhaLista extends StatelessWidget {
  const TelaMinhaLista({
    super.key,
    required this.fileiras,
    this.carregando = false,
    this.aviso,
    this.aoBuscar,
    this.perfil,
    this.aoAtualizar,
    this.controle,
    this.cores,
    this.folgaInferior = 96,
  });

  /// As fileiras, de cima para baixo (Séries, Filmes, Animes).
  final List<FileiraDoInicio> fileiras;

  /// A lista ainda não chegou: mostra fileiras de espera no lugar.
  final bool carregando;

  /// O que aparece no lugar das fileiras: lista vazia, falha, fonte fora do ar.
  final Widget? aviso;

  final VoidCallback? aoBuscar;

  /// O que fica no canto de cima, do lado oposto à busca: a pílula de quem está usando o app.
  final Widget? perfil;

  /// Puxar para atualizar; sem isto o gesto não existe.
  final Future<void> Function()? aoAtualizar;

  final ScrollController? controle;

  /// De onde sai a cor do pôster; por padrão, o cache do app.
  final CorPosterCache? cores;

  /// Espaço no fim da lista para a barra flutuante não cobrir a última fileira.
  final double folgaInferior;

  /// Altura reservada no topo para a pílula do perfil e o botão de busca.
  static const double topo = 72;

  /// Quantas fileiras de espera aparecem enquanto a lista carrega.
  static const int fileirasDeEspera = 2;

  @override
  Widget build(BuildContext context) {
    final base = TemaHeisuca.de(context);
    final media = MediaQuery.of(context);
    final comCartoes = [
      for (final fileira in fileiras)
        if (fileira.itens.isNotEmpty) fileira,
    ];
    final hashes = [
      for (final fileira in comCartoes)
        for (final item in fileira.itens.take(1)) ?item.hash,
    ];
    final mostraEspera = carregando && comCartoes.isEmpty && aviso == null;

    final lista = CustomScrollView(
      controller: controle,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: media.padding.top + topo)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Forma.espaco4, 0, Forma.espaco4, Forma.espaco2),
            child: Semantics(
              header: true,
              child: Builder(builder: (context) => Text('Minha lista', style: Tipo.titulo(TemaHeisuca.de(context)))),
            ),
          ),
        ),
        if (aviso != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: Forma.espaco6),
              child: aviso,
            ),
          )
        else if (mostraEspera)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (var i = 0; i < fileirasDeEspera; i++) const FileiraCarregando()],
            ),
          )
        else
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final fileira in comCartoes) Fileira(key: ValueKey(fileira.chave), dados: fileira, cores: cores),
              ],
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: media.padding.bottom + folgaInferior)),
      ],
    );

    return FundoTingido(
      hash: hashes.firstOrNull,
      preparar: hashes,
      cores: cores,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (aoAtualizar == null)
            lista
          else
            // Dentro do fundo tingido: o indicador usa a superfície já com a cor do pôster.
            Builder(
              builder: (context) => RefreshIndicator(
                color: base.texto,
                backgroundColor: TemaHeisuca.de(context).superficie2,
                edgeOffset: media.padding.top + Forma.espaco2,
                onRefresh: aoAtualizar!,
                child: lista,
              ),
            ),
          const VeuDoTopo(),
          if (perfil != null)
            PositionedDirectional(
              top: media.padding.top + Forma.espaco2,
              start: Forma.espaco4,
              // A busca fica do outro lado: a pílula não passa por baixo dela.
              end: Forma.espaco4 + Forma.toqueMinimo + Forma.espaco2,
              child: Align(alignment: AlignmentDirectional.centerStart, child: perfil),
            ),
          if (aoBuscar != null)
            PositionedDirectional(
              top: media.padding.top + Forma.espaco2,
              end: Forma.espaco4,
              child: BotaoDeIcone(icone: Symbols.search_rounded, rotulo: 'Buscar', sobreArte: true, aoTocar: aoBuscar),
            ),
        ],
      ),
    );
  }
}
