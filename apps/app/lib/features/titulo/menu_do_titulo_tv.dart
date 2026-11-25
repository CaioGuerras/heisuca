import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/forma.dart';
import '../../focus/dpad_navigator.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../heisuca/tv/heisuca_tv_area_segura.dart';
import '../../heisuca/tv/heisuca_tv_canvas.dart';
import '../../heisuca/tv/heisuca_tv_pecas.dart';
import '../navegacao_tv/trilho_da_tv.dart';
import '../tema_da_v2.dart';

/// Ações reais do título, alcançáveis com OK longo e com o leitor de tela.
class MenuDoTituloTv extends StatelessWidget {
  const MenuDoTituloTv({
    super.key,
    required this.titulo,
    required this.aoAssistir,
    required this.aoAbrir,
    required this.aoMudarVisto,
    required this.aoMudarLista,
    required this.visto,
    required this.naLista,
    this.aoBaixar,
  });

  final String titulo;
  final VoidCallback aoAssistir;
  final VoidCallback aoAbrir;
  final VoidCallback aoMudarVisto;
  final VoidCallback aoMudarLista;
  final VoidCallback? aoBaixar;
  final bool visto;
  final bool naLista;

  @override
  Widget build(BuildContext context) {
    final tema = TrilhoDaTv.escuroDaTv(TemaHeisuca.de(context));
    VoidCallback executar(VoidCallback acao) => () {
      Navigator.of(context).pop();
      acao();
    };
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, evento) =>
          SelectKeyUpSuppressor.consumeIfSuppressed(evento) ? KeyEventResult.handled : KeyEventResult.ignored,
      child: Theme(
        data: temaDaV2(Theme.of(context), tema),
        child: Material(
          color: tema.fundo,
          child: HeisucaTvCanvas(
            child: HeisucaTvAreaSegura(
              child: Center(
                child: SizedBox(
                  width: 1100,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Forma.espaco6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: Forma.espaco6,
                      children: [
                        Semantics(header: true, child: Text(titulo, style: tvTexto(Tipo.titulo(tema)))),
                        BotaoTv(
                          rotulo: 'Assistir',
                          icone: Symbols.play_arrow_rounded,
                          principal: true,
                          autofocus: true,
                          aoTocar: executar(aoAssistir),
                        ),
                        BotaoTv(rotulo: 'Ver detalhes', icone: Symbols.info_rounded, aoTocar: executar(aoAbrir)),
                        BotaoTv(
                          rotulo: 'Já vi',
                          icone: Symbols.check_rounded,
                          selecionado: visto,
                          aoTocar: executar(aoMudarVisto),
                        ),
                        BotaoTv(
                          rotulo: 'Minha lista',
                          icone: Symbols.bookmark_rounded,
                          selecionado: naLista,
                          aoTocar: executar(aoMudarLista),
                        ),
                        if (aoBaixar != null)
                          BotaoTv(rotulo: 'Baixar', icone: Symbols.download_rounded, aoTocar: executar(aoBaixar!)),
                        BotaoTv(rotulo: 'Fechar', aoTocar: () => Navigator.of(context).pop()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
