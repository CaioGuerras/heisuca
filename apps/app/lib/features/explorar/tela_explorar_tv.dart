import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../heisuca/heisuca_logo.dart';
import '../../heisuca/theme/heisuca_base.dart';
import '../../heisuca/tv/heisuca_tv_area_segura.dart';
import '../../heisuca/tv/heisuca_tv_canvas.dart';
import '../../heisuca/tv/heisuca_tv_pecas.dart';
import '../navegacao_tv/trilho_da_tv.dart';
import '../tema_da_v2.dart';
import 'modelo.dart';

/// Uma biblioteca na TV (Filmes, Séries, Animes): os mesmos dados do Explorar do celular no desenho de 3 m.
///
/// No alto, o nome da biblioteca e as pílulas: as outras bibliotecas, os gêneros, "Não vistos" e a ordem (o OK
/// passa para a próxima). Abaixo, a grade de pôsteres, que pede a próxima página quando o foco chega perto do fim.
/// Tudo anda pelo D-pad; ← na borda abre o trilho.
class TelaExplorarTv extends StatefulWidget {
  const TelaExplorarTv({
    super.key,
    required this.bibliotecas,
    required this.itens,
    this.bibliotecaAtual,
    this.aoEscolherBiblioteca,
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
    this.aoAbrirMenu,
    this.aoPedir,
    this.primeiroCartao,
    this.controle,
  });

  final List<BibliotecaDoExplorar> bibliotecas;
  final String? bibliotecaAtual;
  final ValueChanged<String>? aoEscolherBiblioteca;
  final List<GeneroDoExplorar> generos;

  /// `null` mostra todos.
  final String? generoAtual;

  /// Escolher o gênero já escolhido devolve `null` (volta a mostrar todos).
  final ValueChanged<String?>? aoEscolherGenero;

  /// `null` quando a fonte não sabe filtrar (a pílula some).
  final bool? soNaoVistos;
  final ValueChanged<bool>? aoMudarSoNaoVistos;
  final OrdemDoExplorar ordem;
  final ValueChanged<OrdemDoExplorar>? aoOrdenar;
  final List<ItemDoExplorar> itens;
  final bool carregando;
  final bool carregandoMais;
  final VoidCallback? aoChegarPertoDoFim;
  final VoidCallback? aoTentarMais;

  /// Toma o lugar da grade ([AvisoTv]).
  final Widget? aviso;

  /// ← sem nada à esquerda.
  final VoidCallback? aoAbrirMenu;

  /// Abre a busca com os pedidos do Seerr.
  final VoidCallback? aoPedir;

  /// Foco do 1º pôster: a tela principal manda o foco para ele ao abrir a biblioteca.
  final FocusNode? primeiroCartao;
  final ScrollController? controle;

  /// Colunas da grade (pôster de 192 na tela de referência de 1920, dentro da margem segura).
  static const int colunas = 8;

  /// Proporção do pôster (2:3).
  static const double proporcao = 2 / 3;

  /// A que distância do fim (na tela de referência) a tela pede a próxima página.
  static const double distanciaDoFim = 1200;

  @override
  State<TelaExplorarTv> createState() => _TelaExplorarTvState();
}

class _TelaExplorarTvState extends State<TelaExplorarTv> {
  ScrollController? _proprio;

  ScrollController get _rolagem => widget.controle ?? (_proprio ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _rolagem.addListener(_rolou);
  }

  @override
  void didUpdateWidget(TelaExplorarTv antiga) {
    super.didUpdateWidget(antiga);
    if (antiga.controle != widget.controle) {
      (antiga.controle ?? _proprio)?.removeListener(_rolou);
      _rolagem.addListener(_rolou);
    }
  }

  @override
  void dispose() {
    _rolagem.removeListener(_rolou);
    _proprio?.dispose();
    super.dispose();
  }

  void _rolou() {
    if (!_rolagem.hasClients || widget.carregandoMais) return;
    if (_rolagem.position.extentAfter < TelaExplorarTv.distanciaDoFim) widget.aoChegarPertoDoFim?.call();
  }

  OrdemDoExplorar get _proximaOrdem {
    const ordens = OrdemDoExplorar.values;
    return ordens[(ordens.indexOf(widget.ordem) + 1) % ordens.length];
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
              final aviso = widget.aviso;
              return BordaDoMenuTv(
                aoAbrirMenu: widget.aoAbrirMenu,
                child: HeisucaTvBordasSuaves(
                  altura: margem.top,
                  child: CustomScrollView(
                    controller: _rolagem,
                    clipBehavior: Clip.none,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(margem.left, margem.top, margem.right, 0),
                        sliver: SliverToBoxAdapter(child: _cabeca(context, tema)),
                      ),
                      if (aviso != null)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(margem.left, HeisucaBase.espaco8, margem.right, 0),
                          sliver: SliverToBoxAdapter(child: aviso),
                        )
                      else if (widget.carregando && widget.itens.isEmpty)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(margem.left, HeisucaBase.espaco8, margem.right, 0),
                          sliver: SliverToBoxAdapter(
                            child: Text('Carregando…', style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto2)),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(margem.left, HeisucaBase.espaco8, margem.right, 0),
                          sliver: _grade(context, tema),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(margem.left, Forma.espaco6, margem.right, margem.bottom),
                        sliver: SliverToBoxAdapter(child: _fim(tema)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cabeca(BuildContext context, TemaHeisuca tema) {
    final atual = widget.bibliotecas.where((b) => b.chave == widget.bibliotecaAtual).firstOrNull;
    final soNaoVistos = widget.soNaoVistos;
    final escolherGenero = widget.aoEscolherGenero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(atual?.titulo ?? 'Explorar', style: tvTexto(Tipo.titulo(tema)).copyWith(color: tema.texto)),
              ),
            ),
            const SizedBox(width: Forma.espaco4),
            const HeisucaLogo(siteHeader: true),
          ],
        ),
        const SizedBox(height: Forma.espaco6),
        FocusTraversalGroup(
          child: Wrap(
            spacing: Forma.espaco4,
            runSpacing: Forma.espaco4,
            children: [
              if (widget.aoPedir != null)
                BotaoTv(
                  key: const ValueKey('explorar-tv-pedir'),
                  rotulo: 'Pedir',
                  icone: Symbols.add_rounded,
                  compacto: true,
                  aoTocar: widget.aoPedir,
                ),
              if (widget.bibliotecas.length > 1)
                for (final biblioteca in widget.bibliotecas)
                  BotaoTv(
                    key: ValueKey('explorar-tv-biblioteca-${biblioteca.chave}'),
                    rotulo: biblioteca.titulo,
                    compacto: true,
                    selecionado: biblioteca.chave == widget.bibliotecaAtual,
                    aoTocar: () => widget.aoEscolherBiblioteca?.call(biblioteca.chave),
                  ),
              if (soNaoVistos != null)
                BotaoTv(
                  key: const ValueKey('explorar-tv-nao-vistos'),
                  rotulo: 'Não vistos',
                  icone: Symbols.visibility_off_rounded,
                  compacto: true,
                  selecionado: soNaoVistos,
                  aoTocar: () => widget.aoMudarSoNaoVistos?.call(!soNaoVistos),
                ),
              if (widget.aoOrdenar != null)
                BotaoTv(
                  key: const ValueKey('explorar-tv-ordem'),
                  rotulo: widget.ordem.rotulo,
                  icone: Symbols.sort_rounded,
                  compacto: true,
                  aoTocar: () => widget.aoOrdenar?.call(_proximaOrdem),
                ),
            ],
          ),
        ),
        if (widget.generos.isNotEmpty && escolherGenero != null) ...[
          const SizedBox(height: Forma.espaco4),
          _Generos(generos: widget.generos, atual: widget.generoAtual, aoEscolher: escolherGenero),
        ],
      ],
    );
  }

  Widget _grade(BuildContext context, TemaHeisuca tema) {
    final legenda = CartaoTv.alturaDoTexto(context, tema);
    return SliverLayoutBuilder(
      builder: (context, restricoes) {
        const colunas = TelaExplorarTv.colunas;
        const vao = Forma.espaco6;
        final largura = (restricoes.crossAxisExtent - vao * (colunas - 1)) / colunas;
        final alturaDaArte = largura / TelaExplorarTv.proporcao;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colunas,
            crossAxisSpacing: vao,
            mainAxisSpacing: HeisucaBase.espaco8,
            mainAxisExtent: alturaDaArte + legenda,
          ),
          delegate: SliverChildBuilderDelegate((context, i) {
            final item = widget.itens[i];
            final nota = item.nota;
            final legendaDoItem = [?item.anos, if (nota != null) '★ $nota', ?item.selo].join(' · ');
            return CartaoTv(
              key: ValueKey('explorar-tv-${item.chave}'),
              focusNode: i == 0 ? widget.primeiroCartao : null,
              largura: largura,
              alturaDaArte: alturaDaArte,
              titulo: item.titulo,
              legenda: legendaDoItem.isEmpty ? null : legendaDoItem,
              arte: item.arte,
              progresso: item.visto ? 1 : null,
              aoTocar: item.aoTocar,
              aoSegurar: item.aoSegurar,
              // O foco perto do fim também pede a próxima página (o D-pad pode andar sem a rolagem mudar muito).
              aoFocar: (focado) {
                if (focado && i >= widget.itens.length - colunas * 2) widget.aoChegarPertoDoFim?.call();
              },
            );
          }, childCount: widget.itens.length),
        );
      },
    );
  }

  Widget _fim(TemaHeisuca tema) {
    final tentar = widget.aoTentarMais;
    if (tentar != null) {
      return Row(
        children: [
          Text('Não deu para carregar mais títulos.', style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto2)),
          const SizedBox(width: Forma.espaco6),
          BotaoTv(rotulo: 'Tentar de novo', icone: Symbols.refresh_rounded, compacto: true, aoTocar: tentar),
        ],
      );
    }
    if (widget.carregandoMais) {
      return Text('Carregando mais…', style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto2));
    }
    return const SizedBox.shrink();
  }
}

/// Os gêneros numa fileira que anda para os lados; "Todos" primeiro.
class _Generos extends StatelessWidget {
  const _Generos({required this.generos, required this.atual, required this.aoEscolher});

  final List<GeneroDoExplorar> generos;
  final String? atual;
  final ValueChanged<String?> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BotaoTv.alturaCompacta(context, TemaHeisuca.de(context)),
      child: FocusTraversalGroup(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: generos.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: Forma.espaco4),
          itemBuilder: (context, i) {
            if (i == 0) {
              return BotaoTv(
                key: const ValueKey('explorar-tv-genero-todos'),
                rotulo: 'Todos os gêneros',
                compacto: true,
                selecionado: atual == null,
                aoTocar: () => aoEscolher(null),
              );
            }
            final genero = generos[i - 1];
            return BotaoTv(
              key: ValueKey('explorar-tv-genero-${genero.chave}'),
              rotulo: genero.nome,
              compacto: true,
              selecionado: genero.chave == atual,
              aoTocar: () => aoEscolher(genero.chave == atual ? null : genero.chave),
            );
          },
        ),
      ),
    );
  }
}
