// Regressão da navegação atual: topo aprovado, pílula e menu mantido no modo offline.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_navigation.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/cgflix/cgflix_user_menu.dart';
import 'package:plezy/heisuca/heisuca_home_chrome.dart';
import 'package:plezy/heisuca/heisuca_logo.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/navigation/navigation_tabs.dart';

List<NavigationTabId> _ids(List<NavigationTab> tabs) => [for (final tab in tabs) tab.id];
Widget _fakePage(String name) => Scaffold(appBar: AppBar(title: Text(name)), body: Center(child: Text('página $name')));
const _sizes = {
  'retrato 360': Size(360, 760), 'retrato 412': Size(412, 914), 'tablet': Size(800, 1280),
  'paisagem 360': Size(760, 360), 'paisagem 412': Size(914, 412), 'paisagem tablet': Size(1280, 800),
};

Future<void> _fonts() async {
  final inter = FontLoader('Inter');
  for (final weight in ['Regular', 'SemiBold']) {
    inter.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Inter-$weight.ttf').readAsBytesSync())));
  }
  await inter.load();
  await (FontLoader('Sora')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Sora-VF.ttf').readAsBytesSync())))).load();
}

Future<ScrollController> _pumpHeader(WidgetTester tester, Size size, {bool title = false}) async {
  tester.view.physicalSize = size * 2.625;
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  final scroll = ScrollController();
  addTearDown(scroll.dispose);
  final anchor = GlobalKey();
  await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(), home: Builder(builder: (context) => Scaffold(
    body: Stack(fit: StackFit.expand, children: [
      SingleChildScrollView(controller: scroll, child: Column(children: [
        const SizedBox(height: 240), SizedBox(key: anchor, height: 56), const SizedBox(height: 1200),
      ])),
      Positioned.fill(child: HeisucaHomeChrome(scrollController: scroll, logoAnchor: anchor,
        pageColor: CgflixPalette.isis.background,
        item: title ? MediaItem(id: 'titulo', backend: MediaBackend.jellyfin, kind: MediaKind.movie,
          title: 'Um título comprido para conferir o encaixe com fonte grande') : null,
        titleFontFamily: 'Sora', onSearch: () => cgflixOpenSearch(context), onHome: () {}, onDockedChanged: (_) {})),
    ])))));
  await tester.pumpAndSettle();
  return scroll;
}

Future<void> _pumpOffline(WidgetTester tester, {Size size = const Size(412, 914)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(), home: Scaffold(
    body: Column(children: [CgflixOfflineTopBar(reconnecting: false, onReconnect: () {}), const Expanded(child: SizedBox())]))));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_fonts);
  setUp(() {
    CgflixPages.search = (_) => _fakePage('Busca');
    CgflixPages.downloads = (_) => _fakePage('Baixados');
    CgflixPages.settings = () => MaterialPageRoute<void>(builder: (_) => _fakePage('Configurações'));
    CgflixPages.myRequests = (_) => _fakePage('Meus pedidos');
    CgflixPages.libraries = (_) => _fakePage('Bibliotecas');
    cgflixUserMenuDebugOnline = true; // Exercita os despachantes sem conta nem rede.
  });
  tearDown(() => cgflixUserMenuDebugOnline = null);

  test('seções conectadas disponibilizadas ao Main; pílula pública tem cobertura própria', () {
    const sections = [NavigationTabId.discover, NavigationTabId.libraries, NavigationTabId.search, NavigationTabId.downloads];
    expect(_ids(cgflixMobileTabs(allNavigationTabs)), sections);
    expect(_ids(cgflixMobileTabs(NavigationTab.getVisibleTabs(isOffline: false, hasLiveTv: true, hasExplore: true))), sections);
  });
  test('sem conexão: Baixados é a raiz', () {
    expect(_ids(cgflixMobileTabs(NavigationTab.getVisibleTabs(isOffline: true))), [NavigationTabId.downloads]);
  });

  for (final entry in _sizes.entries) {
    testWidgets('topo atual em ${entry.key}: marca e busca cabem, alinhadas e acessíveis', (tester) async {
      await _pumpHeader(tester, entry.value);
      final brand = find.bySemanticsLabel('Heisuca: trocar fonte');
      final search = find.widgetWithIcon(IconButton, Icons.search_rounded);
      expect(tester.takeException(), isNull);
      expect(find.byType(HeisucaLogo), findsOneWidget);
      expect(tester.getCenter(brand).dy, moreOrLessEquals(tester.getCenter(search).dy, epsilon: .5));
      for (final target in [brand, search]) {
        final rect = tester.getRect(target);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(entry.value.width));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
    });
  }

  testWidgets('tela estreita com fonte grande: título encaixa sem cobrir marca ou busca', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final scroll = await _pumpHeader(tester, const Size(320, 640), title: true);
    scroll.jumpTo(300);
    await tester.pumpAndSettle();
    final title = tester.getRect(find.byKey(const ValueKey('heisuca-docking-logo')));
    expect(title.left, greaterThanOrEqualTo(tester.getRect(find.bySemanticsLabel('Heisuca: trocar fonte')).right));
    expect(title.right, lessThanOrEqualTo(tester.getRect(find.widgetWithIcon(IconButton, Icons.search_rounded)).left));
    expect(find.widgetWithIcon(IconButton, Icons.search_rounded).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(412, 914), const Size(914, 412)]) {
    testWidgets('busca real do topo e Voltar em $size', (tester) async {
      await _pumpHeader(tester, size);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(find.text('página Busca'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('página Busca'), findsNothing);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.search_rounded));
      await tester.pumpAndSettle();
      await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
      await tester.pumpAndSettle();
      expect(find.text('página Busca'), findsNothing);
    });
  }

  for (final item in [
    (CgflixUserMenuItem.libraries, 'Bibliotecas'), (CgflixUserMenuItem.myRequests, 'Meus pedidos'),
    (CgflixUserMenuItem.downloads, 'Baixados'), (CgflixUserMenuItem.settings, 'Configurações'),
  ]) {
    testWidgets('menu mantido no offline: despachante ${item.$2} e Voltar', (tester) async {
      await _pumpOffline(tester);
      await tester.tap(find.byKey(const ValueKey('cgflix-top-menu')));
      await tester.pumpAndSettle();
      final target = find.byKey(ValueKey('cgflix-menu-${item.$1.name}'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text('página ${item.$2}'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cgflix-top-menu')), findsOneWidget);
    });
  }
  testWidgets('menu mantido no offline cabe deitado e permite rolar', (tester) async {
    await _pumpOffline(tester, size: const Size(914, 412));
    await tester.tap(find.byKey(const ValueKey('cgflix-top-menu')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('cgflix-menu-settings')));
    expect(find.byKey(const ValueKey('cgflix-menu-settings')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('leitor de tela identifica busca, fonte e menu offline', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpHeader(tester, const Size(412, 914));
      final search = tester.getSemantics(find.widgetWithIcon(IconButton, Icons.search_rounded)).getSemanticsData();
      expect([search.label, search.tooltip], contains('Buscar'));
      expect(find.bySemanticsLabel('Heisuca: trocar fonte'), findsOneWidget);
      await _pumpOffline(tester);
      expect(find.bySemanticsLabel(RegExp('^Menu do Heisuca')), findsOneWidget);
    } finally { semantics.dispose(); }
  });
}
