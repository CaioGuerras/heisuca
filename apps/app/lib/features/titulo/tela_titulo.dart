import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/cor_poster/cor_poster_cache.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../design/vibracao.dart';
import '../fundo_tingido.dart';
import '../veu_do_topo.dart';
import 'cabeca.dart';
import 'modelo.dart';

/// A página de um título na V2: a cabeça com a arte no topo, as seções embaixo e o fundo tingido pelo pôster.
///
/// Quando o botão de assistir sai de vista, o topo ganha uma barra com o nome e um "assistir" pequeno.
/// Não conhece servidor nem player: recebe o título pronto e as seções já montadas.
class TelaTitulo extends StatefulWidget {
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

  /// Altura da barra do topo, abaixo da área do sistema.
  static const double alturaDaBarra = Forma.toqueMinimo + 2 * Forma.espaco2;

  /// Marca a barra do topo enquanto ela está à vista.
  static const Key chaveDaBarra = ValueKey('barra-do-titulo');

  @override
  State<TelaTitulo> createState() => _TelaTituloState();
}

class _TelaTituloState extends State<TelaTitulo> {
  final _chaveDoAssistir = GlobalKey();
  final _rolagem = ValueNotifier<double>(0);
  final _grudado = ValueNotifier<bool>(false);
  ScrollController? _proprio;

  ScrollController get _controle => widget.controle ?? (_proprio ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _controle.addListener(_aoRolar);
  }

  @override
  void didUpdateWidget(TelaTitulo antiga) {
    super.didUpdateWidget(antiga);
    if (antiga.controle != widget.controle) {
      (antiga.controle ?? _proprio)?.removeListener(_aoRolar);
      _controle.addListener(_aoRolar);
    }
  }

  @override
  void dispose() {
    (widget.controle ?? _proprio)?.removeListener(_aoRolar);
    _proprio?.dispose();
    _rolagem.dispose();
    _grudado.dispose();
    super.dispose();
  }

  void _aoRolar() {
    final controle = _controle;
    if (!controle.hasClients) return;
    final rolado = controle.offset;
    _rolagem.value = rolado;

    final media = MediaQuery.of(context);
    final fimDaBarra = media.padding.top + TelaTitulo.alturaDaBarra;
    final botao = _chaveDoAssistir.currentContext?.findRenderObject();
    if (botao is RenderBox && botao.attached) {
      // Onde o botão fica na página não depende de quanto ela rolou: a conta vale antes do próximo quadro.
      final topoDoBotao = RenderAbstractViewport.of(botao).getOffsetToReveal(botao, 0).offset;
      // O botão passou inteiro para baixo da barra: ela assume.
      _grudado.value = rolado >= topoDoBotao + botao.size.height - fimDaBarra;
    } else {
      // Sem botão de assistir, a barra entra quando a arte acabou de passar.
      _grudado.value = rolado >= _alturaDaArte(media) - fimDaBarra;
    }
  }

  double _alturaDaArte(MediaQueryData media) =>
      (media.size.height * TelaTitulo.fracaoDaArte).clamp(TelaTitulo.arteMinima, TelaTitulo.arteMaxima);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final pagina = widget.pagina;
    final topo = media.padding.top + Forma.espaco2;

    return FundoTingido(
      hash: pagina.hash,
      cores: widget.cores,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            controller: _controle,
            slivers: [
              SliverToBoxAdapter(
                child: CabecaDoTitulo(
                  pagina: pagina,
                  alturaDaArte: _alturaDaArte(media),
                  chaveDoAssistir: _chaveDoAssistir,
                  rolagem: _rolagem,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Forma.espaco4)),
              SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.secoes),
              ),
              SliverToBoxAdapter(child: SizedBox(height: media.padding.bottom + widget.folgaInferior)),
            ],
          ),
          const VeuDoTopo(),
          ValueListenableBuilder<bool>(
            valueListenable: _grudado,
            builder: (context, grudado, _) =>
                _BarraDoTitulo(pagina: pagina, visivel: grudado, temMenu: widget.aoAbrirMenu != null),
          ),
          PositionedDirectional(
            top: topo,
            start: Forma.espaco4,
            child: BotaoDeIcone(
              icone: Symbols.arrow_back_rounded,
              rotulo: 'Voltar',
              sobreArte: true,
              aoTocar: widget.aoVoltar ?? () => Navigator.maybePop(context),
            ),
          ),
          if (widget.aoAbrirMenu != null)
            PositionedDirectional(
              top: topo,
              end: Forma.espaco4,
              child: BotaoDeIcone(
                icone: Symbols.more_horiz_rounded,
                rotulo: 'Mais opções',
                sobreArte: true,
                aoTocar: widget.aoAbrirMenu,
              ),
            ),
        ],
      ),
    );
  }
}

/// A barra que assume o topo depois que o botão de assistir rolou para fora: o nome e um "assistir" pequeno.
///
/// Os botões de voltar e de menu são os da tela, por cima dela; aqui só se guarda o lugar deles.
class _BarraDoTitulo extends StatelessWidget {
  const _BarraDoTitulo({required this.pagina, required this.visivel, required this.temMenu});

  final PaginaDoTitulo pagina;
  final bool visivel;
  final bool temMenu;

  @override
  Widget build(BuildContext context) {
    // O tema daqui já vem com a cor do pôster: a barra tem o tom do fundo da página.
    final tema = TemaHeisuca.de(context);
    final cima = MediaQuery.paddingOf(context).top;
    const lugarDoBotao = Forma.espaco4 + Forma.toqueMinimo + Forma.espaco2;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: cima + TelaTitulo.alturaDaBarra,
      // Fora de vista a barra não existe: nem toque, nem leitor de tela, nem um segundo nome na página.
      child: AnimatedSwitcher(
        duration: Movimento.tempo(context, Movimento.troca),
        switchInCurve: Movimento.entra,
        switchOutCurve: Movimento.sai,
        child: !visivel
            ? const SizedBox.expand()
            : DecoratedBox(
                key: TelaTitulo.chaveDaBarra,
                decoration: BoxDecoration(
                  color: tema.fundo,
                  border: Border(bottom: BorderSide(color: tema.borda)),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: cima,
                    start: lugarDoBotao,
                    end: temMenu ? lugarDoBotao : Forma.espaco4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pagina.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tipo.subtitulo(tema),
                        ),
                      ),
                      if (pagina.aoAssistir != null) ...[
                        const SizedBox(width: Forma.espaco2),
                        BotaoDeIcone(
                          icone: Symbols.play_arrow_rounded,
                          rotulo: pagina.rotuloDeAssistir,
                          vibracao: Vibracao.confirmar,
                          aoTocar: pagina.aoAssistir,
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
