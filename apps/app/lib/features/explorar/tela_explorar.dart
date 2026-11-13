import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/componentes/cartao.dart';
import '../../design/componentes/pilula_de_escolha.dart';
import '../../design/componentes/toque.dart';
import '../../design/cor_poster/cor_poster_cache.dart';
import '../../design/cor_poster/temas_cor_poster.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../fundo_tingido.dart';
import '../inicio/aviso.dart';
import '../veu_do_topo.dart';
import 'modelo.dart';

/// A tela Explorar da V2: a biblioteca em grade de pôsteres, com gêneros, ordem e "não vistos".
///
/// Não conhece servidor: recebe as bibliotecas, os gêneros e os cartões prontos, e avisa o que foi escolhido.
class TelaExplorar extends StatefulWidget {
  const TelaExplorar({
    super.key,
    required this.bibliotecas,
    required this.itens,
    this.bibliotecaAtual,
    this.aoEscolherBiblioteca,
    this.aoAbrirFavoritos,
    this.generos = const [],
    this.generoAtual,
    this.aoEscolherGenero,
    this.soNaoVistos,
    this.aoMudarSoNaoVistos,
    this.ordem = OrdemDoExplorar.titulo,
    this.aoOrdenar,
    this.carregando = false,
    this.carregandoMais = false,
    this.aoChegarPertoDoFim,
    this.aoTentarMais,
    this.aviso,
    this.aoBuscar,
    this.perfil,
    this.aoAtualizar,
    this.controle,
    this.chaveDeRolagem,
    this.cores,
    this.folgaInferior = 96,
  });

  final List<BibliotecaDoExplorar> bibliotecas;

  /// Chave da biblioteca aberta.
  final String? bibliotecaAtual;
  final ValueChanged<String>? aoEscolherBiblioteca;

  /// Abre os favoritos (pílula depois das bibliotecas); sem isto a pílula não existe.
  final VoidCallback? aoAbrirFavoritos;

  /// Gêneros da biblioteca aberta. Vazio esconde a faixa.
  final List<GeneroDoExplorar> generos;

  /// Chave do gênero escolhido; `null` mostra todos.
  final String? generoAtual;

  /// Tocar no gênero já escolhido devolve `null` (volta a mostrar todos).
  final ValueChanged<String?>? aoEscolherGenero;

  /// "Só não vistos" ligado ou desligado; `null` quando a fonte não sabe filtrar (a pílula some).
  final bool? soNaoVistos;
  final ValueChanged<bool>? aoMudarSoNaoVistos;

  final OrdemDoExplorar ordem;
  final ValueChanged<OrdemDoExplorar>? aoOrdenar;

  /// Os cartões já carregados, na ordem da grade.
  final List<ItemDoExplorar> itens;

  /// A primeira página ainda não chegou: a grade guarda o lugar dos cartões.
  final bool carregando;

  /// Mais uma página está a caminho: a grade ganha uma linha de espera no fim.
  final bool carregandoMais;

  /// A rolagem chegou perto do fim: hora de pedir a próxima página.
  final VoidCallback? aoChegarPertoDoFim;

  /// A página seguinte falhou: o fim da grade diz isso e oferece tentar de novo.
  final VoidCallback? aoTentarMais;

  /// O que ocupa o lugar da grade quando há algo a dizer (falha de carga, fonte sem biblioteca).
  final Widget? aviso;

  final VoidCallback? aoBuscar;

  /// O que fica no canto de cima, do lado oposto à busca: a pílula de quem está usando o app.
  final Widget? perfil;

  /// Puxar para atualizar; sem isto o gesto não existe.
  final Future<void> Function()? aoAtualizar;

  final ScrollController? controle;
  final Key? chaveDeRolagem;

  /// De onde sai a cor do pôster; por padrão, o cache do app.
  final CorPosterCache? cores;

  /// Espaço no fim da grade para a barra flutuante não cobrir a última linha.
  final double folgaInferior;

  /// Altura do topo: o lugar da pílula do perfil e do botão de busca.
  static const double topo = 72;

  /// A grade nunca tem menos colunas que isto, nem cartão mais largo que [larguraIdeal] em tela larga.
  static const int colunasMinimas = 3;
  static const int colunasMaximas = 9;
  static const double larguraIdeal = 150;

  /// Quantos cartões de espera a primeira carga mostra.
  static const int cartoesCarregando = 12;

  /// A que distância do fim a tela pede a próxima página.
  static const double distanciaDoFim = 600;

  /// Quantas colunas cabem em [largura] (a largura da grade, já sem as margens).
  static int colunasPara(double largura) =>
      (largura / larguraIdeal).floor().clamp(colunasMinimas, colunasMaximas).toInt();

  @override
  State<TelaExplorar> createState() => _TelaExplorarState();
}

class _TelaExplorarState extends State<TelaExplorar> {
  CorPosterCache get _cores => widget.cores ?? CorPosterCache.global;

  @override
  void initState() {
    super.initState();
    _cores.addListener(_mudou);
    _aquecer();
  }

  @override
  void didUpdateWidget(TelaExplorar antiga) {
    super.didUpdateWidget(antiga);
    final antes = antiga.cores ?? CorPosterCache.global;
    if (antes != _cores) {
      antes.removeListener(_mudou);
      _cores.addListener(_mudou);
    }
    if (antes != _cores || !identical(antiga.itens, widget.itens)) _aquecer();
  }

  @override
  void dispose() {
    _cores.removeListener(_mudou);
    super.dispose();
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  void _aquecer() {
    final hashes = [for (final item in widget.itens) ?item.hash];
    if (hashes.isNotEmpty) _cores.aquecer(hashes);
  }

  bool _rolou(ScrollNotification aviso) {
    _conferirOFim(aviso.metrics);
    return false;
  }

  /// A lista mudou de tamanho sem ninguém rolar: grade que cabe inteira na tela também pede a página seguinte.
  bool _mediu(ScrollMetricsNotification aviso) {
    _conferirOFim(aviso.metrics);
    return false;
  }

  void _conferirOFim(ScrollMetrics medida) {
    if (medida.axis == Axis.vertical && medida.extentAfter < TelaExplorar.distanciaDoFim) {
      widget.aoChegarPertoDoFim?.call();
    }
  }

  Future<void> _escolherOrdem() async {
    final tema = TemaHeisuca.de(context);
    final escolhida = await showModalBottomSheet<OrdemDoExplorar>(
      context: context,
      useSafeArea: true,
      backgroundColor: tema.superficie,
      sheetAnimationStyle: Movimento.reduzido(context) ? AnimationStyle.noAnimation : null,
      builder: (folha) => _Ordens(tema: tema, atual: widget.ordem),
    );
    if (escolhida != null && escolhida != widget.ordem && mounted) widget.aoOrdenar?.call(escolhida);
  }

  bool get _temFiltro => widget.generoAtual != null || (widget.soNaoVistos ?? false);

  void _limparFiltros() {
    if (widget.generoAtual != null) widget.aoEscolherGenero?.call(null);
    if (widget.soNaoVistos ?? false) widget.aoMudarSoNaoVistos?.call(false);
  }

  Widget _grade(BuildContext context) {
    final itens = widget.itens;
    final esperando = widget.carregando && itens.isEmpty;
    final papel = TemasCorPoster.de(TemaHeisuca.de(context).nome);
    final comSubtitulo = itens.any((item) => item.anos != null);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
      sliver: SliverLayoutBuilder(
        builder: (context, limites) {
          final colunas = TelaExplorar.colunasPara(limites.crossAxisExtent);
          final largura = (limites.crossAxisExtent - (colunas - 1) * Forma.espaco3) / colunas;
          final quadro = Size(largura, largura / FormatoDoCartao.poster.proporcao);
          final total = esperando
              ? TelaExplorar.cartoesCarregando
              : itens.length + (widget.carregandoMais ? colunas : 0);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colunas,
              crossAxisSpacing: Forma.espaco3,
              mainAxisSpacing: Forma.espaco3,
              mainAxisExtent: Cartao.alturaPara(context, largura: largura, comSubtitulo: comSubtitulo),
            ),
            delegate: SliverChildBuilderDelegate(childCount: total, (context, i) {
              // Cartão de espera: guarda o lugar, sem esqueleto cinza e sem nada para o leitor de tela.
              if (i >= itens.length) {
                return ExcludeSemantics(
                  child: Cartao(titulo: '', largura: largura),
                );
              }
              final item = itens[i];
              final paleta = _cores.ler(item.hash, papel);
              return Cartao(
                key: ValueKey(item.chave),
                titulo: item.titulo,
                subtitulo: item.anos,
                largura: largura,
                corDoPoster: paleta == null ? null : Color(paleta.superficie2),
                arte: item.arte?.call(context, quadro),
                nota: item.nota,
                visto: item.visto,
                aoTocar: item.aoTocar,
                aoSegurar: item.aoSegurar,
              );
            }),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = TemaHeisuca.de(context);
    final media = MediaQuery.of(context);
    final itens = widget.itens;
    final hash = itens.where((item) => item.hash != null).firstOrNull?.hash;
    final temBiblioteca = widget.bibliotecas.isNotEmpty;
    final vazia = widget.aviso == null && !widget.carregando && itens.isEmpty && temBiblioteca;

    final lista = NotificationListener<ScrollNotification>(
      onNotification: _rolou,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _mediu,
        child: CustomScrollView(
          key: widget.chaveDeRolagem,
          controller: widget.controle,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: media.padding.top + TelaExplorar.topo)),
            if (temBiblioteca) ...[
              SliverToBoxAdapter(
                child: _Faixa(
                  rotulo: 'Bibliotecas',
                  pilulas: [
                    for (final biblioteca in widget.bibliotecas)
                      PilulaDeEscolha(
                        texto: biblioteca.titulo,
                        selecionado: biblioteca.chave == widget.bibliotecaAtual,
                        aoTocar: biblioteca.chave == widget.bibliotecaAtual
                            ? null
                            : () => widget.aoEscolherBiblioteca?.call(biblioteca.chave),
                      ),
                    if (widget.aoAbrirFavoritos != null)
                      PilulaDeEscolha(texto: 'Favoritos', aoTocar: widget.aoAbrirFavoritos),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _Faixa(
                  rotulo: 'Ordem e filtros',
                  pilulas: [
                    PilulaDeEscolha(
                      texto: widget.ordem.rotulo,
                      rotulo: 'Ordenar, agora por ${widget.ordem.rotulo}',
                      aoTocar: _escolherOrdem,
                    ),
                    if (widget.soNaoVistos case final ligado?)
                      PilulaDeEscolha(
                        texto: 'Não vistos',
                        rotulo: 'Só não vistos',
                        selecionado: ligado,
                        aoTocar: () => widget.aoMudarSoNaoVistos?.call(!ligado),
                      ),
                  ],
                ),
              ),
              if (widget.generos.isNotEmpty)
                SliverToBoxAdapter(
                  child: _Faixa(
                    rotulo: 'Gêneros',
                    pilulas: [
                      for (final genero in widget.generos)
                        PilulaDeEscolha(
                          texto: genero.nome,
                          selecionado: genero.chave == widget.generoAtual,
                          aoTocar: () =>
                              widget.aoEscolherGenero?.call(genero.chave == widget.generoAtual ? null : genero.chave),
                        ),
                    ],
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: Forma.espaco2)),
            ],
            if (widget.aviso != null)
              SliverToBoxAdapter(child: widget.aviso)
            else if (vazia)
              SliverToBoxAdapter(
                child: _temFiltro
                    ? Aviso(
                        icone: Symbols.filter_alt_off_rounded,
                        titulo: 'Nenhum título com estes filtros',
                        texto: 'Tire um filtro para ver mais títulos.',
                        acoes: [Botao(rotulo: 'Limpar filtros', aoTocar: _limparFiltros)],
                      )
                    : const Aviso(
                        icone: Symbols.video_library_rounded,
                        titulo: 'Esta biblioteca ainda está vazia',
                        texto: 'Puxe para atualizar ou escolha outra biblioteca.',
                      ),
              )
            else if (temBiblioteca || widget.carregando)
              Builder(builder: _grade),
            if (widget.aoTentarMais != null && widget.aviso == null && itens.isNotEmpty)
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.fromLTRB(Forma.espaco4, Forma.espaco4, Forma.espaco4, 0),
                    child: Column(
                      children: [
                        Text(
                          'Não foi possível carregar mais títulos.',
                          textAlign: TextAlign.center,
                          style: Tipo.pequeno(TemaHeisuca.de(context)),
                        ),
                        const SizedBox(height: Forma.espaco2),
                        Botao(rotulo: 'Tentar de novo', tipo: TipoDeBotao.secundario, aoTocar: widget.aoTentarMais),
                      ],
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: media.padding.bottom + widget.folgaInferior)),
          ],
        ),
      ),
    );

    return FundoTingido(
      hash: hash,
      cores: widget.cores,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.aoAtualizar == null)
            lista
          else
            // Dentro do fundo tingido: o indicador usa a superfície já com a cor do pôster.
            Builder(
              builder: (context) => RefreshIndicator(
                color: base.texto,
                backgroundColor: TemaHeisuca.de(context).superficie2,
                edgeOffset: media.padding.top + Forma.espaco2,
                onRefresh: widget.aoAtualizar!,
                child: lista,
              ),
            ),
          const VeuDoTopo(),
          if (widget.perfil != null)
            PositionedDirectional(
              top: media.padding.top + Forma.espaco2,
              start: Forma.espaco4,
              // A busca fica do outro lado: a pílula não passa por baixo dela.
              end: Forma.espaco4 + Forma.toqueMinimo + Forma.espaco2,
              child: Align(alignment: AlignmentDirectional.centerStart, child: widget.perfil),
            ),
          if (widget.aoBuscar != null)
            PositionedDirectional(
              top: media.padding.top + Forma.espaco2,
              end: Forma.espaco4,
              child: BotaoDeIcone(
                icone: Symbols.search_rounded,
                rotulo: 'Buscar',
                sobreArte: true,
                aoTocar: widget.aoBuscar,
              ),
            ),
        ],
      ),
    );
  }
}

/// Uma faixa de pílulas que rola de lado.
class _Faixa extends StatelessWidget {
  const _Faixa({required this.rotulo, required this.pilulas});

  /// Como o leitor de tela chama a faixa.
  final String rotulo;
  final List<Widget> pilulas;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: rotulo,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
      child: Row(
        children: [
          for (final (i, pilula) in pilulas.indexed) ...[if (i > 0) const SizedBox(width: Forma.espaco2), pilula],
        ],
      ),
    ),
  );
}

/// A folha de escolha da ordem.
class _Ordens extends StatelessWidget {
  const _Ordens({required this.tema, required this.atual});

  /// O tema de quem abriu: a folha nasce fora da tela e não o herdaria.
  final TemaHeisuca tema;
  final OrdemDoExplorar atual;

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    padding: const EdgeInsets.symmetric(vertical: Forma.espaco3),
    children: [
      for (final ordem in OrdemDoExplorar.values)
        Toque(
          forma: Forma.superelipse(Forma.raioPequeno),
          rotulo: ordem.rotulo,
          selecionado: ordem == atual,
          excluirSemantica: true,
          escala: 1,
          aoTocar: () => Navigator.of(context).pop(ordem),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Forma.toqueMinimo),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4, vertical: Forma.espaco2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ordem.rotulo,
                      style: Tipo.texto(tema).copyWith(fontWeight: ordem == atual ? FontWeight.w600 : null),
                    ),
                  ),
                  if (ordem == atual) Icon(Symbols.check_rounded, size: 24, color: tema.texto),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
