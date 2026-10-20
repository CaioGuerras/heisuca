// Etapa 1E (A): pedidos pelo Seerr sem tela de login. Seerr de mentira (MockClient): acha o
// endereço ao lado do Jellyfin, entra pelo Quick Connect aprovado com o token da pessoa, guarda
// o cookie no armazenamento seguro e renova sozinho no 401.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/cgflix/requests/cgflix_secure_store.dart';
import 'package:plezy/cgflix/requests/cgflix_seerr.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seerr = 'https://pedidos.docaio.com.br';

/// Seerr falso. [up] = responde; [validCookie] = o cookie que ele aceita agora.
class _FakeSeerr {
  bool up = true;
  String validCookie = 'sessao-1';
  int logins = 0;
  final calls = <String>[];
  final posted = <Map<String, dynamic>>[];

  http.Response _json(Object body, {int status = 200, Map<String, String> headers = const {}}) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});

  Future<http.Response> handle(http.Request request) async {
    final url = request.url;
    calls.add('${request.method} ${url.host}${url.path}');
    if (!up) throw http.ClientException('fora do ar', url);
    // Só o Seerr do CGFLIX existe; os outros nomes não respondem.
    if (url.host != 'pedidos.docaio.com.br') throw http.ClientException('host desconhecido', url);
    final path = url.path.replaceFirst('/api/v1', '');
    switch (path) {
      case '/settings/public':
        return _json({'initialized': true, 'mediaServerType': 2});
      case '/auth/jellyfin/quickconnect/initiate':
        return _json({'code': '123456', 'secret': 'segredo-qc'});
      case '/auth/jellyfin/quickconnect/check':
        return _json({'authenticated': true});
      case '/auth/jellyfin/quickconnect/authenticate':
        logins++;
        validCookie = 'sessao-${logins + 1}';
        return _json({'id': 7}, headers: {'set-cookie': 'connect.sid=$validCookie; Path=/; HttpOnly'});
    }
    final cookie = request.headers['Cookie'] ?? '';
    if (cookie != 'connect.sid=$validCookie') {
      return _json({'message': 'Unauthorized'}, status: 401);
    }
    switch (path) {
      case '/auth/me':
        return _json({'id': 7, 'displayName': 'Caio', 'permissions': 32});
      case '/search':
        expect(url.queryParameters['language'], 'pt-BR');
        return _json({
          'page': 1,
          'totalPages': 1,
          'results': [
            {'id': 1, 'mediaType': 'movie', 'title': 'Duna', 'releaseDate': '2021-09-15', 'posterPath': '/d.jpg'},
            {
              'id': 2,
              'mediaType': 'tv',
              'name': 'Duna: A Profecia',
              'firstAirDate': '2024-11-17',
              'mediaInfo': {'status': 1},
            },
            {
              'id': 3,
              'mediaType': 'movie',
              'title': 'Duna: Parte Dois',
              'mediaInfo': {'status': 2},
            },
            {
              'id': 4,
              'mediaType': 'movie',
              'title': 'Duna (1984)',
              'mediaInfo': {'status': 3},
            },
            {
              'id': 5,
              'mediaType': 'movie',
              'title': 'Já temos',
              'mediaInfo': {'status': 5},
            },
            {
              'id': 6,
              'mediaType': 'tv',
              'name': 'Temos em parte',
              'mediaInfo': {'status': 4},
            },
            {'id': 7, 'mediaType': 'person', 'name': 'Denis Villeneuve'},
          ],
        });
      case '/tv/2':
        return _json({
          'name': 'Duna: A Profecia',
          'seasons': [
            {'seasonNumber': 0, 'name': 'Especiais'},
            {'seasonNumber': 1, 'name': 'Temporada 1', 'episodeCount': 6},
            {'seasonNumber': 2, 'name': 'Temporada 2', 'episodeCount': 6},
          ],
          'mediaInfo': {
            'status': 4,
            'seasons': [
              {'seasonNumber': 1, 'status': 5},
            ],
          },
        });
      case '/request':
        posted.add(jsonDecode(request.body) as Map<String, dynamic>);
        return _json({'id': 99, 'status': 1}, status: 201);
      case '/user/7/requests':
        return _json({
          'results': [
            {
              'id': 10,
              'status': 2,
              'createdAt': '2026-10-01T10:00:00.000Z',
              'media': {'tmdbId': 1, 'mediaType': 'movie', 'status': 5},
            },
            {
              'id': 11,
              'status': 1,
              'createdAt': '2026-10-06T10:00:00.000Z',
              'type': 'tv',
              'media': {'tmdbId': 2, 'mediaType': 'tv', 'status': 2},
              'seasons': [
                {'seasonNumber': 2},
              ],
            },
          ],
        });
    }
    return _json({'message': 'não achei'}, status: 404);
  }
}

void main() {
  late _FakeSeerr seerr;
  late CgflixMemorySecureStore store;
  late List<String> approvedCodes;

  CgflixSeerrRequests backend() => CgflixSeerrRequests(
    jellyfinBaseUrl: 'https://netflix.docaio.com.br',
    accountKey: 'srv:user',
    authorizeQuickConnect: (code) async => approvedCodes.add(code),
    store: store,
    httpClientFactory: () => MockClient(seerr.handle),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    seerr = _FakeSeerr();
    store = CgflixMemorySecureStore();
    approvedCodes = [];
  });

  test('endereço do Seerr sai do endereço do Jellyfin ("pedidos" primeiro)', () {
    expect(cgflixSeerrCandidates('https://netflix.docaio.com.br').first, _seerr);
    expect(cgflixSeerrCandidates('https://netflix.docaio.com.br'), contains('https://seerr.docaio.com.br'));
    expect(cgflixSeerrCandidates('http://192.168.0.10:8096'), ['http://192.168.0.10:5055']);
    expect(cgflixSeerrCandidates(''), isEmpty);
  });

  test('situação no Seerr: pedir, "Pedido", "Baixando"; disponível não repete', () {
    expect(cgflixRequestStateFor(null), CgflixRequestState.requestable);
    expect(cgflixRequestStateFor(1), CgflixRequestState.requestable);
    expect(cgflixRequestStateFor(2), CgflixRequestState.requested);
    expect(cgflixRequestStateFor(3), CgflixRequestState.downloading);
    expect(cgflixRequestStateFor(4), isNull);
    expect(cgflixRequestStateFor(5), isNull);
  });

  test('busca: entra sozinho pelo Quick Connect e separa disponível, pedido e baixando', () async {
    final results = await backend().search('duna');

    // Entrou sem formulário: o código foi aprovado com o token da pessoa no Jellyfin.
    expect(approvedCodes, ['123456']);
    expect(seerr.logins, 1);
    // Cookie no armazenamento seguro (nunca em SharedPreferences).
    expect(store.values['seerr_session:srv:user'], contains('sessao-2'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);

    expect(results.map((r) => r.title), ['Duna', 'Duna: A Profecia', 'Duna: Parte Dois', 'Duna (1984)']);
    expect(results.map((r) => r.state), [
      CgflixRequestState.requestable,
      CgflixRequestState.requestable,
      CgflixRequestState.requested,
      CgflixRequestState.downloading,
    ]);
    expect(results.first.isMovie, isTrue);
    expect(results.first.year, 2021);
    expect(results.first.posterUrl, 'https://image.tmdb.org/t/p/w342/d.jpg');
    expect(results[1].isMovie, isFalse);
  });

  test('cookie guardado é reaproveitado (sem entrar de novo)', () async {
    await backend().search('duna');
    approvedCodes.clear();
    final again = backend(); // outra abertura do app: lê o armazenamento seguro
    await again.search('duna');
    expect(approvedCodes, isEmpty);
    expect(seerr.logins, 1);
  });

  test('401: renova a sessão sozinho e repete a busca', () async {
    final first = backend();
    await first.search('duna');
    // O Seerr reiniciou e esqueceu a sessão.
    seerr.validCookie = 'outra';
    seerr.logins = 1;
    final results = await first.search('duna');
    expect(results, hasLength(4));
    expect(seerr.logins, 2, reason: 'entrou de novo');
    expect(approvedCodes, hasLength(2));
    expect(store.values['seerr_session:srv:user'], contains(seerr.validCookie));
  });

  test('Seerr fora do ar: CgflixRequestsUnavailable (a busca só esconde a seção)', () async {
    seerr.up = false;
    await expectLater(backend().search('duna'), throwsA(isA<CgflixRequestsUnavailable>()));
    expect(approvedCodes, isEmpty);
  });

  test('Seerr fora do ar: a busca seguinte nem vai à rede por 2 minutos', () async {
    seerr.up = false;
    final api = backend();
    await expectLater(api.search('duna'), throwsA(isA<CgflixRequestsUnavailable>()));
    final calls = seerr.calls.length;
    seerr.up = true;
    await expectLater(api.search('dun'), throwsA(isA<CgflixRequestsUnavailable>()));
    expect(seerr.calls.length, calls, reason: 'aviso na hora, sem esperar a rede de novo');
  });

  test('Quick Connect desligado no Jellyfin: CgflixRequestsUnavailable, nunca login', () async {
    final noQc = CgflixSeerrRequests(
      jellyfinBaseUrl: 'https://netflix.docaio.com.br',
      accountKey: 'srv:user',
      authorizeQuickConnect: (code) async => throw Exception('Quick Connect desligado'),
      store: store,
      httpClientFactory: () => MockClient(seerr.handle),
    );
    await expectLater(noQc.search('duna'), throwsA(isA<CgflixRequestsUnavailable>()));
  });

  test('pedir: filme direto; série com as temporadas escolhidas ou todas', () async {
    final api = backend();
    final results = await api.search('duna');
    await api.request(results[0]);
    await api.request(results[1], seasons: [2]);
    await api.request(results[1]);
    expect(seerr.posted[0], containsPair('mediaType', 'movie'));
    expect(seerr.posted[0], containsPair('mediaId', 1));
    expect(seerr.posted[0].containsKey('seasons'), isFalse);
    expect(seerr.posted[1], containsPair('seasons', [2]));
    expect(seerr.posted[2], containsPair('seasons', 'all'));
  });

  test('temporadas: sem especiais; a que já temos vem travada', () async {
    final seasons = await backend().seasons(2);
    expect(seasons.map((s) => s.number), [1, 2]);
    expect(seasons.first.lockedLabel, 'Já temos');
    expect(seasons.last.lockedLabel, isNull);
    expect(seasons.last.episodes, 6);
  });

  test('Meus pedidos: mais novos primeiro, com a situação em português', () async {
    final requests = await backend().myRequests();
    expect(requests.map((r) => r.id), [11, 10]);
    expect(cgflixMyRequestStatusLabel(requests.first.status), 'Aguardando aprovação');
    expect(requests.first.seasons, [2]);
    expect(requests.first.isMovie, isFalse);
    expect(cgflixMyRequestStatusLabel(requests.last.status), 'Disponível');
  });
}
