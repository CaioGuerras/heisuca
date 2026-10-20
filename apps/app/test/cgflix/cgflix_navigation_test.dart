// Etapa 1D: barra única no topo (sem barra inferior). Retrato e paisagem, 360/412/800 dp.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_navigation.dart';
import 'package:plezy/cgflix/cgflix_user_menu.dart';
import 'package:plezy/navigation/navigation_tabs.dart';

List<NavigationTabId> _ids(List<NavigationTab> tabs) => [for (final tab in tabs) tab.id];

/// Páginas falsas: cada uma tem um Voltar visível (como as de verdade).
Widget _fakePage(String name) => Scaffold(
  appBar: AppBar(title: Text(name)),
  body: Center(child: Text('página $name')),
);

Future<void> _pumpBar(
  WidgetTester tester,
  Size size, {
  List<String> chips = const ['Filmes', 'Séries', 'Animes'],
}) async {
  tester.view.physicalSize = size * 2.625;
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: CgflixTopBar(
              chips: [for (final c in chips) CgflixTopBarChip(label: c, selected: false, onPressed: () {})],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _sizes = {
  'retrato 360': Size(360, 760),
  'retrato 412 (edge 70)': Size(412, 914),
  'retrato 800 (tablet)': Size(800, 1280),
  'paisagem 360': Size(760, 360),
  'paisagem 412 (edge 70)': Size(914, 412),
  'paisagem 800': Size(1280, 800),
};

/// Fonte de verdade (Inter) nas medidas: a fonte padrão dos testes desenha cada letra como um
/// quadrado e deixaria os chips bem mais largos que no aparelho.
Future<void> _loadInter() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'SemiBold']) {
    final bytes = File('assets/fonts/Inter-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadInter);

  setUp(() {
    CgflixPages.search = (_) => _fakePage('Busca');
    CgflixPages.downloads = (_) => _fakePage('Baixados');
    CgflixPages.settings = () => MaterialPageRoute<void>(builder: (_) => _fakePage('Configurações'));
    CgflixPages.myRequests = (_) => _fakePage('Meus pedidos');
    CgflixPages.libraries = (_) => _fakePage('Bibliotecas');
    cgflixUserMenuDebugOnline = true;
  });

  tearDown(() => cgflixUserMenuDebugOnline = null);

  group('abas do celular', () {
    test('conectado: só a Início (sem barra inferior)', () {
      expect(_ids(cgflixMobileTabs(allNavigationTabs)), [NavigationTabId.discover]);
      final visible = NavigationTab.getVisibleTabs(isOffline: false, hasLiveTv: true, hasExplore: true);
      expect(_ids(cgflixMobileTabs(visible)), [NavigationTabId.discover]);
    });

    test('sem conexão: Baixados é a raiz', () {
      final offline = NavigationTab.getVisibleTabs(isOffline: true);
      expect(_ids(cgflixMobileTabs(offline)), [NavigationTabId.downloads]);
    });
  });

  for (final entry in _sizes.entries) {
    testWidgets('barra do topo em ${entry.key}: sem overflow, tudo na mesma linha', (tester) async {
      await _pumpBar(tester, entry.value);
      expect(tester.takeException(), isNull);

      final menu = find.byKey(const ValueKey('cgflix-top-menu'));
      final search = find.byKey(const ValueKey('cgflix-top-search'));
      expect(menu, findsOneWidget);
      expect(search, findsOneWidget);
      // Etapa 1E: uma lupa só; sem o ícone "Pedir" na barra.
      expect(find.byKey(const ValueKey('cgflix-top-request')), findsNothing);

      // Mesma linha: centro vertical de chips, lupa e emblema é o mesmo.
      final centerY = tester.getCenter(search).dy;
      for (final label in ['Filmes', 'Séries', 'Animes']) {
        final chip = find.text(label);
        expect(chip, findsOneWidget);
        expect(tester.getCenter(chip).dy, moreOrLessEquals(centerY, epsilon: 0.5), reason: label);
      }
      expect(tester.getCenter(menu).dy, moreOrLessEquals(centerY, epsilon: 0.5));

      // Mesma altura visual: chips (36 dp) = lupa.
      final chipBoxes = find.ancestor(of: find.text('Filmes'), matching: find.byType(AnimatedContainer));
      expect(tester.getSize(chipBoxes.first).height, 36);
      final searchCircle = find.descendant(of: search, matching: find.byType(Material));
      expect(tester.getSize(searchCircle.first).height, 36);

      // Alvos de toque ≥ 48 dp.
      expect(tester.getSize(menu).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(search).height, greaterThanOrEqualTo(48));

      // Espaçamento visual uniforme entre os itens do centro (desenho, não alvo de toque).
      Rect visual(Finder slot) => tester.getRect(
        find
            .descendant(of: slot, matching: find.byWidgetPredicate((w) => w is AnimatedContainer || w is Material))
            .first,
      );
      final xs = [
        for (final k in ['cgflix-top-chip-Filmes', 'cgflix-top-chip-Séries', 'cgflix-top-chip-Animes'])
          visual(find.byKey(ValueKey(k))),
        visual(search),
      ];
      final gaps = [for (var i = 1; i < xs.length; i++) xs[i].left - xs[i - 1].right];
      // A 360 dp os chips rolam por baixo da lupa (o espaçamento confere de 412 dp em diante).
      if (entry.value.width >= 412) {
        for (final g in gaps) {
          expect(g, moreOrLessEquals(12, epsilon: 0.5), reason: '$gaps');
        }
      }

      // Lupa sempre inteira na tela.
      final width = entry.value.width;
      expect(tester.getRect(search).right, lessThanOrEqualTo(width));
      // Quando cabe: grupo do centro centralizado na TELA.
      final groupCenter = (xs.first.left + xs.last.right) / 2;
      if (width >= 600) expect(groupCenter, moreOrLessEquals(width / 2, epsilon: 2));
      // O emblema nunca é empurrado para fora.
      expect(tester.getTopLeft(menu).dx, greaterThanOrEqualTo(0));
    });
  }

  testWidgets('tela estreita com fonte grande: chips rolam na horizontal, sem quebrar linha', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpBar(tester, const Size(320, 640), chips: ['Filmes', 'Séries', 'Animes', 'Documentários']);
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final y = tester.getCenter(find.text('Filmes')).dy;
    expect(tester.getCenter(find.text('Séries')).dy, y);
  });

  group('cada item leva ao lugar certo e Voltar funciona', () {
    Future<void> openAndBack(WidgetTester tester, Finder tap, String page, {Size size = const Size(412, 914)}) async {
      await _pumpBar(tester, size);
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(find.text('página $page'), findsOneWidget);
      // Voltar visível na página.
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('página $page'), findsNothing);
      expect(find.byKey(const ValueKey('cgflix-top-menu')), findsOneWidget);
      // E o voltar do sistema (gesto/tecla) também.
      await tester.tap(tap);
      await tester.pumpAndSettle();
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('página $page'), findsNothing);
    }

    testWidgets('lupa → Busca', (tester) async {
      await openAndBack(tester, find.byKey(const ValueKey('cgflix-top-search')), 'Busca');
    });

    testWidgets('paisagem: lupa → Busca', (tester) async {
      await openAndBack(tester, find.byKey(const ValueKey('cgflix-top-search')), 'Busca', size: const Size(914, 412));
    });

    for (final item in [
      (CgflixUserMenuItem.libraries, 'Bibliotecas'),
      (CgflixUserMenuItem.myRequests, 'Meus pedidos'),
      (CgflixUserMenuItem.downloads, 'Baixados'),
      (CgflixUserMenuItem.settings, 'Configurações'),
    ]) {
      testWidgets('emblema → menu do usuário → ${item.$2}', (tester) async {
        await _pumpBar(tester, const Size(412, 914));
        await tester.tap(find.byKey(const ValueKey('cgflix-top-menu')));
        await tester.pumpAndSettle();
        // Refino 2: Baixados · Meus pedidos · Bibliotecas ─ Configurações · Sobre e dicas ─ Trocar usuário ·
        // Sair ─ Apoie o CGFLIX (Favoritos só com Jellyfin conectado; aqui não há servidor).
        for (final i in cgflixUserMenuItems(online: true, hasFavorites: false)) {
          expect(find.byKey(ValueKey('cgflix-menu-${i.name}')), findsOneWidget, reason: i.name);
        }
        await tester.tap(find.byKey(ValueKey('cgflix-menu-${item.$1.name}')));
        await tester.pumpAndSettle();
        expect(find.text('página ${item.$2}'), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('cgflix-top-menu')), findsOneWidget);
      });
    }

    testWidgets('menu do usuário cabe deitado (rola, sem overflow)', (tester) async {
      await _pumpBar(tester, const Size(914, 412));
      await tester.tap(find.byKey(const ValueKey('cgflix-top-menu')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Etapa 1E: a dedicatória saiu do menu (fica só no Sobre).
      expect(find.text('Feito com amor, para Isis e Heitor'), findsNothing);
    });
  });

  testWidgets('leitor de tela lê os botões só de ícone', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpBar(tester, const Size(412, 914));
    expect(find.bySemanticsLabel('Buscar'), findsOneWidget);
    expect(find.bySemanticsLabel('Pedir um título'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('^Menu do CGFLIX')), findsOneWidget);
    expect(find.bySemanticsLabel('Mostrar só Filmes'), findsOneWidget);
    semantics.dispose();
  });
}
