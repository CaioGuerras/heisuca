import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heisuca/design/tema.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_pecas.dart';

/// Peças da TV (`BotaoTv`, `CartaoTv`): a fileira reserva para o texto a altura que o texto ocupa de verdade, em
/// qualquer tamanho de letra, e o foco do controle chega ao cartão e ao botão.
///
/// Antes, `alturaDoTexto` fazia `fontSize × height`; o motor arredonda a linha e a coluna do episódio passava 0,4 px
/// da fileira (G1.3: "RenderFlex overflowed by 0.400 pixels").
void main() {
  Widget montar(Widget filho, {double letra = 1}) => MaterialApp(
    theme: ThemeData(extensions: const [TemaHeisuca.shikkoku]),
    home: MediaQuery(
      data: MediaQueryData(size: const Size(1920, 1080), textScaler: TextScaler.linear(letra)),
      child: Scaffold(body: filho),
    ),
  );

  for (final letra in [1.0, 1.3, 2.0]) {
    for (final comLegenda in [true, false]) {
      testWidgets('CartaoTv cabe na altura que reserva (letra ${letra * 100} %, legenda: $comLegenda)', (tester) async {
        await tester.pumpWidget(
          montar(
            Builder(
              builder: (context) {
                final tema = TemaHeisuca.de(context);
                return Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    height: 216 + CartaoTv.alturaDoTexto(context, tema, comLegenda: comLegenda),
                    child: CartaoTv(
                      largura: 384,
                      alturaDaArte: 216,
                      titulo: 'E1 · O Fim da Jornada',
                      legenda: comLegenda ? '24 min' : null,
                      progresso: 0.4,
                    ),
                  ),
                );
              },
            ),
            letra: letra,
          ),
        );
        // Um estouro de layout vira exceção no teste; nada de ClipRect escondendo.
        expect(tester.takeException(), isNull);
        final coluna = tester.getSize(find.descendant(of: find.byType(CartaoTv), matching: find.byType(Column)));
        final caixa = tester.getSize(find.ancestor(of: find.byType(CartaoTv), matching: find.byType(SizedBox)).first);
        expect(coluna.height, lessThanOrEqualTo(caixa.height));
      });
    }
  }

  testWidgets('D-pad leva o foco do botão ao cartão e o OK aciona cada um', (tester) async {
    var botao = 0;
    var cartao = 0;
    await tester.pumpWidget(
      montar(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BotaoTv(rotulo: 'Assistir', principal: true, autofocus: true, aoTocar: () => botao++),
            CartaoTv(largura: 200, alturaDaArte: 300, titulo: 'Frieren', aoTocar: () => cartao++),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(botao, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(cartao, 1);
    expect(botao, 1);
  });

  testWidgets('Sair (Ajustes e Voltar da Fire TV): o foco nasce em Cancelar; só "Sair" confirma', (tester) async {
    late BuildContext contexto;
    await tester.pumpWidget(
      montar(
        Builder(
          builder: (context) {
            contexto = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    bool? resposta;
    unawaited(ConfirmarSaidaTv.mostrar(contexto).then((v) => resposta = v));
    await tester.pumpAndSettle();
    expect(find.text('Sair do Heisuca?'), findsOneWidget);
    // OK sem querer: cai no Cancelar e o app não fecha.
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(resposta, isFalse);

    unawaited(ConfirmarSaidaTv.mostrar(contexto).then((v) => resposta = v));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(resposta, isTrue);
  });

  // Bancada da TV (25/11): "foco invisível" em todas as telas. O Semantics(excludeSemantics) por fora do detector de
  // foco apagava a marca "focado" e a ação de toque: o TalkBack e a bancada não sabiam onde estava o foco.
  testWidgets('Acessibilidade vê o foco e o toque do botão e do cartão', (tester) async {
    final semantica = tester.ensureSemantics();
    var tocou = 0;
    final noBotao = FocusNode();
    final noCartao = FocusNode();
    addTearDown(noBotao.dispose);
    addTearDown(noCartao.dispose);
    await tester.pumpWidget(
      montar(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BotaoTv(rotulo: 'Assistir', focusNode: noBotao, aoTocar: () => tocou++),
            CartaoTv(largura: 200, alturaDaArte: 300, titulo: 'Frieren', focusNode: noCartao, aoTocar: () => tocou++),
          ],
        ),
      ),
    );
    noBotao.requestFocus();
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(BotaoTv)),
      containsSemantics(label: 'Assistir', isButton: true, isFocusable: true, isFocused: true, hasTapAction: true),
    );
    noCartao.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Frieren')),
      containsSemantics(label: 'Frieren', isButton: true, isFocusable: true, isFocused: true, hasTapAction: true),
    );
    semantica.dispose();
  });
}
