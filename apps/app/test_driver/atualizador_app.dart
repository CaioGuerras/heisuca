// Entrada exclusiva da bancada: feed TLS local e dados sintéticos, sem login ou acervo.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/requests/cgflix_secure_store.dart';
import 'package:heisuca/screens/updates/update_screen.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/services/updates/apk_installer.dart';
import 'package:heisuca/services/updates/update_controller.dart';
import 'package:heisuca/services/updates/update_feed_client.dart';
import 'package:heisuca/utils/platform_detector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = ConfiguracaoAtualizacao.doBuild();
  if (kReleaseMode || config.origem?.host != '10.0.2.2') throw StateError('Entrada exclusiva de bancada local.');
  const certificado = String.fromEnvironment('HEISUCA_UPDATE_TEST_CA');
  if (certificado.isEmpty) throw StateError('Falta a CA sintética da bancada.');
  final tls = SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(base64Decode(certificado));
  TvDetectionService.debugSetTvOverride(true);
  final settings = await SettingsService.getInstance();
  final controlador = UpdateController(
    config: config,
    feed: UpdateFeedClient(config, cliente: IOClient(HttpClient(context: tls))),
    instalador: const ApkInstaller(),
    settings: settings,
    segredos: CgflixSecureStore.platform(),
    emReproducao: () => false,
  );
  runApp(
    ChangeNotifierProvider.value(
      value: controlador,
      child: MaterialApp(theme: cgflixDarkTheme(), home: const UpdateScreen()),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(controlador.aoAbrir()));
}
