import 'dart:convert';
import 'package:http/http.dart' as http;
import '../test_helpers/backend_client_fixtures.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plezy/media/media_person.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/cgflix/requests/cgflix_seerr.dart';
import 'package:plezy/cgflix/search/cgflix_sources.dart';
import 'package:plezy/heisuca/heisuca_person_credits.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/utils/media_server_http_client.dart';

class _Pages extends MediaServerClient {
  final offsets = <int>[];
  @override ServerId get serverId => ServerId('server');
  @override MediaBackend get backend => MediaBackend.jellyfin;
  @override Future<LibraryPage<MediaItem>> fetchPersonMediaPage(String personId,
      {int? start, int? size, AbortController? abort}) async {
    offsets.add(start ?? 0);
    return LibraryPage(items: [MediaItem.jellyfin(id: '${start ?? 0}', kind: MediaKind.movie, serverId: 'server')],
      totalCount: 3, offset: start ?? 0);
  }
  @override dynamic noSuchMethod(Invocation invocation) => null;
}
class _Source extends _Pages {
  _Source(this.name, this.movie);
  final String name;
  final bool movie;
  @override MediaBackend get backend => movie ? MediaBackend.jellyfin : MediaBackend.plex;
  @override ServerId get serverId => ServerId(name);
  @override Future<List<MediaPerson>> searchPeople(String query, {int limit = 20, AbortController? abort,
      Set<String> excludedLibraryIds = const {}}) async => [
    MediaPerson(id: '$name-person', name: 'Sadie Sink', backend: backend, serverId: serverId),
  ];
  @override Future<LibraryPage<MediaItem>> fetchPersonMediaPage(String personId,
      {int? start, int? size, AbortController? abort}) async {
    offsets.add(start ?? 0);
    return LibraryPage(items: [MediaItem(id: name, serverId: name, backend: backend,
      kind: movie ? MediaKind.movie : MediaKind.show,
      title: movie ? 'Filme da Sadie' : 'Stranger Things')], totalCount: 1);
  }
}
void main() {
  test('identidade externa não interpreta ID local ou guid Plex como TMDB', () {
    expect(heisucaPersonTmdbId({'Id': '123'}), isNull);
    expect(heisucaPersonTmdbId({'guid': 'plex://person/123'}), isNull);
    expect(heisucaPersonTmdbId({'ProviderIds': {'Tmdb': 'zero'}}), isNull);
    expect(heisucaPersonTmdbId({'ProviderIds': {'Tmdb': '1495251'}}), 1495251);
    expect(heisucaPersonTmdbId({'Guid': [{'id': 'tmdb://1495251'}]}), 1495251);
    expect(heisucaPersonTmdbId({'guid': 'com.plexapp.agents.themoviedb://1495251?lang=pt'}), 1495251);
  });
  test('créditos usam cast, aceitam os dois formatos e separam filme de série', () {
    final items = cgflixParsePersonCredits({
      'cast': [
        {'id': 1, 'mediaType': 'movie', 'title': 'Filme', 'releaseDate': '2020-01-01'},
        {'id': 1, 'media_type': 'tv', 'name': 'Série', 'first_air_date': '2022-01-01'},
        {'id': 1, 'media_type': 'tv', 'name': 'Série', 'first_air_date': '2022-01-01'},
        {'id': 2, 'mediaType': 'movie', 'title': 'Já disponível', 'mediaInfo': {'status': 5}},
        {'id': -1, 'mediaType': 'movie', 'title': 'Inválido'},
      ],
      'crew': [{'id': 99, 'mediaType': 'movie', 'title': 'Só produção'}],
    });
    expect(items.length, 2);
    expect(items.first.isMovie, false);
    expect(items.first.year, 2022);
  });
  test('também atuou em exclui obra do acervo, respeita tipo e IDs conflitantes', () {
    const credit = CgflixRequestable(tmdbId: 10, isMovie: false, title: 'Stranger Things', year: 2016);
    final show = MediaItem.jellyfin(id: 'show', kind: MediaKind.show, title: 'Stranger Things', year: 2016,
      raw: {'ProviderIds': {'Tmdb': '10'}});
    expect(heisucaCreditInLibrary(credit, [show]), true);
    expect(heisucaCreditInLibrary(credit, [show.copyWith(raw: {'ProviderIds': {'Tmdb': '11'}})]), false);
    expect(heisucaCreditInLibrary(credit, [show.copyWith(kind: MediaKind.movie)]), false);
  });
  test('filmografia carrega todos os lotes, não só os primeiros 200', () async {
    final client = _Pages();
    final items = await client.heisucaPersonMediaAll('person', size: 1);
    expect(items.length, 3);
    expect(client.offsets, [0, 1, 2]);
  });
  testWidgets('No acervo inclui outra fonte mesmo com navegação restrita à origem', (tester) async {
    final a = _Source('A', true), b = _Source('B', false);
    final manager = MultiServerManager()..debugRegisterClientForTesting(a)..debugRegisterClientForTesting(b);
    final multi = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(multi.dispose); addTearDown(manager.dispose);
    manager.setNavigationSource(Object(), 'A');
    Future<LibraryPage<MediaItem>>? result;
    await tester.pumpWidget(ChangeNotifierProvider.value(value: multi, child: MaterialApp(
      home: Builder(builder: (context) {
        result ??= cgflixMergedPersonPage(context, serverId: 'A', personId: 'A-person',
          personName: 'Sadie Sink', start: 0, size: 200);
        return const SizedBox();
      }))));
    await tester.pumpAndSettle();
    final page = await result!;
    expect(page.items.map((item) => item.title), containsAll(['Filme da Sadie', 'Stranger Things']));
    expect(a.offsets, [0]); expect(b.offsets, [0]);
    expect(tester.takeException(), isNull);
  });

  test('Plex consulta people, não metadata; tagKey não vira ID TMDB', () async {
    final paths = <String>[];
    var external = false;
    final client = testPlexClient(handler: (request) async {
      paths.add(request.url.path);
      return http.Response(jsonEncode({'MediaContainer': {'Directory': [
        {'id': 42, 'tagType': 6, 'tag': 'Sadie Sink', 'tagKey': '5d-person',
          if (external) 'Guid': [{'id': 'tmdb://1495251'}]},
      ]}}), 200, headers: {'content-type': 'application/json'});
    });
    addTearDown(client.close);
    expect(heisucaPersonTmdbId(await client.cgflixPersonIdentity('42')), isNull);
    external = true;
    expect(heisucaPersonTmdbId(await client.cgflixPersonIdentity('42')), 1495251);
    expect(paths, everyElement('/library/people/42'));
  });

}
