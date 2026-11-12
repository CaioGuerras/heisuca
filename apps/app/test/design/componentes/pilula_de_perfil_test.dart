import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/pilula_de_perfil.dart';
import 'package:heisuca/design/tema.dart';

import 'apoio.dart';

const _avatar = ColoredBox(key: Key('avatar'), color: Color(0xFF336699));

/// A cor de fundo da pílula (o `Toque` tem a sua caixa, a do anel de foco, que não tem cor).
Color _fundo(WidgetTester tester) {
  final caixas = tester.widgetList<DecoratedBox>(
    find.descendant(of: find.byType(PilulaDePerfil), matching: find.byType(DecoratedBox)),
  );
  return caixas.map((caixa) => (caixa.decoration as ShapeDecoration).color).whereType<Color>().single;
}

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: o nome se lê sobre a pílula, no fundo e sobre a arte', (tester) async {
      await tester.pumpWidget(
        naTela(
          PilulaDePerfil(nome: 'Isis', avatar: _avatar, aoTocar: () {}),
          tema: tema,
        ),
      );
      final texto = tester.widget<Text>(find.text('Isis')).style!.color!;
      expect(_fundo(tester), tema.superficie);
      expect(TemaHeisuca.contraste(texto, tema.superficie), greaterThanOrEqualTo(4.5));

      await tester.pumpWidget(
        naTela(
          PilulaDePerfil(nome: 'Isis', avatar: _avatar, sobreArte: true, aoTocar: () {}),
          tema: tema,
        ),
      );
      expect(_fundo(tester).a, closeTo(0.72, 0.001));
    });
  }

  testWidgets('tem 48 de toque, mostra o avatar em círculo e tocar abre', (tester) async {
    var toques = 0;
    await tester.pumpWidget(naTela(PilulaDePerfil(nome: 'Heitor', avatar: _avatar, aoTocar: () => toques++)));
    final pilula = tester.getSize(find.byType(PilulaDePerfil));
    expect(pilula.height, 48);
    expect(pilula.width, greaterThan(48));
    expect(tester.getSize(find.byKey(const Key('avatar'))), const Size(36, 36));
    expect(find.ancestor(of: find.byKey(const Key('avatar')), matching: find.byType(ClipOval)), findsOneWidget);
    await tester.tap(find.byType(PilulaDePerfil));
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('leitor de tela: um botão só, "Você" e o nome', (tester) async {
    final alca = tester.ensureSemantics();
    await tester.pumpWidget(naTela(PilulaDePerfil(nome: ' Isis ', avatar: _avatar, aoTocar: () {})));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Você, Isis')),
      isSemantics(label: 'Você, Isis', isButton: true, hasTapAction: true),
    );
    // O nome visível não vira um segundo nó para o leitor.
    expect(find.bySemanticsLabel('Isis'), findsNothing);
    alca.dispose();
  });

  testWidgets('sem avatar mostra a inicial; sem nome, só o ícone e o rótulo "Você"', (tester) async {
    final alca = tester.ensureSemantics();
    await tester.pumpWidget(naTela(PilulaDePerfil(nome: 'ágata', aoTocar: () {})));
    expect(find.text('Á'), findsOneWidget);
    expect(find.text('ágata'), findsOneWidget);

    await tester.pumpWidget(naTela(PilulaDePerfil(nome: '', aoTocar: () {})));
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Você'), findsOneWidget);
    expect(tester.getSize(find.byType(PilulaDePerfil)), const Size(48, 48));
    alca.dispose();
  });

  testWidgets('só o avatar: a pílula vira um círculo de 48 e o leitor de tela ainda diz o nome', (tester) async {
    final alca = tester.ensureSemantics();
    await tester.pumpWidget(naTela(PilulaDePerfil(nome: 'Isis', soAvatar: true, aoTocar: () {})));
    expect(tester.getSize(find.byType(PilulaDePerfil)), const Size(48, 48));
    expect(find.text('Isis'), findsNothing);
    expect(find.text('I'), findsOneWidget);
    expect(find.bySemanticsLabel('Você, Isis'), findsOneWidget);
    alca.dispose();
  });

  testWidgets('nome comprido ganha reticências e a pílula não passa da largura máxima', (tester) async {
    await tester.pumpWidget(
      naTela(PilulaDePerfil(nome: 'Maria Antonieta das Neves de Albuquerque', avatar: _avatar, aoTocar: () {})),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PilulaDePerfil)).width, PilulaDePerfil.larguraMaxima);
    final nome = tester.widget<Text>(find.textContaining('Maria'));
    expect(nome.maxLines, 1);
    expect(nome.overflow, TextOverflow.ellipsis);
  });

  testWidgets('letra em 200% numa tela de 320 dp: a pílula cresce sem estourar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaHeisuca.hisui.paraMaterial(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: PilulaDePerfil(nome: 'Caio Guerras', avatar: _avatar, aoTocar: () {}),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final pilula = tester.getSize(find.byType(PilulaDePerfil));
    expect(pilula.height, greaterThanOrEqualTo(48));
    expect(pilula.width, lessThanOrEqualTo(PilulaDePerfil.larguraMaxima));
    // O avatar não cresce com a letra: quem cresce é o nome.
    expect(tester.getSize(find.byKey(const Key('avatar'))), const Size(36, 36));
  });

  testWidgets('teclado: Tab chega na pílula e Enter abre', (tester) async {
    var toques = 0;
    await tester.pumpWidget(naTela(PilulaDePerfil(nome: 'Isis', avatar: _avatar, aoTocar: () => toques++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('com "remover animações" o toque responde e nada fica pendente', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      naTela(PilulaDePerfil(nome: 'Isis', avatar: _avatar, aoTocar: () => toques++), semAnimacao: true),
    );
    await tester.tap(find.byType(PilulaDePerfil));
    await tester.pump();
    expect(toques, 1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem ação, a pílula não responde nem se anuncia como tocável', (tester) async {
    final alca = tester.ensureSemantics();
    await tester.pumpWidget(naTela(const PilulaDePerfil(nome: 'Isis', avatar: _avatar, aoTocar: null)));
    expect(tester.getSemantics(find.bySemanticsLabel('Você, Isis')), isSemantics(hasTapAction: false));
    alca.dispose();
  });
}
