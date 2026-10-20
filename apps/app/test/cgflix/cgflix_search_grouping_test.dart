import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/search/cgflix_search_extras.dart';
import 'package:plezy/cgflix/search/cgflix_search_grouping.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_person.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/search_hit.dart';

/// Filme de um servidor Plex compartilhado.
MediaItem _plex(
  String id,
  String server, {
  required String title,
  int? year,
  MediaKind kind = MediaKind.movie,
  String? guid,
  int? height,
  int? viewOffsetMs,
}) => MediaItem.plex(
  id: id,
  kind: kind,
  title: title,
  year: year,
  guid: guid,
  serverId: server,
  serverName: server,
  viewOffsetMs: viewOffsetMs,
  durationMs: viewOffsetMs == null ? null : 7200000,
  mediaVersions: height == null ? null : [MediaVersion(id: 'v$id', height: height)],
);

/// Filme do Jellyfin do CGFLIX.
MediaItem _jellyfin(String id, {required String title, int? year, Map<String, String>? providerIds}) => MediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.movie,
  title: title,
  year: year,
  serverId: 'cgflix-jf',
  serverName: 'CGFLIX',
  raw: {'ProviderIds': ?providerIds},
);

MediaPerson _person(String id, String name, String server, {MediaBackend backend = MediaBackend.plex, String? thumb}) =>
    MediaPerson(id: id, name: name, backend: backend, serverId: ServerId(server), serverName: server, thumbPath: thumb);

void main() {
  setUp(CgflixSourceRegistry.clear);

  group('normalização', () {
    test('tira acento, caixa e pontuação', () {
      expect(cgflixSearchNormalize('Ação: O Filme!'), 'acao o filme');
      expect(cgflixSearchNormalize("  O Poderoso   Chefão  "), 'o poderoso chefao');
      expect(cgflixSearchNormalize(null), '');
    });
  });

  group('títulos', () {
    test('mesmo tmdb em 2 servidores vira 1 cartão (mesmo com nomes diferentes)', () {
      final groups = cgflixGroupTitles([
        _plex(
          '1',
          'Tucho',
          title: 'Top Gun: Maverick',
          year: 2022,
          guid: 'com.plexapp.agents.themoviedb://361743?lang=pt',
        ),
        _jellyfin('a', title: 'Top Gun - Maverick', year: 2022, providerIds: {'Tmdb': '361743'}),
      ]);
      expect(groups, hasLength(1));
      expect(groups.single.sources, hasLength(2));
    });

    test('mesmo guid plex:// entre servidores Plex junta', () {
      final groups = cgflixGroupTitles([
        _plex('1', 'Locadora+', title: 'Heat', year: 1995, guid: 'plex://movie/5d776'),
        _plex('9', 'GuedesFlix', title: 'Fogo contra Fogo', year: 1995, guid: 'plex://movie/5d776'),
      ]);
      expect(groups, hasLength(1));
    });

    test('sem ID, mesmo nome (com acento/caixa diferentes) + ano junta', () {
      final groups = cgflixGroupTitles([
        _plex('1', 'Tucho', title: 'Cidade de Deus', year: 2002),
        _plex('2', 'gabiflix', title: 'cidade de DEUS', year: 2002),
        _jellyfin('a', title: 'Cidade de Deus', year: 2002),
      ]);
      expect(groups, hasLength(1));
      expect(groups.single.sources, hasLength(3));
    });

    test('homônimos de anos diferentes NÃO se juntam', () {
      final groups = cgflixGroupTitles([
        _plex('1', 'Tucho', title: 'Duna', year: 1984),
        _plex('2', 'Tucho', title: 'Duna', year: 2021),
        _jellyfin('a', title: 'Duna', year: 2021),
      ]);
      expect(groups, hasLength(2));
      expect(groups.map((g) => g.best.year), [1984, 2021]);
    });

    test('mesmo nome e ano, mas IDs diferentes do mesmo provedor: não junta', () {
      final groups = cgflixGroupTitles([
        _jellyfin('a', title: 'Halloween', year: 2018, providerIds: {'Tmdb': '424139'}),
        _plex('1', 'Tucho', title: 'Halloween', year: 2018, guid: 'com.plexapp.agents.themoviedb://999?lang=en'),
      ]);
      expect(groups, hasLength(2));
    });

    test('filme e série com o mesmo nome e ano não se juntam', () {
      final groups = cgflixGroupTitles([
        _plex('1', 'Tucho', title: 'Fargo', year: 1996),
        _plex('2', 'Tucho', title: 'Fargo', year: 1996, kind: MediaKind.show),
      ]);
      expect(groups, hasLength(2));
    });

    test('a mesma cópia repetida não conta duas vezes', () {
      final item = _plex('1', 'Tucho', title: 'Heat', year: 1995);
      expect(cgflixGroupTitles([item, item]).single.sources, hasLength(1));
    });
  });

  group('fonte escolhida', () {
    test('o Jellyfin do CGFLIX vence os outros servidores', () {
      final group = cgflixGroupTitles([
        _plex('1', 'Tucho', title: 'Heat', year: 1995, height: 2160, viewOffsetMs: 1000),
        _jellyfin('a', title: 'Heat', year: 1995),
      ]).single;
      expect(group.best.backend, MediaBackend.jellyfin);
    });

    test('sem o CGFLIX: progresso, depois resolução, depois quem respondeu primeiro', () {
      final withProgress = cgflixGroupTitles([
        _plex('1', 'Tucho', title: 'Heat', year: 1995, height: 2160),
        _plex('2', 'Locadora+', title: 'Heat', year: 1995, height: 720, viewOffsetMs: 60000),
      ]).single;
      expect(withProgress.best.serverName, 'Locadora+');

      final byResolution = cgflixGroupTitles([
        _plex('1', 'Tucho', title: 'Heat', year: 1995, height: 720),
        _plex('2', 'Locadora+', title: 'Heat', year: 1995, height: 1080),
      ]).single;
      expect(byResolution.best.serverName, 'Locadora+');

      final firstWins = cgflixGroupTitles([
        _plex('1', 'Tucho', title: 'Heat', year: 1995),
        _plex('2', 'Locadora+', title: 'Heat', year: 1995),
      ]).single;
      expect(firstWins.best.serverName, 'Tucho');
    });

    test('servidor Plex chamado CGFLIX vem antes dos amigos', () {
      final group = cgflixGroupTitles([
        _plex('1', 'Tucho Pictures Studios', title: 'Heat', year: 1995),
        _plex('2', 'CGFLIX', title: 'Heat', year: 1995),
      ]).single;
      expect(group.best.serverName, 'CGFLIX');
    });
  });

  group('pessoas', () {
    test('Val Kilmer em 5 servidores = 1 cartão', () {
      final servers = ['CGFLIX', 'Tucho Pictures Studios', 'Locadora+', 'GuedesFlix', 'gabiflix'];
      final groups = cgflixGroupPeople([
        for (final (i, server) in servers.indexed) _person('$i', i.isEven ? 'Val Kilmer' : 'val kilmer', server),
      ]);
      expect(groups, hasLength(1));
      expect(groups.single.people, hasLength(5));
    });

    test('quem tem foto representa o grupo', () {
      final group = cgflixGroupPeople([
        _person('1', 'Val Kilmer', 'Tucho'),
        _person('2', 'Val Kilmer', 'gabiflix', thumb: '/foto.jpg'),
      ]).single;
      expect(group.best.serverName, 'gabiflix');
    });

    test('nomes diferentes continuam separados', () {
      expect(cgflixGroupPeople([_person('1', 'Val Kilmer', 'A'), _person('2', 'Tom Cruise', 'A')]), hasLength(2));
    });
  });

  group('resultado unificado', () {
    test('Títulos primeiro, depois Pessoas, depois Coleções', () {
      final ordered = cgflixOrderHitsByCategory([
        PersonSearchHit(_person('p', 'Val Kilmer', 'A')),
        MediaSearchHit(_plex('c', 'A', title: 'Top Gun (coleção)', kind: MediaKind.collection)),
        MediaSearchHit(_plex('m', 'A', title: 'Top Gun', year: 1986)),
      ]);
      expect(ordered.map((h) => h.globalKey), ['A:m', 'A:person:p', 'A:c']);
    });

    test('a busca "val kilme" com 5 servidores vira 1 pessoa e lembra as fontes', () {
      final servers = ['CGFLIX', 'Tucho', 'Locadora+', 'GuedesFlix', 'gabiflix'];
      final result = cgflixUnifySearchResult((
        hits: const <SearchHit>[],
        candidates: [for (final server in servers) _plex('1', server, title: 'Top Gun', year: 1986)],
        people: [for (final server in servers) _person('9', 'Val Kilmer', server)],
        succeededServerIds: servers.toSet(),
        cancelledServerIds: const <String>{},
        failedServerIds: const <String>{},
      ), 'val kilme');
      expect(result.people, hasLength(1));
      expect(result.candidates, hasLength(1));
      expect(result.hits, hasLength(2));
      expect(result.hits.first, isA<MediaSearchHit>());
      expect(CgflixSourceRegistry.peopleFor(result.people.single.globalKey), hasLength(5));
      expect(CgflixSourceRegistry.sourcesFor(result.candidates.single.globalKey), hasLength(5));
    });
  });

  group('histórico da busca', () {
    test('novo termo vai para o topo, sem repetir (ignora caixa) e no máximo 8', () {
      var history = <String>[];
      for (final term in ['duna', 'heat', 'Duna', 'x']) {
        history = cgflixPushHistory(history, term);
      }
      expect(history, ['Duna', 'heat']);
      for (var i = 0; i < 20; i++) {
        history = cgflixPushHistory(history, 'termo $i');
      }
      expect(history, hasLength(cgflixSearchHistoryMax));
      expect(history.first, 'termo 19');
    });
  });
}
