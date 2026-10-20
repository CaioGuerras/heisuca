// Etapa 1E (F): Serviços só com o Trakt do CGFLIX. Os testes rodam sem os --dart-define, como um
// build sem os secrets: o Trakt fica escondido e nenhuma chave do Plezy é usada.
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_trakt.dart';
import 'package:plezy/screens/settings/tracker_service_info.dart';
import 'package:plezy/services/trackers/mal/mal_constants.dart';
import 'package:plezy/services/trackers/mdblist/mdblist_constants.dart';
import 'package:plezy/services/trackers/simkl/simkl_constants.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/trakt/trakt_constants.dart';

void main() {
  test('sem os secrets: Trakt escondido e sem o client id do Plezy', () {
    expect(cgflixTraktConfigured, isFalse);
    expect(TraktConstants.clientId, isEmpty);
    expect(TraktConstants.clientSecret, isEmpty);
    expect(TrackerServiceInfo.all, isEmpty, reason: 'nada nos Serviços sem as credenciais do CGFLIX');
  });

  test('MyAnimeList, AniList, Simkl e MDBList nunca aparecem; Seerr manual também não', () {
    for (final service in TrackerService.values) {
      if (service == TrackerService.trakt) continue;
      expect(cgflixShowsTracker(service), isFalse, reason: service.name);
    }
    expect(cgflixShowsSeerrService, isFalse);
  });

  test('chaves do upstream fora do app', () {
    expect(MalConstants.clientId, isEmpty);
    expect(MdblistConstants.clientId, isEmpty);
    expect(SimklConstants.legacyClientId, isEmpty);
    expect(SimklConstants.v2ClientId, isEmpty);
  });

  test('comentários do Trakt: sem spoiler nem vazios, no máximo 3', () {
    final comments = cgflixParseTraktComments([
      {
        'comment': 'Obra-prima.',
        'spoiler': false,
        'likes': 12,
        'user': {'username': 'ana'},
      },
      {
        'comment': 'O vilão morre no fim',
        'spoiler': true,
        'user': {'username': 'bia'},
      },
      {'comment': '   ', 'spoiler': false},
      {'comment': 'Bom', 'spoiler': false},
      {'comment': 'Ótimo', 'spoiler': false},
      {'comment': 'Quarto', 'spoiler': false},
    ]);
    expect(comments.map((c) => c.text), ['Obra-prima.', 'Bom', 'Ótimo']);
    expect(comments.first.user, 'ana');
    expect(comments.first.likes, 12);
    expect(comments[1].user, 'Alguém');
    expect(cgflixParseTraktComments({'erro': 1}), isEmpty);
  });
}
