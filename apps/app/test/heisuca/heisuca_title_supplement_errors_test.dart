import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/exceptions/media_server_exceptions.dart';
import 'package:heisuca/heisuca/heisuca_title_sheet.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_file_info.dart';
import 'package:heisuca/media/media_hub.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/media/server_capabilities.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

/// Servidor que responde 404 aos "semelhantes" e aos "extras" (item sem relacionados, como no run 40712225508).
class _Cliente404 extends MediaServerClient {
  final filme = MediaItem.jellyfin(id: 'filme-1', kind: MediaKind.movie, title: 'Filme', serverId: 'source', durationMs: 1400000,
      genres: List.generate(150, (i) => 'Gênero número $i'));
  int pedidosRelacionados = 0;
  int pedidosExtras = 0;

  MediaServerHttpException get _erro404 => MediaServerHttpException(
    type: MediaServerHttpErrorType.unknown,
    statusCode: 404,
    message: 'HTTP 404',
    requestUri: Uri.parse('https://servidor.exemplo/Items/filme-1?api_key=segredo'),
  );

  @override ServerCapabilities get capabilities => const ServerCapabilities(userFavorites: true);
  @override ServerId get serverId => ServerId('source');
  @override MediaBackend get backend => MediaBackend.jellyfin;
  @override Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id,
      {void Function(MediaItem)? onItemReady}) async => (item: filme, onDeckEpisode: null);
  @override Future<MediaFileInfo?> getFileInfo(MediaItem item) async => null;
  @override Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async {
    pedidosRelacionados++;
    throw _erro404;
  }
  @override Future<List<MediaItem>> fetchExtras(String id) async {
    pedidosExtras++;
    throw _erro404;
  }
  @override dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.hideSpoilers, false);
  });

  testWidgets('404 em semelhantes e extras nunca vira erro não tratado; a ficha segue utilizável', (tester) async {
    tester.view.physicalSize = const Size(412, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cliente = _Cliente404();
    final manager = MultiServerManager()..debugRegisterClientForTesting(cliente);
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(servers.dispose);
    addTearDown(manager.dispose);
    final naoTratados = <Object>[];
    await runZonedGuarded(() async {
      await tester.pumpWidget(ChangeNotifierProvider.value(value: servers, child: MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.isis),
        home: Builder(builder: (ctx) => HeisucaTitleSheet(hostContext: ctx, item: cliente.filme)))));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      // Tela baixa: as seções de baixo ainda não foram construídas (lista preguiçosa), ninguém escuta as Futures.
      expect(find.text('Assistir'), findsWidgets, reason: 'a ficha continua utilizável');
      expect(find.byType(FutureBuilder<List<MediaItem>>, skipOffstage: false), findsNothing, reason: 'precondição: seções de baixo não construídas');
      // Fecha a ficha sem esperar mais nada.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }, (erro, _) => naoTratados.add(erro));
    expect(cliente.pedidosRelacionados, greaterThan(0));
    expect(cliente.pedidosExtras, greaterThan(0));
    expect(tester.takeException(), isNull);
    expect(naoTratados, isEmpty, reason: 'erros de zona não tratados: $naoTratados');
  });

  testWidgets('a seção some quando os semelhantes falham', (tester) async {
    tester.view.physicalSize = const Size(412, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cliente = _Cliente404();
    final manager = MultiServerManager()..debugRegisterClientForTesting(cliente);
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(servers.dispose);
    addTearDown(manager.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: servers, child: MaterialApp(
      theme: cgflixAppTheme(CgflixThemeVariant.isis),
      home: Builder(builder: (ctx) => HeisucaTitleSheet(hostContext: ctx, item: cliente.filme)))));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(find.text('Títulos relacionados'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
