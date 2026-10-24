import 'package:flutter_test/flutter_test.dart';
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
      {int start = 0, int size = 200, AbortController? abort}) async {
    offsets.add(start);
    return LibraryPage(items: [MediaItem.jellyfin(id: '$start', kind: MediaKind.movie, serverId: 'server')],
      totalCount: 3, offset: start);
  }
  @override dynamic noSuchMethod(Invocation invocation) => null;
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
}
