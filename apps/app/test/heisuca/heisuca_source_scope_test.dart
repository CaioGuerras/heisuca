import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heisuca/heisuca/heisuca_source_scope.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/prefs.dart';

class _Profile extends ChangeNotifier implements ActiveProfileProvider {
  @override bool get isBinding => false;
  @override String? get activeId => 'caio';
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Perfil em rebind (logo depois de adicionar um servidor): só assenta quando [settle] for chamado.
class _BindingProfile extends ChangeNotifier implements ActiveProfileProvider {
  bool binding = true;
  final _done = Completer<bool>();
  void settle() { binding = false; _done.complete(true); notifyListeners(); }
  @override bool get isBinding => binding;
  @override Future<bool> awaitBindingSettle() => binding ? _done.future : Future.value(true);
  @override String? get activeId => 'caio';
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
    await tester.tap(find.textContaining('Fonte atual ·'));
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

  testWidgets('escolha feita durante o rebind não é descartada: aplica quando o binding assenta', (tester) async {
    final manager = MultiServerManager();
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    final profile = _BindingProfile();
    addTearDown(manager.dispose);
    addTearDown(servers.dispose);
    addTearDown(profile.dispose);
    manager.debugRegisterClientForTesting(testJellyfinClient(connection: testJellyfinConnection(machineId: 'a', serverName: 'Servidor A')));
    manager.debugRegisterClientForTesting(testJellyfinClient(connection: testJellyfinConnection(machineId: 'novo', serverName: 'Servidor Novo')));
    servers.setExpectedVisibleServerIds({'a', 'novo'});
    servers.setVisibleServerIds({'a', 'novo'});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('heisuca.navigation.source.caio', 'a');
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<MultiServerProvider>.value(value: servers),
      ChangeNotifierProvider<ActiveProfileProvider>.value(value: profile),
    ], child: const MaterialApp(home: HeisucaSourceScope(profileId: 'caio', child: Scaffold(body: HeisucaSourceTile())))));
    await tester.pumpAndSettle();
    expect(manager.navigationServerId, 'a');
    await tester.tap(find.textContaining('Fonte atual ·'));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar fonte'), findsOneWidget, reason: 'porta única para adicionar fonte');
    await tester.tap(find.text('Servidor Novo'));
    await tester.pumpAndSettle();
    expect(manager.navigationServerId, 'a', reason: 'ainda em rebind');
    profile.settle();
    await tester.pumpAndSettle();
    expect(manager.navigationServerId, 'novo');
    expect(prefs.getString('heisuca.navigation.source.caio'), 'novo');
    expect(find.text('Servidor Novo'), findsOneWidget, reason: 'backend com nome legível');
    await tester.pumpWidget(const SizedBox());
  });
}
