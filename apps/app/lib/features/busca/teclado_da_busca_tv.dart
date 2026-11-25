import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/key_event_utils.dart';
import '../../heisuca/tv/heisuca_tv_pecas.dart';

/// Teclado integrado: o campo aceita teclado físico sem abrir outro editor sobre os resultados.
/// Cada tecla usa o botão da TV, com foco real e ação anunciada ao leitor de tela.
class TecladoDaBuscaTv extends StatefulWidget {
  const TecladoDaBuscaTv({
    super.key,
    required this.campo,
    required this.foco,
    this.aoEnviar,
    this.aoVoltar,
    this.aoSairDireita,
  });

  final TextEditingController campo;
  final FocusNode foco;
  final VoidCallback? aoEnviar;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoSairDireita;

  @override
  State<TecladoDaBuscaTv> createState() => _TecladoDaBuscaTvState();
}

class _TecladoDaBuscaTvState extends State<TecladoDaBuscaTv> {
  final _primeiraTecla = FocusNode(debugLabel: 'BuscaTvTeclaA');

  @override
  void dispose() {
    _primeiraTecla.dispose();
    super.dispose();
  }

  void _inserir(String texto) {
    final valor = widget.campo.value;
    final selecao = valor.selection;
    final inicio = selecao.isValid ? selecao.start : valor.text.length;
    final fim = selecao.isValid ? selecao.end : valor.text.length;
    widget.campo.value = TextEditingValue(
      text: valor.text.replaceRange(inicio, fim, texto),
      selection: TextSelection.collapsed(offset: inicio + texto.length),
    );
  }

  void _apagar() {
    final valor = widget.campo.value;
    final selecao = valor.selection;
    final fim = selecao.isValid ? selecao.end : valor.text.length;
    final inicio = selecao.isValid ? selecao.start : fim;
    if (inicio == 0 && fim == 0) return;
    final trecho = expandToGraphemeRange(valor.text, TextRange(start: inicio == fim ? inicio - 1 : inicio, end: fim));
    widget.campo.value = TextEditingValue(
      text: valor.text.replaceRange(trecho.start, trecho.end, ''),
      selection: TextSelection.collapsed(offset: trecho.start),
    );
  }

  KeyEventResult _tecla(FocusNode _, KeyEvent evento) {
    if (evento.logicalKey.isBackKey) return handleBackKeyAction(evento, () => widget.aoVoltar?.call());
    if (evento is! KeyDownEvent && evento is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (evento.logicalKey == LogicalKeyboardKey.backspace) {
      _apagar();
      return KeyEventResult.handled;
    }
    if (evento.isPhysicalKeyboardEnter) {
      widget.aoEnviar?.call();
      return KeyEventResult.handled;
    }
    final caractere = evento.character;
    if (caractere != null && caractere.isNotEmpty && !evento.logicalKey.isReservedControlKey) {
      _inserir(caractere);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final estilo = tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto);
    OutlineInputBorder borda(BorderSide lado) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(Forma.raioGrande), borderSide: lado);
    return Focus(
      canRequestFocus: false,
      onKeyEvent: _tecla,
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.all(Forma.espaco4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Focus(
              canRequestFocus: false,
              onKeyEvent: (_, evento) {
                if (evento.logicalKey == LogicalKeyboardKey.arrowRight && widget.aoSairDireita != null) {
                  if (evento is KeyDownEvent) widget.aoSairDireita!();
                  return KeyEventResult.handled;
                }
                if (!evento.isTvSelectEvent) return KeyEventResult.ignored;
                return handleOneShotSelect(evento, _primeiraTecla.requestFocus);
              },
              child: TextField(
                key: const ValueKey('busca-tv-campo'),
                controller: widget.campo,
                focusNode: widget.foco,
                readOnly: true,
                showCursor: true,
                onTap: _primeiraTecla.requestFocus,
                style: estilo,
                decoration: InputDecoration(
                  hintText: 'Buscar filmes, séries e pessoas',
                  hintStyle: estilo.copyWith(color: tema.texto2),
                  filled: true,
                  fillColor: tema.superficie2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: Forma.espaco6, vertical: Forma.espaco6),
                  border: borda(BorderSide.none),
                  enabledBorder: borda(BorderSide.none),
                  focusedBorder: borda(BorderSide(color: tema.foco, width: Forma.anelDeFoco)),
                ),
              ),
            ),
            const SizedBox(height: Forma.espaco6),
            LayoutBuilder(
              builder: (context, limites) {
                const colunas = 6;
                final largura = (limites.maxWidth - Forma.espaco4 * (colunas - 1)) / colunas;
                return Wrap(
                  spacing: Forma.espaco4,
                  runSpacing: Forma.espaco4,
                  children: [
                    for (final letra in 'abcdefghijklmnopqrstuvwxyz0123456789'.split(''))
                      SizedBox(
                        width: largura,
                        child: BotaoTv(
                          rotulo: letra,
                          compacto: true,
                          focusNode: letra == 'a' ? _primeiraTecla : null,
                          aoTocar: () => _inserir(letra),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: Forma.espaco4),
            Wrap(
              spacing: Forma.espaco4,
              runSpacing: Forma.espaco4,
              children: [
                BotaoTv(rotulo: 'Espaço', compacto: true, aoTocar: () => _inserir(' ')),
                BotaoTv(rotulo: 'Apagar', compacto: true, icone: Symbols.backspace_rounded, aoTocar: _apagar),
                BotaoTv(rotulo: 'Limpar', compacto: true, aoTocar: widget.campo.clear),
                BotaoTv(rotulo: 'Buscar', compacto: true, principal: true, aoTocar: widget.aoEnviar),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
