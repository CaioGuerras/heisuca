import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plezy/heisuca/heisuca_source_scope.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/prefs.dart';

class _Profile extends ChangeNotifier implements ActiveProfileProvider {
  @override bool get isBinding => false;
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetSharedPreferencesForTest);
  testWidgets('seleção persiste por perfil, mantém offline e invalida fonte removida', (tester) async {
    final manager = MultiServerManager();
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    final profile = _Profile();
    addTearDown(manager.dispose);
    addTearDown(servers.dispose);
    addTearDown(profile.dispose);
    manager.debugRegisterClientForTesting(testJellyfinClient(connection: testJellyfinConnection(machineId: 'a', serverName: 'Servidor A')));
    manager.debugRegisterClientForTesting(testJellyfinClient(connection: testJellyfinConnection(machineId: 'b', serverName: 'Servidor B')));
    servers.setExpectedVisibleServerIds({'a', 'b'});
    servers.setVisibleServerIds({'a', 'b'});
    Widget app(String owner) => MultiProvider(providers: [
      ChangeNotifierProvider<MultiServerProvider>.value(value: servers),
      ChangeNotifierProvider<ActiveProfileProvider>.value(value: profile),
    ], child: MaterialApp(home: HeisucaSourceScope(key: ValueKey(owner), profileId: owner,
      child: Scaffold(body: Builder(builder: (ctx) => Column(children: [
        const HeisucaSourceTile(), Text('skip-prompt:${HeisucaSourceScope.skipInitialPromptOf(ctx)}'),
      ]))))));
    await tester.pumpWidget(app('caio'));
    await tester.pumpAndSettle();
    expect(manager.navigationServerId, 'a');
    expect(find.text('skip-prompt:false'), findsOneWidget);
    await tester.tap(find.text('Fonte atual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servidor B'));
    await tester.pumpAndSettle();
    expect(manager.navigationServerId, 'b');
    expect(find.text('skip-prompt:true'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('heisuca.navigation.source.caio'), 'b');
    manager.updateServerStatus(ServerId('b'), false);
    await tester.pumpAndSettle();
    expect(manager.navigationServerId, 'b');
    expect(manager.navigationOnlineClients, isEmpty);
    await tester.pumpWidget(app('outro'));
    await tester.pumpAndSettle();
    expect(manager.navigationServerId, 'a');
    await tester.pumpWidget(app('caio'));
    await tester.pumpAndSettle();
    expect(manager.navigationServerId, 'b');
    servers.setExpectedVisibleServerIds({'a'});
    await tester.pumpAndSettle();
    expect(manager.navigationServerId, 'a');
    expect(manager.visibleOnlineClients.keys, contains('a'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(manager.navigationServerId, isNull);
  });
}
