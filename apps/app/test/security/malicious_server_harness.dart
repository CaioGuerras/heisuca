import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';
import 'package:heisuca/services/jellyfin_client.dart';
import 'package:http/io_client.dart';

import '../test_helpers/backend_client_fixtures.dart';

/// Servidor Jellyfin falso e hostil, em 127.0.0.1 (porta 0), para os testes do
/// lote 4 da P5 (servidor malicioso). Usa o cliente real e a pilha HTTP real
/// (dart:io), sem MockClient, para exercitar redirecionamento, TLS e limites.
typedef MaliciousHandler = FutureOr<void> Function(HttpRequest request);

class MaliciousServer {
  MaliciousServer._(this.server, {required this.secure});

  final HttpServer server;
  final bool secure;

  /// Rotas por caminho exato; o fallback responde 404.
  final Map<String, MaliciousHandler> routes = {};

  /// Todo pedido recebido: método, URI completa e cabeçalhos.
  final List<RecordedRequest> seen = [];

  static Future<MaliciousServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return MaliciousServer._(server, secure: false).._listen();
  }

  static Future<MaliciousServer> startSecure(SecurityContext context) async {
    final server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context);
    return MaliciousServer._(server, secure: true).._listen();
  }

  String get baseUrl => '${secure ? 'https' : 'http'}://127.0.0.1:${server.port}';
  int get port => server.port;

  void _listen() {
    server.listen((request) async {
      final headers = <String, String>{};
      request.headers.forEach((name, values) => headers[name.toLowerCase()] = values.join(','));
      seen.add(RecordedRequest(request.method, request.uri, headers));
      final handler = routes[request.uri.path];
      try {
        if (handler != null) {
          await handler(request);
        } else {
          request.response.statusCode = 404;
        }
      } catch (_) {
        // Cliente desistiu no meio da resposta: normal nestes testes.
      }
      try {
        await request.response.close();
      } catch (_) {}
    }, onError: (_) {});
  }

  /// Responde JSON cru (string já pronta).
  void json(String path, String body) {
    routes[path] = (request) {
      request.response.headers.contentType = ContentType.json;
      request.response.write(body);
    };
  }

  void jsonObject(String path, Object? value) => json(path, jsonEncode(value));

  void redirect(String path, String location, {int status = 302}) {
    routes[path] = (request) {
      request.response.statusCode = status;
      request.response.headers.set(HttpHeaders.locationHeader, location);
    };
  }

  Future<void> stop() => server.close(force: true);
}

class RecordedRequest {
  RecordedRequest(this.method, this.uri, this.headers);
  final String method;
  final Uri uri;
  final Map<String, String> headers;

  bool carriesToken(String token) => headers.values.any((v) => v.contains(token)) || uri.toString().contains(token);
}

/// Token de teste que nenhum pedido a outro host pode carregar.
const maliciousTestToken = 'TOKEN-SECRETO-P5';

Future<JellyfinClient> clientFor(String baseUrl, {String token = maliciousTestToken}) async {
  return JellyfinClient.forTesting(
    connection: testJellyfinConnection(baseUrl: baseUrl, accessToken: token, userId: 'user-1'),
    httpClient: IOClient(HttpClient()),
  );
}

AppDatabase? _db;

/// O cliente grava no cache em respostas 200; precisa do singleton.
void initCache() {
  _db = AppDatabase.forTesting(NativeDatabase.memory());
  JellyfinApiCache.initialize(_db!);
}

Future<void> closeCache() async {
  await _db?.close();
  _db = null;
}
