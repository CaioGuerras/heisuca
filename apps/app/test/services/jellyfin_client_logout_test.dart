import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../test_helpers/backend_client_fixtures.dart';

void main() {
  test('JellyfinClient.logout envia POST /Sessions/Logout para o servidor', () async {
    final requests = <http.BaseRequest>[];
    final mock = MockClient((request) async {
      requests.add(request);
      if (request.method == 'POST' && request.url.path == '/Sessions/Logout') {
        return http.Response('', 204);
      }
      return http.Response('Not Found', 404);
    });

    final conn = testJellyfinConnection(
      baseUrl: 'https://jf.exemplo.invalid',
      accessToken: 'XXXX-falso',
      userName: 'teste-sem-senha',
      deviceId: 'dev-XXXX-falso',
    );
    final client = testJellyfinClient(connection: conn, httpClient: mock);

    await client.logout();

    expect(requests.where((r) => r.method == 'POST' && r.url.path == '/Sessions/Logout'), hasLength(1));
  });

  test('JellyfinClient.logout trata falha de rede sem propagar excecao', () async {
    final mock = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    final conn = testJellyfinConnection(
      baseUrl: 'https://jf.exemplo.invalid',
      accessToken: 'XXXX-falso',
      userName: 'teste-sem-senha',
      deviceId: 'dev-XXXX-falso',
    );
    final client = testJellyfinClient(connection: conn, httpClient: mock);

    await expectLater(client.logout(), completes);
  });

  test('JellyfinClient.logout não trava a saída quando o servidor não responde', () async {
    final pendente = Completer<http.Response>();
    final mock = MockClient((request) => pendente.future);
    final conn = testJellyfinConnection(
      baseUrl: 'https://jf.exemplo.invalid',
      accessToken: 'XXXX-falso',
      userName: 'teste-sem-senha',
      deviceId: 'dev-XXXX-falso',
    );
    final client = testJellyfinClient(connection: conn, httpClient: mock);

    final relogio = Stopwatch()..start();
    await expectLater(client.logout(prazo: const Duration(milliseconds: 200)), completes);
    expect(relogio.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
