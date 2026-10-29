import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:heisuca/cgflix/apoio/cgflix_apoio_screen.dart';
import 'package:heisuca/cgflix/cgflix_about.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_logo.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/screens/settings/about_screen.dart';
import 'package:heisuca/widgets/app_icon.dart';
import 'package:heisuca/widgets/settings_section.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.pt);
  });

  testWidgets('F4: Tela Sobre com nova ordem, sem corações, sem appDescription e apoio com café e seta', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: cgflixAppTheme(),
          home: const Scaffold(body: AboutScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Ordem dos elementos:
    // Logo/Slogan/Versão -> TributeCards -> Apoio -> SettingsGroup -> Dedicatória no fim
    final logoFinder = find.byType(HeisucaLogo);
    final tributeFinder = find.byType(HeisucaTributeCards);
    final apoioFinder = find.byType(CgflixApoioAboutLine);
    final groupFinder = find.byType(SettingsGroup);
    final dedicationFinder = find.byType(CgflixDedication);

    expect(logoFinder, findsOneWidget);
    expect(tributeFinder, findsOneWidget);
    expect(apoioFinder, findsOneWidget);
    expect(groupFinder, findsOneWidget);
    expect(dedicationFinder, findsOneWidget);

    final logoTop = tester.getTopLeft(logoFinder).dy;
    final tributeTop = tester.getTopLeft(tributeFinder).dy;
    final apoioTop = tester.getTopLeft(apoioFinder).dy;
    final groupTop = tester.getTopLeft(groupFinder).dy;
    final dedicationTop = tester.getTopLeft(dedicationFinder).dy;

    expect(logoTop, lessThan(tributeTop), reason: 'Logo deve vir antes dos cartões de homenagem');
    expect(tributeTop, lessThan(apoioTop), reason: 'Cartões de homenagem devem vir antes do apoio');
    expect(apoioTop, lessThan(groupTop), reason: 'Linha de apoio deve vir antes do grupo de dicas/licenças');
    expect(groupTop, lessThan(dedicationTop), reason: 'Dedicatória deve ficar no fim da tela');

    // 2. Ausência dos corações e da frase descritiva antiga
    expect(find.text('Os filmes e séries da família, em qualquer tela'), findsNothing,
        reason: 'Frase appDescription deve ser removida');
    expect(find.descendant(of: dedicationFinder, matching: find.byIcon(Symbols.favorite_rounded)), findsNothing,
        reason: 'Dedicatória não deve ter corações');

    // 3. Apoio discreto com café, texto "Apoiar o Heisuca", seta no fim e área de toque >= 48 dp
    expect(find.descendant(of: apoioFinder, matching: find.text('Apoiar o Heisuca')), findsOneWidget);
    expect(
      find.descendant(of: apoioFinder, matching: find.byWidgetPredicate((w) => w is AppIcon && w.icon == Symbols.coffee_rounded)),
      findsOneWidget,
      reason: 'Apoio discreto deve usar o ícone de café',
    );
    expect(
      find.descendant(of: apoioFinder, matching: find.byWidgetPredicate((w) => w is AppIcon && (w.icon == Symbols.chevron_right_rounded || w.icon == Symbols.chevron_right))),
      findsOneWidget,
      reason: 'Apoio discreto deve ter seta chevron_right no fim',
    );

    final apoioSize = tester.getSize(apoioFinder);
    expect(apoioSize.height, greaterThanOrEqualTo(48.0), reason: 'Área de toque vertical deve ser >= 48 dp');
  });
}
