part of '../../services/plex_client.dart';

// Caio, 24/10: tag id é do namespace people, nunca ratingKey de filme.
// Contrato: https://developer.plex.tv/pms/ (Get person details).
extension CgflixPlexPerson on PlexClient {
  Future<Object?> cgflixPersonIdentity(String personId) async {
    final response = await _getWithFailover('/library/people/${Uri.encodeComponent(personId)}',
      queryParameters: {'includeGuids': 1});
    final data = response.data;
    final container = data is Map ? data['MediaContainer'] : null;
    final rows = container is Map ? container['Directory'] : null;
    if (rows is! List || rows.isEmpty) return null;
    final row = rows.first;
    if (row is! Map) return null;
    final tagType = flexibleInt(row['tagType']);
    if (row['type'] != 'person' && tagType != 6 && tagType != 4) return null;
    // tagKey/plex://person não é TMDB. Sem GUID externo, a tela só mostra o acervo.
    return row;
  }
}
