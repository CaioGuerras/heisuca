import 'package:plezy/heisuca/heisuca_home_chrome.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/heisuca/heisuca_title_sheet.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_file_info.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import '../test_helpers/prefs.dart';

MediaItem _item(String id, MediaKind kind, {int? index, String? parentId, int? parentIndex}) =>
    MediaItem.jellyfin(id: id, kind: kind, title: id, serverId: 'source', index: index,
      parentId: parentId, parentIndex: parentIndex, durationMs: 1400000, viewOffsetMs: id == 'episode-7' ? 300000 : 0);

class _Client extends MediaServerClient {
  Completer<void>? hold;
  final show = _item('Série de teste', MediaKind.show);
  final season = _item('Temporada 1', MediaKind.season, index: 1);
  final episodes = List.generate(13, (i) => _item('episode-${i + 1}', MediaKind.episode,
      index: i + 1, parentId: 'Temporada 1', parentIndex: 1));
  @override ServerCapabilities get capabilities => const ServerCapabilities(userFavorites: true);
  @override ServerId get serverId => ServerId('source');
  @override MediaBackend get backend => MediaBackend.jellyfin;
  @override Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id,
      {void Function(MediaItem)? onItemReady}) async {
    if (hold != null) await hold!.future;
    return (item: show, onDeckEpisode: episodes[6]);
  }
  @override Future<List<MediaItem>> fetchChildren(String id) async => id == show.id ? [season] : episodes;
  @override Future<MediaFileInfo?> getFileInfo(MediaItem item) async => null;
  @override Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async => const [];
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
  for (final variant in [CgflixThemeVariant.isis, CgflixThemeVariant.heitor]) {
    testWidgets('continua episódio 7, pagina a temporada e encaixa play em $variant', (tester) async {
      tester.view.physicalSize = const Size(412, 914);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final client = _Client();
      final manager = MultiServerManager()..debugRegisterClientForTesting(client);
      final servers = MultiServerProvider(manager, DataAggregationService(manager));
      addTearDown(servers.dispose);
      addTearDown(manager.dispose);
      await tester.pumpWidget(ChangeNotifierProvider.value(value: servers, child: MaterialApp(
        theme: cgflixAppTheme(variant), home: Builder(builder: (ctx) => HeisucaTitleSheet(hostContext: ctx, item: client.show)))));
      await tester.pumpAndSettle();
      expect(find.text('Continuar T1:E7'), findsOneWidget);
      // Caio, 25/10: a ficha usa o mesmo encaixe da Início, preservando a continuação.
      expect(find.byType(HeisucaHomeChrome), findsOneWidget);
      final titleLogo = find.byKey(const ValueKey('heisuca-docking-logo'));
      final initialLogo = tester.getRect(titleLogo);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -660));
      await tester.pumpAndSettle();
      expect(tester.getRect(titleLogo).center.dy, lessThan(initialLogo.center.dy));
      expect(find.text('Continuar T1:E7').hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(find.text('11–13'), 180, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('11–13'));
      await tester.pumpAndSettle();
      expect(find.text('11. episode-11'), findsOneWidget);
      expect(find.text('Continuar T1:E7').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Outra página não muda o alvo do botão de continuação.
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('ficha reaberta mantém continuação enquanto revalida; outra sessão não herda cache', (tester) async {
    final first = _Client();
    final manager = MultiServerManager()..debugRegisterClientForTesting(first);
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(servers.dispose); addTearDown(manager.dispose);
    Widget screen(MediaItem item) => ChangeNotifierProvider.value(value: servers, child: MaterialApp(
      theme: cgflixAppTheme(CgflixThemeVariant.isis), home: Builder(builder: (ctx) => HeisucaTitleSheet(hostContext: ctx, item: item))));
    await tester.pumpWidget(screen(first.show)); await tester.pumpAndSettle();
    expect(find.text('Continuar T1:E7'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    first.hold = Completer<void>();
    await tester.pumpWidget(screen(first.show)); await tester.pump();
    expect(find.text('Continuar T1:E7'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); first.hold!.complete(); await tester.pump();
    first.hold = Completer<void>();
    final tappedEpisode = first.episodes[10].copyWith(grandparentId: first.show.id);
    await tester.pumpWidget(screen(tappedEpisode)); await tester.pump();
    expect(find.text('Assistir T1:E11'), findsOneWidget);
    expect(find.text('Continuar T1:E7'), findsNothing);
    await tester.pumpWidget(const SizedBox()); first.hold!.complete(); await tester.pump();
    final other = _Client()..hold = Completer<void>();
    manager.debugRegisterClientForTesting(other);
    await tester.pumpWidget(screen(other.show)); await tester.pump();
    expect(find.text('Continuar T1:E7'), findsNothing);
    other.hold!.complete(); await tester.pumpAndSettle();
    expect(find.text('Continuar T1:E7'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

}
