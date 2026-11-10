import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:heisuca/screens/main_screen.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/screens/profile/profile_switch_screen.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_home_screen.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_menu.dart';
import 'package:heisuca/navigation/profile_navigation_scope.dart';
import 'package:heisuca/providers/catalog_sources_provider.dart';
import 'package:heisuca/providers/playback_state_provider.dart';
import 'package:heisuca/profiles/active_profile_binder.dart';
import 'package:heisuca/profiles/plex_home_service.dart';
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

void main() {
  late HeisucaP3Fixture fixture;
  late GlobalKey<NavigatorState> navigator;
  late List<MethodCall> platformCalls;
  setUp(() async {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetTvOverride(true);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    PackageInfo.setMockInitialValues(
      appName: 'Heisuca',
      packageName: 'app.heisuca.player.teste.home',
      version: '2.0.34',
      buildNumber: '39',
      buildSignature: '',
    );
    fixture = HeisucaP3Fixture();
    await fixture.initialize(settings.ThemeMode.dark);
    navigator = GlobalKey<NavigatorState>();
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
  });
  tearDown(() {
    TvDetectionService.debugSetTvOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
  int exits() => platformCalls.where((call) => call.method == 'SystemNavigator.pop').length;
  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          ],
          child: MaterialApp(
            theme: cgflixDarkTheme(),
            navigatorKey: navigator,
            navigatorObservers: [observer],
            home: ProfileNavigationScope(
              navigatorKey: navigator,
              routeObserver: observer,
              mainScaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
              child: const MainScreen(initialPromptHandled: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(HeisucaTvHomeScreen), findsOneWidget);
    tester.state<HeisucaTvHomeScreenState>(find.byType(HeisucaTvHomeScreen)).avatarFocusNode.requestFocus();
    await tester.pump();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await fixture.dispose();
    });
  }

  testWidgets('menu fecha no KeyDown; KeyUp órfão não sai; aperto completo seguinte sai', (tester) async {
    addTearDown(() => finish(tester));
    await mount(tester);
    await tester.tap(find.byKey(const Key('heisuca-tv-avatar-button')));
    await tester.pumpAndSettle();
    expect(find.byType(HeisucaTvMenu), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pump();
    expect(find.byType(HeisucaTvMenu), findsNothing);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(exits(), 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(exits(), 1);
  });
  testWidgets('Trocar perfil: fechamento durante aperto não deixa KeyUp sair na MainScreen', (tester) async {
    addTearDown(() => finish(tester));
    await mount(tester);
    await tester.tap(find.byKey(const Key('heisuca-tv-avatar-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trocar perfil'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSwitchScreen), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    // O sistema/rota pode terminar o fechamento antes de entregar a soltura.
    if (find.byType(ProfileSwitchScreen).evaluate().isNotEmpty) navigator.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pump();
    expect(find.byType(ProfileSwitchScreen), findsNothing);
    expect(find.byType(HeisucaTvMenu), findsNothing);
    tester.state<HeisucaTvHomeScreenState>(find.byType(HeisucaTvHomeScreen)).avatarFocusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(tester.state<HeisucaTvHomeScreenState>(find.byType(HeisucaTvHomeScreen)).avatarFocusNode.hasFocus, isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(exits(), 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(exits(), 1);
  });
  testWidgets('um aperto completo no destaque sai normalmente no Google TV', (tester) async {
    addTearDown(() => finish(tester));
    await mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(exits(), 1);
  });

  testWidgets('fora do Início, Voltar retorna e foca o destaque antes de sair', (tester) async {
    addTearDown(() => finish(tester));
    await mount(tester);
    await tester.tap(find.byKey(const Key('heisuca-tv-avatar-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(exits(), 0);
    final home = tester.state<HeisucaTvHomeScreenState>(find.byType(HeisucaTvHomeScreen));
    expect(home.heroPlayFocusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(exits(), 1);
  });
}
