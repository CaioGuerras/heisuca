import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/cabecalho_de_fileira.dart';
import 'package:heisuca/design/componentes/toque.dart';
import 'package:heisuca/design/tema.dart';

import 'apoio.dart';

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: título na cor do texto e "Ver tudo" discreto', (tester) async {
      await tester.pumpWidget(
        naTela(
          tema: tema,
          CabecalhoDeFileira(titulo: 'Animes', aoVerTudo: () {}),
        ),
      );
      expect(tester.widget<Text>(find.text('Animes')).style!.color, tema.texto);
      expect(tester.widget<Text>(find.text('Ver tudo')).style!.color, tema.texto2);
    });
  }

  testWidgets('sem ação, "Ver tudo" não aparece', (tester) async {
    await tester.pumpWidget(naTela(const CabecalhoDeFileira(titulo: 'Em breve')));
    expect(find.text('Ver tudo'), findsNothing);
    expect(find.byType(Toque), findsNothing);
  });

  testWidgets('"Ver tudo" tem área de toque de 48 e chama a ação', (tester) async {
    var toques = 0;
    await tester.pumpWidget(naTela(CabecalhoDeFileira(titulo: 'Filmes', aoVerTudo: () => toques++)));
    final area = tester.getSize(find.byType(Toque));
    expect(area.height, greaterThanOrEqualTo(48));
    expect(area.width, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(Toque));
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('teclado: o foco chega em "Ver tudo" e Enter aciona', (tester) async {
    var toques = 0;
    await tester.pumpWidget(naTela(CabecalhoDeFileira(titulo: 'Filmes', aoVerTudo: () => toques++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('leitor de tela: o título é cabeçalho e o botão diz de qual fileira é', (tester) async {
    final leitor = tester.ensureSemantics();
    await tester.pumpWidget(naTela(CabecalhoDeFileira(titulo: 'Animes', aoVerTudo: () {})));
    expect(tester.getSemantics(find.text('Animes')).flagsCollection.isHeader, isTrue);
    expect(find.bySemanticsLabel('Ver tudo de Animes'), findsOneWidget);
    leitor.dispose();
  });

  testWidgets('letra grande: título longo corta em vez de estourar', (tester) async {
    await tester.pumpWidget(
      naTela(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SizedBox(
            width: 320,
            child: CabecalhoDeFileira(titulo: 'Chegaram em Documentários e Especiais de TV', aoVerTudo: () {}),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
