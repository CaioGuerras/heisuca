import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_trakt.dart';
import 'package:heisuca/screens/settings/tracker_service_info.dart';
import 'package:heisuca/services/trackers/tracker_constants.dart';

void main() {
  test('L: app independente não inclui telemetria, destino Plezy nem Discord traduzido', () {
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('sentry_flutter:')));
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') && !file.path.endsWith('.json')) continue;
      final code = file.readAsStringSync();
      expect(code, isNot(contains('plezy.app')), reason: file.path);
      expect(code, isNot(contains('package:sentry')), reason: file.path);
      if (file.path.contains('/i18n/')) expect(code.toLowerCase(), isNot(contains('discord')), reason: file.path);
    }
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('namespace = "app.heisuca"'));
    expect(gradle, contains('"app.heisuca.player.teste.home"'));
    expect(gradle, contains('"app.heisuca.player.teste"'));
  });
  test('código do app não contém destino do relay retirado nem serviço Discord', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final code = file.readAsStringSync();
      if (code.contains('ice.plezy.app') || code.contains('DiscordRPCService') || code.contains('OAuthProxyClient')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });
  test('MAL/AniList não voltam pela opção de testes de mostrar todos os serviços', () {
    cgflixDebugShowAllServices = true;
    addTearDown(() => cgflixDebugShowAllServices = false);
    expect(TrackerServiceInfo.all.map((info) => info.service).toSet(), {TrackerService.trakt});
  });
}
