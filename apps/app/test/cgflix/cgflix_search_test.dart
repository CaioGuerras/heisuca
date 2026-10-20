import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:plezy/cgflix/cgflix_defaults.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/mixins/debounced_media_search.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/utils/search_relevance.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

/// Medição da busca no Jellyfin: quantas chamadas ao servidor cada termo gera.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
  });
  tearDown(() => db.close());

  /// Servidor com 3 bibliotecas de vídeo e 30 pessoas, todas com título.
  Future<int> requestsPerTerm({required int peopleLimit}) async {
    final requests = <Uri>[];
    final client = testJellyfinClient(
      httpClient: MockClient((request) async {
        requests.add(request.url);
        final path = request.url.path;
        if (path.endsWith('/Views')) {
          return jsonResponse({
            'Items': [
              for (final id in ['filmes', 'series', 'animes'])
                {
                  'Id': id,
                  'Name': id,
                  'CollectionType': id == 'filmes' ? 'movies' : 'tvshows',
                  'Type': 'CollectionFolder',
                },
            ],
          });
        }
        if (path == '/Persons') {
          return jsonResponse({
            'Items': [
              for (var i = 0; i < 30; i++) {'Id': 'p$i', 'Name': 'Ator $i', 'Type': 'Person'},
            ],
          });
        }
        if (path == '/Items' && request.url.queryParameters.containsKey('PersonIds')) {
          return jsonResponse({
            'Items': [
              {'Id': 'm', 'Type': 'Movie', 'Name': 'Filme'},
            ],
          });
        }
        return jsonResponse({'Items': <Map<String, dynamic>>[]});
      }),
    );
    addTearDown(client.close);
    await client.searchItems('ator', limit: defaultMediaSearchLimit);
    await client.searchPeople('ator', limit: peopleLimit);
    return requests.length;
  }

  test('a busca gera bem menos chamadas por termo que o padrão do upstream', () async {
    final antes = await requestsPerTerm(peopleLimit: defaultPeopleSearchLimit);
    final depois = await requestsPerTerm(peopleLimit: cgflixSearchPeopleLimit);
    // ignore: avoid_print
    print('chamadas por termo (3 bibliotecas, 30 pessoas): antes=$antes depois=$depois');
    expect(depois, lessThan(antes));
    expect(depois, lessThanOrEqualTo(3 + 1 + 1 + cgflixSearchPeopleLimit));
  });

  test('espera 300 ms após a última letra e limita os resultados', () {
    expect(DebouncedMediaSearch.searchDebounceDuration, const Duration(milliseconds: 300));
    expect(defaultMediaSearchLimit, 40);
  });
}
