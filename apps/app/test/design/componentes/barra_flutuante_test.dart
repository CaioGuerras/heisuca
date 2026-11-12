import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/barra_flutuante.dart';
import 'package:heisuca/design/tema.dart';

import 'apoio.dart';

const _destinos = [
  DestinoDaBarra(icone: Icons.home, rotulo: 'Início'),
  DestinoDaBarra(icone: Icons.explore, rotulo: 'Explorar'),
  DestinoDaBarra(icone: Icons.bookmark, rotulo: 'Minha lista'),
  DestinoDaBarra(icone: Icons.download, rotulo: 'Baixados'),
];

class _Tela extends StatefulWidget {
  const _Tela({required this.mudancas});
  final List<int> mudancas;
  @override
  State<_Tela> createState() => _TelaState();
}

class _TelaState extends State<_Tela> {
  int indice = 0;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 380,
    child: BarraFlutuante(
      destinos: _destinos,
      indice: indice,
      aoMudar: (i) {
        widget.mudancas.add(i);
        setState(() => indice = i);
      },
    ),
  );
}

/// Borda esquerda do marcador do destino ativo.
double _marcador(WidgetTester tester) =>
    tester.getTopLeft(find.descendant(of: find.byType(BarraFlutuante), matching: find.byType(Positioned)).first).dx;

void main() {
  testWidgets('quatro destinos, o ativo marcado, e tocar muda de destino', (tester) async {
    final alca = tester.ensureSemantics();
    final mudancas = <int>[];
    await tester.pumpWidget(naTela(_Tela(mudancas: mudancas)));
    for (final d in _destinos) {
      expect(find.text(d.rotulo), findsOneWidget);
    }
    expect(tester.getSemantics(find.bySemanticsLabel('Início')).flagsCollection.isSelected, Tristate.isTrue);
    expect(tester.getSemantics(find.bySemanticsLabel('Baixados')).flagsCollection.isSelected, Tristate.isFalse);

    await tester.tap(find.text('Minha lista'));
    await tester.pumpAndSettle();
    expect(mudancas, [2]);
    expect(tester.getSemantics(find.bySemanticsLabel('Minha lista')).flagsCollection.isSelected, Tristate.isTrue);

    await tester.tap(find.text('Minha lista'));
    await tester.pumpAndSettle();
    expect(mudancas, [2], reason: 'tocar no destino ativo não repete a mudança');
    alca.dispose();
  });

  testWidgets('o marcador desliza até o destino e para em cima dele', (tester) async {
    await tester.pumpWidget(naTela(_Tela(mudancas: [])));
    final inicio = _marcador(tester);
    await tester.tap(find.text('Baixados'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final meio = _marcador(tester);
    expect(meio, greaterThan(inicio));
    await tester.pumpAndSettle();
    final fim = _marcador(tester);
    expect(meio, lessThan(fim), reason: 'aos 60 ms o marcador ainda está a caminho');
    final passo = (tester.getSize(find.byType(BarraFlutuante)).width - 8) / 4;
    expect(fim - inicio, closeTo(3 * passo, 0.5));
  });

  testWidgets('com "remover animações" o marcador troca de lugar sem deslizar', (tester) async {
    await tester.pumpWidget(naTela(semAnimacao: true, _Tela(mudancas: [])));
    final inicio = _marcador(tester);
    await tester.tap(find.text('Explorar'));
    await tester.pump();
    await tester.pump();
    final passo = (tester.getSize(find.byType(BarraFlutuante)).width - 8) / 4;
    expect(_marcador(tester) - inicio, closeTo(passo, 0.5));
    await tester.pumpAndSettle();
  });

  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: rótulo ativo e inativo se leem sobre a ilha', (tester) async {
      await tester.pumpWidget(naTela(tema: tema, _Tela(mudancas: [])));
      await tester.pumpAndSettle();
      expect(TemaHeisuca.contraste(tema.texto, tema.acentoSuave), greaterThanOrEqualTo(4.5));
      expect(TemaHeisuca.contraste(tema.texto2, tema.superficie), greaterThanOrEqualTo(4.5));
      expect(tester.getSize(find.byType(BarraFlutuante)).height, BarraFlutuante.altura);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cabe em tela estreita com letra grande, sem estourar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaHeisuca.hisui.paraMaterial(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: BarraFlutuante(destinos: _destinos, indice: 1, aoMudar: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cinco destinos em 320 dp com letra em 200%: não estoura e todo destino tem 48 de toque', (tester) async {
    const cinco = [..._destinos, DestinoDaBarra(icone: Icons.person, rotulo: 'Perfil')];
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaHeisuca.shikkoku.paraMaterial(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 296,
                child: BarraFlutuante(destinos: cinco, indice: 4, aoMudar: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final barra = tester.getRect(find.byType(BarraFlutuante));
    expect(barra.width, lessThanOrEqualTo(296));
    for (final destino in cinco) {
      final alvo = tester.getRect(find.bySemanticsLabel(destino.rotulo));
      expect(alvo.height, greaterThanOrEqualTo(48), reason: destino.rotulo);
      expect(alvo.left, greaterThanOrEqualTo(barra.left - 0.5), reason: destino.rotulo);
      expect(alvo.right, lessThanOrEqualTo(barra.right + 0.5), reason: destino.rotulo);
    }
  });

  testWidgets('toque longo num destino chama o atalho dele, sem mudar de destino', (tester) async {
    final alca = tester.ensureSemantics();
    var atalhos = 0;
    final mudancas = <int>[];
    await tester.pumpWidget(
      naTela(
        SizedBox(
          width: 380,
          child: BarraFlutuante(
            destinos: [
              const DestinoDaBarra(icone: Icons.home, rotulo: 'Início'),
              DestinoDaBarra(icone: Icons.explore, rotulo: 'Explorar', aoSegurar: () => atalhos++),
            ],
            indice: 0,
            aoMudar: mudancas.add,
          ),
        ),
      ),
    );
    await tester.longPress(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(atalhos, 1);
    expect(mudancas, isEmpty);

    // Quem usa o leitor de tela alcança o mesmo atalho; o destino sem atalho não anuncia toque longo.
    expect(tester.getSemantics(find.bySemanticsLabel('Explorar')), isSemantics(hasLongPressAction: true));
    expect(tester.getSemantics(find.bySemanticsLabel('Início')), isSemantics(hasLongPressAction: false));
    alca.dispose();
  });
}
