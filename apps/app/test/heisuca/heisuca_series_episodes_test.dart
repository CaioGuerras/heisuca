import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/heisuca/player/heisuca_series_episodes.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/settings_service.dart';
import '../test_helpers/prefs.dart';

MediaItem episode(int index, {int season = 1}) => MediaItem.jellyfin(
  id: '$season-$index', serverId: 'episodes', kind: MediaKind.episode, title: 'Nome $index',
  grandparentId: 'series', grandparentTitle: 'Série', parentId: 'season-$season',
  parentIndex: season, index: index, durationMs: 1200000);
class _Episodes extends MediaServerClient {
  final calls = <String>[];
  @override ServerId get serverId => ServerId('episodes');
  @override MediaBackend get backend => MediaBackend.jellyfin;
  @override Future<List<MediaItem>> fetchChildren(String id) async {
    calls.add(id);
    if (id == 'series') return [
      for (final n in [1, 2]) MediaItem.jellyfin(id: 'season-$n', serverId: 'episodes',
        kind: MediaKind.season, title: 'Temporada $n', index: n),
    ];
    return id == 'season-1' ? List.generate(16, (i) => episode(i + 1)) : [episode(1, season: 2)];
  }
  @override dynamic noSuchMethod(Invocation invocation) => null;
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('código do episódio usa título próprio e filme não abre temporadas', () {
    final ep = episode(16).copyWith(parentIndex: 5);
    expect(heisucaPlayerEpisodeLine(ep), 'T5 · E16 · Nome 16');
    expect(heisucaPlayerSeriesId(ep), 'series');
    expect(heisucaPlayerSeriesId(MediaItem.jellyfin(id: 'film', kind: MediaKind.movie)), isNull);
  });
  testWidgets('título da série abre o seletor pelo callback, sem depender de logo', (tester) async {
    var opened = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 240, height: 100,
      child: HeisucaPlayerTitle(metadata: episode(16), onEpisodes: () => opened++)))));
    await tester.pump();
    expect(find.text('Série'), findsOneWidget);
    expect(find.text('T1 · E16 · Nome 16'), findsOneWidget);
    await tester.tap(find.text('Série')); await tester.pump();
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('seletor abre no episódio atual e escolhe episódio de outra temporada', (tester) async {
    resetSharedPreferencesForTest(); SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.hideSpoilers, false);
    tester.view.physicalSize = const Size(412, 900); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = _Episodes();
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final multi = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(multi.dispose); addTearDown(manager.dispose);
    MediaItem? selected;
    await tester.pumpWidget(ChangeNotifierProvider.value(value: multi, child: MaterialApp(
      home: Builder(builder: (context) => Scaffold(body: Center(child: TextButton(
        onPressed: () async => selected = await showHeisucaSeriesEpisodes(context, episode(16)),
        child: const Text('Abrir'))))))));
    await tester.tap(find.text('Abrir')); await tester.pumpAndSettle();
    expect(find.text('16. Nome 16').hitTestable(), findsOneWidget);
    expect(client.calls, ['series', 'season-1']);
    await tester.tap(find.text('Temporada 2')); await tester.pumpAndSettle();
    expect(client.calls.last, 'season-2');
    await tester.tap(find.text('1. Nome 1')); await tester.pumpAndSettle();
    expect(selected?.id, '2-1');
    expect(tester.takeException(), isNull);
  });
  test('protótipo antigo removido não volta ao app', () {
    // Caio, 25/10, B: protótipo sem uso retirado; o HUD real continua no player.
    expect(File('lib/heisuca/heisuca_player_screen.dart').existsSync(), isFalse);
    final references = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path == 'lib/heisuca/heisuca_player_screen.dart') continue;
      final code = file.readAsStringSync();
      if (code.contains('HeisucaPlayerScreen') || code.contains('heisuca_player_screen.dart')) references.add(file.path);
    }
    expect(references, isEmpty, reason: 'Caio, 24/10: confirmar no ramo real antes de remover o protótipo em commit próprio.');
  });
}
