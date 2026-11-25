import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:heisuca/features/busca/ligacao.dart';
import 'package:heisuca/features/busca/modelo.dart';
import 'package:heisuca/features/busca/tela_busca_tv.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_pecas.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/platform_detector.dart';

import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';

/// Busca da TV no desenho da V2 (reforma da TV, 25/11): antes a TV usava a busca antiga do Plezy, sem as peças da
/// TV. Agora: campo, recentes, pílulas de tipo, pessoas e pôsteres em grade, tudo pelo D-pad, e o ← na borda abre
/// o trilho.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Google TV 1080p: 960×540 dp, densidade 2.
  const tela = Size(1920, 1080);
  late HeisucaP3Fixture fixture;

  setUp(() async {
    resetSharedPreferencesForTest();
    await LocaleSettings.setLocale(AppLocale.pt);
    TvDetectionService.debugSetTvOverride(true);
    fixture = HeisucaP3Fixture();
    await fixture.initialize(settings.ThemeMode.dark);
    addTearDown(fixture.dispose);
  });

  tearDown(() => TvDetectionService.debugSetTvOverride(null));

  Future<void> montar(WidgetTester tester, Widget tela0, {double letra = 1}) async {
    tester.view.physicalSize = tela;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      fixture.wrap(
        MaterialApp(
          builder: (context, filho) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
            child: filho!,
          ),
          home: tela0,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  List<TituloDaBusca> titulos(List<String> tocados) => [
    for (final (i, nome) in ['Frieren', 'Duna', 'Akira', 'Ran'].indexed)
      TituloDaBusca(
        chave: 't$i',
        titulo: nome,
        tipo: i.isEven ? TipoDoResultado.serie : TipoDoResultado.filme,
        anos: '202$i',
        nota: '8,$i',
        aoTocar: () => tocados.add(nome),
      ),
  ];

  for (final letra in [1.0, 2.0]) {
    testWidgets('Busca vazia carrega sugestões reais e direita leva ao pôster, letra $letra', (tester) async {
      await montar(tester, const LigacaoDaBusca(naTv: true), letra: letra);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Sugestões'), findsOneWidget);
      expect(find.byType(CartaoTv), findsNWidgets(2));
      expect(find.text('Uma viagem para lembrar'), findsWidgets);
      expect(find.text('Histórias da nossa família'), findsWidgets);
      final campo = tester.widget<TextField>(find.byKey(const ValueKey('busca-tv-campo')));
      campo.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 400));
      final cartoes = tester.widgetList<CartaoTv>(find.byType(CartaoTv));
      expect(cartoes.first.focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 400));
      // D-pad chega também ao segundo pôster; não fica preso no teclado.
      final segundo = find.byType(CartaoTv).at(1);
      final contexto = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.ancestor(of: find.byElementPredicate((e) => identical(e, contexto)), matching: segundo),
        findsOneWidget,
      );
      expect(campo.focusNode!.hasFocus, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Busca vazia combina buscas recentes e sugestões na mesma coluna', (tester) async {
    final campo = TextEditingController();
    final foco = FocusNode();
    addTearDown(campo.dispose);
    addTearDown(foco.dispose);
    await montar(
      tester,
      TelaBuscaTv(campo: campo, foco: foco, recentes: const ['duna'], sugestoes: titulos([])),
      letra: 2,
    );
    expect(find.text('Buscas recentes'), findsOneWidget);
    expect(find.text('Sugestões'), findsOneWidget);
    expect(find.byType(CartaoTv), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Busca vazia offline conserva apenas a orientação', (tester) async {
    final offline = HeisucaP3Fixture(scenario: 'offline');
    await tester.runAsync(() => offline.initialize(settings.ThemeMode.dark));
    addTearDown(offline.dispose);
    fixture = offline;
    await montar(tester, const LigacaoDaBusca(naTv: true));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Sugestões'), findsNothing);
    expect(find.byType(CartaoTv), findsNothing);
    expect(find.text('Digite um filme, série ou pessoa. Os resultados aparecem aqui.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Resultados: o 1º pôster recebe o foco, o D-pad anda na grade e o OK abre', (tester) async {
    final tocados = <String>[];
    final campo = TextEditingController(text: 'a');
    final foco = FocusNode();
    final primeiro = FocusNode();
    addTearDown(campo.dispose);
    addTearDown(foco.dispose);
    addTearDown(primeiro.dispose);
    await montar(
      tester,
      TelaBuscaTv(
        campo: campo,
        foco: foco,
        titulos: titulos(tocados),
        pessoas: [PessoaDaBusca(chave: 'p1', nome: 'Hayao Miyazaki', aoTocar: () => tocados.add('pessoa'))],
        primeiroResultado: primeiro,
        buscou: true,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Filmes'), findsOneWidget);
    expect(find.text('Séries'), findsOneWidget);
    expect(find.text('Pessoas'), findsWidgets);

    primeiro.requestFocus();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(tocados, ['Frieren']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(tocados, ['Frieren', 'Duna']);

    // Os pôsteres ficam dentro da margem segura (5 %: 48 dp de cada lado em 960).
    for (final chave in ['t0', 't3']) {
      final caixa = tester.getRect(find.byKey(ValueKey('busca-tv-$chave')));
      expect(caixa.left, greaterThanOrEqualTo(48));
      expect(caixa.right, lessThanOrEqualTo(960 - 48));
    }
  });

  testWidgets('Pílula "Filmes" deixa só os filmes; "Todos" traz tudo de volta', (tester) async {
    final campo = TextEditingController(text: 'a');
    final foco = FocusNode();
    addTearDown(campo.dispose);
    addTearDown(foco.dispose);
    await montar(tester, TelaBuscaTv(campo: campo, foco: foco, titulos: titulos([]), buscou: true));
    await tester.tap(find.byKey(const ValueKey('busca-tv-filtro-filmes')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('busca-tv-t1')), findsOneWidget);
    expect(find.byKey(const ValueKey('busca-tv-t0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('busca-tv-filtro-todos')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('busca-tv-t0')), findsOneWidget);
  });

  testWidgets('← entre pôsteres só anda; passando pelo teclado chega ao trilho', (tester) async {
    var menu = 0;
    final campo = TextEditingController(text: 'a');
    final foco = FocusNode();
    final primeiro = FocusNode();
    addTearDown(campo.dispose);
    addTearDown(foco.dispose);
    addTearDown(primeiro.dispose);
    await montar(
      tester,
      TelaBuscaTv(
        campo: campo,
        foco: foco,
        titulos: titulos([]),
        primeiroResultado: primeiro,
        buscou: true,
        aoAbrirMenu: () => menu++,
      ),
    );
    primeiro.requestFocus();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 400));
    expect(menu, 0);
    expect(primeiro.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 400));
    // O teclado agora fica à esquerda dos resultados. A borda dele abre o trilho.
    for (var i = 0; i < 7 && menu == 0; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(menu, 1);
  });

  testWidgets('Sem busca: recentes em pílulas; OK escolhe e "Limpar" apaga', (tester) async {
    final escolhidos = <String>[];
    var limpou = 0;
    final campo = TextEditingController();
    final foco = FocusNode();
    addTearDown(campo.dispose);
    addTearDown(foco.dispose);
    await montar(
      tester,
      TelaBuscaTv(
        campo: campo,
        foco: foco,
        recentes: const ['frieren', 'duna'],
        aoEscolherRecente: escolhidos.add,
        aoLimparRecentes: () => limpou++,
      ),
    );
    expect(find.text('Buscas recentes'), findsOneWidget);
    await tester.tap(find.text('duna'));
    expect(escolhidos, ['duna']);
    await tester.tap(find.byKey(const ValueKey('busca-tv-limpar-recentes')));
    expect(limpou, 1);
  });

  testWidgets('Aviso toma o lugar dos resultados e o botão dele responde ao OK', (tester) async {
    var tentou = 0;
    final campo = TextEditingController(text: 'xyz');
    final foco = FocusNode();
    addTearDown(campo.dispose);
    addTearDown(foco.dispose);
    await montar(
      tester,
      TelaBuscaTv(
        campo: campo,
        foco: foco,
        buscou: true,
        aviso: AvisoTv(
          icone: Symbols.cloud_off_rounded,
          titulo: 'Nenhum servidor respondeu',
          acoes: [BotaoTv(rotulo: 'Tentar novamente', autofocus: true, aoTocar: () => tentou++)],
        ),
      ),
    );
    expect(find.text('Nenhum servidor respondeu'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(tentou, 1);
  });

  for (final letra in [1.0, 2.0]) {
    testWidgets('Nada estoura com letra ${(letra * 100).round()} %', (tester) async {
      final campo = TextEditingController(text: 'a');
      final foco = FocusNode();
      addTearDown(campo.dispose);
      addTearDown(foco.dispose);
      await montar(
        tester,
        TelaBuscaTv(
          campo: campo,
          foco: foco,
          titulos: titulos([]),
          pessoas: const [PessoaDaBusca(chave: 'p1', nome: 'Hayao Miyazaki')],
          buscou: true,
        ),
        letra: letra,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
