import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/botao.dart';
import 'package:heisuca/design/componentes/toque.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/design/vibracao.dart';

import 'apoio.dart';

Color _fundoDe(WidgetTester tester, Finder dentro) {
  final caixa = tester.widget<Container>(find.descendant(of: dentro, matching: find.byType(Container)).first);
  return (caixa.decoration! as ShapeDecoration).color!;
}

/// Escala no eixo X (o eixo Z fica em 1, então o "maior eixo" não serve).
double _escalaDe(WidgetTester tester) => tester
    .widget<Transform>(find.descendant(of: find.byType(Toque), matching: find.byType(Transform)))
    .transform
    .storage[0];

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: o botão principal é neutro e o secundário usa a superfície', (tester) async {
      await tester.pumpWidget(
        naTela(
          tema: tema,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Botao(key: const Key('p'), rotulo: 'Assistir', aoTocar: () {}),
              Botao(key: const Key('s'), rotulo: 'Trailer', tipo: TipoDeBotao.secundario, aoTocar: () {}),
            ],
          ),
        ),
      );
      expect(_fundoDe(tester, find.byKey(const Key('p'))), tema.botaoFundo);
      expect(_fundoDe(tester, find.byKey(const Key('p'))), isNot(tema.acento));
      expect(_fundoDe(tester, find.byKey(const Key('s'))), tema.superficie2);
      expect(tester.widget<Text>(find.text('Assistir')).style!.color, tema.botaoTexto);
    });
  }

  testWidgets('área de toque de pelo menos 48 e toque chama a ação', (tester) async {
    var toques = 0;
    await tester.pumpWidget(naTela(Botao(rotulo: 'Ok', aoTocar: () => toques++)));
    final tamanho = tester.getSize(find.byType(Botao));
    expect(tamanho.height, greaterThanOrEqualTo(48));
    expect(tamanho.width, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(Botao));
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('apertar encolhe com mola e soltar volta ao tamanho', (tester) async {
    await tester.pumpWidget(naTela(Botao(rotulo: 'Assistir', aoTocar: () {})));
    final gesto = await tester.startGesture(tester.getCenter(find.byType(Botao)));
    await tester.pump(const Duration(milliseconds: 150)); // o toque só "desce" depois da espera do gesto
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_escalaDe(tester), closeTo(0.96, 0.01));
    await gesto.up();
    await tester.pumpAndSettle();
    expect(_escalaDe(tester), closeTo(1, 0.001));
  });

  testWidgets('com "remover animações" o botão não encolhe: só esmaece', (tester) async {
    await tester.pumpWidget(naTela(semAnimacao: true, Botao(rotulo: 'Assistir', aoTocar: () {})));
    final gesto = await tester.startGesture(tester.getCenter(find.byType(Botao)));
    await tester.pump(const Duration(milliseconds: 150)); // o toque só "desce" depois da espera do gesto
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_escalaDe(tester), 1);
    final opaco = tester.widget<AnimatedOpacity>(
      find.descendant(of: find.byType(Toque), matching: find.byType(AnimatedOpacity)),
    );
    expect(opaco.opacity, Toque.opacidadeApertado);
    await gesto.up();
    await tester.pumpAndSettle();
  });

  testWidgets('sem ação o botão fica apagado e não responde', (tester) async {
    await tester.pumpWidget(naTela(const Botao(rotulo: 'Baixar', aoTocar: null)));
    final opaco = tester.widget<AnimatedOpacity>(
      find.descendant(of: find.byType(Toque), matching: find.byType(AnimatedOpacity)),
    );
    expect(opaco.opacity, Toque.opacidadeInativo);
    final no = tester.getSemantics(find.byType(Toque));
    expect(no.flagsCollection.isEnabled, isNot(Tristate.isTrue));
    await tester.tap(find.byType(Botao));
    await tester.pumpAndSettle();
  });

  testWidgets('teclado: Enter ativa o botão em foco e o toque aceito vibra', (tester) async {
    final chamadas = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (chamada) async {
      if (chamada.method == 'HapticFeedback.vibrate') chamadas.add('${chamada.arguments}');
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    var toques = 0;
    await tester.pumpWidget(naTela(Botao(rotulo: 'Assistir', vibracao: Vibracao.confirmar, aoTocar: () => toques++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(toques, 1);
    expect(chamadas, ['HapticFeedbackType.mediumImpact']);
  });

  testWidgets('teclado: espaço e o botão central do controle também ativam', (tester) async {
    var toques = 0;
    await tester.pumpWidget(naTela(Botao(rotulo: 'Assistir', aoTocar: () => toques++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(toques, 2);
  });

  testWidgets('botão que perde a ação com o dedo em cima volta ao tamanho', (tester) async {
    await tester.pumpWidget(naTela(Botao(rotulo: 'Baixar', aoTocar: () {})));
    final gesto = await tester.startGesture(tester.getCenter(find.byType(Botao)));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_escalaDe(tester), closeTo(0.96, 0.01));
    await tester.pumpWidget(naTela(const Botao(rotulo: 'Baixar', aoTocar: null)));
    await tester.pumpAndSettle();
    expect(_escalaDe(tester), closeTo(1, 0.001));
    await gesto.up();
    await tester.pumpAndSettle();
    expect(_escalaDe(tester), closeTo(1, 0.001));
  });

  testWidgets('o botão de ícone tem nome para o leitor de tela', (tester) async {
    final alca = tester.ensureSemantics();
    var toques = 0;
    await tester.pumpWidget(
      naTela(BotaoDeIcone(icone: Icons.search, rotulo: 'Buscar', sobreArte: true, aoTocar: () => toques++)),
    );
    expect(find.bySemanticsLabel('Buscar'), findsOneWidget);
    expect(tester.getSize(find.byType(BotaoDeIcone)), const Size(48, 48));
    await tester.tap(find.byType(BotaoDeIcone));
    await tester.pumpAndSettle();
    expect(toques, 1);
    alca.dispose();
  });
}
