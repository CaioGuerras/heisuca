// Ganchos da busca unificada fora da tela de busca:
// - seletor discreto "Disponível em N servidores" na página do título (some com 1 fonte);
// - filmografia da pessoa juntando todos os servidores, sem títulos repetidos.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../media/ids.dart';
import '../../media/library_query.dart';
import '../../media/media_item.dart';
import '../../media/media_person.dart';
import '../../media/media_server_client.dart';
import '../../providers/multi_server_provider.dart';
import '../../screens/media_detail_screen.dart';
import '../../utils/app_logger.dart';
import '../../utils/global_key_utils.dart';
import '../../utils/media_server_http_client.dart';
import '../../widgets/app_icon.dart';
import '../cgflix_palette.dart';
import 'cgflix_search_grouping.dart';

// ---------------------------------------------------------------------------
// Página do título

/// "Disponível em N servidores": só aparece quando o mesmo título veio de mais de um servidor.
class CgflixSourcePicker extends StatelessWidget {
  const CgflixSourcePicker({super.key, required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final sources = CgflixSourceRegistry.sourcesFor(item.globalKey);
    if (sources.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: 'Disponível em ${sources.length} servidores. Trocar servidor',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _choose(context, sources),
          // Alvo de toque de 48 dp (o texto é pequeno, o toque não).
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(Symbols.dns_rounded, size: 16, color: context.cgflix.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Disponível em ${sources.length} servidores',
                  style: TextStyle(color: context.cgflix.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                AppIcon(Symbols.expand_more_rounded, size: 18, color: context.cgflix.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _choose(BuildContext context, List<MediaItem> sources) async {
    final chosen = await showModalBottomSheet<MediaItem>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.cgflix.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Assistir de qual servidor?', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final source in sources)
              ListTile(
                leading: AppIcon(
                  source.globalKey == item.globalKey
                      ? Symbols.radio_button_checked_rounded
                      : Symbols.radio_button_unchecked_rounded,
                  color: source.globalKey == item.globalKey ? context.cgflix.accent : context.cgflix.textMuted,
                ),
                title: Text(source.serverName ?? 'Servidor'),
                subtitle: _qualityLabel(source) == null ? null : Text(_qualityLabel(source)!),
                onTap: () => Navigator.of(sheetContext).pop(source),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || chosen.globalKey == item.globalKey || !context.mounted) return;
    unawaited(Navigator.of(context).pushReplacement(mediaDetailRoute(metadata: chosen)));
  }

  static String? _qualityLabel(MediaItem item) {
    var best = 0;
    for (final version in item.mediaVersions ?? const []) {
      final height = version.resolutionHeight ?? 0;
      if (height > best) best = height;
    }
    if (best >= 2000) return '4K';
    if (best >= 1000) return '1080p';
    if (best >= 700) return '720p';
    if (best > 0) return 'SD';
    return null;
  }
}

// ---------------------------------------------------------------------------
// Página da pessoa

/// Filmografia de todos os servidores onde a pessoa aparece, com os títulos agrupados como
/// na busca. Devolve `null` quando a pessoa só existe num servidor (a tela segue o upstream).
/// Tudo vem numa página só (a filmografia de uma pessoa cabe folgada).
Future<LibraryPage<MediaItem>>? cgflixMergedPersonPage(
  BuildContext context, {
  required String serverId,
  required String personId,
  required String personName,
  required int start,
  required int size,
  AbortController? abort,
}) {
  final multiServer = context.read<MultiServerProvider?>();
  if (multiServer == null) return null;
  final clients = multiServer.serverManager.visibleOnlineClients;
  if (clients.length < 2) return null;
  if (start > 0) return Future.value(LibraryPage<MediaItem>(items: const [], totalCount: start, offset: start));

  final known = CgflixSourceRegistry.peopleFor(buildGlobalKey(ServerId(serverId), 'person:$personId'));
  return () async {
    final people = known.isNotEmpty
        ? known
        : await _findPersonEverywhere(clients, serverId, personId, personName, abort);
    // Primeiro o servidor que abriu a página, depois os outros (o agrupamento mantém essa ordem).
    final ordered = [
      ...people.where((p) => p.serverId.value == serverId && p.id == personId),
      ...people.where((p) => !(p.serverId.value == serverId && p.id == personId)),
    ];
    if (ordered.isEmpty) {
      ordered.add(
        MediaPerson(id: personId, name: personName, backend: clients[serverId]!.backend, serverId: ServerId(serverId)),
      );
    }
    final pages = await Future.wait([
      for (final person in ordered)
        if (clients[person.serverId.value] case final client?)
          client
              .fetchPersonMediaPage(person.id, start: 0, size: size, abort: abort)
              .then((page) => page.items)
              // Um servidor lento/dormindo não segura a página inteira (o padrão do HTTP é 2 min).
              .timeout(const Duration(seconds: 10))
              .catchError((Object e) {
                appLogger.w('CGFLIX: filmografia de ${person.serverName} falhou', error: e);
                return const <MediaItem>[];
              }),
    ]);
    final groups = cgflixGroupTitles([for (final items in pages) ...items]);
    CgflixSourceRegistry.rememberTitles(groups);
    final items = [for (final group in groups) group.best];
    // Filmografia do mais novo para o mais antigo (sem ano vai para o fim).
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
    indexed.sort((a, b) {
      final byYear = (b.$2.year ?? -1).compareTo(a.$2.year ?? -1);
      return byYear != 0 ? byYear : a.$1.compareTo(b.$1);
    });
    final sorted = [for (final entry in indexed) entry.$2];
    return LibraryPage<MediaItem>(items: sorted, totalCount: sorted.length);
  }();
}

/// Quando a página veio do elenco (e não da busca), procura a pessoa pelo nome nos outros servidores.
Future<List<MediaPerson>> _findPersonEverywhere(
  Map<String, MediaServerClient> clients,
  String serverId,
  String personId,
  String personName,
  AbortController? abort,
) async {
  final wanted = cgflixSearchNormalize(personName);
  if (wanted.isEmpty) return const [];
  final results = await Future.wait([
    for (final entry in clients.entries)
      if (entry.key != serverId)
        entry.value.searchPeople(personName, limit: 5, abort: abort).timeout(const Duration(seconds: 10)).catchError((
          Object e,
        ) {
          appLogger.d('CGFLIX: busca da pessoa em ${entry.key} falhou', error: e);
          return const <MediaPerson>[];
        }),
  ]);
  final others = [for (final list in results) ...list.where((p) => cgflixSearchNormalize(p.name) == wanted).take(1)];
  if (others.isEmpty) return const [];
  final self = MediaPerson(
    id: personId,
    name: personName,
    backend: clients[serverId]!.backend,
    serverId: ServerId(serverId),
  );
  return [self, ...others];
}
