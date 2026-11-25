import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../heisuca/theme/heisuca_base.dart';
import '../../heisuca/tv/heisuca_tv_area_segura.dart';
import '../../heisuca/tv/heisuca_tv_canvas.dart';
import '../../heisuca/tv/heisuca_tv_pecas.dart';
import '../inicio/modelo.dart' show ItemDaFileira;
import '../navegacao_tv/trilho_da_tv.dart';
import '../tema_da_v2.dart';
import 'modelo.dart';

/// A página do título na TV: os mesmos dados da ficha do celular ([PaginaDoTitulo] e companhia), no desenho de 3 m.
///
/// Cabeça: a arte em tela cheia, o logo, os dados, a sinopse e os botões (Assistir com o foco inicial). Abaixo,
/// rolando com o controle: episódios por temporada, "Mais como este", elenco e os dados da mídia. Sem dado, sem
/// seção. Tudo é focável pelo D-pad; o foco rola a tela sozinho até o que ganhou o foco.
class TelaTituloTv extends StatefulWidget {
  const TelaTituloTv({
    super.key,
    required this.pagina,
    this.temporadas,
    this.aberta = 0,
    this.aoMudarTemporada,
    this.elenco = const [],
    this.parecidos = const [],
    this.info = const [],
    this.tituloDaInfo = 'Sobre a mídia',
    this.falhou = false,
    this.aoTentar,
    this.aoFocarAssistir,
  });

  final PaginaDoTitulo pagina;

  /// `null` em filme ou enquanto as temporadas não chegam.
  final List<TemporadaDoTitulo>? temporadas;

  /// A temporada aberta quando a tela monta (ou quando quem liga escolhe outra).
  final int aberta;
  final ValueChanged<int>? aoMudarTemporada;
  final List<PessoaDoTitulo> elenco;
  final List<ItemDaFileira> parecidos;
  final List<GrupoDeInfo> info;
  final String tituloDaInfo;

  /// O servidor não respondeu parte do título: aparece o aviso com "Tentar de novo".
  final bool falhou;
  final VoidCallback? aoTentar;

  /// O Assistir ganhou o foco: quem liga aquece o play.
  final VoidCallback? aoFocarAssistir;

  @override
  State<TelaTituloTv> createState() => _TelaTituloTvState();
}

class _TelaTituloTvState extends State<TelaTituloTv> {
  final ScrollController _rolagem = ScrollController();
  late int _aberta = widget.aberta;

  @override
  void didUpdateWidget(TelaTituloTv antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.aberta != widget.aberta) _aberta = widget.aberta;
  }

  @override
  void dispose() {
    _rolagem.dispose();
    super.dispose();
  }

  /// O foco voltou aos botões da cabeça: a tela volta ao topo, com a arte inteira.
  void _voltarAoTopo() {
    if (!_rolagem.hasClients || _rolagem.offset <= 0) return;
    final tempo = Movimento.tempo(context, Movimento.tela);
    if (tempo == Duration.zero) {
      _rolagem.jumpTo(0);
    } else {
      _rolagem.animateTo(0, duration: tempo, curve: Movimento.padrao);
    }
  }

  void _abrirTemporada(int indice) {
    if (indice == _aberta) return;
    setState(() => _aberta = indice);
    widget.aoMudarTemporada?.call(indice);
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
              final tela = MediaQuery.sizeOf(context);
              final margem = HeisucaTvAreaSegura.margem(tela);
              final temporadas = widget.temporadas;
              final pagina = widget.pagina;
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (pagina.arte != null) pagina.arte!(context, tela),
                  _Degrades(tema: tema),
                  AnimatedBuilder(
                    animation: _rolagem,
                    builder: (context, _) {
                      final deslocamento = _rolagem.hasClients ? _rolagem.offset : 0.0;
                      final alfa = (deslocamento / (tela.height * 0.5)).clamp(0.0, 0.9);
                      return IgnorePointer(
                        child: ColoredBox(color: tema.fundo.withValues(alpha: alfa)),
                      );
                    },
                  ),
                  SingleChildScrollView(
                    controller: _rolagem,
                    padding: EdgeInsets.only(bottom: margem.bottom + HeisucaBase.espaco8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Cabeca(
                          pagina: pagina,
                          altura: tela.height * 0.86,
                          margem: margem,
                          aoFocarBotao: _voltarAoTopo,
                          aoFocarAssistir: widget.aoFocarAssistir,
                        ),
                        if (temporadas != null && temporadas.isNotEmpty)
                          _Episodios(
                            temporadas: temporadas,
                            aberta: min(_aberta, temporadas.length - 1),
                            margem: margem,
                            aoAbrir: _abrirTemporada,
                          ),
                        if (widget.parecidos.isNotEmpty) _Parecidos(itens: widget.parecidos, margem: margem),
                        if (widget.elenco.isNotEmpty) _Elenco(pessoas: widget.elenco, margem: margem),
                        if (widget.info.isNotEmpty)
                          _Info(grupos: widget.info, titulo: widget.tituloDaInfo, margem: margem),
                        if (widget.falhou) _Falha(margem: margem, aoTentar: widget.aoTentar),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Os mesmos degradês do Início: o texto da esquerda e as fileiras de baixo ficam sobre o fundo, não sobre a arte.
class _Degrades extends StatelessWidget {
  const _Degrades({required this.tema});

  final TemaHeisuca tema;

  @override
  Widget build(BuildContext context) {
    final fundo = tema.fundo;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [fundo.withValues(alpha: 0.92), fundo.withValues(alpha: 0.55), fundo.withValues(alpha: 0)],
                stops: const [0, 0.42, 0.75],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [fundo.withValues(alpha: 0), fundo.withValues(alpha: 0.7), fundo],
                stops: const [0.35, 0.7, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo, dados, sinopse, botões e progresso, presos ao pé da primeira tela.
class _Cabeca extends StatelessWidget {
  const _Cabeca({
    required this.pagina,
    required this.altura,
    required this.margem,
    required this.aoFocarBotao,
    this.aoFocarAssistir,
  });

  final PaginaDoTitulo pagina;
  final double altura;
  final EdgeInsets margem;
  final VoidCallback aoFocarBotao;
  final VoidCallback? aoFocarAssistir;

  /// Caixa do logo no canvas de 1920.
  static const Size _logo = Size(720, 240);

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final semLogo = Align(
      alignment: Alignment.bottomLeft,
      child: Text(
        pagina.titulo,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: tvTexto(Tipo.destaque(tema)).copyWith(color: tema.texto, fontWeight: FontWeight.w700),
      ),
    );
    final logo = pagina.logo;
    final sinopse = pagina.sinopse;
    final progresso = pagina.progresso;
    final aoAlternarLista = pagina.aoAlternarLista;
    final aoAlternarVisto = pagina.aoAlternarVisto;
    return SizedBox(
      height: altura,
      child: Padding(
        padding: EdgeInsets.fromLTRB(margem.left, margem.top, margem.right, Forma.espaco6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              label: pagina.titulo,
              excludeSemantics: true,
              child: SizedBox.fromSize(size: _logo, child: logo == null ? semLogo : logo(context, _logo, semLogo)),
            ),
            const SizedBox(height: Forma.espaco6),
            _Meta(pagina: pagina),
            if (sinopse != null) ...[
              const SizedBox(height: Forma.espaco4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Text(
                  sinopse,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto2),
                ),
              ),
            ],
            const SizedBox(height: HeisucaBase.espaco8),
            Wrap(
              spacing: Forma.espaco4,
              runSpacing: Forma.espaco4,
              children: [
                BotaoTv(
                  key: const Key('heisuca-tv-title-play'),
                  rotulo: pagina.rotuloDeAssistir,
                  icone: Symbols.play_arrow_rounded,
                  principal: true,
                  autofocus: true,
                  aoTocar: pagina.aoAssistir,
                  aoFocar: () {
                    aoFocarBotao();
                    aoFocarAssistir?.call();
                  },
                ),
                if (aoAlternarLista != null)
                  BotaoTv(
                    key: const Key('heisuca-tv-title-lista'),
                    rotulo: pagina.listaDaConta ? 'Minha lista' : (pagina.naLista ? 'Favorito' : 'Favoritar'),
                    icone: pagina.listaDaConta ? Symbols.bookmark_rounded : Symbols.favorite_rounded,
                    selecionado: pagina.naLista,
                    aoTocar: aoAlternarLista,
                    aoFocar: aoFocarBotao,
                  ),
                if (aoAlternarVisto != null)
                  BotaoTv(
                    key: const Key('heisuca-tv-title-visto'),
                    rotulo: 'Já vi',
                    icone: Symbols.check_circle_rounded,
                    selecionado: pagina.visto,
                    aoTocar: aoAlternarVisto,
                    aoFocar: aoFocarBotao,
                  ),
              ],
            ),
            if (progresso != null && progresso > 0) ...[
              const SizedBox(height: Forma.espaco6),
              _Progresso(valor: progresso),
            ],
          ],
        ),
      ),
    );
  }
}

/// ★ nota · anos · gêneros · detalhes, e o selo da classificação.
class _Meta extends StatelessWidget {
  const _Meta({required this.pagina});

  final PaginaDoTitulo pagina;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final estilo = tvTexto(Tipo.pequeno(tema)).copyWith(color: tema.texto2);
    final nota = pagina.nota;
    final classificacao = pagina.classificacao;
    final partes = [?pagina.anos, ?pagina.generos, ...pagina.detalhes].where((p) => p.trim().isNotEmpty).toList();
    final ponto = Text('·', style: estilo);
    final pecas = <Widget>[
      if (nota != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.star_rounded, fill: 1, size: 28, color: tema.acento),
            const SizedBox(width: Forma.espaco1),
            Text(
              nota,
              style: estilo.copyWith(color: tema.texto, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      for (final parte in partes) Text(parte, style: estilo),
    ];
    return Wrap(
      spacing: Forma.espaco3,
      runSpacing: Forma.espaco2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, peca) in pecas.indexed) ...[if (i > 0) ponto, peca],
        if (classificacao != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Forma.espaco2, vertical: Forma.espaco1),
            decoration: ShapeDecoration(
              shape: Forma.superelipse(Forma.raioPequeno, lado: BorderSide(color: tema.texto2)),
            ),
            child: Text(
              classificacao,
              style: estilo.copyWith(color: tema.texto, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// Quanto já foi visto do que o Assistir toca.
class _Progresso extends StatelessWidget {
  const _Progresso({required this.valor});

  final double valor;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Semantics(
      label: 'Visto ${(valor.clamp(0.0, 1.0) * 100).round()} %',
      excludeSemantics: true,
      child: SizedBox(
        width: 384,
        height: Forma.espaco2,
        child: DecoratedBox(
          decoration: ShapeDecoration(color: tema.superficie2, shape: Forma.pilula()),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: valor.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: ShapeDecoration(color: tema.acento, shape: Forma.pilula()),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de seção, alinhado à margem segura.
class _TituloDaSecao extends StatelessWidget {
  const _TituloDaSecao({required this.texto, required this.margem});

  final String texto;
  final EdgeInsets margem;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(margem.left, HeisucaBase.espaco8, margem.right, Forma.espaco4),
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

/// Fileira horizontal que vai até a borda da tela, começando na margem segura.
class _FileiraTv extends StatefulWidget {
  const _FileiraTv({
    super.key,
    required this.altura,
    required this.margem,
    required this.quantos,
    required this.cartao,
    this.largura,
    this.inicial = 0,
  });

  final double altura;
  final EdgeInsets margem;
  final int quantos;
  final IndexedWidgetBuilder cartao;

  /// Largura de cada cartão, para abrir a fileira já no [inicial].
  final double? largura;
  final int inicial;

  @override
  State<_FileiraTv> createState() => _FileiraTvState();
}

class _FileiraTvState extends State<_FileiraTv> {
  // Um controle por fileira, criado uma vez: no build ele nascia de novo a cada reconstrução e nunca era descartado.
  // Trocar de temporada troca a chave da fileira, e a fileira nova abre no episódio atual dela.
  late final ScrollController _rolagem = ScrollController(
    initialScrollOffset: widget.largura == null ? 0 : max(0, widget.inicial) * (widget.largura! + Forma.espaco6),
  );

  @override
  void dispose() {
    _rolagem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.altura,
      child: FocusTraversalGroup(
        child: ListView.separated(
          controller: _rolagem,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: EdgeInsets.symmetric(horizontal: widget.margem.left),
          itemCount: widget.quantos,
          separatorBuilder: (_, _) => const SizedBox(width: Forma.espaco6),
          itemBuilder: widget.cartao,
        ),
      ),
    );
  }
}

class _Episodios extends StatelessWidget {
  const _Episodios({required this.temporadas, required this.aberta, required this.margem, required this.aoAbrir});

  final List<TemporadaDoTitulo> temporadas;
  final int aberta;
  final EdgeInsets margem;
  final ValueChanged<int> aoAbrir;

  static const double _largura = 384;
  static const double _altura = 216;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final temporada = temporadas[aberta];
    final episodios = temporada.episodios;
    final atual = episodios?.indexWhere((e) => e.atual) ?? -1;
    final pilula = Forma.toqueMinimo + Forma.espaco2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TituloDaSecao(texto: 'Episódios', margem: margem),
        if (temporadas.length > 1) ...[
          SizedBox(
            height: pilula + Forma.espaco4,
            child: FocusTraversalGroup(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: EdgeInsets.symmetric(horizontal: margem.left),
                itemCount: temporadas.length,
                separatorBuilder: (_, _) => const SizedBox(width: Forma.espaco3),
                itemBuilder: (context, i) => Center(
                  child: BotaoTv(
                    rotulo: temporadas[i].nome,
                    compacto: true,
                    principal: i == aberta,
                    selecionado: i == aberta,
                    aoTocar: () => aoAbrir(i),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Forma.espaco4),
        ],
        if (episodios == null)
          SizedBox(
            height: _altura,
            child: Center(
              child: Semantics(
                label: 'Carregando os episódios',
                child: CircularProgressIndicator(color: tema.acento),
              ),
            ),
          )
        else if (episodios.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margem.left),
            child: Text(
              'Nenhum episódio nesta temporada.',
              style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto2),
            ),
          )
        else
          _FileiraTv(
            // Uma fileira por temporada: ao trocar, abre de novo no episódio atual dela.
            key: ValueKey('episodios-${temporada.chave}'),
            altura: _altura + CartaoTv.alturaDoTexto(context, tema),
            margem: margem,
            quantos: episodios.length,
            largura: _largura,
            inicial: atual,
            cartao: (context, i) {
              final episodio = episodios[i];
              return CartaoTv(
                largura: _largura,
                alturaDaArte: _altura,
                titulo: episodio.rotulo,
                arte: episodio.arte,
                legenda: episodio.duracao,
                progresso: episodio.progresso,
                destaque: episodio.atual,
                aoTocar: episodio.aoTocar,
              );
            },
          ),
      ],
    );
  }
}

/// "Mais como este": pôsteres que abrem outra página de título.
class _Parecidos extends StatelessWidget {
  const _Parecidos({required this.itens, required this.margem});

  final List<ItemDaFileira> itens;
  final EdgeInsets margem;

  static const double _largura = 200;
  static const double _altura = 300;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TituloDaSecao(texto: 'Mais como este', margem: margem),
        _FileiraTv(
          altura: _altura + CartaoTv.alturaDoTexto(context, tema),
          margem: margem,
          quantos: itens.length,
          cartao: (context, i) {
            final item = itens[i];
            final nota = item.nota;
            return CartaoTv(
              largura: _largura,
              alturaDaArte: _altura,
              titulo: item.titulo,
              arte: item.arte,
              legenda: nota == null ? null : '★ $nota',
              progresso: item.progresso,
              aoTocar: item.aoTocar,
            );
          },
        ),
      ],
    );
  }
}

/// Elenco em fotos redondas.
class _Elenco extends StatelessWidget {
  const _Elenco({required this.pessoas, required this.margem});

  final List<PessoaDoTitulo> pessoas;
  final EdgeInsets margem;

  static const double _lado = 160;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TituloDaSecao(texto: 'Elenco', margem: margem),
        _FileiraTv(
          altura: _lado + CartaoTv.alturaDoTexto(context, tema),
          margem: margem,
          quantos: pessoas.length,
          cartao: (context, i) {
            final pessoa = pessoas[i];
            return CartaoTv(
              largura: _lado,
              alturaDaArte: _lado,
              titulo: pessoa.nome,
              legenda: pessoa.papel,
              arte: pessoa.foto,
              redondo: true,
              aoTocar: pessoa.aoTocar,
            );
          },
        ),
      ],
    );
  }
}

/// Os dados técnicos em cartões focáveis (o foco chega até eles e a tela rola).
class _Info extends StatelessWidget {
  const _Info({required this.grupos, required this.titulo, required this.margem});

  final List<GrupoDeInfo> grupos;
  final String titulo;
  final EdgeInsets margem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TituloDaSecao(texto: titulo, margem: margem),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: margem.left),
          child: Wrap(
            spacing: Forma.espaco6,
            runSpacing: Forma.espaco6,
            children: [for (final grupo in grupos) _CartaoDeInfo(grupo: grupo)],
          ),
        ),
      ],
    );
  }
}

class _CartaoDeInfo extends StatefulWidget {
  const _CartaoDeInfo({required this.grupo});

  final GrupoDeInfo grupo;

  @override
  State<_CartaoDeInfo> createState() => _CartaoDeInfoState();
}

class _CartaoDeInfoState extends State<_CartaoDeInfo> {
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final grupo = widget.grupo;
    final icone = grupo.icone;
    final estilo = tvTexto(Tipo.pequeno(tema));
    return Semantics(
      label: [grupo.titulo, for (final (nome, valor) in grupo.linhas) '$nome: $valor'].join(', '),
      container: true,
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _foco = v),
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: Movimento.tempo(context, Movimento.toque),
            curve: Movimento.entra,
            width: 520,
            padding: const EdgeInsets.all(Forma.espaco6),
            decoration: ShapeDecoration(
              color: tema.superficie,
              shape: Forma.superelipse(
                Forma.raioGrande,
                lado: _foco ? BorderSide(color: tema.foco, width: Forma.anelDeFoco) : BorderSide.none,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icone != null) ...[
                      Icon(icone, size: 32, color: tema.texto2),
                      const SizedBox(width: Forma.espaco3),
                    ],
                    Expanded(
                      child: Text(
                        grupo.titulo,
                        style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Forma.espaco3),
                for (final (nome, valor) in grupo.linhas)
                  Padding(
                    padding: const EdgeInsets.only(top: Forma.espaco1),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$nome  ',
                            style: estilo.copyWith(color: tema.texto2),
                          ),
                          TextSpan(
                            text: valor,
                            style: estilo.copyWith(color: tema.texto),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O servidor não respondeu tudo: aviso e "Tentar de novo".
class _Falha extends StatelessWidget {
  const _Falha({required this.margem, this.aoTentar});

  final EdgeInsets margem;
  final VoidCallback? aoTentar;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(margem.left, HeisucaBase.espaco8, margem.right, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Não deu para carregar tudo deste título.',
            style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto2),
          ),
          const SizedBox(height: Forma.espaco4),
          BotaoTv(rotulo: 'Tentar de novo', icone: Symbols.refresh_rounded, aoTocar: aoTentar),
        ],
      ),
    );
  }
}
