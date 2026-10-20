// Refino 2b (versão 1.6.1): Configurações no padrão do Android/Material 3 — lista plana com
// cabeçalhos na cor primary, sem sanfonas nem chevron, switch M3 com check e papel de switch,
// "Avançado" fechado no fim, nomes de idioma em português, fonte 200% sem corte e contraste AA.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/cgflix/cgflix_configuracoes.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/settings_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/language_codes.dart';
import 'package:plezy/widgets/setting_tile.dart';
import 'package:plezy/widgets/settings_page.dart';
import 'package:plezy/widgets/settings_section.dart';

import '../test_helpers/cgflix_config_harness.dart';

double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

/// Cor opaca de [c] sobre o fundo [bg] (as cores com alfa da Isis).
Color _sobre(Color c, Color bg) => Color.alphaBlend(c, bg);

void main() {
  setUpAll(() => LocaleSettings.setLocale(AppLocale.pt)); // carrega o português (biblioteca adiada)
  prepararConfiguracoes();
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.pt));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<void> principal(WidgetTester tester, {CgflixThemeVariant variante = CgflixThemeVariant.isis}) async {
    await montarConfiguracoes(tester, variante, 1, const SettingsScreen(), tamanho: const Size(412, 2000));
  }

  double y(WidgetTester tester, String texto) => tester.getTopLeft(find.text(texto).first).dy;

  testWidgets('tela principal: Aparência → Assistir → Baixados → Ajuda → Avançado (fechado) no fim', (tester) async {
    await principal(tester);
    expect(tester.takeException(), isNull);
    // Ordem dos grupos.
    expect(y(tester, 'Aparência'), lessThan(y(tester, 'Assistir')));
    expect(y(tester, 'Assistir'), lessThan(y(tester, 'Baixados')));
    expect(y(tester, 'Baixados'), lessThan(y(tester, 'Ajuda')));
    expect(y(tester, 'Ajuda'), lessThan(y(tester, 'Avançado')));
    // Itens comuns em cima, com o valor atual no resumo.
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Isis'), findsOneWidget);
    expect(find.text('Idioma do app'), findsOneWidget);
    expect(find.text('Português (Brasil)'), findsOneWidget);
    expect(find.text('Áudio e legenda'), findsOneWidget);
    expect(find.textContaining('Áudio: Português'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget); // qualidade
    expect(find.textContaining('Só no Wi-Fi'), findsOneWidget);
    // O técnico não está na frente (foi para Avançado).
    for (final tecnico in [
      'Assistir juntos',
      'Controle remoto',
      'Opções do mpv',
      'Som de abertura',
      t.settings.forceSkipMarkerFallback,
      t.settings.introPattern,
      t.settings.forceTvMode,
      t.connections.sectionTitle,
      t.connections.addConnection,
      t.settings.debugLogging,
      'Geral',
    ]) {
      expect(find.text(tecnico), findsNothing, reason: tecnico);
    }
    // Textos que o dono estranhou.
    expect(find.textContaining('salvo em'), findsNothing);
    expect(find.textContaining('Adicionar a'), findsNothing);
    // Sem chevron (padrão Android) e sem sanfona.
    expect(find.byIcon(Symbols.chevron_right_rounded), findsNothing);
    expect(find.byIcon(Symbols.expand_more_rounded), findsNothing);
  });

  testWidgets('Avançado abre uma subtela com tudo o que saiu da frente, agrupado por assunto', (tester) async {
    await principal(tester);
    await tester.tap(find.text('Avançado'));
    await tester.pumpAndSettle();
    for (final texto in [
      t.connections.sectionTitle,
      t.connections.addConnection,
      'Recursos extras',
      'Assistir juntos',
      'Controle remoto',
      'Ao assistir (técnico)',
      'Reprodução avançada',
      'Opções do mpv',
      t.settings.autoSkipDelay,
      t.settings.forceSkipMarkerFallback,
      t.settings.introPattern,
      'Legendas (técnico)',
      t.subtitlingStyling.assOverride,
      'Este aparelho',
      'Diagnóstico',
    ]) {
      await tester.scrollUntilVisible(find.text(texto).first, 200, scrollable: find.byType(Scrollable).last);
      expect(find.text(texto), findsWidgets, reason: texto);
    }
  });

  testWidgets('cabeçalhos: cor primary e lidos como cabeçalho; switch com papel de switch e estado', (tester) async {
    final semantics = tester.ensureSemantics();
    await montarConfiguracoes(
      tester,
      CgflixThemeVariant.heitor,
      1,
      SettingsPage(
        title: const Text('Teste'),
        children: [
          SettingsGroup(
            title: 'Grupo',
            children: [
              SettingSwitchTile(
                pref: SettingsService.autoPlayNextEpisode,
                icon: Symbols.skip_next_rounded,
                title: 'Liga',
              ),
            ],
          ),
        ],
      ),
    );
    final cabecalho = tester.widget<Text>(find.text('Grupo'));
    expect(cabecalho.style?.color, cgflixHeitorScheme.primary);
    expect(tester.getSemantics(find.text('Grupo')), isSemantics(isHeader: true));
    expect(
      tester.getSemantics(find.byType(SwitchListTile)),
      isSemantics(hasToggledState: true, isToggled: true, hasEnabledState: true, isEnabled: true),
    );
    // Linha M3: 56 dp ou mais, item inteiro alterna.
    expect(tester.getSize(find.byType(SwitchListTile)).height, greaterThanOrEqualTo(56));
    await tester.tap(find.text('Liga'));
    await tester.pumpAndSettle();
    expect(SettingsService.instance.read(SettingsService.autoPlayNextEpisode), isFalse);
    semantics.dispose();
  });

  test('switch M3: trilho primary ligado, contorno outline desligado, check no polegar', () {
    for (final variante in CgflixThemeVariant.values) {
      final tema = cgflixSettingsTheme(cgflixAppTheme(variante));
      final s = tema.colorScheme;
      final sw = tema.switchTheme;
      expect(sw.trackColor!.resolve({WidgetState.selected}), s.primary);
      expect(sw.trackColor!.resolve({}), s.surfaceContainerHighest);
      expect(sw.trackOutlineColor!.resolve({}), s.outline);
      expect(sw.thumbIcon!.resolve({WidgetState.selected}), isNotNull);
      expect(sw.thumbIcon!.resolve({}), isNull);
      // Isis roxa, Heitor verde.
      expect(s.primary, variante == CgflixThemeVariant.isis ? cgflixIsisPrimary : cgflixHeitorScheme.primary);
    }
  });

  test('contraste AA nas Configurações dos dois temas', () {
    for (final variante in CgflixThemeVariant.values) {
      final tema = cgflixSettingsTheme(cgflixAppTheme(variante));
      final s = tema.colorScheme;
      final fundo = tema.scaffoldBackgroundColor;
      expect(_contraste(s.primary, fundo), greaterThanOrEqualTo(4.5), reason: '$variante cabeçalho');
      expect(_contraste(s.onSurface, fundo), greaterThanOrEqualTo(4.5), reason: '$variante título');
      expect(
        _contraste(_sobre(s.onSurfaceVariant, fundo), fundo),
        greaterThanOrEqualTo(4.5),
        reason: '$variante resumo',
      );
      expect(_contraste(s.primary, fundo), greaterThanOrEqualTo(3), reason: '$variante trilho ligado');
      expect(_contraste(_sobre(s.outline, fundo), fundo), greaterThanOrEqualTo(3), reason: '$variante contorno');
      expect(_contraste(s.onPrimary, s.primary), greaterThanOrEqualTo(3), reason: '$variante polegar');
    }
  });

  testWidgets('fonte 200%: tela principal sem corte nem estouro', (tester) async {
    await montarConfiguracoes(
      tester,
      CgflixThemeVariant.isis,
      2,
      const SettingsScreen(),
      tamanho: const Size(360, 4000),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Áudio e legenda'), findsOneWidget);
    expect(find.text('Avançado'), findsOneWidget);
  });

  testWidgets('deitado (914 × 412): tela principal e Avançado sem estouro', (tester) async {
    await montarConfiguracoes(
      tester,
      CgflixThemeVariant.heitor,
      1,
      const SettingsScreen(),
      tamanho: const Size(914, 412),
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Avançado'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Avançado'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(t.connections.addConnection), findsOneWidget);
  });

  testWidgets('foco do teclado/controle visível: realce na cor primary', (tester) async {
    await principal(tester);
    final tema = Theme.of(tester.element(find.text('Idioma do app')));
    expect(tema.focusColor, tema.colorScheme.primary.withValues(alpha: 0.16));
  });

  test('nomes de idioma em português, com inicial maiúscula', () {
    expect(LanguageCodes.getLanguageName('por'), 'Português');
    expect(LanguageCodes.getLanguageName('en'), 'Inglês');
    expect(LanguageCodes.getLanguageName('jpn'), 'Japonês');
    expect(LanguageCodes.getDisplayName('pt-BR'), 'Português (Brasil)');
    final todos = LanguageCodes.getAllLanguages();
    expect(todos.every((l) => l.name[0] == l.name[0].toUpperCase()), isTrue);
    expect(todos.any((l) => l.name == 'Portuguese' || l.name == 'English'), isFalse);
    // Ordem alfabética ignorando acento: "Árabe" fica entre os "A".
    final nomes = todos.map((l) => l.name).toList();
    expect(nomes.indexOf('Árabe'), lessThan(nomes.indexOf('Basco')));
    // Em inglês continua como no upstream.
    LocaleSettings.setLocaleSync(AppLocale.en);
    expect(LanguageCodes.getLanguageName('por'), 'Portuguese');
  });
}
