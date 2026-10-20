// CGFLIX (1.5.0): "Favoritos" no menu do usuário: o que a pessoa marcou com "Minha lista"
// (o coração do Jellyfin), filmes e séries, em ordem alfabética. Só com Jellyfin conectado.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../media/media_item.dart';
import '../../media/media_server_client.dart';
import '../../providers/multi_server_provider.dart';
import '../../screens/libraries/state_messages.dart';
import '../../services/jellyfin_client.dart';
import '../../utils/app_logger.dart';
import '../home/cgflix_actions.dart';
import '../home/cgflix_cards.dart';

/// Fonte dos favoritos (os testes usam uma falsa).
class CgflixFavoritesSource {
  const CgflixFavoritesSource({required this.load, this.client});
  final Future<List<MediaItem>> Function() load;
  final MediaServerClient? client;

  static CgflixFavoritesSource? of(BuildContext context) {
    if (debugOverride case final fake?) return fake;
    final MultiServerProvider? servers;
    try {
      servers = Provider.of<MultiServerProvider?>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
    final client = servers?.serverManager.visibleOnlineClients.values.whereType<JellyfinClient>().firstOrNull;
    if (client == null) return null;
    return CgflixFavoritesSource(
      client: client,
      load: () async => client.cgflixMapItems(
        await client.cgflixFetchRawItems({
          'Filters': 'IsFavorite',
          'IncludeItemTypes': 'Movie,Series',
          'SortBy': 'SortName',
          'SortOrder': 'Ascending',
          'Limit': '300',
        }),
      ),
    );
  }

  static CgflixFavoritesSource? debugOverride;
}

Future<void> cgflixOpenFavorites(BuildContext context, CgflixFavoritesSource source) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: 'cgflix/favoritos'),
    builder: (_) => CgflixFavoritesScreen(source: source),
  ),
);

class CgflixFavoritesScreen extends StatefulWidget {
  const CgflixFavoritesScreen({super.key, required this.source});
  final CgflixFavoritesSource source;

  @override
  State<CgflixFavoritesScreen> createState() => _CgflixFavoritesScreenState();
}

class _CgflixFavoritesScreenState extends State<CgflixFavoritesScreen> {
  late Future<List<MediaItem>> _future = _load();

  Future<List<MediaItem>> _load() async {
    try {
      return await widget.source.load();
    } catch (e) {
      appLogger.w('CGFLIX: Favoritos não carregaram', error: e);
      rethrow;
    }
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // A tela mostra o aviso.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: FutureBuilder<List<MediaItem>>(
        future: _future,
        builder: (context, snapshot) {
          // Recarregando (voltou da página do título): mantém a grade, sem piscar.
          if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && !snapshot.hasData) {
            return ErrorStateWidget(
              message: 'Não deu para carregar os favoritos. Confira a internet e tente de novo.',
              icon: Symbols.cloud_off_rounded,
              onRetry: _refresh,
              retryLabel: 'Tentar de novo',
            );
          }
          final items = snapshot.data ?? const <MediaItem>[];
          if (items.isEmpty) {
            // Puxar para atualizar também no vazio (favoritou em outro aparelho).
            return RefreshIndicator(
              onRefresh: _refresh,
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: box.maxHeight,
                    child: const EmptyStateWidget(
                      message: 'Nenhum favorito ainda',
                      subtitle: 'Na página de um filme ou série, toque em "Minha lista" para guardar aqui.',
                      icon: Symbols.favorite_rounded,
                    ),
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
                childAspectRatio: 2 / 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => LayoutBuilder(
                builder: (context, box) => CgflixPosterCard(
                  item: items[i],
                  client: widget.source.client,
                  width: box.maxWidth,
                  onTap: () => cgflixOpenDetails(context, items[i]).then((_) {
                    // Saiu da Minha lista na página do título? Atualiza a grade.
                    if (mounted) _refresh();
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
