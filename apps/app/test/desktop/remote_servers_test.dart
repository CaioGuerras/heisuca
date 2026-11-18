import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/connection/connection.dart';
import 'package:heisuca/desktop/platform/desktop_connection_vault.dart';
import 'package:heisuca/desktop/remote/desktop_servers_controller.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/services/plex_auth_service.dart';
import 'package:heisuca/utils/active_client_scope.dart';
import 'package:heisuca/utils/log_redaction_manager.dart';

class _FakeMediaServerClient implements MediaServerClient {
  _FakeMediaServerClient({
    required this.serverId,
    required this.backend,
    this.serverName,
    this.healthResult = HealthStatus.online,
    this.healthDelay = Duration.zero,
  });

  @override
  final ServerId serverId;
  @override
  final MediaBackend backend;
  @override
  final String? serverName;
  final HealthStatus healthResult;
  final Duration healthDelay;
  bool closed = false;

  @override
  Future<HealthStatus> checkHealth() async {
    if (healthDelay > Duration.zero) {
      await Future<void>.delayed(healthDelay);
    }
    return healthResult;
  }

  @override
  void close() => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePlexAuthService implements PlexAuthService {
  _FakePlexAuthService({
    required this.clientIdentifier,
    required this.pinData,
    required this.pollHandler,
    required this.userInfo,
    required this.servers,
  });

  @override
  final String clientIdentifier;
  final Map<String, dynamic> pinData;
  final Future<String?> Function(bool Function()? shouldCancel) pollHandler;
  final Map<String, dynamic> userInfo;
  final List<PlexServer> servers;
  bool disposed = false;

  @override
  Future<Map<String, dynamic>> createPin() async => pinData;

  @override
  String getAuthUrl(String pinCode) => 'https://app.plex.tv/auth#?code=$pinCode';

  @override
  Future<String?> pollPinUntilClaimed(
    int pinId, {
    Duration timeout = const Duration(minutes: 2),
    bool Function()? shouldCancel,
    Duration initialBackoff = const Duration(seconds: 1),
    Duration maxBackoff = const Duration(seconds: 5),
  }) => pollHandler(shouldCancel);

  @override
  Future<Map<String, dynamic>> getUserInfo(String authToken) async => userInfo;

  @override
  Future<List<PlexServer>> fetchServers(String authToken) async => servers;

  @override
  void dispose() => disposed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ConfigurableVault implements DesktopConnectionVault {
  _ConfigurableVault({this.persistent = true, List<Map<String, dynamic>>? initial})
    : entries = List<Map<String, dynamic>>.from(initial ?? const <Map<String, dynamic>>[]);

  @override
  final bool persistent;
  List<Map<String, dynamic>> entries;
  Completer<void>? readGate;
  bool throwOnRead = false;
  bool throwOnWrite = false;
  int writeCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> read() async {
    if (throwOnRead) throw const DesktopVaultException('Corrupt');
    final snapshot = List<Map<String, dynamic>>.from(entries);
    await readGate?.future;
    return snapshot;
  }

  @override
  Future<void> write(List<Map<String, dynamic>> nextEntries) async {
    writeCalls++;
    if (throwOnWrite) throw const DesktopVaultException('Write denied');
    entries = List<Map<String, dynamic>>.from(nextEntries);
  }
}

PlexServer _buildPlexServer(String id, String name, {String suffix = 'a'}) {
  return PlexServer(
    name: name,
    clientIdentifier: id,
    accessToken: 'plex-srv-token-$id',
    owned: true,
    connections: <PlexConnection>[
      PlexConnection(
        protocol: 'https',
        address: '10.0.0.10',
        port: 32400,
        uri: 'https://10-0-0-10.$suffix.plex.direct:32400',
        local: true,
        relay: false,
        ipv6: false,
      ),
      PlexConnection(
        protocol: 'https',
        address: '203.0.113.5',
        port: 32400,
        uri: 'https://203-0-113-5.$suffix.plex.direct:32400',
        local: false,
        relay: false,
        ipv6: false,
      ),
    ],
  );
}

JellyfinConnection _buildJfConnection({String machineId = 'jf-machine-1', String userId = 'u1'}) {
  return JellyfinConnection(
    id: '$machineId/$userId',
    baseUrl: 'https://jf.example.org:8096',
    baseUrls: const <String>['https://jf.example.org:8096'],
    serverName: 'Casa Jellyfin',
    serverMachineId: machineId,
    userId: userId,
    userName: 'caio',
    accessToken: 'jf-secret-token-xyz',
    deviceId: 'dev-1',
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  setUp(() => LogRedactionManager.clearTrackedValues());
  tearDown(() => LogRedactionManager.clearTrackedValues());

  test('persistentSessions reflete tipo de cofre e valida entradas Jellyfin sem rede', () async {
    final memController = DesktopServersController(vault: MemoryDesktopConnectionVault());
    expect(memController.persistentSessions, isFalse);
    expect(memController.connections, isEmpty);

    await memController.signInJellyfin(baseUrl: ' ', username: 'caio', password: '123');
    expect(memController.error, isNotNull);
    expect(memController.busy, isFalse);
    memController.clearError();
    expect(memController.error, isNull);

    await memController.signInJellyfin(baseUrl: 'ftp://host:8096', username: 'caio', password: '123');
    expect(memController.error, isNotNull);
    memController.dispose();

    final winController = DesktopServersController(vault: _ConfigurableVault(persistent: true));
    expect(winController.persistentSessions, isTrue);
    winController.dispose();
  });

  test('signInJellyfin persiste schema versionado, redige logs e oculta segredos no toString', () async {
    final vault = _ConfigurableVault();
    final jfClient = _FakeMediaServerClient(
      serverId: ServerId('jf-machine-1'),
      backend: MediaBackend.jellyfin,
      serverName: 'Casa Jellyfin',
    );
    final controller = DesktopServersController(
      vault: vault,
      jellyfinAuthenticator: ({required baseUrl, required username, required password, required deviceId}) async {
        expect(deviceId, isNotEmpty);
        return _buildJfConnection();
      },
      jellyfinClientFactory: (conn) async => jfClient,
    );
    addTearDown(controller.dispose);

    await controller.signInJellyfin(
      baseUrl: 'https://jf.example.org:8096',
      username: 'caio',
      password: 'super-secret-password',
    );

    expect(controller.error, isNull);
    expect(controller.connections, hasLength(1));
    final conn = controller.connections.single;
    expect(conn.id, 'jf-machine-1/u1');
    expect(conn.health, HealthStatus.online);
    expect(conn.toString(), isNot(contains('jf-secret-token-xyz')));
    expect(conn.toString(), isNot(contains('jf.example.org')));

    final redacted = LogRedactionManager.redact('url=https://jf.example.org:8096 tok=jf-secret-token-xyz');
    expect(redacted, isNot(contains('jf-secret-token-xyz')));
    expect(redacted, isNot(contains('jf.example.org')));

    expect(vault.entries, hasLength(1));
    expect(vault.entries.single['version'], DesktopServersController.vaultSchemaVersion);
    expect(vault.entries.single['kind'], 'jellyfin');
    expect(vault.entries.single['id'], 'jf-machine-1/u1');
    expect(vault.entries.single['createdAt'], isA<String>());
    expect(vault.entries.single['config'], isA<Map<String, Object?>>());
  });

  test('signInPlex usa PlexProfileScopeId, prioritizedEndpointUrls e cancelAuthentication limpa estado', () async {
    final vault = _ConfigurableVault();
    final server = _buildPlexServer('plex-srv-1', 'Sala Plex');
    final launchedUris = <Uri>[];
    final capturedScopes = <PlexProfileScopeId>[];
    final capturedEndpoints = <List<String>>[];

    final auth = _FakePlexAuthService(
      clientIdentifier: 'desktop-cid-1',
      pinData: <String, dynamic>{'id': 99, 'code': 'WXYZ'},
      pollHandler: (_) async => 'plex-acct-token',
      userInfo: <String, dynamic>{'username': 'titular', 'uuid': 'acc-uuid-1'},
      servers: <PlexServer>[server],
    );

    final controller = DesktopServersController(
      vault: vault,
      plexAuthFactory: () async => auth,
      plexEndpointResolver: (srv, cid, {onTranscoderCapability}) async {
        onTranscoderCapability?.call(true);
        return srv.connections.last;
      },
      plexClientFactory: ({
        required account,
        required server,
        required endpoint,
        required profileScopeId,
        required prioritizedEndpoints,
        seedTranscoderVideoSupport,
      }) async {
        capturedScopes.add(profileScopeId);
        capturedEndpoints.add(prioritizedEndpoints);
        expect(seedTranscoderVideoSupport, isTrue);
        return _FakeMediaServerClient(
          serverId: ServerId(server.clientIdentifier),
          backend: MediaBackend.plex,
          serverName: server.name,
        );
      },
    );
    addTearDown(controller.dispose);

    await controller.signInPlex(openBrowser: (uri) async => launchedUris.add(uri));

    expect(launchedUris.single.toString(), contains('WXYZ'));
    expect(controller.plexCode, isNull);
    expect(controller.busy, isFalse);
    expect(controller.connections, hasLength(1));
    expect(capturedScopes.single, PlexProfileScopeId(profileId: 'plex.acc-uuid-1', serverId: ServerId('plex-srv-1')));
    expect(capturedEndpoints.single.first, server.connections.last.uri);
    expect(vault.entries.single['kind'], 'plex');

    final clientCompleter = Completer<_FakeMediaServerClient>();
    final lateClient = _FakeMediaServerClient(serverId: ServerId('plex-srv-2'), backend: MediaBackend.plex);
    final cancelAuth = _FakePlexAuthService(
      clientIdentifier: 'desktop-cid-2',
      pinData: <String, dynamic>{'id': 100, 'code': 'CANCEL'},
      pollHandler: (_) async => 'plex-acct-token-2',
      userInfo: <String, dynamic>{'username': 'titular2', 'uuid': 'acc-uuid-2'},
      servers: <PlexServer>[_buildPlexServer('plex-srv-2', 'Quarto', suffix: 'b')],
    );
    final cancelController = DesktopServersController(
      vault: _ConfigurableVault(),
      plexAuthFactory: () async => cancelAuth,
      plexEndpointResolver: (srv, cid, {onTranscoderCapability}) async => srv.connections.first,
      plexClientFactory: ({required account, required server, required endpoint, required profileScopeId, required prioritizedEndpoints, seedTranscoderVideoSupport}) =>
          clientCompleter.future,
    );
    addTearDown(cancelController.dispose);

    final future = cancelController.signInPlex();
    await Future<void>.delayed(Duration.zero);
    cancelController.cancelAuthentication();
    expect(cancelController.busy, isFalse);
    expect(cancelController.plexCode, isNull);

    clientCompleter.complete(lateClient);
    await future;
    expect(lateClient.closed, isTrue);
    expect(cancelController.connections, isEmpty);
  });

  test('restore isola timeout de servidor, preserva cofre offline e nao sobrescreve cofre corrompido', () async {
    final plexConn = PlexAccountConnection(
      id: 'plex.acc-1',
      accountToken: 'tok-plex',
      clientIdentifier: 'cid-1',
      accountLabel: 'titular',
      servers: <PlexServer>[
        _buildPlexServer('srv-fast', 'Rapido', suffix: 'fast'),
        _buildPlexServer('srv-hang', 'Lento', suffix: 'hang'),
      ],
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final jfConn = _buildJfConnection();
    final vault = _ConfigurableVault(
      initial: <Map<String, dynamic>>[
        <String, dynamic>{
          'version': 1,
          'kind': 'plex',
          'id': plexConn.id,
          'createdAt': plexConn.createdAt.toUtc().toIso8601String(),
          'config': plexConn.toConfigJson(),
        },
        <String, dynamic>{
          'version': 1,
          'kind': 'jellyfin',
          'id': jfConn.id,
          'createdAt': jfConn.createdAt.toUtc().toIso8601String(),
          'config': jfConn.toConfigJson(),
        },
      ],
    );

    final controller = DesktopServersController(
      vault: vault,
      connectTimeout: const Duration(milliseconds: 60),
      plexEndpointResolver: (server, cid, {onTranscoderCapability}) async {
        if (server.clientIdentifier == 'srv-hang') {
          await Future<void>.delayed(const Duration(seconds: 5));
        }
        return server.connections.first;
      },
      plexClientFactory: ({required account, required server, required endpoint, required profileScopeId, required prioritizedEndpoints, seedTranscoderVideoSupport}) async {
        return _FakeMediaServerClient(serverId: ServerId(server.clientIdentifier), backend: MediaBackend.plex, serverName: server.name);
      },
      jellyfinClientFactory: (conn) async => _FakeMediaServerClient(
        serverId: ServerId(conn.serverMachineId),
        backend: MediaBackend.jellyfin,
        serverName: conn.serverName,
        healthResult: HealthStatus.online,
        healthDelay: const Duration(milliseconds: 100),
      ),
    );
    addTearDown(controller.dispose);

    await controller.restore();
    expect(controller.restoring, isFalse);
    expect(controller.connections.map((c) => c.id), containsAll(<String>['srv-fast/~plex-profile/plex.acc-1', 'jf-machine-1/u1']));
    expect(controller.connections.firstWhere((c) => c.id == 'jf-machine-1/u1').health, HealthStatus.offline);
    expect(vault.entries, hasLength(2));
    expect(vault.writeCalls, 0);

    final corruptVault = _ConfigurableVault()..throwOnRead = true;
    final corruptController = DesktopServersController(vault: corruptVault);
    addTearDown(corruptController.dispose);
    await corruptController.restore();
    expect(corruptController.error, isNotNull);
    expect(corruptVault.writeCalls, 0);
  });

  test('falha de escrita no vault preserva RAM, disconnect remove unidade e dispose fecha tardio', () async {
    final vault = _ConfigurableVault()..throwOnWrite = true;
    final jfClient = _FakeMediaServerClient(serverId: ServerId('jf-1'), backend: MediaBackend.jellyfin);
    final controller = DesktopServersController(
      vault: vault,
      jellyfinAuthenticator: ({required baseUrl, required username, required password, required deviceId}) async =>
          _buildJfConnection(machineId: 'jf-1', userId: 'u1'),
      jellyfinClientFactory: (_) async => jfClient,
    );
    addTearDown(controller.dispose);

    await controller.signInJellyfin(baseUrl: 'https://jf.example.org', username: 'u', password: 'p');
    expect(controller.connections, hasLength(1));
    expect(controller.error, isNotNull);

    vault.throwOnWrite = false;
    await controller.disconnect('jf-1/u1');
    expect(controller.connections, isEmpty);
    expect(jfClient.closed, isTrue);
    expect(vault.entries, isEmpty);

    final lateCompleter = Completer<_FakeMediaServerClient>();
    final lateJf = _FakeMediaServerClient(serverId: ServerId('jf-late'), backend: MediaBackend.jellyfin);
    final disposeController = DesktopServersController(
      vault: _ConfigurableVault(),
      jellyfinAuthenticator: ({required baseUrl, required username, required password, required deviceId}) async =>
          _buildJfConnection(machineId: 'jf-late', userId: 'u2'),
      jellyfinClientFactory: (_) => lateCompleter.future,
    );
    final pending = disposeController.signInJellyfin(baseUrl: 'https://jf.example.org', username: 'u', password: 'p');
    await Future<void>.delayed(Duration.zero);
    disposeController.dispose();
    lateCompleter.complete(lateJf);
    await pending;
    expect(lateJf.closed, isTrue);
  });
  test('logout durante leitura do cofre não ressuscita conta nem no próximo restore', () async {
    final connection = _buildJfConnection();
    final vault = _ConfigurableVault(initial: [{
      'version': 1, 'kind': 'jellyfin', 'id': connection.id,
      'createdAt': connection.createdAt.toUtc().toIso8601String(),
      'config': connection.toConfigJson(),
    }])..readGate = Completer<void>();
    final controller = DesktopServersController(vault: vault,
      jellyfinClientFactory: (c) async => _FakeMediaServerClient(
        serverId: ServerId('jf-machine-1'), backend: MediaBackend.jellyfin));
    addTearDown(controller.dispose);
    final restoring = controller.restore();
    await controller.disconnect(connection.id);
    vault.readGate!.complete();
    await restoring;
    expect(vault.entries, isEmpty);
    await controller.restore();
    expect(controller.connections, isEmpty);
  });

  test('login aguarda restore antigo antes de registrar nova sessão', () async {
    final vault = _ConfigurableVault()..readGate = Completer<void>();
    var authenticated = false;
    final controller = DesktopServersController(vault: vault,
      jellyfinAuthenticator: ({required baseUrl, required username, required password, required deviceId}) async {
        authenticated = true;
        return _buildJfConnection();
      },
      jellyfinClientFactory: (c) async => _FakeMediaServerClient(
        serverId: ServerId('jf-machine-1'), backend: MediaBackend.jellyfin));
    addTearDown(controller.dispose);
    final restoring = controller.restore();
    final login = controller.signInJellyfin(baseUrl: 'host:8096', username: 'usuario', password: 'canario');
    await Future<void>.delayed(Duration.zero);
    expect(authenticated, isFalse);
    vault.readGate!.complete();
    await Future.wait([restoring, login]);
    expect(controller.connections, hasLength(1));
    expect(vault.entries, hasLength(1));
  });

  test('URL Jellyfin rejeita userinfo, fragmento, query e porta inválida antes de autenticar', () async {
    var authCalls = 0;
    final controller = DesktopServersController(vault: MemoryDesktopConnectionVault(),
      jellyfinAuthenticator: ({required baseUrl, required username, required password, required deviceId}) async {
        authCalls++;
        return _buildJfConnection();
      });
    addTearDown(controller.dispose);
    for (final address in ['https://@host', 'https://user:pass@host', 'https://host/?token=x',
        'https://host/#fragment', 'https://host:99999']) {
      await controller.signInJellyfin(baseUrl: address, username: 'usuario', password: 'canario');
      expect(controller.error, isNotNull);
    }
    expect(authCalls, 0);
  });

}
