import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heisuca/features/explorar/modelo.dart';
import 'package:heisuca/features/explorar/tela_explorar_tv.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/platform_detector.dart';

import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';

/// Biblioteca da TV (Filmes, Séries, Animes) no desenho da V2 (reforma da TV, 25/11): antes a TV usava a tela de
/// bibliotecas antiga do Plezy. Agora: pílulas de biblioteca, gêneros, "Não vistos" e ordem; grade de pôsteres que
/// pede a próxima página perto do fim; tudo pelo D-pad, ← na borda abre o trilho.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HeisucaP3Fixture fixture;

  setUp(() async {
    resetSharedPreferencesForTest();
    await LocaleSettings.setLocale(AppLocale.pt);
    TvDetectionService.debugSetTvOverride(true);
    fixture = HeisucaP3Fixture();
    await fixture.initialize(settings.ThemeMode.dark);
  });

  tearDown(() => TvDetectionService.debugSetTvOverride(null));

  Future<void> montar(WidgetTester tester, Widget tela, {double letra = 1}) async {
    // Google TV 1080p: 960×540 dp, densidade 2.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      fixture.wrap(
        MaterialApp(
          builder: (context, filho) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
            child: filho!,
          ),
          home: tela,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  List<ItemDoExplorar> itens(int quantos, List<String> tocados) => [
    for (var i = 0; i < quantos; i++)
      ItemDoExplorar(chave: 'i$i', titulo: 'Título $i', anos: '2020', nota: '7,$i', aoTocar: () => tocados.add('i$i')),
  ];

  const bibliotecas = [
    BibliotecaDoExplorar(chave: 'filmes', titulo: 'Filmes'),
    BibliotecaDoExplorar(chave: 'animes', titulo: 'Animes'),
  ];

  testWidgets('Grade de 8 colunas dentro da margem segura; D-pad anda e o OK abre', (tester) async {
    final tocados = <String>[];
    final primeiro = FocusNode();
    addTearDown(primeiro.dispose);
    await montar(
      tester,
      TelaExplorarTv(
        bibliotecas: bibliotecas,
        bibliotecaAtual: 'animes',
        itens: itens(20, tocados),
        primeiroCartao: primeiro,
        aoOrdenar: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Animes'), findsWidgets);

    final a = tester.getRect(find.byKey(const ValueKey('explorar-tv-i0')));
    final h = tester.getRect(find.byKey(const ValueKey('explorar-tv-i7')));
    final i = tester.getRect(find.byKey(const ValueKey('explorar-tv-i8')));
    expect(a.left, moreOrLessEquals(48, epsilon: 0.5));
    expect(h.right, moreOrLessEquals(960 - 48, epsilon: 0.5));
    expect(i.top, greaterThan(a.bottom), reason: 'o 9º pôster abre a 2ª linha');

    primeiro.requestFocus();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(tocados, ['i8']);
  });

  testWidgets('Foco perto do fim pede a próxima página', (tester) async {
    var pediu = 0;
    final primeiro = FocusNode();
    addTearDown(primeiro.dispose);
    await montar(
      tester,
      TelaExplorarTv(
        bibliotecas: bibliotecas,
        itens: itens(16, []),
        primeiroCartao: primeiro,
        aoChegarPertoDoFim: () => pediu++,
      ),
    );
    primeiro.requestFocus();
    await tester.pump(const Duration(milliseconds: 400));
    expect(pediu, greaterThan(0), reason: 'com 2 linhas, o 1º pôster já está perto do fim');
  });

  testWidgets('Pílulas: biblioteca, gênero (de novo = todos), "Não vistos" e a ordem que passa para a próxima', (
    tester,
  ) async {
    final escolhas = <String>[];
    String? genero = 'g1';
    OrdemDoExplorar? ordem;
    bool? naoVistos;
    await montar(
      tester,
      TelaExplorarTv(
        bibliotecas: bibliotecas,
        bibliotecaAtual: 'filmes',
        aoEscolherBiblioteca: escolhas.add,
        itens: itens(3, []),
        generos: const [
          GeneroDoExplorar(chave: 'g1', nome: 'Ação'),
          GeneroDoExplorar(chave: 'g2', nome: 'Drama'),
        ],
        generoAtual: 'g1',
        aoEscolherGenero: (g) => genero = g,
        soNaoVistos: false,
        aoMudarSoNaoVistos: (v) => naoVistos = v,
        ordem: OrdemDoExplorar.titulo,
        aoOrdenar: (o) => ordem = o,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('explorar-tv-biblioteca-animes')));
    expect(escolhas, ['animes']);
    await tester.tap(find.byKey(const ValueKey('explorar-tv-genero-g1')));
    expect(genero, isNull);
    await tester.tap(find.byKey(const ValueKey('explorar-tv-genero-g2')));
    expect(genero, 'g2');
    await tester.tap(find.byKey(const ValueKey('explorar-tv-nao-vistos')));
    expect(naoVistos, isTrue);
    await tester.tap(find.byKey(const ValueKey('explorar-tv-ordem')));
    expect(ordem, OrdemDoExplorar.recentes);
  });

  testWidgets('← no 1º pôster abre o trilho', (tester) async {
    var menu = 0;
    final primeiro = FocusNode();
    addTearDown(primeiro.dispose);
    await montar(
      tester,
      TelaExplorarTv(
        bibliotecas: bibliotecas,
        itens: itens(4, []),
        primeiroCartao: primeiro,
        aoAbrirMenu: () => menu++,
      ),
    );
    primeiro.requestFocus();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(menu, 1);
  });

  for (final letra in [1.0, 2.0]) {
    testWidgets('Nada estoura com letra ${(letra * 100).round()} %', (tester) async {
      await montar(
        tester,
        TelaExplorarTv(
          bibliotecas: bibliotecas,
          bibliotecaAtual: 'filmes',
          itens: itens(24, []),
          generos: const [GeneroDoExplorar(chave: 'g1', nome: 'Ação')],
          aoEscolherGenero: (_) {},
          soNaoVistos: true,
          aoMudarSoNaoVistos: (_) {},
          aoOrdenar: (_) {},
          carregandoMais: true,
        ),
        letra: letra,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
