import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../../connection/connection.dart';
import '../../connection/plex_account_setup.dart';
import '../../exceptions/media_server_exceptions.dart';
import '../../media/ids.dart';
import '../../media/media_backend.dart';
import '../../media/media_server_client.dart';
import '../../models/plex/plex_config.dart';
import '../../services/jellyfin_auth_service.dart';
import '../../services/jellyfin_client.dart';
import '../../services/plex_auth_service.dart';
import '../../services/plex_client.dart';
import '../../utils/active_client_scope.dart';
import '../../utils/app_logger.dart';
import '../../utils/device_identity.dart';
import '../../utils/log_redaction_manager.dart';
import '../platform/desktop_connection_vault.dart';

class DesktopServerConnection {
  const DesktopServerConnection({
    required this.id,
    required this.name,
    required this.backend,
    required this.client,
    this.health = HealthStatus.online,
  });

  final String id;
  final String name;
  final MediaBackend backend;
  final MediaServerClient client;
  final HealthStatus health;

  DesktopServerConnection copyWith({
    String? name,
    MediaServerClient? client,
    HealthStatus? health,
  }) {
    return DesktopServerConnection(
      id: id,
      name: name ?? this.name,
      backend: backend,
      client: client ?? this.client,
      health: health ?? this.health,
    );
  }

  @override
  String toString() => LogRedactionManager.redact(
    'DesktopServerConnection(id: $id, name: $name, backend: ${backend.id}, health: ${health.name})',
  );
}

typedef PlexAuthServiceFactory = Future<PlexAuthService> Function();
typedef PlexEndpointResolver = Future<PlexConnection?> Function(
  PlexServer server,
  String clientIdentifier, {
  void Function(bool)? onTranscoderCapability,
});
typedef PlexClientFactory = Future<MediaServerClient> Function({
  required PlexAccountConnection account,
  required PlexServer server,
  required PlexConnection endpoint,
  required PlexProfileScopeId profileScopeId,
  required List<String> prioritizedEndpoints,
  bool? seedTranscoderVideoSupport,
});
typedef JellyfinAuthenticator = Future<JellyfinConnection> Function({
  required String baseUrl,
  required String username,
  required String password,
  required String deviceId,
});
typedef JellyfinClientFactory = Future<MediaServerClient> Function(
  JellyfinConnection connection,
);

class _StaleOperationException implements Exception {
  const _StaleOperationException();
}

class DesktopServersController extends ChangeNotifier {
  DesktopServersController({
    required DesktopConnectionVault vault,
    Duration connectTimeout = _defaultConnectTimeout,
    Duration operationTimeout = _defaultOperationTimeout,
    Duration plexPinTimeout = _defaultPlexPinTimeout,
    PlexAuthServiceFactory? plexAuthFactory,
    PlexEndpointResolver? plexEndpointResolver,
    PlexClientFactory? plexClientFactory,
    JellyfinAuthenticator? jellyfinAuthenticator,
    JellyfinClientFactory? jellyfinClientFactory,
  }) : _vault = vault, // ignore: prefer_initializing_formals
       _connectTimeout = connectTimeout, // ignore: prefer_initializing_formals
       _operationTimeout = operationTimeout, // ignore: prefer_initializing_formals
       _plexPinTimeout = plexPinTimeout, // ignore: prefer_initializing_formals
       _plexAuthFactory = plexAuthFactory ?? _defaultPlexAuthFactory,
       _plexClientFactory = plexClientFactory ?? _defaultPlexClientFactory,
       _jellyfinAuthenticator = jellyfinAuthenticator ?? _defaultJellyfinAuthenticate,
       _jellyfinClientFactory = jellyfinClientFactory ?? _defaultJellyfinClientFactory {
    _plexEndpointResolver = plexEndpointResolver ?? _defaultResolvePlexEndpoint;
  }

  static const int vaultSchemaVersion = 1;
  static const Duration _defaultConnectTimeout = Duration(seconds: 10);
  static const Duration _defaultOperationTimeout = Duration(seconds: 15);
  static const Duration _defaultPlexPinTimeout = Duration(minutes: 2);
  static const Uuid _uuid = Uuid();

  final DesktopConnectionVault _vault;
  final Duration _connectTimeout;
  final Duration _operationTimeout;
  final Duration _plexPinTimeout;
  final PlexAuthServiceFactory _plexAuthFactory;
  late final PlexEndpointResolver _plexEndpointResolver;
  final PlexClientFactory _plexClientFactory;
  final JellyfinAuthenticator _jellyfinAuthenticator;
  final JellyfinClientFactory _jellyfinClientFactory;

  final List<DesktopServerConnection> _connections = <DesktopServerConnection>[];
  final List<Connection> _savedConnections = <Connection>[];
  final Set<void Function()> _activeEndpointCancellers = <void Function()>{};
  final Set<String> _disconnectedDuringRestore = <String>{};

  Future<void>? _activeRestore;
  Future<void> _persistQueue = Future<void>.value();
  PlexAuthService? _activePlexAuth;

  int _authEpoch = 0;
  int _restoreEpoch = 0;
  bool _busy = false;
  bool _restoring = false;
  bool _disposed = false;
  bool _authCommitted = false;
  String? _error;
  String? _plexCode;

  List<DesktopServerConnection> get connections => List<DesktopServerConnection>.unmodifiable(_connections);
  bool get busy => _busy;
  bool get restoring => _restoring;
  String? get error => _error;
  String? get plexCode => _plexCode;
  bool get persistentSessions => _vault.persistent;

  void clearError() {
    if (_disposed || _error == null) return;
    _error = null;
    _notify();
  }

  void cancelAuthentication() {
    if (_disposed || (_busy && _authCommitted)) return;
    _authEpoch++;
    _busy = false;
    _plexCode = null;
    _disposeActivePlexAuth();
    _notify();
  }

  Future<void> restore() {
    if (_disposed || _busy) return Future<void>.value();
    if (_activeRestore != null) return _activeRestore!;
    final future = _performRestore();
    _activeRestore = future;
    return future.whenComplete(() {
      if (identical(_activeRestore, future)) {
        _activeRestore = null;
      }
    });
  }

  Future<void> _performRestore() async {
    final restoreEpoch = ++_restoreEpoch;
    _disconnectedDuringRestore.clear();
    _restoring = true;
    _error = null;
    _notify();

    try {
      final List<Map<String, dynamic>> rawEntries;
      try {
        rawEntries = await _vault.read();
      } on Object {
        appLogger.w('Falha ao ler cofre de conexoes.');
        if (!_disposed && restoreEpoch == _restoreEpoch) {
          _error = 'Nao foi possivel carregar as conexoes salvas.';
        }
        return;
      }

      if (_disposed || restoreEpoch != _restoreEpoch) return;

      final parsed = <Connection>[];
      final seenIds = <String>{};
      var hadCorruptEntry = false;

      for (final rawEntry in rawEntries) {
        final connection = _parseVaultEntry(rawEntry);
        if (connection == null) {
          hadCorruptEntry = true;
          continue;
        }
        _registerConnectionRedactions(connection);
        if (seenIds.add(connection.id)) {
          parsed.add(connection);
        }
      }

      _savedConnections
        ..clear()
        ..addAll(parsed);

      for (final id in _disconnectedDuringRestore) {
        _removeSavedConnection(id);
      }
      if (_disconnectedDuringRestore.isNotEmpty) {
        await _persistVaultWithWarning();
        if (_disposed || restoreEpoch != _restoreEpoch) return;
      }
      _clearConnections();
      _notify();

      final tasks = <Future<bool>>[];
      for (final saved in List<Connection>.of(_savedConnections)) {
        switch (saved) {
          case JellyfinConnection():
            tasks.add(_restoreJellyfinConnection(saved, restoreEpoch));
          case PlexAccountConnection():
            for (final server in saved.servers) {
              tasks.add(_restorePlexServer(saved, server, restoreEpoch));
            }
        }
      }

      final results = await Future.wait(tasks);
      if (_disposed || restoreEpoch != _restoreEpoch) return;

      final hadUnavailableServer = results.any((ok) => !ok);
      if (hadCorruptEntry) {
        _error = 'Algumas conexoes salvas estao invalidas e nao puderam ser restauradas.';
      } else if (hadUnavailableServer) {
        _error = 'Alguns servidores nao responderam no momento.';
      }
    } finally {
      _disconnectedDuringRestore.clear();
      if (!_disposed && restoreEpoch == _restoreEpoch) {
        _restoring = false;
        _notify();
      }
    }
  }

  Future<bool> _restoreJellyfinConnection(
    JellyfinConnection connection,
    int restoreEpoch,
  ) async {
    bool isStale() =>
        _disposed || restoreEpoch != _restoreEpoch || _disconnectedDuringRestore.contains(connection.id);

    if (isStale()) return true;
    try {
      final client = await _runClientFactoryWithCleanup(
        _jellyfinClientFactory(connection),
        timeout: _connectTimeout,
        isStale: isStale,
      );
      _attachJellyfinHook(client);
      final health = await _checkClientHealth(client);
      if (isStale()) {
        _closeClient(client);
        return true;
      }
      _upsertServerConnection(
        DesktopServerConnection(
          id: connection.id,
          name: _nonBlank(client.serverName, connection.serverName),
          backend: connection.kind,
          client: client,
          health: health,
        ),
      );
      _notify();
      return true;
    } on _StaleOperationException {
      return true;
    } on Object {
      appLogger.w('Falha ao restaurar conexao Jellyfin.');
      return false;
    }
  }

  Future<bool> _restorePlexServer(
    PlexAccountConnection account,
    PlexServer server,
    int restoreEpoch,
  ) async {
    final ServerId serverId;
    final PlexProfileScopeId scopeId;
    try {
      serverId = ServerId(server.clientIdentifier);
      scopeId = PlexProfileScopeId(profileId: account.id, serverId: serverId);
    } on ArgumentError {
      return false;
    }

    bool isStale() =>
        _disposed ||
        restoreEpoch != _restoreEpoch ||
        _disconnectedDuringRestore.contains(scopeId) ||
        _disconnectedDuringRestore.contains(account.id);

    final connected = await _connectSinglePlexServer(
      account: account,
      server: server,
      scopeId: scopeId,
      isStale: isStale,
    );
    if (connected == null) return isStale();
    if (isStale()) {
      _closeClient(connected.client);
      return true;
    }
    _upsertServerConnection(connected);
    _notify();
    return true;
  }

  Future<void> signInPlex({Future<void> Function(Uri)? openBrowser}) async {
    if (_disposed || _busy) return;
    if (!await _waitForRestore()) return;

    final authEpoch = ++_authEpoch;
    _authCommitted = false;
    _busy = true;
    _error = null;
    _plexCode = null;
    _notify();

    PlexAuthService? auth;
    try {
      final pendingAuth = _plexAuthFactory();
      var timedOut = false;
      unawaited(pendingAuth.then((lateAuth) {
        if (timedOut) _disposePlexAuthSafely(lateAuth);
      }, onError: (Object _, StackTrace _) {}));
      auth = await pendingAuth.timeout(_operationTimeout, onTimeout: () {
        timedOut = true;
        throw TimeoutException('Autenticacao indisponivel.');
      });
      if (_disposed || authEpoch != _authEpoch) {
        _disposePlexAuthSafely(auth);
        auth = null;
        return;
      }
      _activePlexAuth = auth;

      final pinData = await auth.createPin().timeout(_operationTimeout);
      if (_disposed || authEpoch != _authEpoch) return;

      final rawPinId = pinData['id'];
      final pinId = rawPinId is int
          ? rawPinId
          : (rawPinId is num ? rawPinId.toInt() : int.tryParse(rawPinId?.toString() ?? ''));
      final rawCode = pinData['code'];
      final pinCode = rawCode is String ? rawCode.trim() : '';
      if (pinId == null || pinCode.isEmpty) {
        _error = 'Nao foi possivel iniciar a autenticacao no Plex.';
        return;
      }

      _plexCode = pinCode;
      _notify();

      if (openBrowser != null) {
        final authUri = Uri.parse(auth.getAuthUrl(pinCode));
        try {
          await openBrowser(authUri).timeout(_operationTimeout);
        } on Object {
          appLogger.w('Nao foi possivel abrir o navegador para autenticacao Plex.');
        }
        if (_disposed || authEpoch != _authEpoch) return;
      }

      final token = await auth.pollPinUntilClaimed(
        pinId,
        timeout: _plexPinTimeout,
        shouldCancel: () => _disposed || authEpoch != _authEpoch,
      );
      if (_disposed || authEpoch != _authEpoch) return;

      if (token == null || token.trim().isEmpty) {
        _error = 'Tempo esgotado ao aguardar confirmacao no Plex.';
        return;
      }

      LogRedactionManager.registerToken(token);

      final build = await buildPlexAccountConnection(
        token,
        clientIdentifier: auth.clientIdentifier,
        fetchUserInfo: auth.getUserInfo,
        fetchServers: auth.fetchServers,
        tolerateUserInfoFailure: false,
      ).timeout(_operationTimeout);
      if (_disposed || authEpoch != _authEpoch) return;

      final connection = build.connection;
      _registerConnectionRedactions(connection);

      if (connection.servers.isEmpty) {
        _error = 'Nenhum servidor Plex encontrado nesta conta.';
        return;
      }

      final connectedList = <DesktopServerConnection>[];
      var failedServers = 0;
      await Future.wait(
        connection.servers.map((server) async {
          final ServerId serverId;
          final PlexProfileScopeId scopeId;
          try {
            serverId = ServerId(server.clientIdentifier);
            scopeId = PlexProfileScopeId(profileId: connection.id, serverId: serverId);
          } on ArgumentError {
            failedServers++;
            return;
          }
          final conn = await _connectSinglePlexServer(
            account: connection,
            server: server,
            scopeId: scopeId,
            isStale: () => _disposed || authEpoch != _authEpoch,
          );
          if (conn == null) {
            failedServers++;
          } else {
            connectedList.add(conn);
          }
        }),
      );

      if (_disposed || authEpoch != _authEpoch) {
        for (final conn in connectedList) {
          _closeClient(conn.client);
        }
        return;
      }

      _authCommitted = true;
      _upsertSavedConnection(connection);
      _replaceAccountConnections(connection.id, connectedList);
      _notify();

      final persisted = await _persistVaultWithWarning();
      if (_disposed || authEpoch != _authEpoch) return;
      if (!persisted) {
        _error = 'Conexao ativa, mas nao foi possivel salvar a sessao no cofre.';
      } else if (connectedList.isEmpty) {
        _error = 'Nenhum servidor Plex respondeu no momento.';
      } else if (failedServers > 0) {
        _error = 'Alguns servidores Plex nao responderam no momento.';
      }
    } on _StaleOperationException {
      return;
    } on Object catch (error) {
      if (_disposed || authEpoch != _authEpoch) return;
      appLogger.w('Falha na autenticacao Plex.');
      final safe = _safeUserError(error);
      if (safe != null) {
        _error = safe;
      }
    } finally {
      if (identical(_activePlexAuth, auth)) {
        _activePlexAuth = null;
      }
      _disposePlexAuthSafely(auth);
      if (!_disposed && authEpoch == _authEpoch) {
        _busy = false;
        _plexCode = null;
        _notify();
      }
    }
  }

  Future<void> signInJellyfin({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    if (_disposed || _busy) return;

    if (!await _waitForRestore()) return;

    final validatedUrl = _validateJellyfinBaseUrl(baseUrl);
    if (validatedUrl == null) {
      _error = 'Informe um endereco de servidor valido.';
      _notify();
      return;
    }
    final trimmedUser = username.trim();
    if (trimmedUser.isEmpty) {
      _error = 'Informe o nome de usuario.';
      _notify();
      return;
    }
    if (password.isEmpty) {
      _error = 'Informe a senha.';
      _notify();
      return;
    }

    final authEpoch = ++_authEpoch;
    _authCommitted = false;
    _busy = true;
    _error = null;
    _plexCode = null;
    _notify();

    try {
      LogRedactionManager.registerServerUrl(validatedUrl);
      final deviceId = _uuid.v4();
      final connection = await _jellyfinAuthenticator(
        baseUrl: validatedUrl,
        username: trimmedUser,
        password: password,
        deviceId: deviceId,
      ).timeout(_operationTimeout);

      if (_disposed || authEpoch != _authEpoch) return;
      _registerConnectionRedactions(connection);

      final client = await _runClientFactoryWithCleanup(
        _jellyfinClientFactory(connection),
        timeout: _connectTimeout,
        isStale: () => _disposed || authEpoch != _authEpoch,
      );
      _attachJellyfinHook(client);

      final serverConnection = DesktopServerConnection(
        id: connection.id,
        name: _nonBlank(client.serverName, connection.serverName),
        backend: connection.kind,
        client: client,
        health: HealthStatus.online,
      );

      _authCommitted = true;
      _upsertSavedConnection(connection);
      _upsertServerConnection(serverConnection);
      _notify();

      final persisted = await _persistVaultWithWarning();
      if (_disposed || authEpoch != _authEpoch) return;
      if (!persisted) {
        _error = 'Conexao ativa, mas nao foi possivel salvar a sessao no cofre.';
      }
    } on _StaleOperationException {
      return;
    } on Object catch (error) {
      if (_disposed || authEpoch != _authEpoch) return;
      appLogger.w('Falha na autenticacao Jellyfin.');
      final safe = _safeUserError(error);
      if (safe != null) {
        _error = safe;
      }
    } finally {
      if (!_disposed && authEpoch == _authEpoch) {
        _busy = false;
        _notify();
      }
    }
  }

  Future<void> disconnect(String id) async {
    if (_disposed || id.trim().isEmpty) return;
    if (_restoring) {
      _disconnectedDuringRestore.add(id);
    }

    var removedAny = false;
    for (var i = _connections.length - 1; i >= 0; i--) {
      final conn = _connections[i];
      if (conn.id == id || _belongsToAccount(conn, id)) {
        _connections.removeAt(i);
        _closeClient(conn.client);
        removedAny = true;
      }
    }

    final updatedSaved = _removeSavedConnection(id);

    if (!removedAny && !updatedSaved) return;
    _notify();

    final persisted = await _persistVaultWithWarning();
    if (!_disposed && !persisted) {
      _error = 'Conexao removida da sessao, mas nao foi possivel atualizar o cofre.';
      _notify();
    }
  }

  bool _removeSavedConnection(String id) {
    final scope = PlexProfileScopeId.tryParse(id);
    var updatedSaved = false;
    for (var i = _savedConnections.length - 1; i >= 0; i--) {
      final saved = _savedConnections[i];
      if (saved.id == id) {
        _savedConnections.removeAt(i);
        updatedSaved = true;
      } else if (scope != null && saved is PlexAccountConnection && saved.id == scope.profileId) {
        final remaining = saved.servers
            .where((server) => server.clientIdentifier != scope.publicServerId)
            .toList(growable: false);
        if (remaining.isEmpty) {
          _savedConnections.removeAt(i);
        } else if (remaining.length != saved.servers.length) {
          _savedConnections[i] = saved.copyWith(servers: remaining);
        }
        updatedSaved = true;
      }
    }

    return updatedSaved;
  }

  Future<bool> _waitForRestore() async {
    final epoch = _authEpoch;
    await _activeRestore;
    return !_disposed && !_busy && epoch == _authEpoch;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _authEpoch++;
    _restoreEpoch++;
    _busy = false;
    _restoring = false;
    _plexCode = null;
    _disposeActivePlexAuth();
    _cancelPendingEndpointResolvers();
    _clearConnections();
    _savedConnections.clear();
    super.dispose();
  }

  Future<DesktopServerConnection?> _connectSinglePlexServer({
    required PlexAccountConnection account,
    required PlexServer server,
    required PlexProfileScopeId scopeId,
    required bool Function() isStale,
  }) async {
    if (isStale()) return null;
    try {
      _registerPlexServerRedactions(server);
      bool? transcoderSupport;
      final endpoint = await _plexEndpointResolver(
        server,
        account.clientIdentifier,
        onTranscoderCapability: (supported) => transcoderSupport = supported,
      ).timeout(_connectTimeout);

      if (endpoint == null || isStale()) return null;

      final prioritized = server.prioritizedEndpointUrls(preferredFirst: endpoint.uri);
      for (final url in prioritized) {
        LogRedactionManager.registerServerUrl(url);
      }

      final client = await _runClientFactoryWithCleanup(
        _plexClientFactory(
          account: account,
          server: server,
          endpoint: endpoint,
          profileScopeId: scopeId,
          prioritizedEndpoints: prioritized,
          seedTranscoderVideoSupport: transcoderSupport,
        ),
        timeout: _connectTimeout,
        isStale: isStale,
      );

      return DesktopServerConnection(
        id: scopeId,
        name: _nonBlank(client.serverName, server.name),
        backend: MediaBackend.plex,
        client: client,
        health: HealthStatus.online,
      );
    } on _StaleOperationException {
      return null;
    } on Object {
      appLogger.w('Nao foi possivel conectar ao servidor Plex.');
      return null;
    }
  }

  Future<T> _runClientFactoryWithCleanup<T extends MediaServerClient>(
    Future<T> future, {
    required Duration timeout,
    required bool Function() isStale,
  }) async {
    var timedOut = false;
    unawaited(
      future.then(
        (client) {
          if (timedOut) {
            _closeClient(client);
          }
        },
        onError: (Object _, StackTrace _) {},
      ),
    );

    final client = await future.timeout(
      timeout,
      onTimeout: () {
        timedOut = true;
        throw TimeoutException('Tempo esgotado ao inicializar cliente.');
      },
    );

    if (_disposed || isStale()) {
      _closeClient(client);
      throw const _StaleOperationException();
    }
    return client;
  }

  Future<HealthStatus> _checkClientHealth(MediaServerClient client) async {
    try {
      return await client.checkHealth().timeout(_connectTimeout);
    } on TimeoutException {
      return HealthStatus.offline;
    } on MediaServerAuthException catch (error) {
      return error.statusCode == 403 ? HealthStatus.accessDenied : HealthStatus.authError;
    } on MediaServerHttpException catch (error) {
      if (error.statusCode == 401) return HealthStatus.authError;
      if (error.statusCode == 403) return HealthStatus.accessDenied;
      return HealthStatus.offline;
    } on Object {
      return HealthStatus.offline;
    }
  }

  void _attachJellyfinHook(MediaServerClient client) {
    if (client is JellyfinClient) {
      client.onConnectionUpdated = _handleJellyfinConnectionUpdated;
    }
  }

  void _handleJellyfinConnectionUpdated(JellyfinConnection updated) {
    if (_disposed) return;
    final index = _savedConnections.indexWhere((c) => c is JellyfinConnection && c.id == updated.id);
    if (index < 0) return;
    _savedConnections[index] = updated;
    _registerConnectionRedactions(updated);
    unawaited(_persistVaultWithWarning());
  }

  Future<bool> _persistVaultWithWarning() {
    final entries = _savedConnections.map(_encodeVaultEntry).toList(growable: false);
    final future = _persistQueue.then((_) async {
      try {
        await _vault.write(entries);
        return true;
      } on Object {
        appLogger.w('Falha ao persistir conexoes no cofre.');
        return false;
      }
    });
    _persistQueue = future.then<void>((_) {}, onError: (Object _) {});
    return future;
  }

  void _upsertSavedConnection(Connection connection) {
    final index = _savedConnections.indexWhere((c) => c.id == connection.id);
    if (index >= 0) {
      _savedConnections[index] = connection;
    } else {
      _savedConnections.add(connection);
    }
  }

  void _upsertServerConnection(DesktopServerConnection serverConnection) {
    final index = _connections.indexWhere((c) => c.id == serverConnection.id);
    if (index >= 0) {
      final old = _connections[index];
      _connections[index] = serverConnection;
      if (!identical(old.client, serverConnection.client)) {
        _closeClient(old.client);
      }
    } else {
      _connections.add(serverConnection);
    }
  }

  void _replaceAccountConnections(String accountId, List<DesktopServerConnection> nextServers) {
    for (var i = _connections.length - 1; i >= 0; i--) {
      final existing = _connections[i];
      if (_belongsToAccount(existing, accountId)) {
        _connections.removeAt(i);
        if (!nextServers.any((next) => identical(next.client, existing.client))) {
          _closeClient(existing.client);
        }
      }
    }
    for (final next in nextServers) {
      _upsertServerConnection(next);
    }
  }

  void _clearConnections() {
    for (final conn in _connections) {
      _closeClient(conn.client);
    }
    _connections.clear();
  }

  void _disposeActivePlexAuth() {
    final auth = _activePlexAuth;
    _activePlexAuth = null;
    _disposePlexAuthSafely(auth);
  }

  void _cancelPendingEndpointResolvers() {
    final cancellers = _activeEndpointCancellers.toList(growable: false);
    _activeEndpointCancellers.clear();
    for (final cancel in cancellers) {
      cancel();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<PlexConnection?> _defaultResolvePlexEndpoint(
    PlexServer server,
    String clientIdentifier, {
    void Function(bool)? onTranscoderCapability,
  }) {
    final completer = Completer<PlexConnection?>();
    late final StreamSubscription<PlexConnection> subscription;
    late final Timer timer;

    void cancelResolver() {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      unawaited(subscription.cancel());
    }

    _activeEndpointCancellers.add(cancelResolver);
    timer = Timer(_connectTimeout, () {
      _activeEndpointCancellers.remove(cancelResolver);
      cancelResolver();
    });

    subscription = server
        .findBestWorkingConnection(
          clientIdentifier: clientIdentifier,
          onTranscoderCapability: onTranscoderCapability,
        )
        .listen(
          (endpoint) {
            _activeEndpointCancellers.remove(cancelResolver);
            timer.cancel();
            if (!completer.isCompleted) {
              completer.complete(endpoint);
            }
            unawaited(subscription.cancel());
          },
          onError: (Object _) {
            _activeEndpointCancellers.remove(cancelResolver);
            timer.cancel();
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
          onDone: () {
            _activeEndpointCancellers.remove(cancelResolver);
            timer.cancel();
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
          cancelOnError: true,
        );

    return completer.future;
  }

  static Future<PlexAuthService> _defaultPlexAuthFactory() => PlexAuthService.create(productName: 'Heisuca');

  static Future<MediaServerClient> _defaultPlexClientFactory({
    required PlexAccountConnection account,
    required PlexServer server,
    required PlexConnection endpoint,
    required PlexProfileScopeId profileScopeId,
    required List<String> prioritizedEndpoints,
    bool? seedTranscoderVideoSupport,
  }) async {
    PlexConfig config;
    try {
      config = await PlexConfig.create(
        baseUrl: endpoint.uri,
        token: server.accessToken,
        clientIdentifier: account.clientIdentifier,
        product: 'Heisuca',
        machineIdentifier: server.clientIdentifier,
      );
    } on Object {
      config = PlexConfig(
        baseUrl: endpoint.uri,
        token: server.accessToken,
        clientIdentifier: account.clientIdentifier,
        product: 'Heisuca',
        version: '1.0.0',
        machineIdentifier: server.clientIdentifier,
      );
    }

    return PlexClient.create(
      config,
      serverId: ServerId(server.clientIdentifier),
      profileScopeId: profileScopeId,
      serverName: server.name,
      prioritizedEndpoints: prioritizedEndpoints,
      seedTranscoderVideoSupport: seedTranscoderVideoSupport,
      onEndpointChanged: (newBaseUrl) async {
        LogRedactionManager.registerServerUrl(newBaseUrl);
      },
    );
  }

  static Future<JellyfinConnection> _defaultJellyfinAuthenticate({
    required String baseUrl,
    required String username,
    required String password,
    required String deviceId,
  }) async {
    var version = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.version.isNotEmpty) {
        version = packageInfo.version;
      }
    } on Object {
      // Optional platform metadata or teardown; keep errors payload-free.
    }

    var deviceName = 'Desktop';
    try {
      final identity = await DeviceIdentityService.resolve();
      final sanitized = sanitizeHeaderValue(identity.deviceName);
      if (sanitized != null && sanitized.isNotEmpty) {
        deviceName = sanitized;
      }
    } on Object {
      // Optional platform metadata or teardown; keep errors payload-free.
    }

    final authService = JellyfinConnectionAuthService(
      clientName: 'Heisuca Windows',
      clientVersion: version,
      deviceName: deviceName,
    );
    return authService.authenticateByName(
      baseUrl: baseUrl,
      username: username,
      password: password,
      deviceId: deviceId,
    );
  }

  static Future<MediaServerClient> _defaultJellyfinClientFactory(JellyfinConnection connection) {
    return JellyfinClient.create(connection, clientName: 'Heisuca Windows');
  }

  static Map<String, dynamic> _encodeVaultEntry(Connection connection) {
    return <String, dynamic>{
      'version': vaultSchemaVersion,
      'kind': connection.kind.id,
      'id': connection.id,
      'createdAt': connection.createdAt.toUtc().toIso8601String(),
      'lastAuthenticatedAt': connection.lastAuthenticatedAt?.toUtc().toIso8601String(),
      'config': connection.toConfigJson(),
    };
  }

  static Connection? _parseVaultEntry(Map<String, dynamic> entry) {
    try {
      if (entry['version'] != vaultSchemaVersion) return null;
      final rawKind = entry['kind'];
      if (rawKind is! String) return null;
      if (rawKind != MediaBackend.plex.id && rawKind != MediaBackend.jellyfin.id && rawKind != MediaBackend.emby.id) {
        return null;
      }
      final backend = MediaBackend.fromId(rawKind);
      final rawId = entry['id'];
      if (rawId is! String || rawId.trim().isEmpty || rawId.contains('://')) return null;
      final id = rawId.trim();

      final rawCreatedAt = entry['createdAt'];
      if (rawCreatedAt is! String) return null;
      final createdAt = DateTime.tryParse(rawCreatedAt);
      if (createdAt == null) return null;

      DateTime? lastAuthenticatedAt;
      final rawLastAuth = entry['lastAuthenticatedAt'];
      if (rawLastAuth != null) {
        if (rawLastAuth is! String) return null;
        lastAuthenticatedAt = DateTime.tryParse(rawLastAuth);
        if (lastAuthenticatedAt == null) return null;
      }

      final rawConfig = entry['config'];
      if (rawConfig is! Map) return null;
      final normalizedConfig = _normalizeJsonValue(rawConfig);
      if (normalizedConfig is! Map<String, dynamic>) return null;

      if (backend == MediaBackend.plex) {
        final conn = PlexAccountConnection.fromConfigJson(
          id: id,
          json: normalizedConfig,
          createdAt: createdAt,
          lastAuthenticatedAt: lastAuthenticatedAt,
        );
        if (conn.accountToken.trim().isEmpty || conn.clientIdentifier.trim().isEmpty || conn.servers.isEmpty) {
          return null;
        }
        for (final server in conn.servers) {
          if (ServerId.tryParse(server.clientIdentifier) == null ||
              server.accessToken.trim().isEmpty ||
              server.connections.isEmpty) {
            return null;
          }
        }
        return conn;
      }

      final dialect = backend.dialect;
      if (dialect == null) return null;
      final conn = JellyfinConnection.fromConfigJson(
        id: id,
        json: normalizedConfig,
        createdAt: createdAt,
        lastAuthenticatedAt: lastAuthenticatedAt,
        dialect: dialect,
      );
      if (_validateJellyfinBaseUrl(conn.baseUrl) == null ||
          conn.baseUrls.any((url) => _validateJellyfinBaseUrl(url) == null) ||
          conn.accessToken.trim().isEmpty ||
          conn.serverMachineId.trim().isEmpty ||
          conn.userId.trim().isEmpty ||
          conn.deviceId.trim().isEmpty) {
        return null;
      }
      return conn;
    } on Object {
      return null;
    }
  }

  static Object? _normalizeJsonValue(Object? value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          if (entry.key != null) entry.key.toString(): _normalizeJsonValue(entry.value),
      };
    }
    if (value is List) {
      return <dynamic>[for (final item in value) _normalizeJsonValue(item)];
    }
    return value;
  }

  static void _registerConnectionRedactions(Connection connection) {
    switch (connection) {
      case PlexAccountConnection():
        LogRedactionManager.registerToken(connection.accountToken);
        for (final server in connection.servers) {
          _registerPlexServerRedactions(server);
        }
      case JellyfinConnection():
        LogRedactionManager.registerToken(connection.accessToken);
        for (final url in connection.baseUrls) {
          LogRedactionManager.registerServerUrl(url);
        }
    }
  }

  static void _registerPlexServerRedactions(PlexServer server) {
    LogRedactionManager.registerToken(server.accessToken);
    for (final ep in server.connections) {
      LogRedactionManager.registerServerUrl(ep.uri);
    }
  }

  static String? _validateJellyfinBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.runes.any((r) => r <= 0x20)) return null;
    try {
      final explicit = trimmed.contains('://');
      final uri = Uri.tryParse(explicit ? trimmed : 'http://$trimmed');
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment ||
          uri.port < 1 || uri.port > 65535) {
        return null;
      }
      // Raw @ catches even an empty userinfo that Uri normalizes away.
      if (uri.authority.contains('@') || trimmed.contains('@')) return null;
      return uri.toString();
    } on Object { return null; }
  }

  static bool _belongsToAccount(DesktopServerConnection serverConn, String accountId) {
    final scope = PlexProfileScopeId.tryParse(serverConn.id);
    if (scope != null) {
      return scope.profileId == accountId;
    }
    return serverConn.id == accountId;
  }

  static String _nonBlank(String? candidate, String fallback) {
    final trimmed = candidate?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }

  static void _closeClient(MediaServerClient client) {
    try {
      client.close();
    } on Object {
      // Optional platform metadata or teardown; keep errors payload-free.
    }
  }

  static void _disposePlexAuthSafely(PlexAuthService? auth) {
    if (auth == null) return;
    try {
      auth.dispose();
    } on Object {
      // Optional platform metadata or teardown; keep errors payload-free.
    }
  }

  static String? _safeUserError(Object error) {
    return switch (error) {
      MediaServerPinExpiredException() => 'O codigo do Plex expirou. Tente novamente.',
      MediaServerAuthException(:final statusCode) when statusCode == 401 || statusCode == 403 =>
        'Credenciais invalidas ou acesso negado.',
      MediaServerAuthException() => 'Nao foi possivel autenticar no servidor.',
      MediaServerUrlException() => 'Endereco do servidor invalido ou inacessivel.',
      MediaServerHttpException(:final isCancellation) when isCancellation => null,
      MediaServerHttpException(:final type) when
          type == MediaServerHttpErrorType.connectionTimeout || type == MediaServerHttpErrorType.receiveTimeout =>
        'Tempo esgotado ao conectar ao servidor.',
      MediaServerHttpException(:final type) when type == MediaServerHttpErrorType.connectionError =>
        'Nao foi possivel conectar ao servidor.',
      MediaServerHttpException(:final statusCode) when statusCode == 401 || statusCode == 403 =>
        'Credenciais invalidas ou acesso negado.',
      MediaServerHttpException() => 'Falha na comunicacao com o servidor.',
      TimeoutException() => 'Tempo esgotado ao conectar ao servidor.',
      ServerParsingException() => 'Nao foi possivel interpretar a lista de servidores do Plex.',
      DesktopVaultException() => 'Nao foi possivel acessar as conexoes protegidas.',
      _ => 'Nao foi possivel concluir a operacao no servidor.',
    };
  }
}
