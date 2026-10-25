/// Calendário do mesmo plugin e mapa usados por apps/web/src/api/jellyfin.ts.
class HeisucaUpcoming {
  const HeisucaUpcoming({required this.id, required this.title, required this.subtitle,
    required this.isMovie, this.imagePath, this.jellyfinId, this.tmdbId, this.tvdbId});
  final String id;
  final String title;
  final String subtitle;
  final bool isMovie;
  final String? imagePath;
  final String? jellyfinId;
  final int? tmdbId;
  final int? tvdbId;
}

List<HeisucaUpcoming> heisucaParseUpcoming(Object? mapping, Object? section, {required bool isMovie}) {
  if (mapping is! Map || section is! Map || section['Items'] is! List) return const [];
  final index = mapping[isMovie ? 'm' : 's'];
  if (index is! Map) return const [];
  final seen = <String>{};
  final result = <HeisucaUpcoming>[];
  for (final row in section['Items'] as List) {
    if (row is! Map || row['ProviderIds'] is! Map) continue;
    final providers = row['ProviderIds'] as Map;
    final key = '${providers[isMovie ? 'RadarrMovieId' : 'SonarrSeriesId'] ?? ''}';
    final target = index[key];
    if (target is! Map || !seen.add(key)) continue;
    final title = '${(!isMovie ? target['nome'] : null) ?? row['SeriesName'] ?? row['Name'] ?? ''}'.trim();
    if (title.isEmpty) continue;
    final jf = target['jf'] is String && (target['jf'] as String).isNotEmpty ? target['jf'] as String : null;
    final poster = providers[isMovie ? 'RadarrPoster' : 'SonarrPoster'];
    final cachedPoster = poster is String && poster.startsWith('/HomeScreen/CachedImage/') && !poster.contains('..') ? poster : null;
    final date = DateTime.tryParse('${row['PremiereDate'] ?? ''}');
    final day = date == null ? '' : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    final episode = isMovie ? '' : '${providers['EpisodeInfo'] ?? ''}'.split(' - ').first;
    result.add(HeisucaUpcoming(id: '${isMovie ? 'movie' : 'tv'}:$key', title: title,
      subtitle: [day, episode].where((s) => s.isNotEmpty).join(' · '), isMovie: isMovie,
      imagePath: cachedPoster ?? (jf == null ? null : '/Items/${Uri.encodeComponent(jf)}/Images/Primary'),
      jellyfinId: jf, tmdbId: int.tryParse('${target['tmdb'] ?? ''}'),
      tvdbId: int.tryParse('${target['tvdb'] ?? ''}')));
  }
  return result;
}
