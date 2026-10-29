import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_settings_screen.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/providers/theme_provider.dart';
import 'package:heisuca/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() {
    SettingsService.resetForTesting();
  });

  testWidgets('F5: distância vertical entre heisuca-quality e Pular Abertura Automático >= 12 dp', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider.value(
          value: themeProvider,
          child: MaterialApp(
            theme: cgflixAppTheme(),
            home: const Scaffold(body: HeisucaSettingsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final qualityFinder = find.byKey(const ValueKey('heisuca-quality'));
    final skipIntroFinder = find.ancestor(
      of: find.text('Pular Abertura Automático'),
      matching: find.byType(Container),
    ).first;

    expect(qualityFinder, findsOneWidget);
    expect(skipIntroFinder, findsOneWidget);

    final qualityBottom = tester.getBottomLeft(qualityFinder).dy;
    final cardTop = tester.getTopLeft(skipIntroFinder).dy;
    final verticalDistance = cardTop - qualityBottom;

    expect(verticalDistance, greaterThanOrEqualTo(12.0),
        reason: 'Espaço entre seletor de qualidade e o cartão deve ser >= 12 dp');
  });
}
