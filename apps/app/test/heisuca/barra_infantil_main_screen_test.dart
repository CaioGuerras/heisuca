import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/cgflix_palette.dart';
import 'package:heisuca/design/componentes/barra_flutuante.dart';
import 'package:heisuca/features/baixados/ligacao.dart';
import 'package:heisuca/features/casca/casca.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids.dart';
import 'package:heisuca/navigation/profile_navigation_scope.dart';
import 'package:heisuca/profiles/active_profile_binder.dart';
import 'package:heisuca/profiles/plex_home_service.dart';
import 'package:heisuca/providers/catalog_sources_provider.dart';
import 'package:heisuca/providers/playback_state_provider.dart';
import 'package:heisuca/screens/main_screen.dart';
import 'package:heisuca/services/offline_watch_sync_service.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/platform_detector.dart';
import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';

class _Binder implements ActiveProfileBinder {
  @override
  void start({bool allowInitialPinPrompt = true}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PlexHome implements PlexHomeService {
  @override
  Future<void> start() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sync extends ChangeNotifier implements OfflineWatchSyncService {
  @override
  void onServersConnected() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _quadros(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// A barra flutuante da tela principal de verdade (não só o predicado), no celular Android.
void main() {
  late HeisucaP3Fixture fixture;

  Future<void> preparar(String cenario, {required bool infantil}) async {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetTvOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    PackageInfo.setMockInitialValues(
      appName: 'Heisuca',
      packageName: 'app.heisuca.player.teste.home',
      version: '2.0.40',
      buildNumber: '3025',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    // Fecho de janela do computador: sem efeito no celular, mas o canal é chamado na montagem.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      (call) async => null,
    );
    HeisucaKids.instance.debugReset();
    fixture = HeisucaP3Fixture(scenario: cenario);
    await fixture.initialize(settings.ThemeMode.dark);
    if (infantil) {
      // O perfil ativo da fixture ('familia') passa a ser o infantil.
      await HeisucaKids.instance.save(
        const HeisucaKidsRecord(
          parentProfileId: 'responsavel',
          kidsProfileId: 'familia',
          variant: CgflixThemeVariant.ichigo,
          ceiling: 'livre',
          pinHash: 'pin',
          name: 'Criança',
        ),
      );
    }
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      null,
    );
    TvDetectionService.debugSetTvOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    HeisucaKids.instance.debugReset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  Future<void> montar(WidgetTester tester, {bool semConexao = false}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final navigator = GlobalKey<NavigatorState>();
    final observer = RouteObserver<PageRoute<dynamic>>();
    await tester.pumpWidget(
      fixture.wrap(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CatalogSourcesProvider()),
            ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
            Provider<ActiveProfileBinder>.value(value: _Binder()),
            Provider<PlexHomeService>.value(value: _PlexHome()),
            ChangeNotifierProvider<OfflineWatchSyncService>.value(value: _Sync()),
            ChangeNotifierProvider<HeisucaKids>.value(value: HeisucaKids.instance),
          ],
          child: MaterialApp(
            theme: cgflixDarkTheme(),
            navigatorKey: navigator,
            navigatorObservers: [observer],
            home: ProfileNavigationScope(
              navigatorKey: navigator,
              routeObserver: observer,
              mainScaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
              child: MainScreen(initialPromptHandled: true, isOfflineMode: semConexao),
            ),
          ),
        ),
      ),
    );
    // A Início tem animação contínua: quadros com tempo fixo, sem esperar tudo parar.
    await _quadros(tester, 12);
    expect(find.byType(Casca), findsOneWidget);
  }

  Future<void> encerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await fixture.dispose();
    });
  }

  Finder naBarra(String rotulo) => find.descendant(of: find.byType(BarraFlutuante), matching: find.text(rotulo));

  testWidgets('fora do modo infantil a barra mostra os baixados e o toque abre a tela deles', (tester) async {
    await tester.runAsync(() => preparar('normal', infantil: false));
    addTearDown(() => encerrar(tester));
    await montar(tester);
    expect(naBarra('Início'), findsOneWidget);
    expect(naBarra('Baixados'), findsOneWidget);
    expect(find.byType(LigacaoDosBaixados), findsNothing);

    await tester.tap(naBarra('Baixados'));
    await _quadros(tester, 6);
    expect(find.byType(LigacaoDosBaixados), findsOneWidget);
    expect(tester.widget<Casca>(find.byType(Casca)).indice, 3);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('modo infantil com conexão: a barra fica sem os baixados', (tester) async {
    await tester.runAsync(() => preparar('normal', infantil: true));
    addTearDown(() => encerrar(tester));
    await montar(tester);
    expect(naBarra('Início'), findsOneWidget);
    expect(naBarra('Minha lista'), findsOneWidget);
    expect(naBarra('Baixados'), findsNothing);
    expect(tester.widget<Casca>(find.byType(Casca)).destinos, hasLength(3));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('modo infantil sem conexão: os baixados voltam para a barra', (tester) async {
    await tester.runAsync(() => preparar('offline', infantil: true));
    addTearDown(() => encerrar(tester));
    await montar(tester, semConexao: true);
    // Sem conexão a tela já abre nos baixados, e a barra marca onde a pessoa está.
    expect(naBarra('Baixados'), findsOneWidget);
    expect(find.byType(LigacaoDosBaixados), findsOneWidget);
    expect(tester.widget<Casca>(find.byType(Casca)).indice, 3);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
