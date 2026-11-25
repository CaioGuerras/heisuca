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
}
