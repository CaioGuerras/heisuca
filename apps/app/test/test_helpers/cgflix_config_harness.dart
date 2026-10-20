// Monta as Configurações reais com tudo o que elas leem (perfis, bibliotecas, contas, baixados),
// para os testes e as capturas do refino 2b.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/account_preferences.dart';
import 'package:plezy/media/account_preferences_source.dart';
import 'package:plezy/media/account_preferences_target.dart';
import 'package:plezy/media/account_ref.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_user_profile.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/services/account_preferences_accounts.dart';
import 'package:plezy/services/account_preferences_repository.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import 'backend_client_fixtures.dart';
import 'io_fakes.dart';
import 'prefs.dart';

/// Conta Jellyfin de mentira com áudio e legenda em português (como o CGFLIX configura).
const configRef = AccountRef.mediaBrowser(backend: MediaBackend.jellyfin, connectionId: 'srv-1/user-1');
const configAlvo = AccountPreferenceTarget(
  ref: configRef,
  label: 'CGFLIX',
  subtitle: 'caioguerras',
  isDefaultConnection: true,
);

class _FonteDaConta implements AccountPreferencesSource {
  @override
  AccountPreferencesCapabilities get capabilities => AccountPreferencesCapabilities.jellyfin;

  @override
  Future<AccountPreferences> read() async => const AccountPreferences(
    preferredAudioLanguage: 'por',
    playDefaultAudioTrack: false,
    preferredSubtitleLanguage: 'por',
    subtitlePlaybackMode: SubtitlePlaybackMode.smart,
    displayMissingEpisodes: false,
    hidePlayedInLatest: true,
    displayCollectionsView: false,
  );

  @override
  Future<AccountPreferences> write(AccountPreferencesPatch patch, {void Function()? checkCurrent}) => read();
}

class _ContaFalsa extends AccountPreferencesController {
  _ContaFalsa(this._repositorio);
  final AccountPreferencesRepository _repositorio;

  @override
  AccountPreferencesRepository get repository => _repositorio;

  @override
  List<AccountPreferenceAccount> get accounts => [
    AccountPreferenceAccount(
      target: configAlvo,
      connection: testJellyfinConnection(userName: 'caioguerras'),
    ),
  ];
}

class _Bibliotecas extends LibrariesProvider {
  @override
  List<MediaLibrary> get libraries => const [];
}

class _SemBibliotecasOcultas implements StorageService {
  @override
  Set<String> getHiddenLibraries() => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PastaGravavel extends Fake implements DownloadStorageService {
  @override
  Future<bool> isDirectoryWritable(Directory dir) async => true;
}

/// Monta [home] com tudo que as Configurações leem (perfis, bibliotecas, contas, baixados).
Future<void> montarConfiguracoes(
  WidgetTester tester,
  CgflixThemeVariant variante,
  double escala,
  Widget home, {
  Size? tamanho,
}) async {
  // Bem alta para caber a lista inteira; 200% precisa do dobro.
  final tela = tamanho ?? Size(412, escala > 1 ? 3600 : 2000);
  tester.view.physicalSize = tela * 1.5;
  tester.view.devicePixelRatio = 1.5;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final database = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(database.close);
  final connections = ConnectionRegistry(database);
  final profileConnections = ProfileConnectionRegistry(database);
  final plexHome = PlexHomeService(
    connections: connections,
    profileConnections: profileConnections,
    plexHomeUserFetcher: (_) async => const [],
  );
  final perfis = ActiveProfileProvider(
    registry: ProfileRegistry(database),
    plexHome: plexHome,
    connections: connections,
    profileConnections: profileConnections,
  );
  final ocultas = HiddenLibrariesProvider(storageService: _SemBibliotecasOcultas());
  await ocultas.ensureInitialized();
  final repositorio = AccountPreferencesRepository(sourceFor: (_) async => _FonteDaConta());
  final settingsService = SettingsService.instance;
  await tester.runAsync(() => DownloadStorageService.instance.initialize(settingsService));
  final downloads = DownloadManagerService(
    database: database,
    storageService: _PastaGravavel(),
    clientResolver: (_, {clientScopeId}) => null,
    downloadLocationReader: () => (path: null, type: null),
    downloadPathWriter: (_) async {},
    downloadPathTypeWriter: (_) async {},
    downloadStorageRefresher: () async {},
  )..recoveryFuture = Future<void>.value();
  final theme = ThemeProvider();
  addTearDown(theme.dispose);

  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('cgflix-captura'),
      child: TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ChangeNotifierProvider<ActiveProfileProvider>.value(value: perfis),
            ChangeNotifierProvider<LibrariesProvider>.value(value: _Bibliotecas()),
            ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: ocultas),
            ChangeNotifierProvider<TrackersProvider>.value(value: TrackersProvider()),
            ChangeNotifierProvider<SeerrAccountProvider>.value(value: SeerrAccountProvider()),
            ChangeNotifierProvider<DownloadProvider>.value(
              value: DownloadProvider.forTesting(downloadManager: downloads, database: database),
            ),
            ChangeNotifierProvider<AccountPreferencesController>.value(value: _ContaFalsa(repositorio)),
            Provider<AccountPreferencesRepository>.value(value: repositorio),
          ],
          child: MaterialApp(
            key: UniqueKey(), // cada montagem começa do zero (sem subtela aberta da anterior)
            debugShowCheckedModeBanner: false,
            theme: cgflixAppTheme(variante).copyWith(platform: TargetPlatform.android),
            home: home,
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// setUp/tearDown das Configurações: preferências limpas, pasta dos baixados de mentira e celular
/// (nem TV nem computador).
void prepararConfiguracoes() {
  late Directory temporario;
  late PathProviderPlatform caminhosOriginais;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    temporario = await Directory.systemTemp.createTemp('cgflix_config_');
    caminhosOriginais = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(temporario);
    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    await SettingsService.getInstance();
  });

  tearDown(() async {
    TvDetectionService.debugSetAppleTVOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    DownloadStorageService.resetForTesting();
    PathProviderPlatform.instance = caminhosOriginais;
    if (temporario.existsSync()) await temporario.delete(recursive: true);
  });
}
