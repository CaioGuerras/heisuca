import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/meta_do_titulo.dart';

import '../design/componentes/apoio.dart';

void main() {
  testWidgets('mostra nota, anos, gêneros e classificação nos três temas; o selo não leva ponto', (tester) async {
    for (final tema in TemaHeisuca.todos) {
      await tester.pumpWidget(
        naTela(
          tema: tema,
          const MetaDoTitulo(nota: '8,6', anos: '2001', generos: 'Animação', classificacao: 'L'),
        ),
      );
      // A troca de tema é animada: a cor nova só vale no fim.
      await tester.pumpAndSettle();
      for (final texto in ['8,6', '2001', 'Animação', 'L']) {
        expect(find.text(texto), findsOneWidget, reason: tema.nome);
      }
      expect(find.text('·'), findsNWidgets(2), reason: 'ponto só entre os textos');
      expect(tester.widget<Icon>(find.byType(Icon)).color, tema.acento);
    }
  });

  testWidgets('o que falta não aparece, nem o ponto dele', (tester) async {
    await tester.pumpWidget(naTela(const MetaDoTitulo(anos: '1988')));
    expect(find.text('1988'), findsOneWidget);
    expect(find.text('·'), findsNothing);
    expect(find.byType(Icon), findsNothing);

    await tester.pumpWidget(naTela(const MetaDoTitulo()));
    expect(tester.getSize(find.byType(MetaDoTitulo)), Size.zero);
  });

  testWidgets('lugar estreito e letra em 200%: o que não cabe desce de linha, sem estourar', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      naTela(
        const SizedBox(
          width: 280,
          child: MetaDoTitulo(nota: '7,1', anos: '2004 – 2006', generos: 'Faroeste, Crime, Drama', classificacao: '16'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MetaDoTitulo)).width, lessThanOrEqualTo(280));
    expect(tester.getTopLeft(find.text('16')).dy, greaterThan(tester.getTopLeft(find.text('7,1')).dy));
  });

  test('o leitor de tela recebe os dados por extenso', () {
    expect(MetaDoTitulo.rotulos(nota: '8,6', anos: '2001', classificacao: 'L'), [
      'nota 8,6',
      '2001',
      'classificação L',
    ]);
    expect(MetaDoTitulo.rotulos(), isEmpty);
  });
}
