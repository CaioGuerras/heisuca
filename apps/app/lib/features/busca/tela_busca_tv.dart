import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../focus/focusable_text_field.dart';
import '../../heisuca/theme/heisuca_base.dart';
import '../../heisuca/tv/heisuca_tv_area_segura.dart';
import '../../heisuca/tv/heisuca_tv_canvas.dart';
import '../../heisuca/tv/heisuca_tv_pecas.dart';
import '../navegacao_tv/trilho_da_tv.dart';
import '../tema_da_v2.dart';
import 'modelo.dart';

/// A Busca na TV: os mesmos resultados da busca do celular ([TituloDaBusca], [PessoaDaBusca]) no desenho de 3 m.
///
/// No alto, o campo (o teclado da TV abre com o OK). Sem busca, as buscas recentes em pílulas. Com resultado, as
/// pílulas de tipo, as pessoas em fotos redondas e os pôsteres em grade. Tudo anda pelo D-pad; ← na borda abre o
/// trilho; o foco rola a tela sozinho.
class TelaBuscaTv extends StatefulWidget {
  const TelaBuscaTv({
    super.key,
    required this.campo,
    required this.foco,
    this.teclado,
    this.aoEnviar,
    this.aoVoltar,
    this.aoAbrirMenu,
    this.recentes = const [],
    this.aoEscolherRecente,
    this.aoLimparRecentes,
    this.titulos = const [],
    this.pessoas = const [],
    this.primeiroResultado,
    this.buscando = false,
    this.buscou = false,
    this.aviso,
  });

  final TextEditingController campo;
  final FocusNode foco;

  /// Abre e fecha o teclado da TV de fora (a busca que chega do celular não deixa o teclado aberto).
  final TvTextInputController? teclado;
  final VoidCallback? aoEnviar;

  /// Voltar com o campo vazio (o campo com texto primeiro se limpa).
  final VoidCallback? aoVoltar;

  /// ← sem nada à esquerda.
  final VoidCallback? aoAbrirMenu;

  final List<String> recentes;
  final ValueChanged<String>? aoEscolherRecente;
  final VoidCallback? aoLimparRecentes;

  final List<TituloDaBusca> titulos;
  final List<PessoaDaBusca> pessoas;

  /// Foco do 1º cartão da grade: o "Buscar" do teclado leva o foco até ele.
  final FocusNode? primeiroResultado;
  final bool buscando;
  final bool buscou;

  /// Nada achado ou servidor fora do ar ([AvisoTv]); toma o lugar dos resultados.
  final Widget? aviso;

  /// Pôster da grade na tela de referência de 1920 (8 por linha dentro da margem segura).
  static const double larguraDoPoster = 192;
  static const double alturaDoPoster = 288;

  /// Foto de pessoa.
  static const double ladoDaPessoa = 160;

  @override
  State<TelaBuscaTv> createState() => _TelaBuscaTvState();
}

class _TelaBuscaTvState extends State<TelaBuscaTv> {
  FiltroDaBusca _filtro = FiltroDaBusca.todos;

  @override
  void didUpdateWidget(TelaBuscaTv antiga) {
    super.didUpdateWidget(antiga);
    // Resultado novo: a pílula escolhida volta a Todos se o tipo dela sumiu.
    if (!identical(antiga.titulos, widget.titulos) || !identical(antiga.pessoas, widget.pessoas)) {
      if (!filtrosDaBusca(widget.titulos, widget.pessoas).contains(_filtro)) _filtro = FiltroDaBusca.todos;
    }
  }

  void _voltar() {
    if (widget.campo.text.isNotEmpty) {
      widget.campo.clear();
    } else {
      widget.aoVoltar?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = TrilhoDaTv.escuroDaTv(TemaHeisuca.de(context));
    return Theme(
      data: temaDaV2(Theme.of(context), tema),
      child: Scaffold(
        backgroundColor: tema.fundo,
        body: HeisucaTvCanvas(
          child: Builder(
            builder: (context) {
              final margem = HeisucaTvAreaSegura.margem(MediaQuery.sizeOf(context));
              return BordaDoMenuTv(
                aoAbrirMenu: widget.aoAbrirMenu,
                child: HeisucaTvBordasSuaves(
                  altura: margem.top,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(margem.left, margem.top, margem.right, margem.bottom),
                    clipBehavior: Clip.none,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text('Buscar', style: tvTexto(Tipo.titulo(tema)).copyWith(color: tema.texto)),
                        ),
                        const SizedBox(height: Forma.espaco6),
                        _Campo(
                          campo: widget.campo,
                          foco: widget.foco,
                          teclado: widget.teclado,
                          aoEnviar: widget.aoEnviar,
                          aoVoltar: _voltar,
                        ),
                        const SizedBox(height: HeisucaBase.espaco8),
                        ..._corpo(context, tema),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _corpo(BuildContext context, TemaHeisuca tema) {
    final aviso = widget.aviso;
    if (!widget.buscou && !widget.buscando) return _recentes(tema);
    if (aviso != null) return [aviso];
    final temResultado = widget.titulos.isNotEmpty || widget.pessoas.isNotEmpty;
    if (widget.buscando && !temResultado) {
      return [Text('Buscando…', style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto2))];
    }
    final filtros = filtrosDaBusca(widget.titulos, widget.pessoas);
    final titulos = titulosDoFiltro(widget.titulos, _filtro);
    final mostraPessoas = _filtro == FiltroDaBusca.todos || _filtro == FiltroDaBusca.pessoas;
    return [
      if (filtros.isNotEmpty) ...[
        FocusTraversalGroup(
          child: Wrap(
            spacing: Forma.espaco4,
            runSpacing: Forma.espaco4,
            children: [
              for (final filtro in filtros)
                BotaoTv(
                  key: ValueKey('busca-tv-filtro-${filtro.name}'),
                  rotulo: filtro.rotulo,
                  compacto: true,
                  selecionado: filtro == _filtro,
                  aoTocar: () => setState(() => _filtro = filtro),
                ),
            ],
          ),
        ),
        const SizedBox(height: HeisucaBase.espaco8),
      ],
      if (mostraPessoas && widget.pessoas.isNotEmpty) ...[
        _Secao(texto: 'Pessoas'),
        _Pessoas(pessoas: widget.pessoas),
        const SizedBox(height: HeisucaBase.espaco8),
      ],
      if (titulos.isNotEmpty) ...[
        if (mostraPessoas && widget.pessoas.isNotEmpty) _Secao(texto: 'Títulos'),
        _Grade(titulos: titulos, primeiro: widget.primeiroResultado),
      ],
    ];
  }

  List<Widget> _recentes(TemaHeisuca tema) {
    if (widget.recentes.isEmpty) {
      return [
        Text(
          'Busque por filme, série ou pessoa. Aperte OK no campo para abrir o teclado.',
          style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto2),
        ),
      ];
    }
    return [
      _Secao(texto: 'Buscas recentes'),
      FocusTraversalGroup(
        child: Wrap(
          spacing: Forma.espaco4,
          runSpacing: Forma.espaco4,
          children: [
            for (final termo in widget.recentes)
              BotaoTv(
                rotulo: termo,
                icone: Symbols.history_rounded,
                compacto: true,
                aoTocar: () => widget.aoEscolherRecente?.call(termo),
              ),
            if (widget.aoLimparRecentes != null)
              BotaoTv(
                key: const ValueKey('busca-tv-limpar-recentes'),
                rotulo: 'Limpar',
                icone: Symbols.delete_sweep_rounded,
                compacto: true,
                aoTocar: widget.aoLimparRecentes,
              ),
          ],
        ),
      ),
    ];
  }
}

/// O campo da busca em pílula, com o anel de foco da TV.
class _Campo extends StatelessWidget {
  const _Campo({required this.campo, required this.foco, this.teclado, this.aoEnviar, this.aoVoltar});

  final TextEditingController campo;
  final FocusNode foco;
  final TvTextInputController? teclado;
  final VoidCallback? aoEnviar;
  final VoidCallback? aoVoltar;

  /// Largura do campo na tela de referência.
  static const double largura = 1100;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final estilo = tvTexto(Tipo.subtitulo(tema)).copyWith(color: tema.texto, fontWeight: FontWeight.w500);
    OutlineInputBorder borda(BorderSide lado) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(Forma.raioGrande), borderSide: lado);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: largura),
      child: FocusableTextField(
        key: const ValueKey('busca-tv-campo'),
        controller: campo,
        focusNode: foco,
        tvTextInputController: teclado,
        textInputAction: TextInputAction.search,
        onEditingComplete: aoEnviar,
        onBack: aoVoltar,
        style: estilo,
        decoration: InputDecoration(
          // Começa por "Buscar filmes": é assim que a bancada da TV (scripts/bancada/tv.py) reconhece a Busca.
          hintText: 'Buscar filmes, séries e pessoas',
          hintStyle: estilo.copyWith(color: tema.texto2),
          filled: true,
          fillColor: tema.superficie2,
          contentPadding: const EdgeInsets.symmetric(horizontal: HeisucaBase.espaco8, vertical: Forma.espaco6),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: Forma.espaco6, right: Forma.espaco3),
            child: Icon(Symbols.search_rounded, size: 36, color: tema.texto2),
          ),
          border: borda(BorderSide.none),
          enabledBorder: borda(BorderSide.none),
          focusedBorder: borda(BorderSide(color: tema.foco, width: Forma.anelDeFoco)),
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Forma.espaco4),
      child: Semantics(
        header: true,
        child: Text(
          texto,
          style: tvTexto(Tipo.subtitulo(tema)).copyWith(color: tema.texto, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Pessoas numa fileira que anda para os lados.
class _Pessoas extends StatelessWidget {
  const _Pessoas({required this.pessoas});

  final List<PessoaDaBusca> pessoas;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    const lado = TelaBuscaTv.ladoDaPessoa;
    return SizedBox(
      height: lado + CartaoTv.alturaDoTexto(context, tema, comLegenda: false),
      child: FocusTraversalGroup(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: pessoas.length,
          separatorBuilder: (_, _) => const SizedBox(width: Forma.espaco6),
          itemBuilder: (context, i) {
            final pessoa = pessoas[i];
            return CartaoTv(
              largura: lado,
              alturaDaArte: lado,
              titulo: pessoa.nome,
              arte: pessoa.foto,
              redondo: true,
              aoTocar: pessoa.aoTocar,
            );
          },
        ),
      ),
    );
  }
}

/// Os pôsteres em grade: o D-pad anda por linha e coluna.
class _Grade extends StatelessWidget {
  const _Grade({required this.titulos, this.primeiro});

  final List<TituloDaBusca> titulos;
  final FocusNode? primeiro;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Wrap(
        spacing: Forma.espaco6,
        runSpacing: HeisucaBase.espaco8,
        children: [for (var i = 0; i < titulos.length; i++) _cartao(titulos[i], focusNode: i == 0 ? primeiro : null)],
      ),
    );
  }

  Widget _cartao(TituloDaBusca titulo, {FocusNode? focusNode}) {
    final legenda = [?titulo.anos, if (titulo.nota != null) '★ ${titulo.nota}', ?titulo.origem].join(' · ');
    return CartaoTv(
      key: ValueKey('busca-tv-${titulo.chave}'),
      focusNode: focusNode,
      largura: TelaBuscaTv.larguraDoPoster,
      alturaDaArte: TelaBuscaTv.alturaDoPoster,
      titulo: titulo.titulo,
      legenda: legenda.isEmpty ? null : legenda,
      arte: titulo.arte,
      progresso: titulo.visto ? 1 : null,
      aoTocar: titulo.aoTocar,
    );
  }
}
