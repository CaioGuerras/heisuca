part of '../../services/plex_client.dart';

// Caio, 24/10: um tag id pode colidir com ratingKey de filme; só aceita metadado de pessoa.
extension CgflixPlexPerson on PlexClient {
  Future<Object?> cgflixPersonIdentity(String personId) async {
    final response = await _getWithFailover('/library/metadata/${Uri.encodeComponent(personId)}',
      queryParameters: {'includeGuids': 1});
    final data = response.data;
    final container = data is Map ? data['MediaContainer'] : null;
    final rows = container is Map ? container['Metadata'] : null;
    if (rows is! List || rows.isEmpty) return null;
    final row = rows.first;
    if (row is! Map || !const ['person', 'actor', 'director'].contains(row['type'])) return null;
    return row;
  }
}
