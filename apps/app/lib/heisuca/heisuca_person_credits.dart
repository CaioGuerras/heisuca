import 'package:flutter/material.dart';
import '../cgflix/requests/cgflix_requests_ui.dart';
import '../cgflix/requests/cgflix_seerr.dart';
import '../cgflix/search/cgflix_search_grouping.dart';
import '../heisuca/kids/heisuca_kids_flow.dart';
import '../media/ids.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../services/jellyfin_client.dart';
import '../services/plex_client.dart';
import '../utils/provider_extensions.dart';

/// Identidade de pessoa, separada da consulta à filmografia. Nunca reutiliza tag id como TMDB.
int? heisucaPersonTmdbId(Object? data) {
  if (data is! Map) return null;
  int? positive(Object? value) {
    final id = int.tryParse('$value');
    return id != null && id > 0 ? id : null;
  }
  final providers = data['ProviderIds'];
  if (providers is Map) {
    final id = positive(providers['Tmdb'] ?? providers['tmdb']);
    if (id != null) return id;
  }
  final guids = data['Guid'];
  final values = [
    if (data['guid'] is String) data['guid'] as String,
    if (guids is List) for (final guid in guids)
      if (guid is Map && guid['id'] is String) guid['id'] as String,
  ];
  for (final guid in values) {
    final match = RegExp(r'^(?:tmdb|themoviedb|com\.plexapp\.agents\.themoviedb)://(?:person/)?(\d+)(?:[/?].*)?$').firstMatch(guid);
    if (match != null) return positive(match.group(1));
  }
  return null;
}

/// Mesmas regras de IDs/conflitos/título-ano da busca, incluindo filme versus série.
bool heisucaCreditInLibrary(CgflixRequestable credit, List<MediaItem> library) {
  final candidate = MediaItem(id: 'person-credit', backend: MediaBackend.jellyfin,
    kind: credit.isMovie ? MediaKind.movie : MediaKind.show, title: credit.title, year: credit.year,
    raw: {'ProviderIds': {'Tmdb': '${credit.tmdbId}'}});
  return cgflixGroupTitles([...library, candidate]).any((group) =>
    group.sources.any((item) => identical(item, candidate)) && group.sources.length > 1);
}

class HeisucaPersonCredits extends StatefulWidget {
  const HeisucaPersonCredits({super.key, required this.serverId, required this.personId, required this.library});
  final String serverId, personId;
  final List<MediaItem> library;
  @override State<HeisucaPersonCredits> createState() => _HeisucaPersonCreditsState();
}

class _HeisucaPersonCreditsState extends State<HeisucaPersonCredits> {
  Future<int?>? _identity;
  Future<int?> _resolve() async {
    if (heisucaKidsActive(context, listen: false)) return null;
    final client = context.tryGetMediaClientForServer(ServerId(widget.serverId));
    try {
      if (client is JellyfinClient) {
        return heisucaPersonTmdbId(await client.cgflixGetJson('/Items/${Uri.encodeComponent(widget.personId)}'));
      }
      if (client is PlexClient) {
        return heisucaPersonTmdbId(await client.cgflixPersonIdentity(widget.personId));
      }
    } catch (_) {
      // Falta de identidade/rede não esconde o acervo nem inventa uma pessoa no catálogo.
    }
    return null;
  }
  @override void didUpdateWidget(HeisucaPersonCredits oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personId != widget.personId || oldWidget.serverId != widget.serverId) _identity = null;
  }
  @override Widget build(BuildContext context) {
    if (heisucaKidsActive(context)) return const SizedBox.shrink();
    return FutureBuilder<int?>(future: _identity ??= _resolve(), builder: (context, snapshot) {
      final id = snapshot.data;
      if (id == null) return const SizedBox.shrink();
      return CgflixRequestSection(key: ValueKey('person-credits-$id'), query: 'person:$id',
        title: 'Também atuou em',
        loadItems: (backend) => backend is CgflixPersonCreditsBackend
          ? (backend as CgflixPersonCreditsBackend).personCredits(id)
          : Future.value(const <CgflixRequestable>[]),
        includeItem: (item) => !heisucaCreditInLibrary(item, widget.library));
    });
  }
}
