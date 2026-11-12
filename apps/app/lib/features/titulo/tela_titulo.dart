import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/cor_poster/cor_poster_cache.dart';
import '../../design/forma.dart';
import '../fundo_tingido.dart';
import '../veu_do_topo.dart';
import 'cabeca.dart';
import 'modelo.dart';

/// A página de um título na V2: a cabeça com a arte no topo, as seções embaixo e o fundo tingido pelo pôster.
///
/// Não conhece servidor nem player: recebe o título pronto e as seções já montadas.
class TelaTitulo extends StatelessWidget {
  const TelaTitulo({
    super.key,
    required this.pagina,
    this.secoes = const [],
    this.aoVoltar,
    this.aoAbrirMenu,
    this.controle,
    this.cores,
    this.folgaInferior = Forma.espaco6,
  });

  final PaginaDoTitulo pagina;

  /// As seções abaixo da cabeça, de cima para baixo (temporadas, elenco, parecidos, dados da mídia).
  final List<Widget> secoes;

  /// Por padrão, volta para a tela anterior.
  final VoidCallback? aoVoltar;

  /// Abre o menu do título ("⋯"); sem isto o botão não existe.
  final VoidCallback? aoAbrirMenu;

  final ScrollController? controle;

  /// De onde sai a cor do pôster; por padrão, o cache do app.
  final CorPosterCache? cores;

  /// Espaço no fim da lista, além da área do sistema.
  final double folgaInferior;

  /// Fração da altura da tela que a arte ocupa, e os limites em telas muito baixas ou altas.
  static const double fracaoDaArte = 0.6;
  static const double arteMinima = 320;
  static const double arteMaxima = 640;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final alturaDaArte = (media.size.height * fracaoDaArte).clamp(arteMinima, arteMaxima);
    final topo = media.padding.top + Forma.espaco2;

    return FundoTingido(
      hash: pagina.hash,
      cores: cores,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            controller: controle,
            slivers: [
              SliverToBoxAdapter(
                child: CabecaDoTitulo(pagina: pagina, alturaDaArte: alturaDaArte),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Forma.espaco4)),
              SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: secoes),
              ),
              SliverToBoxAdapter(child: SizedBox(height: media.padding.bottom + folgaInferior)),
            ],
          ),
          const VeuDoTopo(),
          PositionedDirectional(
            top: topo,
            start: Forma.espaco4,
            child: BotaoDeIcone(
              icone: Symbols.arrow_back_rounded,
              rotulo: 'Voltar',
              sobreArte: true,
              aoTocar: aoVoltar ?? () => Navigator.maybePop(context),
            ),
          ),
          if (aoAbrirMenu != null)
            PositionedDirectional(
              top: topo,
              end: Forma.espaco4,
              child: BotaoDeIcone(
                icone: Symbols.more_horiz_rounded,
                rotulo: 'Mais opções',
                sobreArte: true,
                aoTocar: aoAbrirMenu,
              ),
            ),
        ],
      ),
    );
  }
}
