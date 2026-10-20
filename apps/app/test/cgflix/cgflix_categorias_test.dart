// Etapa 1E (B): Filmes, Séries e Animes separados pela biblioteca, nunca pelo tipo do item.
// O servidor de mentira tem 3 bibliotecas (Filmes = movies; Séries e Animes = tvshows) e, como
// o Jellyfin de verdade, ignora o ParentId quando a consulta pede Ids.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/cgflix/home/cgflix_home_logic.dart';
import 'package:plezy/cgflix/home/cgflix_home_repository.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

const _movies = CgflixHomeFilter(CgflixChipKind.movies, 'lib-filmes');
const _shows = CgflixHomeFilter(CgflixChipKind.shows, 'lib-series');
const _animes = CgflixHomeFilter(CgflixChipKind.animes, 'lib-animes');

/// Itens de mentira: f* = filmes, s* = séries, a* = animes.
Map<String, dynamic> _item(String id) => {
  'Id': id,
  'Type': id.startsWith('f') ? 'Movie' : (id.startsWith('e') ? 'Episode' : 'Series'),
  'Name': 'Título $id',
};

String _libraryOf(String id) => switch (id[0]) {
  'f' => 'lib-filmes',
  's' => 'lib-series',
  _ => 'lib-animes',
};

void main() {
  group('emalta.json por categoria', () {
    Map<String, dynamic> entry(String id, [String? library]) => {'id': id, 'biblioteca': ?library};

    test('porBiblioteca: cada categoria usa a sua lista, na ordem', () {
      final trending = CgflixTrending.parse({
        'itens': [entry('f1'), entry('s1'), entry('a1')],
        'porBiblioteca': {
          'filmes': [entry('f2'), entry('f1'), entry('f3')],
          'series': [entry('s1'), entry('s2'), entry('s3')],
          'animes': [entry('a3'), entry('a2'), entry('a1')],
        },
      })!;
      expect(trending.idsFor(CgflixChipKind.movies), ['f2', 'f1', 'f3']);
      expect(trending.idsFor(CgflixChipKind.shows), ['s1', 's2', 's3']);
      expect(trending.idsFor(CgflixChipKind.animes), ['a3', 'a2', 'a1']);
      // A Início continua com o geral.
      expect(trending.ids, ['f1', 's1', 'a1']);
    });

    test('menos de 3 na categoria: a linha some', () {
      final trending = CgflixTrending.parse({
        'porBiblioteca': {
          'filmes': [entry('f1'), entry('f2'), entry('f3')],
          'animes': [entry('a1'), entry('a2')],
        },
      })!;
      expect(trending.idsFor(CgflixChipKind.movies), hasLength(3));
      expect(trending.idsFor(CgflixChipKind.animes), isNull);
      expect(trending.idsFor(CgflixChipKind.shows), isNull);
    });

    test('sem porBiblioteca: filtra os itens pelo campo biblioteca (com ou sem acento)', () {
      final trending = CgflixTrending.parse({
        'itens': [
          entry('s1', 'Séries'),
          entry('a1', 'animes'),
          entry('s2', 'series'),
          entry('f1', 'filmes'),
          entry('s3', 'series'),
          entry('a2', 'animes'),
        ],
      })!;
      expect(trending.idsFor(CgflixChipKind.shows), ['s1', 's2', 's3']);
      expect(trending.idsFor(CgflixChipKind.animes), isNull, reason: 'só 2 animes');
    });

    test('sem nenhum dos dois: Filmes separa pelo tipo; Séries e Animes somem', () {
      final trending = CgflixTrending.parse({
        'itens': [
          {'id': 'f1', 'tipo': 'Movie'},
          {'id': 's1', 'tipo': 'Series'},
          {'id': 'f2', 'tipo': 'Movie'},
          {'id': 'f3', 'tipo': 'Movie'},
        ],
      })!;
      expect(trending.idsFor(CgflixChipKind.movies), ['f1', 'f2', 'f3']);
      expect(trending.idsFor(CgflixChipKind.shows), isNull);
      expect(trending.idsFor(CgflixChipKind.animes), isNull);
    });
  });

  group('cada categoria só mostra o seu', () {
    late AppDatabase db;
    late Directory tmp;
    final requests = <Uri>[];

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      JellyfinApiCache.initialize(db);
      tmp = Directory.systemTemp.createTempSync('cgflix_categorias');
      requests.clear();
    });
    tearDown(() async {
      await db.close();
      tmp.deleteSync(recursive: true);
    });

    // 3 de cada no ranking (o mínimo para a linha aparecer).
    const all = ['f1', 'f2', 'f3', 's1', 's2', 's3', 'a1', 'a2', 'a3'];

    Future<http.Response> server(http.Request request) async {
      requests.add(request.url);
      final path = request.url.path;
      final q = request.url.queryParameters;
      if (path.endsWith('/cgflix/emalta.json')) {
        return jsonResponse({
          'titulo': 'Em alta no Brasil',
          'itens': [
            for (final id in all) {'id': id, 'biblioteca': _libraryOf(id).substring(4)},
          ],
          'porBiblioteca': {
            'filmes': [
              for (final id in all.where((i) => i.startsWith('f'))) {'id': id},
            ],
            'series': [
              for (final id in all.where((i) => i.startsWith('s'))) {'id': id},
            ],
            'animes': [
              for (final id in all.where((i) => i.startsWith('a'))) {'id': id},
            ],
          },
        });
      }
      if (path.endsWith('/Views')) {
        return jsonResponse({
          'Items': [
            {'Id': 'lib-filmes', 'Name': 'Filmes', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
            {'Id': 'lib-series', 'Name': 'Séries', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
            {'Id': 'lib-animes', 'Name': 'Animes', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
          ],
        });
      }
      // Como o Jellyfin: com Ids, o ParentId não filtra nada.
      final ids = q['Ids'];
      if (ids != null) {
        return jsonResponse({
          'Items': [for (final id in ids.split(',')) _item(id)],
        });
      }
      // Sem Ids, o ParentId filtra (linhas, Continuar, Próximos).
      final parent = q['ParentId'] ?? q['parentId'];
      final scoped = parent == null ? all : all.where((id) => _libraryOf(id) == parent).toList();
      if (path.contains('Resume')) {
        // Um episódio de série e um de anime em andamento.
        final eps = [
          {..._item('e-s1'), 'SeriesId': 's1', 'SeriesName': 'Título s1', 'lib': 'lib-series'},
          {..._item('e-a1'), 'SeriesId': 'a1', 'SeriesName': 'Título a1', 'lib': 'lib-animes'},
        ];
        return jsonResponse({
          'Items': [
            for (final e in eps)
              if (parent == null || e['lib'] == parent) e,
          ],
        });
      }
      if (path.contains('NextUp')) return jsonResponse({'Items': <Object>[]});
      return jsonResponse({
        'Items': [for (final id in scoped) _item(id)],
      });
    }

    test('Em alta: Filmes, Séries e Animes, cada um com a sua lista', () async {
      final client = testJellyfinClient(handler: server);
      addTearDown(client.close);
      final repository = CgflixHomeRepository(client, cacheDir: () async => tmp);
      Future<List<String>> idsOf(CgflixHomeFilter? filter) async =>
          (await repository.watchTrending(filter: filter).toList()).last.items.map((i) => i.id).toList();

      expect(await idsOf(_movies), ['f1', 'f2', 'f3']);
      expect(await idsOf(_shows), ['s1', 's2', 's3']);
      expect(await idsOf(_animes), ['a1', 'a2', 'a3']);
      expect(await idsOf(null), all, reason: 'a Início continua com o ranking geral');
      repository.dispose();
      await repository.flushed;
    });

    test('linhas de consulta: tudo com o ParentId da categoria', () async {
      final client = testJellyfinClient(handler: server);
      addTearDown(client.close);
      final repository = CgflixHomeRepository(client, cacheDir: () async => tmp);
      for (final (filter, prefix) in [(_movies, 'f'), (_shows, 's'), (_animes, 'a')]) {
        for (final kind in [CgflixRowKind.releases, CgflixRowKind.newMovies, CgflixRowKind.newShows]) {
          final query = cgflixRowQuery(kind, filter: filter);
          if (query == null) continue;
          expect(query['ParentId'], filter.libraryId);
          final rows = await repository.watchRow(kind, filter: filter).toList();
          expect(rows.last.items.map((i) => i.id), everyElement(startsWith(prefix)), reason: '${kind.name} em $prefix');
        }
      }
      repository.dispose();
      await repository.flushed;
    });

    test('Continuar assistindo: Séries não mostra anime e Animes não mostra série', () async {
      final client = testJellyfinClient(handler: server);
      addTearDown(client.close);
      final repository = CgflixHomeRepository(client, cacheDir: () async => tmp);

      final shows = await repository.continueWatchingIn(_shows);
      final animes = await repository.continueWatchingIn(_animes);
      final movies = await repository.continueWatchingIn(_movies);
      expect(shows.map((i) => i.id), ['e-s1']);
      expect(animes.map((i) => i.id), ['e-a1']);
      expect(movies, isEmpty);
      final resumeCalls = requests.where((u) => u.path.contains('Resume'));
      expect(
        resumeCalls.map((u) => u.queryParameters['ParentId'] ?? u.queryParameters['parentId']),
        containsAll(['lib-series', 'lib-animes', 'lib-filmes']),
      );
      repository.dispose();
      await repository.flushed;
    });
  });
}
