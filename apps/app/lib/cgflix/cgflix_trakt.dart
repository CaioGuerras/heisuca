// Etapa 1E (F): Serviços só com o Trakt, com credenciais PRÓPRIAS do CGFLIX.
//
// As credenciais vêm do build (`--dart-define=TRAKT_CLIENT_ID=... --dart-define=TRAKT_CLIENT_SECRET=...`,
// lidas dos secrets CGFLIX_TRAKT_CLIENT_ID/CGFLIX_TRAKT_CLIENT_SECRET no workflow do CGFLIX). Sem
// elas o Trakt some da interface: nunca cai no app OAuth registrado pelo autor do Plezy (era daí
// que vinha o nome "Plezy" ao abrir um serviço). MyAnimeList, AniList, Simkl, MDBList e o Seerr
// manual saem da interface (o código do upstream continua lá).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../services/discord_rpc_service.dart';
import '../services/trackers/tracker_constants.dart';
import '../services/trackers/trakt/trakt_constants.dart';
import '../utils/app_logger.dart';
import '../utils/external_ids.dart';
import '../widgets/app_icon.dart';
import 'cgflix_palette.dart';

/// Client id do app "CGFLIX" no trakt.tv (vazio = Trakt escondido).
const cgflixTraktClientId = String.fromEnvironment('TRAKT_CLIENT_ID');
const cgflixTraktClientSecret = String.fromEnvironment('TRAKT_CLIENT_SECRET');

/// O build tem as credenciais do CGFLIX?
const cgflixTraktConfigured = cgflixTraktClientId != '' && cgflixTraktClientSecret != '';

/// Testes do upstream ligam isto para ver todos os serviços (como no Plezy).
bool cgflixDebugShowAllServices = false;

/// Quais rastreadores aparecem nos Serviços (e no resto da interface): só o Trakt, e só com
/// credenciais próprias.
bool cgflixShowsTracker(TrackerService service) =>
    cgflixDebugShowAllServices || (service == TrackerService.trakt && cgflixTraktConfigured);

/// A linha "Seerr" dos Serviços sai: os pedidos entram sozinhos pela busca (Quick Connect).
bool get cgflixShowsSeerrService => cgflixDebugShowAllServices;

/// Configurações › Serviços só aparece se houver algo dentro (Trakt; Discord no computador).
bool get cgflixShowsServicesTile =>
    cgflixDebugShowAllServices || cgflixTraktConfigured || DiscordRPCService.isAvailable;

// ---------------------------------------------------------------------------
// Comentários do Trakt na página do título

class CgflixTraktComment {
  const CgflixTraktComment({required this.user, required this.text, this.likes = 0});
  final String user;
  final String text;
  final int likes;
}

/// Lê `GET /movies|shows/{id}/comments/likes` (sem spoiler, sem resenha vazia).
List<CgflixTraktComment> cgflixParseTraktComments(Object? json, {int max = 3}) {
  if (json is! List) return const [];
  return [
    for (final raw in json.whereType<Map>())
      if (raw['spoiler'] != true && raw['comment'] is String && (raw['comment'] as String).trim().isNotEmpty)
        CgflixTraktComment(
          user: raw['user'] is Map ? '${(raw['user'] as Map)['username'] ?? 'Alguém'}' : 'Alguém',
          text: (raw['comment'] as String).trim(),
          likes: raw['likes'] is int ? raw['likes'] as int : 0,
        ),
  ].take(max).toList();
}

/// Comentários mais curtidos no Trakt (só com as credenciais do CGFLIX e o IMDb do título).
class CgflixTraktComments extends StatefulWidget {
  const CgflixTraktComments({super.key, required this.item, this.httpClient});
  final MediaItem item;
  final http.Client? httpClient;

  @override
  State<CgflixTraktComments> createState() => _CgflixTraktCommentsState();
}

class _CgflixTraktCommentsState extends State<CgflixTraktComments> {
  List<CgflixTraktComment> _comments = const [];

  @override
  void initState() {
    super.initState();
    if (cgflixTraktConfigured) _load();
  }

  String? get _imdb {
    final providerIds = widget.item.raw?['ProviderIds'];
    if (providerIds is! Map) return null;
    return ExternalIds.fromJellyfinProviderIds(providerIds.cast<String, Object?>()).imdb;
  }

  Future<void> _load() async {
    final imdb = _imdb;
    final kind = switch (widget.item.kind) {
      MediaKind.movie => 'movies',
      MediaKind.show => 'shows',
      _ => null,
    };
    if (imdb == null || kind == null) return;
    final client = widget.httpClient ?? http.Client();
    try {
      final res = await client
          .get(
            Uri.parse('${TraktConstants.apiBase}/$kind/$imdb/comments/likes?limit=10'),
            headers: TraktConstants.headers(),
          )
          .timeout(TrackerConstants.requestTimeout);
      if (res.statusCode != 200) return;
      final comments = cgflixParseTraktComments(jsonDecode(res.body));
      if (mounted) setState(() => _comments = comments);
    } catch (e) {
      appLogger.d('CGFLIX: comentários do Trakt indisponíveis', error: e);
    } finally {
      if (widget.httpClient == null) client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_comments.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comentários no Trakt', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final comment in _comments)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.cgflix.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.user,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (comment.likes > 0) ...[
                        AppIcon(Symbols.favorite_rounded, size: 14, fill: 1, color: context.cgflix.accentSoft),
                        const SizedBox(width: 4),
                        Text(
                          '${comment.likes}',
                          semanticsLabel: '${comment.likes} curtidas',
                          style: TextStyle(color: context.cgflix.textMuted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(comment.text, maxLines: 5, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
