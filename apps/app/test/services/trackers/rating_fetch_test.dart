// Caio, 25/10: retirados somente casos dos serviços removidos; demais serviços e filas continuam cobertos.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/models/trackers/anime_ids.dart';
import 'package:heisuca/services/trackers/simkl/simkl_tracker.dart';
import 'package:heisuca/services/trackers/tracker_id_resolver.dart';
import 'package:heisuca/services/trackers/tracker_session.dart';
import 'package:heisuca/services/trackers/trakt/trakt_tracker.dart';
import 'package:heisuca/utils/external_ids.dart';

int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

TrackerSession _traktSession() =>
    TrackerSession(accessToken: 'token', refreshToken: 'refresh', expiresAt: _now() + 86400, createdAt: _now());

TrackerSession _simklSession() => TrackerSession(accessToken: 'token', createdAt: _now());

TrackerRatingContext _ctx({
  required MediaKind kind,
  ExternalIds external = const ExternalIds(tvdb: 123, tmdb: 456, imdb: 'tt789'),
  AnimeIds? anime,
  int? season,
  int? episodeNumber,
}) {
  return TrackerRatingContext(
    ids: TrackerIds(external: external, anime: anime),
    kind: kind,
    season: season,
    episodeNumber: episodeNumber,
  );
}

void main() {
  tearDown(() {
    TraktTracker.instance.rebindSession(null, onSessionInvalidated: () {});
    SimklTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  });

  test('Trakt fetches the current episode rating by show ids and episode number', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/sync/ratings/episodes');
      return http.Response(
        json.encode([
          {
            'rating': 8,
            'show': {
              'ids': {'tvdb': 123},
            },
            'episode': {'season': 1, 'number': 2},
          },
        ]),
        200,
      );
    });
    TraktTracker.instance.rebindSession(_traktSession(), onSessionInvalidated: () {}, httpClient: client);

    final score = await TraktTracker.instance.getRating(_ctx(kind: MediaKind.episode, season: 1, episodeNumber: 2));

    expect(score, 8);
  });

  test('Simkl fetches the current show rating by external ids', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/sync/ratings/shows');
      return http.Response(
        json.encode({
          'shows': [
            {
              'user_rating': 7,
              'show': {
                'ids': {'tmdb': 456},
              },
            },
          ],
        }),
        200,
      );
    });
    SimklTracker.instance.rebindSession(_simklSession(), onSessionInvalidated: () {}, httpClient: client);

    final score = await SimklTracker.instance.getRating(_ctx(kind: MediaKind.show));

    expect(score, 7);
  });

  test('Simkl checks the anime ratings bucket for non-movie anime', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      paths.add(request.url.path);
      if (request.url.path == '/sync/ratings/shows') {
        return http.Response(json.encode({'shows': []}), 200);
      }
      if (request.url.path == '/sync/ratings/anime') {
        return http.Response(
          json.encode({
            'anime': [
              {
                'user_rating': 9,
                'show': {
                  'ids': {'simkl': 987},
                },
              },
            ],
          }),
          200,
        );
      }
      fail('Unexpected Simkl request: ${request.url.path}');
    });
    SimklTracker.instance.rebindSession(_simklSession(), onSessionInvalidated: () {}, httpClient: client);

    final score = await SimklTracker.instance.getRating(_ctx(kind: MediaKind.show, anime: AnimeIds(simkl: 987)));

    expect(score, 9);
    expect(paths, ['/sync/ratings/shows', '/sync/ratings/anime']);
  });




}
