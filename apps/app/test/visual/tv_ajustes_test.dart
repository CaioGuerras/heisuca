// Ajustes e Atualizações da TV (960×540 dp, densidade 2), para revisão visual.
//   HEISUCA_SNAPSHOT=1 flutter test test/visual/tv_ajustes_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/requests/cgflix_secure_store.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_settings_screen.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/screens/updates/update_settings_screen.dart';
import 'package:heisuca/services/playback_diagnostics.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/services/updates/apk_installer.dart';
import 'package:heisuca/services/updates/update_controller.dart';
import 'package:heisuca/services/updates/update_feed_client.dart';
import 'package:heisuca/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';
import 'heisuca_snapshot.dart';

void main() {
  const nativo = MethodChannel('app.heisuca/updates');
  late HeisucaP3Fixture fixture;
  late UpdateController atualizacoes;

  setUp(() async {
    resetSharedPreferencesForTest();
    await LocaleSettings.setLocale(AppLocale.pt);
    TvDetectionService.debugSetTvOverride(true);
    fixture = HeisucaP3Fixture();
    await fixture.initialize(settings.ThemeMode.dark);
    final pasta = await Directory.systemTemp.createTemp('heisuca-tv-ajustes-visual-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(nativo, (call) async {
      return switch (call.method) {
        'estado' => {'habilitado': true, 'build': 3032, 'versao': '2.0.47', 'espacoLivre': 999999999},
        _ => null,
      };
    });
    final config = ConfiguracaoAtualizacao(feed: 'https://feed.example/');
    atualizacoes = UpdateController(
      config: config,
      feed: UpdateFeedClient(config),
      instalador: ApkInstaller(diagnosticos: PlaybackDiagnosticStore(directory: () async => pasta)),
      settings: settings.SettingsService.instanceOrNull!,
      segredos: CgflixMemorySecureStore(),
      emReproducao: () => true,
      cache: () async => pasta,
    );
  });

  tearDown(() {
    atualizacoes.dispose();
    TvDetectionService.debugSetTvOverride(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(nativo, null);
  });

  Future<void> montar(WidgetTester tester, Widget tela, {double letra = 1}) async {
    await heisucaLoadFonts();
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      fixture.wrap(
        ChangeNotifierProvider<UpdateController>.value(
          value: atualizacoes,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: cgflixDarkTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
              child: child!,
            ),
            home: tela,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> descer(WidgetTester tester, int vezes) async {
    for (var i = 0; i < vezes; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
  }

  for (final (nome, descidas, letra) in [('entrada', 0, 1.0), ('atualizacoes', 7, 1.0), ('letra_200', 4, 2.0)]) {
    testWidgets('Ajustes da TV: $nome', (tester) async {
      await montar(tester, const HeisucaTvSettingsScreen(), letra: letra);
      await descer(tester, descidas);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/tv_ajustes_$nome.png'));
    }, skip: !heisucaSnapshotEnabled);
  }

  testWidgets('Atualizações na TV', (tester) async {
    await tester.runAsync(atualizacoes.iniciar);
    await montar(tester, UpdateSettingsScreen(controlador: atualizacoes));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/tv_atualizacoes.png'));
  }, skip: !heisucaSnapshotEnabled);
}
