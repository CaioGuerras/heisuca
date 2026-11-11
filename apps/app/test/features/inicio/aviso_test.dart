import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/botao.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/inicio/aviso.dart';

import '../../design/componentes/apoio.dart';

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: título e texto nas cores do tema', (tester) async {
      await tester.pumpWidget(
        naTela(
          tema: tema,
          const Aviso(icone: Icons.cloud_off, titulo: 'Sem conexão', texto: 'Puxe para atualizar.'),
        ),
      );
      expect(tester.widget<Text>(find.text('Sem conexão')).style!.color, tema.texto);
      expect(tester.widget<Text>(find.text('Puxe para atualizar.')).style!.color, tema.texto2);
      expect(tester.widget<Icon>(find.byType(Icon)).color, tema.texto2);
    });
  }

  testWidgets('sem texto e sem ações, mostra só o ícone e o título', (tester) async {
    await tester.pumpWidget(naTela(const Aviso(icone: Icons.cloud_off, titulo: 'Sem conexão')));
    expect(find.byType(Text), findsOneWidget);
    expect(find.byType(Botao), findsNothing);
  });

  testWidgets('as ações aparecem e funcionam', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      naTela(
        Aviso(
          icone: Icons.cloud_off,
          titulo: 'Esta fonte está indisponível',
          acoes: [Botao(rotulo: 'Tentar novamente', aoTocar: () => toques++)],
        ),
      ),
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('leitor de tela: título e texto saem como uma frase só', (tester) async {
    final leitor = tester.ensureSemantics();
    await tester.pumpWidget(
      naTela(const Aviso(icone: Icons.cloud_off, titulo: 'Sem conexão', texto: 'Puxe para atualizar.')),
    );
    expect(find.bySemanticsLabel('Sem conexão\nPuxe para atualizar.'), findsOneWidget);
    leitor.dispose();
  });

  testWidgets('letra grande em tela estreita: cabe na largura (a tela que o usa é que rola)', (tester) async {
    await tester.pumpWidget(
      naTela(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SizedBox(
            width: 280,
            child: SingleChildScrollView(
              child: Aviso(
                icone: Icons.cloud_off,
                titulo: 'Não foi possível conectar ao acervo',
                texto: 'Verifique a conexão ou puxe para atualizar.',
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
