import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/design/tema.dart';

import 'apoio.dart';

void main() {
  testWidgets('proporções: pôster 2:3 e paisagem 16:9', (tester) async {
    await tester.pumpWidget(
      naTela(
        const Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Cartao(key: Key('p'), titulo: 'InuYasha', largura: 120),
            Cartao(key: Key('q'), titulo: 'One Piece', largura: 160, formato: FormatoDoCartao.paisagem),
          ],
        ),
      ),
    );
    Size quadro(String chave) =>
        tester.getSize(find.descendant(of: find.byKey(Key(chave)), matching: find.byType(AspectRatio)));
    expect(quadro('p'), const Size(120, 180));
    expect(quadro('q'), const Size(160, 90));
  });

  testWidgets('sem arte o cartão aparece na cor do pôster; sem cor, na superfície do tema', (tester) async {
    const cor = Color(0xFF7A3B2E);
    await tester.pumpWidget(
      naTela(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Cartao(key: Key('a'), titulo: 'A', largura: 100, corDoPoster: cor),
            Cartao(key: Key('b'), titulo: 'B', largura: 100),
          ],
        ),
      ),
    );
    Color fundo(String chave) => tester
        .widget<ColoredBox>(find.descendant(of: find.byKey(Key(chave)), matching: find.byType(ColoredBox)).first)
        .color;
    expect(fundo('a'), cor);
    expect(fundo('b'), TemaHeisuca.shikkoku.superficie2);
  });

  testWidgets('progresso desenha a barra na fração vista e limita a 0–1', (tester) async {
    await tester.pumpWidget(
      naTela(const Cartao(titulo: 'Deadwood', largura: 200, formato: FormatoDoCartao.paisagem, progresso: 0.25)),
    );
    expect(tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor, 0.25);
    await tester.pumpWidget(
      naTela(const Cartao(titulo: 'Deadwood', largura: 200, formato: FormatoDoCartao.paisagem, progresso: 7)),
    );
    expect(tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor, 1);
    await tester.pumpWidget(naTela(const Cartao(titulo: 'Deadwood', largura: 200, progresso: 0)));
    expect(find.byType(FractionallySizedBox), findsNothing);
  });

  testWidgets('título longo corta com reticências e não estoura', (tester) async {
    await tester.pumpWidget(
      naTela(
        const Cartao(
          titulo: 'DanMachi: É Errado Tentar Pegar Garotas em uma Masmorra?',
          subtitulo: 'T23:E2 · Nami no Corre! A Aventura do Reino dos Blocos',
          largura: 112,
          tempo: '10:41 / 23:35',
          progresso: 0.4,
          formato: FormatoDoCartao.paisagem,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(Cartao)).width, 112);
  });

  testWidgets('toque abre, toque longo chama o menu, e o leitor de tela ouve título e progresso', (tester) async {
    final alca = tester.ensureSemantics();
    final eventos = <String>[];
    await tester.pumpWidget(
      naTela(
        Cartao(
          titulo: 'One Piece',
          subtitulo: 'T23:E2',
          largura: 160,
          formato: FormatoDoCartao.paisagem,
          progresso: 0.5,
          aoTocar: () => eventos.add('abrir'),
          aoSegurar: () => eventos.add('menu'),
        ),
      ),
    );
    expect(find.bySemanticsLabel('One Piece, T23:E2, 50%'), findsOneWidget);
    await tester.tap(find.byType(Cartao));
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(Cartao));
    await tester.pumpAndSettle();
    expect(eventos, ['abrir', 'menu']);
    alca.dispose();
  });
}
