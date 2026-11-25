import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';

/// Um destino do trilho da TV (Início, Filmes, Ajustes…).
class ItemDoTrilhoTv {
  const ItemDoTrilhoTv({
    required this.chave,
    required this.rotulo,
    required this.icone,
    required this.aoTocar,
    this.key,
  });

  /// Identifica o item: [TrilhoDaTv.selecionado] e [TrilhoDaTv.focoInicial] apontam para ela.
  final String chave;

  /// Texto do item e o que o leitor de tela anuncia.
  final String rotulo;
  final IconData icone;
  final VoidCallback aoTocar;

  /// Chave do widget do item (os testes da TV acham o item por ela).
  final Key? key;
}

/// Trilho de navegação da TV, no jeito do Google TV e do Apple TV: um painel de vidro escuro que entra pela
/// esquerda, com um véu em degradê por cima do conteúdo.
///
/// Um caminho só de foco pelos dois grupos ([destinos] e [extras]): ↑ e ↓ andam e param nas pontas; OK
/// escolhe; → e Voltar chamam [aoFechar]. Na TV vale sempre um tema escuro: o claro vira o escuro
/// equivalente (o kids mantém o acento). Com letra grande, o painel rola até o item com foco.
class TrilhoDaTv extends StatefulWidget {
  const TrilhoDaTv({
    super.key,
    required this.destinos,
    this.extras = const [],
    this.cabecalho,
    this.selecionado,
    this.focoInicial,
    required this.aoFechar,
  });

  /// Para onde ir: Início, Filmes, Séries, Animes, Buscar.
  final List<ItemDoTrilhoTv> destinos;

  /// Ações da conta e do app, abaixo de uma linha: modo infantil, retrospectiva, perfil, Ajustes.
  final List<ItemDoTrilhoTv> extras;

  /// Perfil ativo no topo (sem foco).
  final Widget? cabecalho;

  /// Chave do destino em que a pessoa está: ganha a marca de "você está aqui".
  final String? selecionado;

  /// Chave do item que recebe o foco ao abrir; sem ela, o [selecionado] ou o primeiro.
  final String? focoInicial;

  /// → ou Voltar: o trilho fecha e o foco volta ao conteúdo.
  final VoidCallback aoFechar;

  /// Largura do painel numa TV de 960 dp: um terço da tela, o resto continua à vista sob o véu.
  static const double largura = 320;

  /// Quanto o véu avança sobre o conteúdo à direita do painel.
  static const double larguraDoVeu = 160;

  /// Altura mínima de um item: acima dos 48 de toque, com folga para o crescimento do foco.
  static const double alturaDoItem = 52;

  /// O tema escuro que a TV usa no lugar de [tema].
  static TemaHeisuca escuroDaTv(TemaHeisuca tema) {
    if (tema.brilho == Brightness.dark) return tema;
    if (tema.acento == TemaHeisuca.ichigo.acento) return TemaHeisuca.ichigoNoite;
    if (tema.acento == TemaHeisuca.sorairo.acento) return TemaHeisuca.sorairoNoite;
    return TemaHeisuca.shikkoku;
  }

  @override
  State<TrilhoDaTv> createState() => _TrilhoDaTvState();
}

class _TrilhoDaTvState extends State<TrilhoDaTv> {
  final Map<String, FocusNode> _focos = {};

  List<ItemDoTrilhoTv> get _caminho => [...widget.destinos, ...widget.extras];

  FocusNode _foco(String chave) => _focos.putIfAbsent(chave, () => FocusNode(debugLabel: 'trilho-$chave'));

  String? get _chaveDoFocoInicial {
    final chaves = _caminho.map((i) => i.chave).toList();
    for (final candidata in [widget.focoInicial, widget.selecionado]) {
      if (candidata != null && chaves.contains(candidata)) return candidata;
    }
    return chaves.isEmpty ? null : chaves.first;
  }

  @override
  void didUpdateWidget(TrilhoDaTv antigo) {
    super.didUpdateWidget(antigo);
    // Item que saiu (Atualizações sem oferta, retrospectiva no kids) leva o nó junto.
    final vivas = _caminho.map((i) => i.chave).toSet();
    _focos.removeWhere((chave, no) {
      if (vivas.contains(chave)) return false;
      no.dispose();
      return true;
    });
  }

  @override
  void dispose() {
    for (final no in _focos.values) {
      no.dispose();
    }
    super.dispose();
  }

  static final _teclasDoTrilho = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.gameButtonA,
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.goBack,
  };

  void _focar(FocusNode no) {
    no.requestFocus();
    final contexto = no.context;
    if (contexto == null) return;
    // Com letra grande o painel rola; o item com foco fica sempre inteiro na tela.
    Scrollable.ensureVisible(
      contexto,
      alignment: 0.5,
      duration: Movimento.tempo(context, Movimento.toque),
      curve: Movimento.padrao,
    );
  }

  KeyEventResult _tecla(FocusNode _, KeyEvent evento) {
    final caminho = _caminho;
    final atual = caminho.indexWhere((i) => _foco(i.chave).hasFocus);
    final tecla = evento.logicalKey;
    if (atual < 0 || !_teclasDoTrilho.contains(tecla)) return KeyEventResult.ignored;
    // O trilho é dono dessas teclas enquanto tem o foco: nem o soltar chega à tela de baixo.
    if (evento is KeyUpEvent) return KeyEventResult.handled;

    if (tecla == LogicalKeyboardKey.arrowUp || tecla == LogicalKeyboardKey.arrowDown) {
      final proximo = atual + (tecla == LogicalKeyboardKey.arrowDown ? 1 : -1);
      if (proximo >= 0 && proximo < caminho.length) _focar(_foco(caminho[proximo].chave));
      return KeyEventResult.handled;
    }
    // ← não tem para onde ir: o trilho já está na borda esquerda.
    if (tecla == LogicalKeyboardKey.arrowLeft) return KeyEventResult.handled;
    // Segurar uma tecla não repete o fechar nem a escolha.
    if (evento is! KeyDownEvent) return KeyEventResult.handled;
    if (tecla == LogicalKeyboardKey.arrowRight ||
        tecla == LogicalKeyboardKey.escape ||
        tecla == LogicalKeyboardKey.goBack) {
      widget.aoFechar();
      return KeyEventResult.handled;
    }
    caminho[atual].aoTocar();
    return KeyEventResult.handled;
  }

  Widget _item(ItemDoTrilhoTv item, String? chaveInicial) => _ItemDoTrilho(
    key: item.key,
    item: item,
    foco: _foco(item.chave),
    selecionado: item.chave == widget.selecionado,
    focoInicial: item.chave == chaveInicial,
  );

  @override
  Widget build(BuildContext context) {
    final tema = TrilhoDaTv.escuroDaTv(TemaHeisuca.de(context));
    final chaveInicial = _chaveDoFocoInicial;
    final margem = Forma.margemSeguraTv;
    return Theme(
      data: Theme.of(context).copyWith(extensions: [tema]),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _tecla,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: TrilhoDaTv.largura,
              child: DecoratedBox(
                decoration: BoxDecoration(color: tema.fundo.withValues(alpha: _opacidadeDoPainel)),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(margem.left, margem.top, Forma.espaco4, margem.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.cabecalho != null) ...[widget.cabecalho!, const SizedBox(height: Forma.espaco6)],
                      for (final item in widget.destinos) _item(item, chaveInicial),
                      if (widget.extras.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Forma.espaco3, horizontal: Forma.espaco4),
                          child: SizedBox(height: 1, child: ColoredBox(color: tema.borda)),
                        ),
                        for (final item in widget.extras) _item(item, chaveInicial),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // O véu escurece a beirada do conteúdo e some em degradê: o trilho não parece uma caixa colada.
            SizedBox(
              width: TrilhoDaTv.larguraDoVeu,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tema.fundo.withValues(alpha: _opacidadeDoPainel),
                      tema.fundo.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// O painel deixa um pouco do conteúdo aparecer por trás, como vidro escuro.
  static const double _opacidadeDoPainel = 0.94;
}

class _ItemDoTrilho extends StatelessWidget {
  const _ItemDoTrilho({
    super.key,
    required this.item,
    required this.foco,
    required this.selecionado,
    required this.focoInicial,
  });

  final ItemDoTrilhoTv item;
  final FocusNode foco;
  final bool selecionado;
  final bool focoInicial;

  /// O item com foco cresce um pouco; menos que o botão do player, porque a linha é larga.
  static const double escalaComFoco = 1.04;

  /// Fundo do item em que a pessoa está, quando não tem o foco.
  static const double _opacidadeSelecionado = 0.72;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final forma = Forma.pilula();
    return ListenableBuilder(
      listenable: foco,
      builder: (context, _) {
        final comFoco = foco.hasFocus;
        final tinta = comFoco ? tema.botaoTexto : (selecionado ? tema.texto : tema.texto2);
        final fundo = comFoco
            ? tema.botaoFundo
            : selecionado
            ? tema.superficie2.withValues(alpha: _opacidadeSelecionado)
            : Colors.transparent;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: Forma.espaco1),
          child: AnimatedScale(
            // Com "remover animações", o foco aparece só pela cor.
            scale: comFoco && !Movimento.reduzido(context) ? escalaComFoco : 1,
            alignment: Alignment.centerLeft,
            duration: Movimento.tempo(context, Movimento.toque),
            curve: Movimento.padrao,
            child: Toque(
              foco: foco,
              focoInicial: focoInicial,
              forma: forma,
              rotulo: item.rotulo,
              // Só o destino atual leva estado de seleção; os outros são botões comuns para o leitor de tela.
              selecionado: selecionado ? true : null,
              excluirSemantica: true,
              aoTocar: item.aoTocar,
              child: AnimatedContainer(
                duration: Movimento.tempo(context, Movimento.toque),
                curve: Movimento.padrao,
                constraints: const BoxConstraints(minHeight: TrilhoDaTv.alturaDoItem),
                padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4, vertical: Forma.espaco2),
                decoration: ShapeDecoration(color: fundo, shape: forma),
                child: Row(
                  children: [
                    Icon(item.icone, size: _tamanhoDoIcone, color: tinta),
                    const SizedBox(width: Forma.espaco3),
                    Expanded(
                      child: Text(
                        item.rotulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Tipo.subtitulo(tema).copyWith(
                          color: tinta,
                          fontWeight: comFoco || selecionado ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    // "Você está aqui": um ponto pequeno no acento (o acento só vai em coisa pequena).
                    if (selecionado && !comFoco)
                      SizedBox.square(
                        dimension: Forma.espaco2,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(color: tema.acento, shape: const CircleBorder()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static const double _tamanhoDoIcone = 26;
}
