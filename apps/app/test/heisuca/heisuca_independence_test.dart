import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_trakt.dart';
import 'package:plezy/screens/settings/tracker_service_info.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';

void main() {
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
    expect(cgflixShowsTracker(TrackerService.mal), isFalse);
    expect(cgflixShowsTracker(TrackerService.anilist), isFalse);
    expect(TrackerServiceInfo.all.map((info) => info.service).toSet(), {
      TrackerService.trakt, TrackerService.simkl, TrackerService.mdblist,
    });
  });
}
