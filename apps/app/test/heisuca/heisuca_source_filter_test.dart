import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/services/multi_server_manager.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetSharedPreferencesForTest);

  test('fonte selecionada não altera clientes autenticados nem autorização', () {
    final manager = MultiServerManager();
    addTearDown(manager.dispose);
    final a = testJellyfinClient(connection: testJellyfinConnection(machineId: 'a'));
    final b = testJellyfinClient(connection: testJellyfinConnection(machineId: 'b'));
    manager.debugRegisterClientForTesting(a);
    manager.debugRegisterClientForTesting(b);
    manager.setVisibleServerIds({'a', 'b'});
    manager.navigationServerId = 'b';
    expect(manager.navigationOnlineClients.keys, ['b']);
    expect(manager.visibleOnlineClients.length, 2);
    expect(manager.resolveDownloadClient(ServerId('a')), same(a));
    manager.setVisibleServerIds({'a'});
    expect(manager.navigationOnlineClients, isEmpty);
    expect(manager.navigationServerId, 'b');
  });

  test('fonte offline não cai silenciosamente em outro servidor', () {
    final manager = MultiServerManager();
    addTearDown(manager.dispose);
    manager.debugRegisterClientForTesting(testJellyfinClient(connection: testJellyfinConnection(machineId: 'a')));
    manager.debugRegisterClientForTesting(testJellyfinClient(connection: testJellyfinConnection(machineId: 'b')), online: false);
    manager.navigationServerId = 'b';
    expect(manager.navigationOnlineClients, isEmpty);
    manager.updateServerStatus(ServerId('b'), true);
    expect(manager.navigationOnlineClients.keys, ['b']);
    manager.navigationServerId = 'a';
    expect(manager.navigationOnlineClients.keys, ['a']);
  });
}
