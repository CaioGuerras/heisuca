import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/componentes/paginacao.dart';
import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../design/vibracao.dart';
import '../meta_do_titulo.dart';
import 'modelo.dart';

/// O destaque no topo do Início: a arte sobe até a barra de status e se desfaz no fundo.
///
/// A página troca **só pelo dedo** (não há troca sozinha). Tocar abre o título; quem
/// toca o vídeo é o botão "Assistir".
class Destaque extends StatefulWidget {
  const Destaque({super.key, required this.titulos, required this.altura, this.aoMudar});

  final List<TituloEmDestaque> titulos;
  final double altura;

  /// Avisa qual título ficou à frente (a tela usa para tingir o fundo).
  final ValueChanged<int>? aoMudar;

  /// Fração da altura que a arte ocupa; o resto é o bloco de texto sobre o fundo.
  static const double fracaoDaArte = 0.82;

  /// Onde a arte começa a se desfazer, em fração da própria altura.
  static const double inicioDoEsmaecer = 0.52;

  @override
  State<Destaque> createState() => _DestaqueState();
}

class _DestaqueState extends State<Destaque> {
  final _paginas = PageController();
  int _atual = 0;

  @override
  void didUpdateWidget(Destaque antigo) {
    super.didUpdateWidget(antigo);
    // A lista pode encolher numa atualização: volta para o primeiro em vez de mostrar página vazia.
    if (_atual >= widget.titulos.length && widget.titulos.isNotEmpty) {
      _atual = 0;
      if (_paginas.hasClients) _paginas.jumpToPage(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.aoMudar?.call(0);
      });
    }
  }

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  void _mudou(int indice) {
    if (indice == _atual) return;
    setState(() => _atual = indice);
    Vibracao.alternar.tocar();
    widget.aoMudar?.call(indice);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.titulos.isEmpty) return SizedBox(height: widget.altura);
    return SizedBox(
      height: widget.altura,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _paginas,
              itemCount: widget.titulos.length,
              onPageChanged: _mudou,
              itemBuilder: (context, i) => _Pagina(key: ValueKey(widget.titulos[i].chave), titulo: widget.titulos[i]),
            ),
          ),
          SizedBox(
            height: Forma.espaco6,
            child: Center(
              child: Paginacao(total: widget.titulos.length, atual: _atual),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagina extends StatelessWidget {
  const _Pagina({super.key, required this.titulo});

  final TituloEmDestaque titulo;

  static const double _alturaDoLogo = 64;
  static const double _larguraDoLogo = 0.58;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final rotulo = [
      titulo.titulo,
      ...MetaDoTitulo.rotulos(
        nota: titulo.nota,
        anos: titulo.anos,
        generos: titulo.generos,
        classificacao: titulo.classificacao,
      ),
    ].join(', ');

    return LayoutBuilder(
      builder: (context, limites) {
        final largura = limites.maxWidth;
        final alturaDaArte = limites.maxHeight * Destaque.fracaoDaArte;
        final tamanhoDoLogo = Size(largura * _larguraDoLogo, _alturaDoLogo);
        final semLogo = Text(
          titulo.titulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Tipo.titulo(tema),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // Arte e textos são uma área só de toque: abrir o título.
            Toque(
              forma: const RoundedRectangleBorder(),
              escala: 1,
              rotulo: rotulo,
              excluirSemantica: true,
              aoTocar: titulo.aoAbrir,
              aoSegurar: titulo.aoSegurar,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (titulo.arte != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: alturaDaArte,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        // Só o alfa conta: a arte se desfaz no fundo tingido da tela.
                        shaderCallback: (area) => LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, Destaque.inicioDoEsmaecer, 1],
                          colors: [tema.fundo, tema.fundo, tema.fundo.withValues(alpha: 0)],
                        ).createShader(area),
                        child: titulo.arte!(context, Size(largura, alturaDaArte)),
                      ),
                    ),
                  Positioned(
                    left: Forma.espaco6,
                    right: Forma.espaco6,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.fromSize(
                          size: tamanhoDoLogo,
                          child: titulo.logo == null
                              ? Align(alignment: Alignment.bottomCenter, child: semLogo)
                              : titulo.logo!(context, tamanhoDoLogo, Center(child: semLogo)),
                        ),
                        const SizedBox(height: Forma.espaco2),
                        MetaDoTitulo(
                          nota: titulo.nota,
                          anos: titulo.anos,
                          generos: titulo.generos,
                          classificacao: titulo.classificacao,
                        ),
                        if (titulo.sinopse != null) ...[
                          const SizedBox(height: Forma.espaco2),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '「${titulo.titulo}」 ',
                                  style: TextStyle(color: tema.texto, fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: titulo.sinopse),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Tipo.pequeno(tema),
                          ),
                        ],
                        // Lugar do botão "Assistir", que fica por cima (irmão, não filho).
                        if (titulo.aoAssistir != null) const SizedBox(height: Forma.espaco3 + Botao.altura),
                        const SizedBox(height: Forma.espaco2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (titulo.aoAssistir != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: Forma.espaco2,
                child: Center(
                  child: Semantics(
                    container: true,
                    button: true,
                    label: 'Assistir ${titulo.titulo}',
                    excludeSemantics: true,
                    onTap: titulo.aoAssistir,
                    child: Botao(
                      rotulo: 'Assistir',
                      icone: Symbols.play_arrow_rounded,
                      vibracao: Vibracao.confirmar,
                      aoTocar: titulo.aoAssistir,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
