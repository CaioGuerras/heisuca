import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';

import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/connection/connection_registry.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/profiles/plex_home_service.dart';
import 'package:heisuca/profiles/profile_connection_registry.dart';
import 'package:heisuca/profiles/profile_registry.dart';
import 'package:heisuca/providers/account_preferences_controller.dart';
import 'package:heisuca/providers/download_provider.dart';
import 'package:heisuca/providers/hidden_libraries_provider.dart';
import 'package:heisuca/providers/libraries_provider.dart';
import 'package:heisuca/providers/seerr_account_provider.dart';
import 'package:heisuca/providers/theme_provider.dart';
import 'package:heisuca/screens/settings/settings_screen.dart';
import 'package:heisuca/services/download_manager_service.dart';
import 'package:heisuca/services/download_storage_service.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/services/storage_service.dart';
import 'package:heisuca/utils/platform_detector.dart';
import 'package:heisuca/services/plex_api_cache.dart';
import 'package:heisuca/widgets/overlay_sheet.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/prefs.dart';

class _FakeHiddenLibrariesStorage implements StorageService {
  @override
  Set<String> getHiddenLibraries() => {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WritableDownloadStorage extends Fake implements DownloadStorageService {
  @override
  Future<bool> isDirectoryWritable(Directory dir) async => true;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory temporaryDirectory;
  late AppDatabase database;
  late PlexHomeService plexHome;
  late ActiveProfileProvider activeProfile;
  late LibrariesProvider libraries;
  late HiddenLibrariesProvider hiddenLibraries;
  late ThemeProvider theme;
  late SeerrAccountProvider seerr;
  late DownloadManagerService downloadManager;
  late DownloadProvider downloadProvider;
  late AccountPreferencesController accountPreferences;

  setUpAll(() {
    originalPathProvider = PathProviderPlatform.instance;
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    temporaryDirectory = await Directory.systemTemp.createTemp('heisuca_test_');
    PathProviderPlatform.instance = FakePathProvider(temporaryDirectory);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    await SettingsService.getInstance();

    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    final connections = ConnectionRegistry(database);
    final profileConnections = ProfileConnectionRegistry(database);
    final profiles = ProfileRegistry(database);
    plexHome = PlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      plexHomeUserFetcher: (_) async => const [],
    );
    activeProfile = ActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      profileConnections: profileConnections,
    );
    libraries = LibrariesProvider();
    hiddenLibraries = HiddenLibrariesProvider(storageService: _FakeHiddenLibrariesStorage());
    await hiddenLibraries.ensureInitialized();
    theme = ThemeProvider();
    seerr = SeerrAccountProvider();
    accountPreferences = AccountPreferencesController();
    final settingsService = SettingsService.instance;
    final storageService = DownloadStorageService.instance;
    await storageService.initialize(settingsService);
    downloadManager = DownloadManagerService(
      database: database,
      storageService: _WritableDownloadStorage(),
      clientResolver: (_, {clientScopeId}) => null,
      downloadLocationReader: () => (path: null, type: null),
      downloadPathWriter: (_) async {},
      downloadPathTypeWriter: (_) async {},
      downloadStorageRefresher: () async {},
    )..recoveryFuture = Future<void>.value();
    downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: database);
    await downloadProvider.ensureInitialized();
  });

  tearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    hiddenLibraries.dispose();
    libraries.dispose();
    theme.dispose();
    seerr.dispose();
    activeProfile.dispose();
    accountPreferences.dispose();
    await plexHome.dispose();
    await database.close();
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = originalPathProvider;
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  Future<void> pumpAppWithNavigator(
    WidgetTester tester, {
    required GlobalKey<NavigatorState> navKey,
  }) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: activeProfile),
            ChangeNotifierProvider.value(value: libraries),
            ChangeNotifierProvider.value(value: hiddenLibraries),
            ChangeNotifierProvider.value(value: theme),
            ChangeNotifierProvider.value(value: seerr),
            ChangeNotifierProvider.value(value: downloadProvider),
            ChangeNotifierProvider.value(value: accountPreferences),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            theme: cgflixAppTheme(),
            home: const Scaffold(body: Text('RootSettingsScreen')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final section in HeisucaSettingsSection.values) {
    testWidgets('F6: seção ${section.name} não intercepta com OverlaySheetHost e sai por handlePopRoute e gesto preditivo', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final navKey = GlobalKey<NavigatorState>();
        await pumpAppWithNavigator(tester, navKey: navKey);

        navKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => SettingsScreen(heisucaSection: section),
          ),
        );
        await tester.pumpAndSettle();

        final sectionFinder = find.byType(SettingsScreen);
        expect(sectionFinder, findsOneWidget);

        // Na raiz da correção: a tela da seção Heisuca não deve ser embrulhada em OverlaySheetHost
        // (OverlaySheetHost(canPop: true) instala PopScope que intercepta e quebra o gesto)
        expect(
          find.descendant(of: sectionFinder, matching: find.byType(OverlaySheetHost)),
          findsNothing,
          reason: 'Seções Heisuca não devem usar OverlaySheetHost para não competir com o gesto de voltar',
        );

        // Simula gesto preditivo (startBackGesture -> commitBackGesture)
        final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('startBackGesture', <String, dynamic>{
            'touchOffset': <double>[5.0, 300.0],
            'progress': 0.0,
            'swipeEdge': 0, // left
          }),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          startMessage,
          (ByteData? _) {},
        );

        final ByteData commitMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('commitBackGesture'),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          commitMessage,
          (ByteData? _) {},
        );
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsNothing, reason: 'Gesto preditivo deve remover a rota da seção');
        expect(find.text('RootSettingsScreen'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('F6: seção ${section.name} sai com handlePopRoute', (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await pumpAppWithNavigator(tester, navKey: navKey);

      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SettingsScreen(heisucaSection: section),
        ),
      );
      await tester.pumpAndSettle();

      final popped = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.text('RootSettingsScreen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
