import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/veu_do_topo.dart';

import 'componentes/apoio.dart';

/// Lista com o véu por cima, como na Início (limite = fim do destaque) e na Explorar (limite 0).
Widget _tela({double limite = 0, TemaHeisuca tema = TemaHeisuca.shikkoku}) => naTela(
  SizedBox(
    width: 400,
    height: 600,
    child: AreaDoVeu(
      limite: limite,
      child: Stack(
        children: [
          ListView(
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(
                  height: 80,
                  // Fileira horizontal: rolar para o lado não pode acender a barra.
                  child: ListView(
                    key: ValueKey('fileira-$i'),
                    scrollDirection: Axis.horizontal,
                    children: [for (var j = 0; j < 10; j++) SizedBox(width: 120, child: Text('$i-$j'))],
                  ),
                ),
            ],
          ),
          const VeuDoTopo(),
        ],
      ),
    ),
  ),
  tema: tema,
);

double _opacidadeDaBarra(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('veu-do-topo-barra'))).opacity;

void main() {
  for (final tema in [...TemaHeisuca.todos, ...TemaHeisuca.doKids]) {
    testWidgets('barra some no topo e aparece quando o conteúdo passa por baixo (${tema.nome})', (tester) async {
      await tester.pumpWidget(_tela(tema: tema));
      expect(_opacidadeDaBarra(tester), 0);

      await tester.drag(find.byKey(const ValueKey('fileira-1')), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_opacidadeDaBarra(tester), 1);

      await tester.drag(find.byKey(const ValueKey('fileira-3')), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(_opacidadeDaBarra(tester), 0);
    });
  }

  testWidgets('na Início, a barra só aparece depois do destaque', (tester) async {
    await tester.pumpWidget(_tela(limite: 300));
    await tester.drag(find.byKey(const ValueKey('fileira-1')), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(_opacidadeDaBarra(tester), 0, reason: 'ainda sobre a arte do destaque');

    await tester.drag(find.byKey(const ValueKey('fileira-4')), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(_opacidadeDaBarra(tester), 1);
  });

  testWidgets('rolar uma fileira para o lado não acende a barra', (tester) async {
    await tester.pumpWidget(_tela());
    await tester.drag(find.byKey(const ValueKey('fileira-1')), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(_opacidadeDaBarra(tester), 0);
  });

  testWidgets('sem AreaDoVeu fica só o degradê da barra de status', (tester) async {
    await tester.pumpWidget(naTela(const SizedBox(width: 400, height: 600, child: Stack(children: [VeuDoTopo()]))));
    expect(find.byKey(const ValueKey('veu-do-topo-barra')), findsNothing);
  });

  testWidgets('a barra não recebe toque', (tester) async {
    var tocou = false;
    await tester.pumpWidget(
      naTela(
        SizedBox(
          width: 400,
          height: 600,
          child: AreaDoVeu(
            child: Stack(
              children: [
                Positioned.fill(child: GestureDetector(onTap: () => tocou = true)),
                const VeuDoTopo(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(200, 10));
    expect(tocou, isTrue);
  });
}
