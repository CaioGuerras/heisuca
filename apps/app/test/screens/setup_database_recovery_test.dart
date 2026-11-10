import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/database/tvos_database_recovery_store.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/main.dart';
import 'package:heisuca/screens/auth_screen.dart';
import 'package:heisuca/services/base_shared_preferences_service.dart';
import 'package:heisuca/utils/platform_detector.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetSharedPreferencesForTest);
  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  test('only recoveryRequired bypasses setup; fresh follows ordinary bootstrap path', () {
    expect(shouldBypassSetupForDatabaseRecovery(TvosDatabaseRecoveryOutcome.recoveryRequired), isTrue);
    expect(shouldBypassSetupForDatabaseRecovery(TvosDatabaseRecoveryOutcome.fresh), isFalse);
    expect(shouldBypassSetupForDatabaseRecovery(TvosDatabaseRecoveryOutcome.adoptedExistingDatabase), isFalse);
    expect(shouldBypassSetupForDatabaseRecovery(TvosDatabaseRecoveryOutcome.restored), isFalse);
    expect(shouldBypassSetupForDatabaseRecovery(TvosDatabaseRecoveryOutcome.notApplicable), isFalse);
  });

  testWidgets('recoveryRequired routes localized notice before legacy bootstrap writes', (tester) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.setString('plex_token', 'LEGACY-TOKEN-MUST-REMAIN');
    await prefs.setString('current_user_uuid', 'legacy-user');
    String? routedMessage;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: SetupScreen(
            databaseRecoveryOutcome: TvosDatabaseRecoveryOutcome.recoveryRequired,
            initializeAuthServices: false,
            debugRecoveryRequiredRouter: (_, message) {
              routedMessage = message;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(routedMessage, t.auth.localDataRecoveryRequired);
    expect(prefs.getString('plex_token'), 'LEGACY-TOKEN-MUST-REMAIN');
    expect(prefs.getString('current_user_uuid'), 'legacy-user');
  });

  testWidgets('AuthScreen visibly renders recovery notice with Plex and Jellyfin actions', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: AuthScreen(
            initialErrorMessage: t.auth.localDataRecoveryRequired,
            initializeServices: false,
            databaseRecoveryRequired: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(t.auth.localDataRecoveryRequired), findsOneWidget);
    expect(find.text(t.auth.signInWithPlex), findsOneWidget);
    expect(find.text(t.auth.connectToMediaBrowser(product: 'Jellyfin')), findsOneWidget);
    // CGFLIX: Emby não é mais oferecido na entrada.
    expect(find.text(t.auth.connectToMediaBrowser(product: 'Emby')), findsNothing);
  });

  testWidgets('fresh AuthScreen has normal actions without recovery notice', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await tester.pumpWidget(TranslationProvider(child: const MaterialApp(home: AuthScreen(initializeServices: false))));
    await tester.pump();

    expect(find.text(t.auth.localDataRecoveryRequired), findsNothing);
    expect(find.text(t.auth.signInWithPlex), findsOneWidget);
    expect(find.text(t.auth.connectToMediaBrowser(product: 'Jellyfin')), findsOneWidget);
    expect(find.text(t.auth.connectToMediaBrowser(product: 'Emby')), findsNothing);
  });
}
