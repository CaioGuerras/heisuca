// Tela de Atualizações (celular) em três situações, para revisão visual.
//   HEISUCA_SNAPSHOT=1 flutter test test/visual/atualizacoes_test.dart --update-goldens
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/requests/cgflix_secure_store.dart';
import 'package:heisuca/screens/updates/update_settings_screen.dart';
import 'package:heisuca/services/playback_diagnostics.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/services/updates/apk_installer.dart';
import 'package:heisuca/services/updates/update_controller.dart';
import 'package:heisuca/services/updates/update_feed_client.dart';
import 'package:heisuca/utils/platform_detector.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../test_helpers/prefs.dart';
import 'heisuca_snapshot.dart';

void main() {
  const nativo = MethodChannel('app.heisuca/updates');
  final bytes = List<int>.generate(128, (i) => i);

  Future<UpdateController> controlador({required bool comVersaoNova}) async {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetTvOverride(false);
    final settings = await SettingsService.getInstance();
    final pasta = await Directory.systemTemp.createTemp('heisuca-update-visual-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(nativo, (call) async {
      return switch (call.method) {
        'estado' => {'habilitado': true, 'build': 3016, 'versao': '2.0.36', 'espacoLivre': 999999999},
        'escolherAbi' => 'universal',
        _ => null,
      };
    });
    final config = ConfiguracaoAtualizacao(feed: 'https://feed.example/');
    final feed = UpdateFeedClient(
      config,
      cliente: MockClient((r) async {
        final canal = r.url.path.contains('/teste/') ? 'teste' : 'estavel';
        // Em bytes UTF-8: com corpo em texto, o pacote http mandaria os acentos em Latin-1.
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'canal': canal,
              'build': comVersaoNova ? 3018 : 3016,
              'versao': '2.0.36',
              'notas':
                  'Novo\n- Em título do Jellyfin, o botão é o coração "Favoritar".\n'
                  '- Em servidor Plex, o botão é o marcador "Minha lista".',
              'assinatura_sha256': 'b' * 64,
              'apks': [
                {
                  'abi': 'universal',
                  'url': 'https://feed.example/app.apk',
                  'bytes': bytes.length,
                  'sha256': sha256.convert(bytes).toString(),
                },
              ],
            }),
          ),
          200,
        );
      }),
    );
    return UpdateController(
      config: config,
      feed: feed,
      instalador: ApkInstaller(diagnosticos: PlaybackDiagnosticStore(directory: () async => pasta)),
      settings: settings,
      segredos: CgflixMemorySecureStore(),
      emReproducao: () => false,
      cache: () async => pasta,
    );
  }

  tearDown(() {
    TvDetectionService.debugSetTvOverride(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(nativo, null);
  });

  for (final (nome, comVersaoNova, codigo) in [
    ('em_dia', false, ''),
    ('versao_nova', true, ''),
    ('com_codigo', false, 'LCDbeta'),
  ]) {
    testWidgets('Atualizações: $nome', (tester) async {
      await heisucaLoadFonts();
      heisucaPhoneView(tester);
      final c = await tester.runAsync(() => controlador(comVersaoNova: comVersaoNova));
      addTearDown(c!.dispose);
      await tester.runAsync(c.iniciar);
      if (codigo.isNotEmpty) await tester.runAsync(() => c.definirCodigo(codigo));
      await tester.runAsync(() => c.verificar(manual: true));
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: cgflixDarkTheme(),
          home: UpdateSettingsScreen(controlador: c),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/atualizacoes_$nome.png'));
    }, skip: !heisucaSnapshotEnabled);
  }
}
