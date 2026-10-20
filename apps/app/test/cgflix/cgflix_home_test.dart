import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:plezy/cgflix/home/cgflix_home_logic.dart';
import 'package:plezy/cgflix/home/cgflix_home_repository.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

MediaLibrary _lib(String id, String title, MediaKind kind, {bool hidden = false}) =>
    MediaLibrary(id: id, backend: MediaBackend.jellyfin, title: title, kind: kind, hidden: hidden);

void main() {
  group('ordem das linhas da Início', () {
    test('destaque fica fora; depois Continuar, Em alta, Lançamentos, Novidades', () {
      expect(cgflixFixedRowOrder.map((k) => cgflixRowTitle(k)).toList(), [
        'Continuar assistindo',
        'Em alta no Brasil',
        'Lançamentos',
        'Novidades em filmes',
        'Novidades em séries e animes',
      ]);
    });

    test('consultas: lançamentos por data de estreia, novidades por data de chegada', () {
      final now = DateTime.utc(2026, 10, 7, 12);
      final releases = cgflixRowQuery(CgflixRowKind.releases, now: now)!;
      expect(releases['IncludeItemTypes'], 'Movie');
      expect(releases['SortBy'], startsWith('PremiereDate'));
      expect(releases['MaxPremiereDate'], startsWith('2026-10-07'));
      // Etapa 1E: sem a linha de episódios soltos.
      expect(CgflixRowKind.values.map((k) => k.name), isNot(contains('newEpisodes')));
      expect(cgflixRowQuery(CgflixRowKind.newMovies)!['SortBy'], startsWith('DateCreated'));
      expect(cgflixRowQuery(CgflixRowKind.newShows)!['SortBy'], startsWith('DateLastContentAdded'));
      expect(cgflixRowQuery(CgflixRowKind.genre, genre: 'Comédia')!['Genres'], 'Comédia');
      expect(cgflixRowQuery(CgflixRowKind.continueWatching), isNull);
      expect(cgflixRowQuery(CgflixRowKind.trending), isNull);
    });

    test('título do Em alta vem do servidor quando houver', () {
      expect(cgflixRowTitle(CgflixRowKind.trending, trendingTitle: 'Top da semana'), 'Top da semana');
      expect(cgflixRowTitle(CgflixRowKind.trending, trendingTitle: '  '), 'Em alta no Brasil');
    });
  });

  group('emalta.json', () {
    test('lê título e itens na ordem, ignorando sem id e repetidos', () {
      final trending = CgflixTrending.parse({
        'titulo': 'Em alta no Brasil',
        'itens': [
          {'id': 'b', 'nome': 'B', 'tipo': 'Series'},
          {'nome': 'sem id'},
          {'id': 'a', 'nome': 'A', 'tipo': 'Movie'},
          {'id': 'b', 'nome': 'B de novo'},
          'lixo',
        ],
      })!;
      expect(trending.title, 'Em alta no Brasil');
      expect(trending.ids, ['b', 'a']);
      expect(trending.entries.first.type, 'Series');
    });

    test('sem itens aproveitáveis ou formato errado devolve null', () {
      expect(CgflixTrending.parse(null), isNull);
      expect(CgflixTrending.parse('texto'), isNull);
      expect(CgflixTrending.parse({'itens': []}), isNull);
      expect(CgflixTrending.parse({'titulo': 'x'}), isNull);
    });

    test('reordena a resposta do servidor pela ordem do ranking', () {
      final ordered = cgflixOrderByIds(['a', 'c', 'b'], ['b', 'x', 'a'], (s) => s);
      expect(ordered, ['b', 'a']);
    });
  });

  group('chips Filmes · Séries · Animes', () {
    test('acha cada biblioteca; Animes é a de séries com esse nome', () {
      final chips = cgflixLibraryChips([
        _lib('s', 'Séries', MediaKind.show),
        _lib('a', 'ANIMES', MediaKind.show),
        _lib('f', 'Filmes', MediaKind.movie),
        _lib('m', 'Música', MediaKind.artist),
      ]);
      expect([for (final c in chips) c.label], ['Filmes', 'Séries', 'Animes']);
      expect([for (final c in chips) c.library.id], ['f', 's', 'a']);
    });

    test('sem biblioteca de animes o chip some; ocultas não contam', () {
      final chips = cgflixLibraryChips([
        _lib('f', 'Filmes', MediaKind.movie, hidden: true),
        _lib('s', 'Séries', MediaKind.show),
      ]);
      expect([for (final c in chips) c.label], ['Séries']);
    });
  });

  group('gêneros', () {
    test('mais títulos primeiro, sem vazios nem repetidos (ignora acento)', () {
      final genres = cgflixPickGenres([
        {'Name': 'Ação', 'MovieCount': 3, 'SeriesCount': 1},
        {'Name': 'Comédia', 'MovieCount': 10},
        {'Name': 'Acao', 'MovieCount': 50},
        {'Name': 'Faroeste', 'MovieCount': 0, 'SeriesCount': 0},
        {'Name': ''},
      ], max: 5);
      expect(genres, ['Comédia', 'Ação']);
    });

    test('sem contagens mantém a ordem do servidor e respeita o máximo', () {
      final genres = cgflixPickGenres([
        {'Name': 'Drama'},
        {'Name': 'Ação'},
        {'Name': 'Terror'},
      ], max: 2);
      expect(genres, ['Drama', 'Ação']);
    });
  });

  group('repositório (Em alta)', () {
    late AppDatabase db;
    late Directory tmp;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      JellyfinApiCache.initialize(db);
      tmp = Directory.systemTemp.createTempSync('cgflix_home_test');
    });
    tearDown(() async {
      await db.close();
      tmp.deleteSync(recursive: true);
    });

    Map<String, dynamic> movie(String id) => {'Id': id, 'Type': 'Movie', 'Name': 'Filme $id'};

    test('usa o emalta.json na ordem do arquivo', () async {
      final client = testJellyfinClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/cgflix/emalta.json')) {
            return jsonResponse({
              'titulo': 'Em alta no Brasil',
              'itens': [
                {'id': 'm2'},
                {'id': 'm1'},
              ],
            });
          }
          if (request.url.path.endsWith('/Items') && request.url.queryParameters['Ids'] == 'm2,m1') {
            return jsonResponse({
              'Items': [movie('m1'), movie('m2')],
            });
          }
          return jsonResponse({'Items': <Map<String, dynamic>>[]});
        }),
      );
      addTearDown(client.close);
      final repository = CgflixHomeRepository(client, cacheDir: () async => tmp);
      final rows = await repository.watchTrending().toList();
      repository.dispose();
      await repository.flushed;
      expect(rows.last.items.map((i) => i.id), ['m2', 'm1']);
      expect(rows.last.title, 'Em alta no Brasil');
    });

    test('sem emalta.json cai na coleção "Em alta no Brasil"; sem nenhum, a linha some', () async {
      var hasCollection = true;
      final client = testJellyfinClient(
        httpClient: MockClient((request) async {
          final q = request.url.queryParameters;
          if (request.url.path.endsWith('/cgflix/emalta.json')) return jsonResponse({'erro': 1}, status: 404);
          if (q['IncludeItemTypes'] == 'BoxSet') {
            return jsonResponse({
              'Items': [
                if (hasCollection) {'Id': 'col', 'Type': 'BoxSet', 'Name': 'Em alta no Brasil'},
              ],
            });
          }
          if (q['ParentId'] == 'col') {
            return jsonResponse({
              'Items': [movie('x')],
            });
          }
          return jsonResponse({'Items': <Map<String, dynamic>>[]});
        }),
      );
      addTearDown(client.close);
      final repository = CgflixHomeRepository(client, cacheDir: () async => tmp);
      final viaCollection = await repository.watchTrending().toList();
      expect(viaCollection.last.items.map((i) => i.id), ['x']);

      hasCollection = false;
      final empty = CgflixHomeRepository(client, cacheDir: () async => Directory(tmp.createTempSync().path));
      final none = await empty.watchTrending().toList();
      expect(none.last.items, isEmpty);
      repository.dispose();
      empty.dispose();
      await Future.wait([repository.flushed, empty.flushed]);
    });
  });

  // CGFLIX 1D (auditoria H, alto): linha salva vazia no cache + rede fora = esqueleto para sempre.
  test('linha salva vazia e rede fora: emite vazio (sai do esqueleto)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final tmp = Directory.systemTemp.createTempSync('cgflix_home_empty');
    addTearDown(() async {
      await db.close();
      tmp.deleteSync(recursive: true);
    });
    var online = true;
    final client = testJellyfinClient(
      httpClient: MockClient((request) async {
        if (!online) throw Exception('sem rede');
        return jsonResponse({'Items': <Map<String, dynamic>>[]});
      }),
    );
    addTearDown(client.close);

    final first = CgflixHomeRepository(client, cacheDir: () async => tmp);
    final saved = await first.watchRow(CgflixRowKind.newMovies).toList();
    expect(saved.single.items, isEmpty);
    first.dispose();
    await first.flushed; // gravação do cache

    online = false;
    final second = CgflixHomeRepository(client, cacheDir: () async => tmp);
    final rows = await second.watchRow(CgflixRowKind.newMovies).toList();
    second.dispose();
    await second.flushed; // senão o tearDown apaga a pasta no meio da gravação
    expect(rows, isNotEmpty, reason: 'sem nenhuma emissão a linha fica no esqueleto');
    expect(rows.last.items, isEmpty);
  });

  group('chips filtram a Início', () {
    const movies = CgflixHomeFilter(CgflixChipKind.movies, 'lib-filmes');
    const animes = CgflixHomeFilter(CgflixChipKind.animes, 'lib-animes');

    test('destaque e linhas ficam dentro da biblioteca escolhida', () {
      expect(cgflixHeroQuery(filter: movies)['ParentId'], 'lib-filmes');
      expect(cgflixHeroQuery(filter: movies)['IncludeItemTypes'], 'Movie');
      expect(cgflixHeroQuery(filter: animes)['IncludeItemTypes'], 'Series');
      expect(cgflixHeroQuery().containsKey('ParentId'), isFalse);

      final releases = cgflixRowQuery(CgflixRowKind.releases, filter: animes)!;
      expect(releases['ParentId'], 'lib-animes');
      expect(releases['IncludeItemTypes'], 'Series');
      expect(cgflixRowQuery(CgflixRowKind.genre, genre: 'Ação', filter: movies)!['Genres'], 'Ação');
    });

    test('linhas sem sentido para a biblioteca somem', () {
      expect(cgflixRowQuery(CgflixRowKind.newShows, filter: movies), isNull);
      expect(cgflixRowQuery(CgflixRowKind.newMovies, filter: animes), isNull);
      expect(cgflixRowQuery(CgflixRowKind.newShows, filter: animes)!['ParentId'], 'lib-animes');
    });

    test('títulos das linhas falam do tipo escolhido', () {
      expect(cgflixRowTitle(CgflixRowKind.newShows), 'Novidades em séries e animes');
      expect(cgflixRowTitle(CgflixRowKind.newShows, filter: animes), 'Novidades em animes');
      expect(
        cgflixRowTitle(CgflixRowKind.newShows, filter: const CgflixHomeFilter(CgflixChipKind.shows, 's')),
        'Novidades em séries',
      );
    });

    test('filtro do chip compara por tipo e biblioteca', () {
      final chip = CgflixLibraryChip(CgflixChipKind.movies, _lib('lib-filmes', 'Filmes', MediaKind.movie));
      expect(CgflixHomeFilter.fromChip(chip), movies);
      expect(CgflixHomeFilter.fromChip(chip) == animes, isFalse);
    });
  });
}
