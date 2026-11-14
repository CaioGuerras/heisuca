import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/componentes/cartao.dart';
import '../../design/componentes/pilula_de_escolha.dart';
import '../../design/componentes/toque.dart';
import '../../design/cor_poster/cor_poster_cache.dart';
import '../../design/cor_poster/temas_cor_poster.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../explorar/tela_explorar.dart' show TelaExplorar;
import '../fundo_tingido.dart';
import 'modelo.dart';

/// A tela de busca da V2: campo no topo, buscas recentes antes de digitar e, depois, um cartão por título.
///
/// Não conhece servidor: o campo e o foco vêm de quem liga a tela, e os resultados chegam prontos.
/// As pílulas (Todos, Filmes, Séries, Pessoas) só aparecem quando há mais de um tipo de resultado.
class TelaBusca extends StatefulWidget {
  const TelaBusca({
    super.key,
    required this.campo,
    required this.foco,
    this.focoInicial = true,
    this.aoVoltar,
    this.aoEnviar,
    this.recentes = const [],
    this.aoEscolherRecente,
    this.aoTirarRecente,
    this.aoLimparRecentes,
    this.titulos = const [],
    this.pessoas = const [],
    this.buscando = false,
    this.buscou = false,
    this.aviso,
    this.pedir,
    this.cores,
    this.folgaInferior = 0,
  });

  final TextEditingController campo;
  final FocusNode foco;

  /// Abre o teclado ao chegar na tela.
  final bool focoInicial;
  final VoidCallback? aoVoltar;

  /// A pessoa tocou na lupa do teclado.
  final ValueChanged<String>? aoEnviar;

  /// Buscas recentes, da mais nova para a mais velha. Só aparecem antes da primeira busca.
  final List<String> recentes;
  final ValueChanged<String>? aoEscolherRecente;
  final ValueChanged<String>? aoTirarRecente;
  final VoidCallback? aoLimparRecentes;

  final List<TituloDaBusca> titulos;
  final List<PessoaDaBusca> pessoas;

  /// Uma busca está a caminho.
  final bool buscando;

  /// Já houve uma busca com o texto atual: sai o histórico, entram os resultados.
  final bool buscou;

  /// O que fica no lugar dos resultados: nada encontrado, falha, sem servidor.
  final Widget? aviso;

  /// A seção "Pedir" (o que ainda não está no servidor). Vai depois dos resultados ou do aviso.
  final Widget? pedir;

  /// De onde sai a cor do pôster; por padrão, o cache do app.
  final CorPosterCache? cores;

  final double folgaInferior;

  /// Quantos cartões de espera a busca mostra.
  static const int cartoesCarregando = 6;

  /// Lado da foto de uma pessoa.
  static const double ladoDaFoto = 72;

  @override
  State<TelaBusca> createState() => _TelaBuscaState();
}

class _TelaBuscaState extends State<TelaBusca> {
  FiltroDaBusca _filtro = FiltroDaBusca.todos;

  CorPosterCache get _cores => widget.cores ?? CorPosterCache.global;

  @override
  void initState() {
    super.initState();
    _cores.addListener(_mudou);
    _aquecer();
  }

  @override
  void didUpdateWidget(TelaBusca antiga) {
    super.didUpdateWidget(antiga);
    final antes = antiga.cores ?? CorPosterCache.global;
    if (antes != _cores) {
      antes.removeListener(_mudou);
      _cores.addListener(_mudou);
    }
    if (!identical(antiga.titulos, widget.titulos) || !identical(antiga.pessoas, widget.pessoas)) {
      // Resultado novo: a pílula escolhida volta a Todos se o tipo dela sumiu.
      if (!_filtros.contains(_filtro)) _filtro = FiltroDaBusca.todos;
      _aquecer();
    } else if (antes != _cores) {
      _aquecer();
    }
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
    final hashes = [for (final item in widget.titulos) ?item.hash];
    if (hashes.isNotEmpty) _cores.aquecer(hashes);
  }

  /// As pílulas que têm o que mostrar. Com um tipo só, nenhuma aparece.
  List<FiltroDaBusca> get _filtros {
    final temFilme = widget.titulos.any((t) => t.tipo == TipoDoResultado.filme);
    final temSerie = widget.titulos.any((t) => t.tipo == TipoDoResultado.serie);
    final temPessoa = widget.pessoas.isNotEmpty;
    final tipos = [
      if (temFilme) FiltroDaBusca.filmes,
      if (temSerie) FiltroDaBusca.series,
      if (temPessoa) FiltroDaBusca.pessoas,
    ];
    final temOutro = widget.titulos.any((t) => t.tipo == TipoDoResultado.outro);
    if (tipos.length + (temOutro ? 1 : 0) < 2) return const [];
    return [FiltroDaBusca.todos, ...tipos];
  }

  List<TituloDaBusca> get _titulosVisiveis => switch (_filtro) {
    FiltroDaBusca.todos => widget.titulos,
    FiltroDaBusca.filmes => [
      for (final t in widget.titulos)
        if (t.tipo == TipoDoResultado.filme) t,
    ],
    FiltroDaBusca.series => [
      for (final t in widget.titulos)
        if (t.tipo == TipoDoResultado.serie) t,
    ],
    FiltroDaBusca.pessoas => const [],
  };

  bool get _mostraPessoas => _filtro == FiltroDaBusca.todos || _filtro == FiltroDaBusca.pessoas;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final temResultado = widget.titulos.isNotEmpty || widget.pessoas.isNotEmpty;
    final esperando = widget.buscando && !temResultado && widget.aviso == null;
    final hashes = [for (final item in _titulosVisiveis.take(6)) ?item.hash];

    final corpo = <Widget>[
      if (!widget.buscou && !widget.buscando)
        ..._recentes(context)
      else if (widget.aviso != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: Forma.espaco6),
            child: widget.aviso,
          ),
        )
      else if (esperando)
        _grade(context, const [], esperando: true)
      else ...[
        if (_filtros.isNotEmpty) SliverToBoxAdapter(child: _pilulas()),
        if (_mostraPessoas && widget.pessoas.isNotEmpty) SliverToBoxAdapter(child: _Pessoas(pessoas: widget.pessoas)),
        if (_titulosVisiveis.isNotEmpty) _grade(context, _titulosVisiveis),
      ],
      if (widget.buscou && widget.pedir != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: Forma.espaco6),
            child: widget.pedir,
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: media.padding.bottom + widget.folgaInferior + Forma.espaco6)),
    ];

    return FundoTingido(
      hash: hashes.firstOrNull,
      preparar: hashes,
      cores: widget.cores,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: media.padding.top),
          _Topo(
            campo: widget.campo,
            foco: widget.foco,
            focoInicial: widget.focoInicial,
            aoVoltar: widget.aoVoltar,
            aoEnviar: widget.aoEnviar,
          ),
          Expanded(
            child: CustomScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, slivers: corpo),
          ),
        ],
      ),
    );
  }

  List<Widget> _recentes(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    if (widget.recentes.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Forma.espaco4, Forma.espaco4, Forma.espaco2, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(header: true, child: Text('Buscas recentes', style: Tipo.subtitulo(tema))),
              ),
              if (widget.aoLimparRecentes != null)
                Botao(rotulo: 'Limpar', tipo: TipoDeBotao.discreto, aoTocar: widget.aoLimparRecentes),
            ],
          ),
        ),
      ),
      SliverList.list(
        children: [
          for (final termo in widget.recentes)
            _Recente(
              key: ValueKey(termo),
              termo: termo,
              aoEscolher: widget.aoEscolherRecente == null ? null : () => widget.aoEscolherRecente!(termo),
              aoTirar: widget.aoTirarRecente == null ? null : () => widget.aoTirarRecente!(termo),
            ),
        ],
      ),
    ];
  }

  Widget _pilulas() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(Forma.espaco4, Forma.espaco2, Forma.espaco4, Forma.espaco3),
    child: Row(
      children: [
        for (final filtro in _filtros)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: Forma.espaco2),
            child: PilulaDeEscolha(
              texto: filtro.rotulo,
              selecionado: filtro == _filtro,
              aoTocar: () => setState(() => _filtro = filtro),
            ),
          ),
      ],
    ),
  );

  Widget _grade(BuildContext context, List<TituloDaBusca> itens, {bool esperando = false}) {
    final papel = TemasCorPoster.de(TemaHeisuca.de(context).nome);
    final comSubtitulo = itens.any((item) => item.anos != null || item.origem != null);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(Forma.espaco4, Forma.espaco2, Forma.espaco4, 0),
      sliver: SliverLayoutBuilder(
        builder: (context, limites) {
          final colunas = TelaExplorar.colunasPara(limites.crossAxisExtent);
          final largura = (limites.crossAxisExtent - (colunas - 1) * Forma.espaco3) / colunas;
          final quadro = Size(largura, largura / FormatoDoCartao.poster.proporcao);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colunas,
              crossAxisSpacing: Forma.espaco3,
              mainAxisSpacing: Forma.espaco3,
              mainAxisExtent: Cartao.alturaPara(context, largura: largura, comSubtitulo: comSubtitulo),
            ),
            delegate: SliverChildBuilderDelegate(childCount: esperando ? TelaBusca.cartoesCarregando : itens.length, (
              context,
              i,
            ) {
              // Cartão de espera: guarda o lugar, sem nada para o leitor de tela.
              if (esperando) {
                return ExcludeSemantics(
                  child: Cartao(titulo: '', largura: largura),
                );
              }
              final item = itens[i];
              final paleta = _cores.ler(item.hash, papel);
              final subtitulo = [?item.anos, ?item.origem].join(' · ');
              return Cartao(
                key: ValueKey(item.chave),
                titulo: item.titulo,
                subtitulo: subtitulo.isEmpty ? null : subtitulo,
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
}

/// O topo: voltar e o campo em pílula, com o "limpar" dentro dele.
class _Topo extends StatelessWidget {
  const _Topo({required this.campo, required this.foco, required this.focoInicial, this.aoVoltar, this.aoEnviar});

  final TextEditingController campo;
  final FocusNode foco;
  final bool focoInicial;
  final VoidCallback? aoVoltar;
  final ValueChanged<String>? aoEnviar;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Forma.espaco2, Forma.espaco2, Forma.espaco4, Forma.espaco2),
      child: Row(
        children: [
          if (aoVoltar != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Forma.espaco1),
              child: BotaoDeIcone(icone: Symbols.arrow_back_rounded, rotulo: 'Voltar', aoTocar: aoVoltar),
            ),
          Expanded(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: tema.superficie2,
                shape: Forma.pilula(lado: BorderSide(color: tema.borda)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Forma.toqueMinimo),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: Forma.espaco4, end: Forma.espaco2),
                      child: ExcludeSemantics(child: Icon(Symbols.search_rounded, color: tema.texto2)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: campo,
                        focusNode: foco,
                        autofocus: focoInicial,
                        textInputAction: TextInputAction.search,
                        onSubmitted: aoEnviar,
                        style: Tipo.texto(tema),
                        cursorColor: tema.texto,
                        // Sem borda: a pílula em volta é a forma do campo. O recheio leva o alvo de toque a 48.
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: Forma.espaco3 + Forma.espaco1),
                          hintText: 'Filmes, séries e pessoas',
                          hintStyle: Tipo.texto(tema).copyWith(color: tema.texto2),
                        ),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: campo,
                      builder: (context, _) => campo.text.isEmpty
                          ? const SizedBox(width: Forma.espaco3)
                          : BotaoDeIcone(
                              icone: Symbols.close_rounded,
                              rotulo: 'Limpar a busca',
                              aoTocar: () {
                                campo.clear();
                                foco.requestFocus();
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma busca recente: tocar busca de novo; o × tira do histórico.
class _Recente extends StatelessWidget {
  const _Recente({super.key, required this.termo, this.aoEscolher, this.aoTirar});

  final String termo;
  final VoidCallback? aoEscolher;
  final VoidCallback? aoTirar;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: Forma.espaco2, end: Forma.espaco2),
      child: Row(
        children: [
          Expanded(
            child: Toque(
              forma: Forma.superelipse(Forma.raioPequeno),
              rotulo: 'Buscar "$termo"',
              aoTocar: aoEscolher,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Forma.toqueMinimo),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Forma.espaco2, vertical: Forma.espaco2),
                  child: Row(
                    children: [
                      Icon(Symbols.history_rounded, color: tema.texto2),
                      const SizedBox(width: Forma.espaco3),
                      Expanded(
                        child: Text(termo, style: Tipo.texto(tema), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (aoTirar != null)
            BotaoDeIcone(icone: Symbols.close_rounded, rotulo: 'Tirar "$termo" do histórico', aoTocar: aoTirar),
        ],
      ),
    );
  }
}

/// As pessoas achadas, numa faixa que corre de lado.
class _Pessoas extends StatelessWidget {
  const _Pessoas({required this.pessoas});

  final List<PessoaDaBusca> pessoas;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    const lado = TelaBusca.ladoDaFoto;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(Forma.espaco4, Forma.espaco2, Forma.espaco4, Forma.espaco4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final pessoa in pessoas)
            Padding(
              key: ValueKey(pessoa.chave),
              padding: const EdgeInsetsDirectional.only(end: Forma.espaco3),
              child: Toque(
                forma: Forma.superelipse(Forma.raioMedio),
                rotulo: pessoa.nome,
                aoTocar: pessoa.aoTocar,
                child: SizedBox(
                  width: lado + Forma.espaco4,
                  child: Column(
                    children: [
                      ClipOval(
                        child: ColoredBox(
                          color: tema.superficie2,
                          child: SizedBox.square(
                            dimension: lado,
                            child:
                                pessoa.foto?.call(context, const Size.square(lado)) ??
                                Icon(Symbols.person_rounded, color: tema.texto2, size: lado / 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: Forma.espaco2),
                      Text(
                        pessoa.nome,
                        style: Tipo.pequeno(tema),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
