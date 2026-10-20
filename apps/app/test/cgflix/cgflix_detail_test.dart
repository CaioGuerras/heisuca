import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_detail.dart';
import 'package:plezy/cgflix/home/cgflix_actions.dart';
import 'package:plezy/cgflix/home/cgflix_preview_sheet.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_stream.dart';
import 'package:plezy/media/media_version.dart';

MediaItem _item({
  MediaKind kind = MediaKind.movie,
  int? season,
  int? episode,
  int? offset,
  List<MediaStream> streams = const [],
}) => MediaItem.jellyfin(
  id: 'x',
  kind: kind,
  parentIndex: season,
  index: episode,
  viewOffsetMs: offset,
  mediaVersions: [
    MediaVersion(
      id: 'v',
      parts: [MediaPart(id: 'p', streams: streams)],
    ),
  ],
);

void main() {
  test('botão principal: Assistir / Continuar e o episódio nas séries', () {
    MediaItem same(MediaItem i) => i;
    expect(cgflixPlayButtonLabel(_item(), null, same), 'Assistir');
    expect(cgflixPlayButtonLabel(_item(offset: 1000), null, same), 'Continuar');
    final show = _item(kind: MediaKind.show);
    expect(cgflixPlayButtonLabel(show, null, same), 'Assistir');
    expect(cgflixPlayButtonLabel(show, _item(kind: MediaKind.episode, season: 1, episode: 1), same), 'Assistir T1:E1');
    expect(cgflixPlayButtonLabel(show, _item(kind: MediaKind.episode, season: 2, episode: 5), same), 'Continuar T2:E5');
  });

  test('selos: Dublado pelo áudio por, Legendado pela legenda por/pob', () {
    const audioPt = MediaStream(id: '1', kind: MediaStreamKind.audio, languageCode: 'por');
    const audioEn = MediaStream(id: '2', kind: MediaStreamKind.audio, languageCode: 'eng');
    const subPob = MediaStream(id: '3', kind: MediaStreamKind.subtitle, languageCode: 'pob');
    const subNamed = MediaStream(id: '4', kind: MediaStreamKind.subtitle, language: 'Portuguese');

    expect(cgflixLanguageFlags(_item(streams: [audioPt, audioEn])), (dubbed: true, subtitled: false));
    expect(cgflixLanguageFlags(_item(streams: [audioEn, subPob])), (dubbed: false, subtitled: true));
    expect(cgflixLanguageFlags(_item(streams: [subNamed])), (dubbed: false, subtitled: true));
    expect(cgflixLanguageFlags(null), (dubbed: false, subtitled: false));
    expect(cgflixLanguageBadges(_item(streams: [audioPt, subPob])), hasLength(2));
  });

  test('metadados da prévia: ano · classificação · duração · nota', () {
    final movie = MediaItem.jellyfin(
      id: 'm',
      kind: MediaKind.movie,
      year: 2023,
      contentRating: '14',
      durationMs: 112 * 60000,
      rating: 7.8,
    );
    expect(cgflixMetaParts(movie), ['2023', '14', '1h 52min', '★ 7,8']);
    final show = MediaItem.jellyfin(id: 's', kind: MediaKind.show, childCount: 3);
    expect(cgflixMetaParts(show), ['3 temporadas']);
    expect(cgflixEpisodeLabel(_item(kind: MediaKind.episode, season: 1, episode: 3)), 'T1:E3');
  });
}
