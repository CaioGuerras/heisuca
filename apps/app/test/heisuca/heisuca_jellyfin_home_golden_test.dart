import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_palette.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/heisuca/heisuca_home_screen.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/providers/discover_provider.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
import '../test_helpers/prefs.dart';

class _Discover extends ChangeNotifier implements DiscoverProvider {
  @override Future<void> load() async {}
  @override List<MediaItem> get onDeck => const [];
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Início Jellyfin preserva composição aprovada, parada e rolada', (tester) async {
    resetSharedPreferencesForTest();
    await tester.runAsync(() async {
      await (FontLoader('Sora')..addFont(rootBundle.load('assets/fonts/Sora-VF.ttf'))).load();
      await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))).load();
    });
    tester.view.physicalSize = const Size(412, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tmp = Directory.systemTemp.createTempSync('heisuca-c-golden-');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (_) async => tmp.path);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final manager = MultiServerManager();
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    final discover = _Discover();
    final client = testJellyfinClient(handler: (request) async {
      final path = request.url.path;
      if (path.endsWith('/Views')) return jsonResponse({'Items': [
        {'Id': 'filmes', 'Name': 'Filmes', 'Type': 'CollectionFolder', 'CollectionType': 'movies'},
        {'Id': 'series', 'Name': 'Séries', 'Type': 'CollectionFolder', 'CollectionType': 'tvshows'},
      ]});
      if (path.contains('/cgflix/')) return jsonResponse({});
      if (path.contains('Upcoming')) return jsonResponse({'Items': []});
      final item = {'Id': 'a', 'Name': 'Um título', 'Type': 'Movie', 'ProductionYear': 2026,
        'Overview': 'Uma história para assistir em família.', 'CommunityRating': 8.2};
      return jsonResponse(path.endsWith('/Latest') ? [item] : {'Items': [item]});
    });
    manager.debugRegisterClientForTesting(client);
    servers.setExpectedVisibleServerIds({'srv-1'});
    servers.setVisibleServerIds({'srv-1'});
    final capture = GlobalKey();
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<MultiServerProvider>.value(value: servers),
      ChangeNotifierProvider<DiscoverProvider>.value(value: discover),
    ], child: TranslationProvider(child: MaterialApp(theme: cgflixAppTheme(CgflixThemeVariant.isis),
      home: MediaQuery(data: const MediaQueryData(size: Size(412, 914), disableAnimations: true),
        child: RepaintBoundary(key: capture, child: const HeisucaHomeScreen()))))));
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 300)); });
    for (var i = 0; i < 12; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await expectLater(find.byKey(capture), matchesGoldenFile('goldens/c_jellyfin_home_before.png'));
    final scroll = tester.widget<CustomScrollView>(find.byType(CustomScrollView)).controller!;
    scroll.jumpTo(350);
    expect(scroll.offset, 350);
    await tester.pumpAndSettle();
    await expectLater(find.byKey(capture), matchesGoldenFile('goldens/c_jellyfin_home_scrolled_before.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 50)); });
    discover.dispose(); servers.dispose(); manager.dispose();
    await db.close();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), null);
    tmp.deleteSync(recursive: true);
  });
}
