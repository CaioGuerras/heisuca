import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/pilula_de_escolha.dart';
import 'package:heisuca/design/tema.dart';

import 'apoio.dart';

ShapeDecoration _desenho(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(of: find.byType(PilulaDeEscolha), matching: find.byType(DecoratedBox)).last,
            )
            .decoration
        as ShapeDecoration;

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: marcada fica preenchida com o texto forte; solta, só contorno e texto discreto', (
      tester,
    ) async {
      await tester.pumpWidget(
        naTela(
          tema: tema,
          PilulaDeEscolha(texto: '1-10', selecionado: true, aoTocar: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(_desenho(tester).color, tema.superficie2);
      expect(tester.widget<Text>(find.text('1-10')).style!.color, tema.texto);

      await tester.pumpWidget(
        naTela(
          tema: tema,
          PilulaDeEscolha(texto: '1-10', selecionado: false, aoTocar: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(_desenho(tester).color, isNull);
      expect((_desenho(tester).shape as StadiumBorder).side.color, tema.borda);
      expect(tester.widget<Text>(find.text('1-10')).style!.color, tema.texto2);
    });
  }

  testWidgets('a pílula desenhada tem 36 de altura e a área de toque, 48', (tester) async {
    var toques = 0;
    await tester.pumpWidget(naTela(PilulaDeEscolha(texto: 'Drama', aoTocar: () => toques++)));
    final area = tester.getSize(find.byType(PilulaDeEscolha));
    expect(area.height, greaterThanOrEqualTo(48));
    expect(area.width, greaterThanOrEqualTo(48));
    final desenho = find.descendant(of: find.byType(PilulaDeEscolha), matching: find.byType(DecoratedBox)).last;
    expect(tester.getSize(desenho).height, PilulaDeEscolha.altura);
    // O toque na borda da área, fora do desenho, também vale.
    await tester.tapAt(tester.getRect(find.byType(PilulaDeEscolha)).topCenter + const Offset(0, 2));
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('teclado: o foco chega na pílula e Enter aciona', (tester) async {
    var toques = 0;
    await tester.pumpWidget(naTela(PilulaDeEscolha(texto: 'Drama', aoTocar: () => toques++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('leitor de tela: a escolha diz o rótulo e se está marcada; sem escolha, é um botão', (tester) async {
    final alca = tester.ensureSemantics();
    await tester.pumpWidget(
      naTela(PilulaDeEscolha(texto: '1-10', rotulo: 'Episódios 1 a 10', selecionado: true, aoTocar: () {})),
    );
    final no = tester.getSemantics(find.bySemanticsLabel('Episódios 1 a 10'));
    expect(no.flagsCollection.isSelected.toBoolOrNull(), isTrue);
    expect(find.bySemanticsLabel('1-10'), findsNothing);

    await tester.pumpWidget(naTela(PilulaDeEscolha(texto: 'Drama', aoTocar: () {})));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.bySemanticsLabel('Drama')).flagsCollection.isSelected.toBoolOrNull(), isNull);
    expect(tester.getSemantics(find.bySemanticsLabel('Drama')).flagsCollection.isButton, isTrue);
    alca.dispose();
  });

  testWidgets('letra em 200% e "remover animações": a pílula cresce sem estourar', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(naTela(semAnimacao: true, PilulaDeEscolha(texto: 'Ficção científica', aoTocar: () {})));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PilulaDeEscolha)).height, greaterThan(48));
  });
}
