import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../models/catalog/catalog_item.dart';
import '../providers/catalog_sources_provider.dart';
import '../services/catalog/library_watchlist_candidates.dart';
import '../services/plex_client.dart';

/// Onde fica a "Minha lista" de um título que mora num servidor Plex: a Watchlist da conta Plex.
///
/// O Plex não tem favorito por servidor. A Watchlist é da conta e vale para qualquer servidor, o nosso ou o de
/// um amigo. É dela que o acervo puxa os pedidos: o que entra aqui é procurado nas nossas fontes e, se não
/// houver, vem do servidor do amigo.
abstract class ListaDoPlex {
  /// Só para teste: troca a conta Plex de verdade por uma de mentira.
  @visibleForTesting
  static ListaDoPlex? Function(BuildContext context, MediaItem item, MediaServerClient? cliente)? fabricaDeTeste;

  /// Lê do [context], já, o que a gravação precisa; quem chama pode gravar depois, com a tela de origem fechada.
  ///
  /// Null quando o título não é de servidor Plex, não é filme nem série, ou não há conta Plex ligada.
  static ListaDoPlex? de(BuildContext context, MediaItem item, MediaServerClient? cliente) {
    if (fabricaDeTeste case final fabrica?) return fabrica(context, item, cliente);
    if (cliente is! PlexClient) return null;
    if (item.kind != MediaKind.movie && item.kind != MediaKind.show) return null;
    final CatalogSourcesProvider catalogos;
    try {
      catalogos = Provider.of<CatalogSourcesProvider>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
    return _ListaDaConta(catalogos, cliente, item);
  }

  /// Se o título está na lista; null quando a conta não soube dizer.
  Future<bool?> estaNaLista();

  /// Põe na lista ou tira dela. Falha com erro: quem chama desfaz o que a tela mostrava.
  Future<void> gravar(bool naLista);
}

class _ListaDaConta implements ListaDoPlex {
  _ListaDaConta(this._catalogos, this._cliente, this._item);

  final CatalogSourcesProvider _catalogos;
  final MediaServerClient _cliente;
  final MediaItem _item;

  /// O título nos termos da conta Plex; null se a conta não o reconhece ou não há conta ligada.
  Future<WatchlistCandidate?> _naConta() async {
    final todos = await _catalogos.watchlistCandidatesFor(_item, client: _cliente);
    for (final candidato in todos) {
      if (candidato.source.id == CatalogSourceId.plex) return candidato;
    }
    return null;
  }

  @override
  Future<bool?> estaNaLista() async {
    final candidato = await _naConta();
    if (candidato == null) return null;
    await candidato.source.ensureWatchlistLoaded();
    return candidato.source.isOnWatchlist(_item.kind, candidato.ids);
  }

  @override
  Future<void> gravar(bool naLista) async {
    final candidato = await _naConta();
    if (candidato == null) throw StateError('A conta Plex não reconhece este título');
    final rodou = await mutateWatchlistMembership(_item.kind, candidato, add: naLista);
    if (!rodou) throw StateError('A mesma gravação já estava em andamento');
  }
}
