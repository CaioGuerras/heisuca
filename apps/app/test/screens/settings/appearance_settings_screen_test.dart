import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/appearance_settings_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/cgflix/cgflix_config_itens.dart';
import 'package:plezy/cgflix/cgflix_navigation.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

void main() {
  // CGFLIX: as seções das Configurações começam fechadas; estes testes olham as opções por dentro.
  setUpAll(() => cgflixSettingsDebugInline = true);
  setUpAll(() => cgflixDebugShowUpstreamSettings = true); // CGFLIX: Configurações completas, como na TV
  tearDownAll(() => cgflixDebugShowUpstreamSettings = false);
  tearDownAll(() => cgflixSettingsDebugInline = false);

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('appearance screen renders every reorganized group', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 3000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final theme = ThemeProvider();
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: theme,
        child: MaterialApp(theme: monoTheme(dark: true), home: const AppearanceSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (final group in [
      t.settings.display,
      t.settings.libraryAndCards,
      t.settings.homeScreen,
      t.settings.navigation,
    ]) {
      expect(find.text(group), findsOneWidget, reason: 'group $group missing');
    }
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text(t.settings.liveTv), 500, scrollable: scrollable);
    expect(find.text(t.settings.liveTvDefaultFavorites), findsOneWidget);
    // Moved away: profile prompt and performance overlay no longer live here.
    expect(find.text(t.settings.requireProfileSelectionOnOpen), findsNothing);
    expect(find.text(t.settings.autoHidePerformanceOverlay), findsNothing);
  });

  // CGFLIX: no celular (o teste roda como Android) somem as opções da navegação do upstream.
  testWidgets('CGFLIX: celular sem Tela inicial, Navegação, TV ao vivo e escolha de tema', (tester) async {
    cgflixDebugShowUpstreamSettings = false;
    addTearDown(() => cgflixDebugShowUpstreamSettings = true);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 3000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final theme = ThemeProvider();
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: theme,
        child: MaterialApp(theme: monoTheme(dark: true), home: const AppearanceSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.settings.display), findsOneWidget);
    expect(find.text(t.settings.libraryAndCards), findsOneWidget);
    for (final gone in [t.settings.homeScreen, t.settings.navigation, t.settings.liveTv, t.settings.theme]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
  });
}
