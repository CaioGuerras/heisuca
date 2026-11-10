import '../media/media_item.dart';
import '../media/media_kind.dart';

/// Anime usa a identificação do acervo, nunca nacionalidade ou duração presumida.
enum HeisucaMediaCategory { all, movies, shows, anime }
extension HeisucaMediaCategoryLabel on HeisucaMediaCategory {
  String get label => switch (this) {
    HeisucaMediaCategory.all => 'Todos', HeisucaMediaCategory.movies => 'Filmes',
    HeisucaMediaCategory.shows => 'Séries', HeisucaMediaCategory.anime => 'Animes',
  };
}
bool heisucaAnimeLabel(String? text) => RegExp(r'\banimes?\b', caseSensitive: false).hasMatch(text ?? '');
HeisucaMediaCategory heisucaMediaCategory(MediaItem item) {
  if (heisucaAnimeLabel(item.libraryTitle) || (item.genres ?? const <String>[]).any(heisucaAnimeLabel)) {
    return HeisucaMediaCategory.anime;
  }
  return item.kind == MediaKind.movie ? HeisucaMediaCategory.movies : HeisucaMediaCategory.shows;
}
