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

  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: título como seletor tem 48 de toque, chama a ação e mostra a seta', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        naTela(
          tema: tema,
          CabecalhoDeFileira(titulo: 'Temporada 1', aoTocarTitulo: () => toques++, iconeDoTitulo: Icons.expand_more),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('Temporada 1')).style!.color, tema.texto);
      expect(tester.widget<Icon>(find.byIcon(Icons.expand_more)).color, tema.texto2);
      expect(tester.getSize(find.byType(Toque)).height, greaterThanOrEqualTo(48));
      await tester.tap(find.text('Temporada 1'));
      await tester.pumpAndSettle();
      expect(toques, 1);
    });
  }

  testWidgets('seletor: teclado aciona, e o leitor de tela ouve cabeçalho, botão e o rótulo dado', (tester) async {
    final leitor = tester.ensureSemantics();
    var toques = 0;
    await tester.pumpWidget(
      naTela(
        CabecalhoDeFileira(
          titulo: 'Temporada 1',
          aoTocarTitulo: () => toques++,
          rotuloDoTitulo: 'Temporada 1, trocar de temporada',
          aoVerTudo: () {},
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(toques, 1, reason: 'o seletor vem antes do "Ver tudo" na ordem do foco');
    final no = tester.getSemantics(find.bySemanticsLabel('Temporada 1, trocar de temporada'));
    expect(no.flagsCollection.isButton, isTrue);
    expect(find.bySemanticsLabel('Ver tudo de Temporada 1'), findsOneWidget);
    leitor.dispose();
  });

  testWidgets('seletor com letra em 200% e nome longo: corta em vez de estourar', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      naTela(
        semAnimacao: true,
        CabecalhoDeFileira(
          titulo: 'Temporada 12: A grande travessia do deserto',
          aoTocarTitulo: () {},
          iconeDoTitulo: Icons.expand_more,
          aoVerTudo: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
