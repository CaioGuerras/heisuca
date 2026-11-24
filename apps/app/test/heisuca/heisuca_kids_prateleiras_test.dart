// Prateleiras do modo kids (pedido do Caio, 24/11): uma linha por coleção infantil do servidor,
// buscada pelo nome (BoxSet + SearchTerm, depois ParentId). Coleção ausente ou vazia some.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:heisuca/cgflix/home/cgflix_home_logic.dart';
import 'package:heisuca/cgflix/home/cgflix_home_repository.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;
  final requests = <Uri>[];

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    tmp = Directory.systemTemp.createTempSync('heisuca_kids_prateleiras');
    requests.clear();
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  // Servidor de mentira: "Filmes da turma" tem 2 itens, "Desenhos" existe vazia, "Anime kids" não existe;
  // a busca por texto devolve também uma coleção de nome parecido, que não pode ser usada.
  Future<http.Response> server(http.Request request) async {
    requests.add(request.url);
    final q = request.url.queryParameters;
    if (q['IncludeItemTypes'] == 'BoxSet') {
      final termo = q['SearchTerm'] ?? '';
      return jsonResponse({
        'Items': [
          if (termo == 'Filmes da turma') ...[
            {'Id': 'col-turma-2', 'Name': 'Filmes da turma 2', 'Type': 'BoxSet'},
            {'Id': 'col-turma', 'Name': 'Filmes da Turma', 'Type': 'BoxSet'},
          ],
          if (termo == 'Desenhos') {'Id': 'col-desenhos', 'Name': 'Desenhos', 'Type': 'BoxSet'},
        ],
      });
    }
    final itens = switch (q['ParentId']) {
      'col-turma' => [
        {'Id': 'f1', 'Type': 'Movie', 'Name': 'Filme 1'},
        {'Id': 's1', 'Type': 'Series', 'Name': 'Série 1'},
      ],
      _ => <Map<String, Object>>[],
    };
    return jsonResponse({'Items': itens});
  }

  Future<List<String>> idsOf(CgflixHomeRepository repository, String nome) async =>
      (await repository.watchCollection(nome).toList()).last.items.map((i) => i.id).toList();

  test('as três prateleiras, nesta ordem', () {
    expect(cgflixKidsCollections, ['Filmes da turma', 'Desenhos', 'Anime kids']);
  });

  test('coleção pelo nome exato (sem diferença de maiúscula), novidades primeiro', () async {
    final client = testJellyfinClient(handler: server);
    addTearDown(client.close);
    final repository = CgflixHomeRepository(client, cacheDir: () async => tmp);

    expect(await idsOf(repository, 'Filmes da turma'), ['f1', 's1']);
    final itens = requests.firstWhere((u) => u.queryParameters['ParentId'] != null).queryParameters;
    expect(itens['ParentId'], 'col-turma', reason: 'não usa a coleção de nome só parecido');
    expect(itens['IncludeItemTypes'], 'Movie,Series');
    expect(itens['SortBy'], 'DateCreated');
    expect(itens['SortOrder'], 'Descending');
    expect(itens['Limit'], '$cgflixCollectionRowLimit');
    repository.dispose();
    await repository.flushed;
  });

  test('coleção vazia ou ausente: linha vazia (a fileira some)', () async {
    final client = testJellyfinClient(handler: server);
    addTearDown(client.close);
    final repository = CgflixHomeRepository(client, cacheDir: () async => tmp);

    expect(await idsOf(repository, 'Desenhos'), isEmpty);
    expect(await idsOf(repository, 'Anime kids'), isEmpty);
    expect(
      requests.where((u) => u.queryParameters['ParentId'] == null && u.queryParameters['SearchTerm'] == 'Anime kids'),
      isNotEmpty,
    );
    repository.dispose();
    await repository.flushed;
  });
}
