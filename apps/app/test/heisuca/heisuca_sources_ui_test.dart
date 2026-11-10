import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:heisuca/cgflix/cgflix_palette.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/search/cgflix_search_grouping.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/heisuca/heisuca_search_origin.dart';
import 'package:heisuca/heisuca/heisuca_sources_ui.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_person.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

void main() {
  tearDown(CgflixSourceRegistry.clear);
  test('origem conta servidores, respeita perfil e esquece associação antiga', () {
    final a = MediaItem.plex(id: '1', serverId: 'a', serverName: 'Casa', kind: MediaKind.movie, title: 'Filme');
    final b = a.copyWith(id: '2', serverId: 'b', serverName: 'Família');
    CgflixSourceRegistry.rememberTitles([CgflixTitleGroup([a, b, a.copyWith(id: 'outra-versao')])]);
    expect(heisucaSearchTitleOrigin(a), '2 fontes');
    expect(heisucaSearchTitleOrigin(a, visibleServerIds: {'a'}), 'Casa');
    CgflixSourceRegistry.rememberTitles([CgflixTitleGroup([a])]);
    expect(heisucaSearchTitleOrigin(a), 'Casa');
    final person = MediaPerson(id: 'p', name: 'Pessoa', backend: MediaBackend.plex, serverId: ServerId('a'), serverName: 'Casa');
    final other = MediaPerson(id: 'q', name: 'Pessoa', backend: MediaBackend.jellyfin, serverId: ServerId('b'), serverName: 'Família');
    CgflixSourceRegistry.rememberPeople([CgflixPersonGroup([person, other])]);
    expect(heisucaSearchPersonOrigin(person), '2 fontes');
    CgflixSourceRegistry.rememberPeople([CgflixPersonGroup([person])]);
    expect(heisucaSearchPersonOrigin(person), 'Casa');
  });

  for (final theme in [CgflixThemeVariant.isis, CgflixThemeVariant.heitor]) {
    testWidgets('fontes no tema ${theme.name}: texto grande, toque e estado acessível', (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(theme), home: MediaQuery(
        data: const MediaQueryData(size: Size(360, 1200), textScaler: TextScaler.linear(2)), child: Scaffold(
          body: HeisucaSourceSheet(title: 'Escolha uma fonte', children: [
            for (final status in HeisucaSourceStatus.values) HeisucaSourceRow(title: 'Fonte ${status.name}',
              subtitle: 'Jellyfin', status: status, onTap: () => taps++),
          ])))));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
      expect(find.byType(HeisucaSourceMark), findsNWidgets(4));
      for (final label in ['On-line', 'Conectando', 'Fora do ar', 'Erro de acesso']) {
        expect(find.bySemanticsLabel(RegExp(label)), findsWidgets);
        expect(find.text(label), findsNothing);
      }
      await tester.tap(find.text('Fonte online'));
      expect(taps, 1); expect(tester.takeException(), isNull);
      } finally { semantics.dispose(); }
    });
  }

  test('reconexão informa conectando sem emitir um falso status de saúde', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db); addTearDown(db.close);
    final response = Completer<http.Response>();
    final client = testJellyfinClient(handler: (_) => response.future);
    final manager = MultiServerManager();
    manager.debugRegisterJellyfinClientForTesting(client, online: false);
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(servers.dispose); addTearDown(manager.dispose);
    final health = <Map<String, bool>>[];
    final sub = manager.statusStream.listen(health.add); addTearDown(sub.cancel);
    expect(heisucaSourceStatus(servers, 'srv-1'), HeisucaSourceStatus.offline);
    final reconnect = manager.reconnectOfflineServers();
    await Future<void>.delayed(Duration.zero);
    expect(heisucaSourceStatus(servers, 'srv-1'), HeisucaSourceStatus.connecting);
    expect(health, isEmpty, reason: 'atividade não dispara o contrato de saúde/bibliotecas');
    response.complete(jsonResponse({'Id': 'user-1'}));
    await reconnect;
    expect(heisucaSourceStatus(servers, 'srv-1'), HeisucaSourceStatus.online);
    manager.debugMarkAuthErrorForTesting(ServerId('srv-1'));
    expect(heisucaSourceStatus(servers, 'srv-1'), HeisucaSourceStatus.error);
  });
}
