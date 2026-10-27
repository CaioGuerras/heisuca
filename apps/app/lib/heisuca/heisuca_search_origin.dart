import '../cgflix/search/cgflix_search_grouping.dart';
import '../media/media_item.dart';
import '../media/media_person.dart';

String _label(Iterable<({String? id, String? name})> sources, Set<String>? visible) {
  final names = <String, String>{};
  for (final source in sources) {
    final id = source.id;
    if (id == null || (visible != null && !visible.contains(id))) continue;
    final name = source.name?.trim();
    if (name != null && name.isNotEmpty) { names[id] = name; } else { names.putIfAbsent(id, () => 'Fonte'); }
  }
  return names.length > 1 ? '${names.length} fontes' : names.values.firstOrNull ?? 'Fonte';
}
String heisucaSearchTitleOrigin(MediaItem item, {Set<String>? visibleServerIds}) => _label([
  for (final source in [item, ...CgflixSourceRegistry.sourcesFor(item.globalKey)])
    (id: source.serverId, name: source.serverName),
], visibleServerIds);
String heisucaSearchPersonOrigin(MediaPerson person, {Set<String>? visibleServerIds}) => _label([
  for (final source in [person, ...CgflixSourceRegistry.peopleFor(person.globalKey)])
    (id: source.serverId, name: source.serverName),
], visibleServerIds);
