import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/movimento.dart';

void main() {
  test('os tempos formam uma escala crescente', () {
    final escala = [
      Movimento.toque,
      Movimento.troca,
      Movimento.cartao,
      Movimento.tela,
      Movimento.longe,
      Movimento.tema,
    ];
    for (var i = 1; i < escala.length; i++) {
      expect(escala[i], greaterThan(escala[i - 1]));
    }
  });

  test('com menos movimento, nenhum tempo passa do esmaecido', () {
    expect(Movimento.tempoPara(Movimento.longe, reduzido: true), Movimento.troca);
    expect(Movimento.tempoPara(Movimento.tema, reduzido: true), Movimento.troca);
    expect(Movimento.tempoPara(Movimento.toque, reduzido: true), Movimento.toque);
    expect(Movimento.tempoPara(Movimento.longe, reduzido: false), Movimento.longe);
  });

  test('a escada cresce por item, tem teto e some com menos movimento', () {
    expect(Movimento.atrasoDaEscada(0, reduzido: false), Duration.zero);
    expect(Movimento.atrasoDaEscada(3, reduzido: false), Movimento.escada * 3);
    expect(Movimento.atrasoDaEscada(200, reduzido: false), Movimento.atrasoDaEscada(8, reduzido: false));
    expect(Movimento.atrasoDaEscada(3, reduzido: true), Duration.zero);
  });

  test('as molas passam um pouco do alvo e assentam em menos de 700 ms', () {
    for (final mola in [Movimento.molaRapida, Movimento.molaPadrao, Movimento.molaLenta]) {
      final sim = SpringSimulation(mola, 0, 1, 0);
      var pico = 0.0;
      for (var ms = 0; ms <= 700; ms += 4) {
        final x = sim.x(ms / 1000);
        if (x > pico) pico = x;
      }
      expect(pico, greaterThan(1.0), reason: 'mola espacial tem de ter vida');
      expect(pico, lessThan(1.12), reason: 'passar demais do alvo vira brinquedo');
      expect(sim.x(0.7), closeTo(1.0, 0.005));
    }
  });

  testWidgets('tempo() obedece ao "remover animações" do sistema', (tester) async {
    late Duration lido;
    Widget arvore({required bool semAnimacao}) => MediaQuery(
      data: MediaQueryData(disableAnimations: semAnimacao),
      child: Builder(
        builder: (context) {
          lido = Movimento.tempo(context, Movimento.longe);
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(arvore(semAnimacao: false));
    expect(lido, Movimento.longe);
    await tester.pumpWidget(arvore(semAnimacao: true));
    expect(lido, Movimento.troca);
  });

  testWidgets('comMola anima até o alvo; com menos movimento, vai direto', (tester) async {
    final controle = AnimationController.unbounded(vsync: tester);
    addTearDown(controle.dispose);

    final valores = <double>[];
    controle.addListener(() => valores.add(controle.value));
    unawaited(Movimento.comMola(controle, 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(controle.value, inExclusiveRange(0.0, 1.0), reason: 'no meio do caminho');
    await tester.pumpAndSettle();
    expect(controle.value, closeTo(1.0, 0.01));
    expect(valores.length, greaterThan(3));

    valores.clear();
    final fim = Movimento.comMola(controle, 0, reduzido: true);
    expect(controle.value, 0);
    expect(controle.isAnimating, isFalse);
    expect(valores, [0.0]);
    await fim;
  });
}
