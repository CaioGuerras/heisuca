// Tema Heitor (versão 1.4.0): Início, Detalhes, Configurações e Login montam nos dois temas
// (Isis e Heitor) sem exceção nem overflow, e cada uma pega as cores e a marca do tema certo.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_layout.dart';
import 'package:heisuca/cgflix/cgflix_navigation.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/home/cgflix_hero.dart';
import 'package:heisuca/cgflix/home/cgflix_preview_sheet.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/providers/theme_provider.dart';
import 'package:heisuca/screens/auth_screen.dart';
import 'package:heisuca/cgflix/cgflix_configuracoes.dart';
import 'package:heisuca/cgflix/cgflix_theme_picker.dart';
import 'package:heisuca/widgets/settings_page.dart';
import 'package:heisuca/widgets/settings_section.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

const _tela = Size(412, 914);

final _item = MediaItem.jellyfin(
  id: 'f',
  kind: MediaKind.movie,
  title: 'Ainda Estou Aqui',
  summary: 'Rio de Janeiro, 1971. Uma família vê a vida mudar para sempre.',
  genres: const ['Drama', 'História'],
  year: 2024,
);

/// Monta [home] num celular de 412 × 914 com o tema do CGFLIX.
Future<void> _montar(WidgetTester tester, CgflixThemeVariant variante, Widget home) async {
  tester.view.physicalSize = _tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = ThemeProvider();
  addTearDown(theme.dispose);
  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<ThemeProvider>.value(
        value: theme,
        child: MaterialApp(theme: cgflixAppTheme(variante), home: home),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

CgflixPalette _paleta(CgflixThemeVariant v) => CgflixPalette.forVariant(v);

Color? _fundoDoBotao(WidgetTester tester, String rotulo) {
  final containerFinder = find.ancestor(
    of: find.text(rotulo),
    matching: find.byType(Container),
  );
  if (containerFinder.evaluate().isNotEmpty) {
    final container = tester.widget<Container>(containerFinder.first);
    final decoration = container.decoration;
    if (decoration is BoxDecoration) {
      return decoration.color;
    }
  }
  final botao = tester.widget<ButtonStyleButton>(
    find.ancestor(of: find.text(rotulo), matching: find.bySubtype<ButtonStyleButton>()).first,
  );
  return botao.style?.backgroundColor?.resolve({});
}

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    settings.SettingsService.resetForTesting();
    await settings.SettingsService.getInstance();
  });

  for (final variante in const [CgflixThemeVariant.isis, CgflixThemeVariant.heitor]) {
    final nome = variante.name;

    testWidgets('$nome: Início (destaque + barra do topo)', (tester) async {
      await _montar(
        tester,
        variante,
        Scaffold(
          body: Stack(
            children: [
              ListView(
                children: [
                  CgflixHero(items: [_item], height: cgflixHeroHeight(_tela), paused: true),
                ],
              ),
              CgflixTopBar(
                chips: [
                  CgflixTopBarChip(label: 'Filmes', selected: true, onPressed: () {}),
                  CgflixTopBarChip(label: 'Séries', selected: false, onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Assistir'), findsOneWidget);
      expect(_fundoDoBotao(tester, 'Assistir'), _paleta(variante).action);
      expect(_fundoDoBotao(tester, 'Detalhes'), _paleta(variante).glass);
    });

    testWidgets('$nome: Detalhes (prévia do título)', (tester) async {
      await _montar(
        tester,
        variante,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(onPressed: () => showCgflixPreview(context, _item), child: const Text('abrir')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.text('Ainda Estou Aqui'), findsWidgets);
      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.backgroundColor, _paleta(variante).surface);
    });

    testWidgets('$nome: Configurações (lista M3) com a escolha de tema', (tester) async {
      await _montar(
        tester,
        variante,
        SettingsPage(
          title: const Text('Configurações'),
          children: [
            SettingsGroup(title: t.settings.appearance, children: const [CgflixThemeSelector()]),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Isis'), findsOneWidget); // padrão, só o nome (refino 2)
      expect(find.textContaining('escuro'), findsNothing);
      final fundo =
          tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor ??
          Theme.of(tester.element(find.byType(Scaffold).first)).scaffoldBackgroundColor;
      expect(fundo, _paleta(variante).background);
      // Refino 2b: cabeçalho na cor primary do tema (Isis lilás, Heitor verde).
      final cabecalho = tester.widget<Text>(find.text(t.settings.appearance));
      expect(
        cabecalho.style?.color,
        variante == CgflixThemeVariant.isis ? cgflixIsisPrimary : cgflixHeitorScheme.primary,
      );
    });

    testWidgets('$nome: Login (entrada) com a marca do tema', (tester) async {
      await _montar(tester, variante, const AuthScreen(initializeServices: false));
      expect(tester.takeException(), isNull);
      final emblemas = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
      expect(emblemas, isNotEmpty);
      final loader = emblemas.first.bytesLoader as SvgAssetLoader;
      final expectedAsset = _paleta(variante).isLight
          ? 'assets/heisuca/marca_site_hisui.svg'
          : 'assets/heisuca/marca_site_shikkoku.svg';
      expect(loader.assetName, expectedAsset);
    });
  }

  testWidgets('trocar o tema vale na hora, sem reiniciar', (tester) async {
    final service = await settings.SettingsService.getInstance();
    final theme = ThemeProvider();
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: theme,
        child: Consumer<ThemeProvider>(
          builder: (context, provider, _) => MaterialApp(
            theme: cgflixAppTheme(CgflixThemeVariant.heitor),
            darkTheme: cgflixAppTheme(),
            themeMode: cgflixMaterialThemeMode(provider.themeMode),
            home: Builder(builder: (context) => Text(context.cgflix.variant.name)),
          ),
        ),
      ),
    );
    expect(find.text('isis'), findsOneWidget);
    await service.write(settings.SettingsService.themeMode, settings.ThemeMode.light); // Heitor
    await tester.pumpAndSettle();
    expect(find.text('heitor'), findsOneWidget);
  });
}
