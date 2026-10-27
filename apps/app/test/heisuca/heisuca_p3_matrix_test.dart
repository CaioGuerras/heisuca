import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_home_screen.dart';
import 'package:heisuca/heisuca/heisuca_library_screen.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/heisuca/heisuca_news.dart';
import 'package:heisuca/heisuca/heisuca_profile_screen.dart';
import 'package:heisuca/heisuca/heisuca_settings_screen.dart';
import 'package:heisuca/heisuca/heisuca_title_sheet.dart';
import 'package:heisuca/heisuca/heisuca_context_menu.dart';
import 'package:heisuca/heisuca/heisuca_floating_island.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids_flow.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/screens/search_screen.dart';
import 'package:heisuca/screens/downloads/downloads_screen.dart';
import 'package:heisuca/screens/settings/about_screen.dart';
import 'package:heisuca/screens/profile/profile_switch_screen.dart';
import 'package:heisuca/screens/settings/settings_screen.dart';
import 'package:heisuca/screens/settings/general_settings_screen.dart';
import 'package:heisuca/screens/settings/appearance_settings_screen.dart';
import 'package:heisuca/screens/settings/playback_settings_screen.dart';
import 'package:heisuca/screens/settings/subtitle_styling_screen.dart';
import 'package:heisuca/screens/settings/services_settings_screen.dart';
import 'package:heisuca/screens/settings/mpv_config_screen.dart';
import 'package:heisuca/screens/settings/external_player_screen.dart';
import 'package:heisuca/screens/settings/licenses_screen.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/heisuca_tap_targets.dart';
import '../visual/heisuca_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment('P3_PHASE');
  final capturePhase = Platform.environment['P3_CAPTURE_PHASE'] ?? phase;
  final onlyScreen = Platform.environment['P3_SCREEN'];
  final onlyCase = Platform.environment['P3_CASE'];
  final quick = Platform.environment['P3_QUICK'] == '1';
  setUp(resetSharedPreferencesForTest);
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.pt);
    PackageInfo.setMockInitialValues(appName: 'Heisuca', packageName: 'app.heisuca.player.teste.home',
      version: '2.0.34', buildNumber: '2036', buildSignature: '');
    await heisucaLoadFonts();
    await (FontLoader('Sora')..addFont(rootBundle.load('assets/fonts/Sora-VF.ttf'))).load();
  });
  final screens = <String, Widget Function(HeisucaP3Fixture)> {
    'login': (_) => const HeisucaLoginScreen(),
    'inicio': (_) => const HeisucaHomeScreen(),
    'biblioteca': (_) => const HeisucaLibraryScreen(),
    'busca': (_) => const SearchScreen(),
    'baixados': (_) => const DownloadsScreen(),
    'voce': (_) => const HeisucaProfileScreen(),
    'config-geral': (_) => const HeisucaSettingsScreen(),
    'config-avancada': (_) => const HeisucaSettingsScreen(),
    'sobre': (_) => const AboutScreen(),
    'novidades': (_) => const HeisucaNewsScreen(),
    'kids-config': (_) => const HeisucaKidsSetupScreen(),
    'ficha-filme': (f) => Builder(builder: (c) => HeisucaTitleSheet(hostContext: c, item: f.movie)),
    'ficha-serie': (f) => Builder(builder: (c) => HeisucaTitleSheet(hostContext: c, item: f.show)),
    'perfis': (_) => const ProfileSwitchScreen(),
    'config-completas': (_) => const SettingsScreen(),
    'config-basicas': (_) => const GeneralSettingsScreen(),
    'config-aparencia': (_) => const AppearanceSettingsScreen(),
    'config-reproducao': (_) => const PlaybackSettingsScreen(),
    'config-reproducao-avancada': (_) => const PlaybackSettingsScreen(cgflixTechnical: true),
    'config-legendas': (_) => const SubtitleStylingScreen(),
    'config-servicos': (_) => const ServicesSettingsScreen(),
    'config-mpv': (_) => const MpvConfigScreen(),
    'config-player-externo': (_) => const ExternalPlayerScreen(),
    'licencas': (_) => const LicensesScreen(),
    'barra-abas': (_) => Scaffold(body: Stack(children: [HeisucaFloatingIsland(currentIndex: 0, onDestinationSelected: (_) {})])),
    'menu-titulo': (f) => Scaffold(body: HeisucaContextMenu(item: f.movie)),
  };
  final modes = quick ? [settings.ThemeMode.oled] : [settings.ThemeMode.oled, settings.ThemeMode.light, settings.ThemeMode.dark];
  for (final mode in modes) {
    for (final (device, physical, dpr) in [
      ('moto', const Size(1080, 2400), 2.625),
      if (!quick) ('tab', const Size(1200, 1920), 1.5),
    ]) {
      for (final landscape in quick ? [false] : [false, true]) {
        for (final scale in [1.0, 2.0]) {
          for (final screen in screens.entries.where((e) => onlyScreen == null || e.key == onlyScreen)) {
            final tag = '${screen.key}-${mode.name}-$device-${landscape ? "paisagem" : "retrato"}-f${(scale * 100).round()}';
            if (onlyCase != null && tag != onlyCase) continue;
            testWidgets('P3 matriz $tag', (tester) async {
              final f = HeisucaP3Fixture();
              await tester.runAsync(() => f.initialize(mode));
              addTearDown(() => tester.runAsync(f.dispose));
              tester.view.devicePixelRatio = dpr;
              tester.view.physicalSize = landscape ? Size(physical.height, physical.width) : physical;
              tester.view.padding = FakeViewPadding(top: 24 * dpr, bottom: 24 * dpr);
              addTearDown(tester.view.reset);
              final boundary = GlobalKey();
              final semantics = tester.ensureSemantics();
              final errors = <String>[];
              final layoutDiagnostics = <String>[];
              final original = FlutterError.onError;
              FlutterError.onError = (details) {
                final message = details.exceptionAsString();
                errors.add(message);
                if (details.library == 'rendering library' && message.contains('RenderFlex overflowed')) {
                  final diagnostic = details.toString();
                  if (!layoutDiagnostics.contains(diagnostic)) layoutDiagnostics.add(diagnostic);
                }
                if (!(details.library == 'rendering library' && message.contains('RenderFlex overflowed'))) {
                  original?.call(details);
                }
              };
              try {
                await tester.pumpWidget(f.wrap(MaterialApp(
                  theme: mode == settings.ThemeMode.light ? cgflixLightTheme() : cgflixDarkTheme(mode),
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale), disableAnimations: true),
                    child: RepaintBoundary(key: boundary, child: child!)),
                  initialRoute: {'login', 'inicio', 'biblioteca', 'busca', 'baixados', 'voce', 'barra-abas'}.contains(screen.key) ? '/' : '/alvo',
                  routes: {
                    '/': (_) => {'login', 'inicio', 'biblioteca', 'busca', 'baixados', 'voce', 'barra-abas'}.contains(screen.key)
                        ? f.scope(KeyedSubtree(key: const ValueKey('p3-scene'), child: screen.value(f)))
                        : const Scaffold(body: SizedBox()),
                    '/alvo': (_) => f.scope(KeyedSubtree(key: const ValueKey('p3-scene'), child: screen.value(f))),
                  },
                )));
                await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 60)));
                for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
                final sceneContext = tester.element(find.byKey(const ValueKey('p3-scene')));
                expect(ModalRoute.of(sceneContext)?.isCurrent, isTrue);
                expect(Navigator.of(sceneContext).canPop(),
                    !{'login', 'inicio', 'biblioteca', 'busca', 'baixados', 'voce', 'barra-abas'}.contains(screen.key));
                if (screen.key == 'config-avancada') {
                  await tester.tap(find.text('Avançado'));
                  for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
                }
                final pages = <Map<String, Object?>>[];
                final out = Directory('../../docs/evidencias/p3/$capturePhase');
                final representative = device == 'moto' && !landscape && scale == 1 ||
                    mode == settings.ThemeMode.oled && device == 'tab' && landscape && scale == 2;
                Future<void> capture(String suffix) async {
                  if (capturePhase.isEmpty) return;
                  final name = '$tag$suffix';
                  final pairedBefore = File('../../docs/evidencias/p3/antes/$name.png').existsSync();
                  if (!representative && errors.isEmpty && !pairedBefore && Platform.environment['P3_CAPTURE_ALL'] != '1') return;
                  out.createSync(recursive: true);
                  final render = boundary.currentContext?.findRenderObject();
                  if (render is RenderRepaintBoundary && !render.debugNeedsPaint) {
                    await tester.runAsync(() async {
                      final frame = await render.toImage(pixelRatio: dpr);
                      expect(frame.width, tester.view.physicalSize.width.round());
                      expect(frame.height, tester.view.physicalSize.height.round());
                      final png = await frame.toByteData(format: ui.ImageByteFormat.png);
                      File('${out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
                      frame.dispose();
                    });
                  } else { errors.add('A tela não produziu um quadro capturável.'); }
                }
                var ended = false;
                var capturedFailure = false;
                for (var page = 0; page < 128; page++) {
                  final touch = await heisucaTapTargets.evaluate(tester);
                  if (!touch.passed) {
                    final issue = 'Alvo Android menor que 48 dp: ${touch.reason}';
                    if (!errors.contains(issue)) errors.add(issue);

                  }
                  pages.add({'pagina': page, 'errosAteAqui': errors.length});
                  final suffix = page == 0 ? '' : '-rolagem-$page';
                  final paired = File('../../docs/evidencias/p3/antes/$tag$suffix.png').existsSync();
                  if (page == 0 || representative || paired || errors.isNotEmpty && !capturedFailure) {
                    await capture(suffix);
                    if (errors.isNotEmpty) capturedFailure = true;
                  }
                  final positions = find.byType(Scrollable).evaluate()
                      .map((element) => ((element as StatefulElement).state as ScrollableState).position)
                      .where((position) => position.axis == Axis.vertical && position.hasContentDimensions &&
                          position.maxScrollExtent - position.pixels > 1);
                  if (positions.isEmpty) {
                    if (page > 0) await capture('-fim');
                    ended = true;
                    break;
                  }
                  final position = positions.first;
                  final next = (position.pixels + position.viewportDimension * .8).clamp(0.0, position.maxScrollExtent);
                  position.jumpTo(next);
                  await tester.pump(const Duration(milliseconds: 100));
                  await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 2)));
                  await tester.pump();
                }
                if (!ended) errors.add('A lista não terminou na fixture em 128 janelas.');
                if (capturePhase.isNotEmpty) {
                  out.createSync(recursive: true);
                  File('${out.path}/$tag.json').writeAsStringSync(jsonEncode({
                    'tela': screen.key, 'tema': mode.name, 'dispositivo': device,
                    'larguraPx': tester.view.physicalSize.width, 'alturaPx': tester.view.physicalSize.height,
                    'dpr': dpr, 'fonte': scale, 'alvoFlutter': 'android', 'insetsLogicos': {'top': 24, 'bottom': 24}, 'erros': errors, 'diagnosticosLayout': layoutDiagnostics, 'paginasVerificadas': pages,
                    'limite': 'widget real com fixture local em host Linux; não é teste nativo/em aparelho/servidor real',
                  }));
                }
                await tester.pumpWidget(const SizedBox());
                await tester.pump();
              } finally { FlutterError.onError = original; semantics.dispose(); }
              expect(errors, isEmpty, reason: tag);
            }, variant: TargetPlatformVariant.only(TargetPlatform.android));
          }
        }
      }
    }
  }
}
