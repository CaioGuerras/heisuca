import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_palette.dart';
import 'package:heisuca/design/componentes/barra_flutuante.dart';
import 'package:heisuca/design/forma.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/casca/casca.dart';

const _destinos = [
  DestinoDaBarra(icone: Icons.home_rounded, rotulo: 'Início'),
  DestinoDaBarra(icone: Icons.explore_rounded, rotulo: 'Explorar'),
  DestinoDaBarra(icone: Icons.bookmark_rounded, rotulo: 'Minha lista'),
  DestinoDaBarra(icone: Icons.download_rounded, rotulo: 'Baixados'),
];

Widget _app({
  CgflixPalette paleta = CgflixPalette.isis,
  int indice = 0,
  ValueChanged<int>? aoMudar,
  EdgeInsets recuo = EdgeInsets.zero,
  EdgeInsets teclado = EdgeInsets.zero,
  Widget corpo = const ColoredBox(key: Key('corpo'), color: Color(0x00000000)),
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(extensions: [paleta]),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: recuo, viewPadding: recuo, viewInsets: teclado),
      child: Casca(corpo: corpo, destinos: _destinos, indice: indice, aoMudar: aoMudar ?? (_) {}, desfoque: false),
    ),
  ),
);

void main() {
  for (final (paleta, tema) in [
    (CgflixPalette.isis, TemaHeisuca.shikkoku),
    (CgflixPalette.heitor, TemaHeisuca.hisui),
    (CgflixPalette.sumi, TemaHeisuca.sumi),
  ]) {
    testWidgets('${tema.nome}: a ilha usa o tema da V2 do tema escolhido no app', (tester) async {
      await tester.pumpWidget(_app(paleta: paleta));
      expect(TemaHeisuca.de(tester.element(find.text('Início'))), tema);
      // A tela de baixo continua no tema do app: só a ilha troca.
      expect(Theme.of(tester.element(find.byKey(const Key('corpo')))).extension<TemaHeisuca>(), isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a ilha flutua no pé da tela, acima da barra de gestos, e a tela passa por baixo', (tester) async {
    await tester.pumpWidget(_app(recuo: const EdgeInsets.only(bottom: 24)));
    final tela = tester.getSize(find.byType(Casca));
    final ilha = tester.getRect(find.byType(BarraFlutuante));
    expect(ilha.bottom, tela.height - 24 - Casca.folgaDaIlha);
    expect(ilha.height, BarraFlutuante.altura);
    expect(ilha.left, greaterThanOrEqualTo(Forma.espaco4));
    expect(ilha.right, lessThanOrEqualTo(tela.width - Forma.espaco4));
    expect(ilha.center.dx, tela.width / 2);
    expect(tester.getRect(find.byKey(const Key('corpo'))), Offset.zero & tela);
    expect(Casca.reserva, greaterThanOrEqualTo(BarraFlutuante.altura + Casca.folgaDaIlha));
  });

  testWidgets('em tela estreita a ilha encolhe com a tela; em tela larga para na largura máxima', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpWidget(_app());
    expect(tester.getSize(find.byType(BarraFlutuante)).width, 320 - Forma.espaco4 * 2);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(900, 640);
    await tester.pumpWidget(_app());
    expect(tester.getSize(find.byType(BarraFlutuante)).width, BarraFlutuante.larguraMaxima);
  });

  testWidgets('o toque em outro destino avisa qual; o toque no destino atual não avisa', (tester) async {
    final mudancas = <int>[];
    await tester.pumpWidget(_app(indice: 1, aoMudar: mudancas.add));
    await tester.tap(find.text('Explorar'));
    await tester.tap(find.text('Baixados'));
    expect(mudancas, [3]);
  });

  testWidgets('com o teclado aberto a ilha some e volta quando ele fecha', (tester) async {
    await tester.pumpWidget(_app(teclado: const EdgeInsets.only(bottom: 300)));
    expect(find.byType(BarraFlutuante), findsNothing);
    await tester.pumpWidget(_app());
    expect(find.byType(BarraFlutuante), findsOneWidget);
  });

  testWidgets('o leitor de tela encontra os quatro destinos e sabe qual está ativo', (tester) async {
    final alca = tester.ensureSemantics();
    await tester.pumpWidget(_app(indice: 2));
    for (final destino in _destinos) {
      expect(find.bySemanticsLabel(destino.rotulo), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Minha lista')),
      isSemantics(isSelected: true, hasTapAction: true),
    );
    expect(tester.getSemantics(find.bySemanticsLabel('Início')), isSemantics(isSelected: false, hasTapAction: true));
    alca.dispose();
  });

  testWidgets('letra em 200% numa tela de 320: a casca monta sem estourar', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2)),
        child: _app(),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(BarraFlutuante)).height, BarraFlutuante.altura);
  });
}
