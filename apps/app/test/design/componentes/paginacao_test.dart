import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/paginacao.dart';
import 'package:heisuca/design/movimento.dart';
import 'package:heisuca/design/tema.dart';

import 'apoio.dart';

List<AnimatedContainer> _pontos(WidgetTester tester) =>
    tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).toList();

Color _corDe(AnimatedContainer ponto) => (ponto.decoration! as ShapeDecoration).color!;

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: um ponto por página, e o atual é mais largo e mais forte', (tester) async {
      await tester.pumpWidget(naTela(tema: tema, const Paginacao(total: 4, atual: 1)));
      final pontos = _pontos(tester);
      expect(pontos, hasLength(4));
      final larguras = [for (final ponto in pontos) ponto.constraints!.maxWidth];
      expect(larguras[1], greaterThan(larguras[0]));
      expect(larguras[0], larguras[2]);
      expect(_corDe(pontos[1]), tema.texto);
      expect(_corDe(pontos[0]).a, lessThan(_corDe(pontos[1]).a));
    });
  }

  testWidgets('com uma página só, não aparece', (tester) async {
    await tester.pumpWidget(naTela(const Paginacao(total: 1, atual: 0)));
    expect(find.byType(AnimatedContainer), findsNothing);
    expect(tester.getSize(find.byType(Paginacao)), Size.zero);
  });

  testWidgets('índice fora da faixa não quebra: fica no último', (tester) async {
    await tester.pumpWidget(naTela(const Paginacao(total: 3, atual: 9)));
    final larguras = [for (final ponto in _pontos(tester)) ponto.constraints!.maxWidth];
    expect(larguras[2], greaterThan(larguras[1]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('leitor de tela: lê a posição, não os pontos', (tester) async {
    final leitor = tester.ensureSemantics();
    await tester.pumpWidget(naTela(const Paginacao(total: 5, atual: 2)));
    expect(find.bySemanticsLabel('Destaque 3 de 5'), findsOneWidget);
    leitor.dispose();
  });

  testWidgets('com "remover animações", a troca não passa do tempo curto', (tester) async {
    await tester.pumpWidget(naTela(semAnimacao: true, const Paginacao(total: 3, atual: 0)));
    expect(_pontos(tester).first.duration, lessThanOrEqualTo(Movimento.troca));
  });
}
