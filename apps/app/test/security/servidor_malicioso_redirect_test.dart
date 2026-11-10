import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/exceptions/media_server_exceptions.dart';
import 'package:heisuca/services/jellyfin_client.dart';
import 'package:heisuca/utils/media_server_http_client.dart';
import 'package:http/io_client.dart';

import 'malicious_server_harness.dart';

/// P5 lote 4, caso 5: redirecionamentos hostis. Aceite: laço e destino
/// proibido terminam com erro tratado em tempo limitado e o token (cabeçalho
/// ou api_key) nunca chega a outro host.
void main() {
  late MaliciousServer server;
  late MaliciousServer other;
  late JellyfinClient client;

  setUp(() async {
    initCache();
    server = await MaliciousServer.start();
    other = await MaliciousServer.start();
    other.jsonObject('/capturado', {'Id': 'a', 'Name': 'x', 'Type': 'Movie'});
    client = await clientFor(server.baseUrl);
  });
  tearDown(() async {
    client.close();
    await server.stop();
    await other.stop();
    await closeCache();
  });

  /// Outro host de verdade (nome diferente) apontando para o segundo servidor.
  String otherHostUrl(String path) => 'http://localhost:${other.port}$path';

  Future<void> expectHandled(Future<Object?> call) async {
    await expectLater(call.timeout(const Duration(seconds: 30)), throwsA(isA<MediaServerException>()));
  }

  test('302 para si mesmo termina com erro tratado e em tempo limitado', () async {
    server.redirect('/Users/user-1/Items/a', '/Users/user-1/Items/a');
    final sw = Stopwatch()..start();
    await expectHandled(client.fetchItem('a'));
    expect(sw.elapsed, lessThan(const Duration(seconds: 20)));
    expect(server.seen.length, lessThanOrEqualTo(6));
  });

  test('A -> B -> A termina com erro tratado', () async {
    server.redirect('/Users/user-1/Items/a', '/b');
    server.redirect('/b', '/Users/user-1/Items/a');
    await expectHandled(client.fetchItem('a'));
    expect(server.seen.length, lessThanOrEqualTo(6));
  });

  test('redirect para outro host não leva o token e é recusado', () async {
    server.redirect('/Users/user-1/Items/a', otherHostUrl('/capturado'));
    await expectHandled(client.fetchItem('a'));
    expect(other.seen, isEmpty, reason: 'o outro host nem deve ser contatado com credencial');
    expect(other.seen.any((r) => r.carriesToken(maliciousTestToken)), isFalse);
  });

  test('redirect para outro host com api_key na URL também é recusado', () async {
    server.redirect('/img', otherHostUrl('/capturado'));
    final http = MediaServerHttpClient(client: IOClient(HttpClient()), baseUrl: server.baseUrl);
    await expectLater(
      http.getBytes('${server.baseUrl}/img?api_key=$maliciousTestToken'),
      throwsA(isA<MediaServerException>()),
    );
    expect(other.seen, isEmpty);
    http.close();
  });

  test('redirect para esquema não-http (file://) é recusado', () async {
    server.redirect('/Users/user-1/Items/a', 'file:///etc/passwd');
    await expectHandled(client.fetchItem('a'));
  });

  test('redirect no mesmo host continua funcionando', () async {
    server.redirect('/Users/user-1/Items/a', '/novo');
    server.jsonObject('/novo', {'Id': 'a', 'Name': 'Filme', 'Type': 'Movie'});
    final item = await client.fetchItem('a');
    expect(item?.title, 'Filme');
    expect(server.seen.every((r) => r.headers['x-emby-token'] == maliciousTestToken), isTrue);
  });

  test('sem credencial (sondagem pública), salto para outro host segue e a URL final é informada', () async {
    server.redirect('/System/Info/Public', otherHostUrl('/capturado'));
    final http = MediaServerHttpClient(client: IOClient(HttpClient()), baseUrl: server.baseUrl);
    final response = await http.get('/System/Info/Public');
    expect(response.effectiveUri?.host, 'localhost');
    expect(other.seen.any((r) => r.carriesToken(maliciousTestToken)), isFalse);
    http.close();
  });
}
