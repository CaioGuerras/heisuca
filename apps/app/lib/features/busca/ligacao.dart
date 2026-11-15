import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../cgflix/home/cgflix_actions.dart';
import '../../cgflix/requests/cgflix_requests_ui.dart';
import '../../cgflix/search/cgflix_search_extras.dart';
import '../../cgflix/search/cgflix_search_grouping.dart';
import '../../design/componentes/botao.dart';
import '../../exceptions/media_server_exceptions.dart';
import '../../heisuca/heisuca_context_menu.dart';
import '../../heisuca/heisuca_home_style.dart';
import '../../heisuca/heisuca_search_origin.dart';
import '../../heisuca/heisuca_state_store.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_person.dart';
import '../../media/search_hit.dart';
import '../../mixins/debounced_media_search.dart';
import '../../providers/download_provider.dart';
import '../../providers/hidden_libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/data_aggregation_service.dart';
import '../../utils/download_utils.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/media_navigation_helper.dart';
import '../../utils/media_server_http_client.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/search_relevance.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/optimized_media_image.dart';
import '../inicio/aviso.dart';
import '../inicio/ligacao.dart' show notaDe;
import '../tema_da_v2.dart';
import '../titulo/ligacao.dart' show LigacaoDoTitulo;
import 'modelo.dart';
import 'tela_busca.dart';

/// Liga a tela de Busca da V2 aos servidores: um resultado por título, mesmo com Jellyfin e Plex,
/// histórico de buscas e o "Pedir" pelo Seerr.
class LigacaoDaBusca extends StatefulWidget {
  const LigacaoDaBusca({super.key, this.folgaInferior = 0, this.focoInicial = true});

  /// Espaço no fim da lista (barra flutuante, quando houver).
  final double folgaInferior;

  /// Abre o teclado ao entrar.
  final bool focoInicial;

  @override
  State<LigacaoDaBusca> createState() => _LigacaoDaBuscaState();
}

/// Nenhum servidor respondeu: a busca não chegou a acontecer.
final class _BuscaIndisponivel implements Exception {
  const _BuscaIndisponivel();
}

class _LigacaoDaBuscaState extends State<LigacaoDaBusca> with DebouncedMediaSearch<LigacaoDaBusca, SearchHit> {
  List<TituloDaBusca> _titulos = const [];
  List<PessoaDaBusca> _pessoas = const [];
  List<String> _recentes = const [];
  bool _indisponivel = false;

  AbortController? _cancelar;
  ({String query, SearchAggregationResult result})? _pendente;

  HiddenLibrariesProvider? _ocultas;
  Set<String> _ultimasOcultas = const {};

  @override
  String get searchDebugLabel => 'BuscaV2';

  @override
  void initState() {
    super.initState();
    unawaited(_lerRecentes());
    unawaited(_ligarOcultas());
  }

  @override
  void dispose() {
    _ocultas?.removeListener(_aoMudarOcultas);
    _cancelar?.abort();
    super.dispose();
  }

  // --- histórico -----------------------------------------------------------

  Future<void> _lerRecentes() async {
    final lidos = await cgflixReadSearchHistory();
    if (mounted) setState(() => _recentes = lidos);
  }

  Future<void> _gravarRecentes(List<String> novos) async {
    setState(() => _recentes = novos);
    await cgflixWriteSearchHistory(novos);
  }

  void _escolherRecente(String termo) {
    searchController.value = TextEditingValue(
      text: termo,
      selection: TextSelection.collapsed(offset: termo.length),
    );
  }

  // --- bibliotecas ocultas --------------------------------------------------

  /// Refaz a busca da tela quando uma biblioteca some ou volta. O ouvinte entra só depois da carga
  /// inicial, para a primeira busca (que espera a mesma carga) não rodar duas vezes.
  Future<void> _ligarOcultas() async {
    final ocultas = context.read<HiddenLibrariesProvider>();
    await ocultas.ensureInitialized();
    if (!mounted) return;
    _ultimasOcultas = Set.of(ocultas.hiddenLibraryKeys);
    _ocultas = ocultas..addListener(_aoMudarOcultas);
  }

  void _aoMudarOcultas() {
    final ocultas = _ocultas;
    if (ocultas == null || !mounted) return;
    final agora = ocultas.hiddenLibraryKeys;
    if (agora.length == _ultimasOcultas.length && agora.containsAll(_ultimasOcultas)) return;
    _ultimasOcultas = Set.of(agora);
    final texto = searchController.text.trim();
    if (texto.isEmpty || !hasSearched) return;
    unawaited(runSearch(texto));
  }

  // --- busca -----------------------------------------------------------------

  @override
  Future<List<SearchHit>> performSearchQuery(String query) async {
    final servidores = Provider.of<MultiServerProvider>(context, listen: false);
    if (!servidores.hasConnectedServers) throw const _BuscaIndisponivel();

    // Ler antes de qualquer await: a árvore do perfil pode sair no meio da busca.
    final ocultas = context.read<HiddenLibrariesProvider>();
    await ocultas.ensureInitialized();
    if (!mounted) return const [];

    final cancelar = AbortController();
    _cancelar = cancelar;
    try {
      final resultado = await servidores.aggregationService.searchAcrossServers(
        query,
        hiddenLibraryKeys: ocultas.hiddenLibraryKeys,
        abort: cancelar,
      );
      cancelar.throwIfAborted();
      if (resultado.succeededServerIds.isEmpty && resultado.failedServerIds.isNotEmpty) {
        throw const _BuscaIndisponivel();
      }
      if (resultado.succeededServerIds.isEmpty && resultado.cancelledServerIds.isNotEmpty) {
        throw MediaServerHttpException(
          type: MediaServerHttpErrorType.cancelled,
          message: 'Busca cancelada antes de algum servidor responder',
        );
      }
      final unificado = cgflixUnifySearchResult(resultado, query);
      _pendente = (query: query, result: unificado);
      return unificado.hits;
    } finally {
      if (identical(_cancelar, cancelar)) _cancelar = null;
    }
  }

  @override
  void onSearchInvalidated() {
    _cancelar?.abort();
    _cancelar = null;
    _pendente = null;
  }

  @override
  void onSearchCleared() {
    _pendente = null;
    setState(() {
      _titulos = const [];
      _pessoas = const [];
      _indisponivel = false;
    });
  }

  @override
  void onSearchError(Object error) {
    _pendente = null;
    setState(() {
      _titulos = const [];
      _pessoas = const [];
      _indisponivel = error is _BuscaIndisponivel;
    });
  }

  @override
  void onSearchCompleted(String query, List<SearchHit> results) {
    final pendente = _pendente;
    _pendente = null;
    final unificado = pendente != null && pendente.query == query ? pendente.result : null;
    final candidatos =
        unificado?.candidates ??
        [
          for (final hit in results)
            if (hit case MediaSearchHit(:final item)) item,
        ];
    final pessoas =
        unificado?.people ??
        [
          for (final hit in results)
            if (hit case PersonSearchHit(:final person)) person,
        ];
    final visiveis = Provider.of<MultiServerProvider>(context, listen: false).expectedServerIds.toSet();
    setState(() {
      _indisponivel = false;
      _titulos = [
        for (final item in rankMediaSearchResults(candidatos, query, limit: defaultMediaSearchLimit))
          _emTitulo(item, visiveis),
      ];
      _pessoas = [for (final pessoa in rankPeopleSearchResults(pessoas, query)) _emPessoa(pessoa)];
    });

    if (results.isNotEmpty) unawaited(_gravarRecentes(cgflixPushHistory(_recentes, query)));
    if (unificado != null && unificado.failedServerIds.isNotEmpty) {
      showAppSnackBar(context, 'Nem todos os servidores responderam. Mostrando o que foi encontrado.');
    }
  }

  TituloDaBusca _emTitulo(MediaItem item, Set<String> visiveis) => TituloDaBusca(
    chave: item.globalKey,
    titulo: item.displayTitle,
    tipo: switch (item.kind) {
      MediaKind.movie => TipoDoResultado.filme,
      MediaKind.show => TipoDoResultado.serie,
      _ => TipoDoResultado.outro,
    },
    anos: item.year?.toString(),
    origem: heisucaSearchTitleOrigin(item, visibleServerIds: visiveis),
    arte: (context, tamanho) => OptimizedMediaImage(
      client: cgflixClientFor(context, item),
      imagePath: cgflixPosterPath(item),
      width: tamanho.width,
      height: tamanho.height,
    ),
    hash: heisucaArtworkHash(item),
    nota: notaDe(item.rating),
    visto: item.isWatched,
    aoTocar: () => unawaited(_abrir(item)),
    aoSegurar: () => _menu(item),
  );

  PessoaDaBusca _emPessoa(MediaPerson pessoa) => PessoaDaBusca(
    chave: pessoa.globalKey,
    nome: pessoa.name,
    foto: (context, tamanho) => OptimizedMediaImage(
      client: context.tryGetMediaClientForServer(pessoa.serverId),
      imagePath: pessoa.thumbPath,
      width: tamanho.width,
      height: tamanho.height,
      fit: BoxFit.cover,
      fallbackIcon: Symbols.person_rounded,
      imageType: ImageType.avatar,
    ),
    aoTocar: () => unawaited(
      navigateToPersonMedia(
        context,
        personId: pessoa.id,
        name: pessoa.name,
        thumbPath: pessoa.thumbPath,
        serverId: pessoa.serverId,
        serverName: pessoa.serverName,
        backend: pessoa.backend,
      ),
    ),
  );

  // --- ações do cartão ---------------------------------------------------------

  Future<void> _abrir(MediaItem item) async {
    if (!mounted) return;
    await LigacaoDoTitulo.abrir(context, item);
  }

  void _baixar(MediaItem item) {
    if (!mounted) return;
    final cliente = cgflixClientFor(context, item);
    if (cliente == null) return;
    unawaited(
      queueDownloadWithFeedback(
        context,
        metadata: item,
        client: cliente,
        downloadProvider: Provider.of<DownloadProvider>(context, listen: false),
      ),
    );
  }

  /// Ação do menu que muda o título: na volta, a busca da tela roda de novo para a marca aparecer.
  Future<void> _gravar(Future<void> Function(BuildContext, MediaItem) gravacao, MediaItem item) async {
    if (!mounted) return;
    try {
      await gravacao(context, item);
    } finally {
      final texto = searchController.text.trim();
      if (mounted && texto.isNotEmpty) unawaited(runSearch(texto));
    }
  }

  void _menu(MediaItem item) {
    if (!mounted) return;
    unawaited(
      HeisucaContextMenu.show(
        context,
        item: item,
        onPlay: () => unawaited(_gravar(cgflixPlay, item)),
        onOpenDetails: () => unawaited(_abrir(item)),
        onDownload: () => _baixar(item),
        onToggleFavorite: () => unawaited(_gravar(HeisucaStateStore.instance.toggleFavorite, item)),
        onToggleWatched: () => unawaited(_gravar(HeisucaStateStore.instance.toggleWatched, item)),
      ),
    );
  }

  // --- tela ------------------------------------------------------------------

  void _enviar(String texto) {
    final query = texto.trim();
    if (query.isEmpty) return;
    searchFocusNode.unfocus();
    cancelPendingSearch();
    if (query != lastSearchedQuery || lastSearchFailed) unawaited(runSearch(query));
  }

  Widget? _aviso() {
    if (isSearching || !hasSearched) return null;
    if (lastSearchFailed) {
      return Aviso(
        icone: Symbols.cloud_off_rounded,
        titulo: _indisponivel ? 'Nenhum servidor respondeu' : 'Não foi possível buscar',
        texto: 'Verifique a conexão e tente de novo.',
        acoes: [Botao(rotulo: 'Tentar novamente', aoTocar: () => unawaited(runSearch(lastSearchedQuery)))],
      );
    }
    if (_titulos.isEmpty && _pessoas.isEmpty && lastSearchedQuery.isNotEmpty) {
      return Aviso(
        icone: Symbols.search_off_rounded,
        titulo: 'Nada encontrado',
        texto: 'Nenhum título ou pessoa com "$lastSearchedQuery". Confira a grafia ou peça abaixo.',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => SobOTemaDaV2(
    child: TelaBusca(
      campo: searchController,
      foco: searchFocusNode,
      focoInicial: widget.focoInicial,
      aoVoltar: () => unawaited(Navigator.of(context).maybePop()),
      aoEnviar: _enviar,
      recentes: _recentes,
      aoEscolherRecente: _escolherRecente,
      aoTirarRecente: (termo) => unawaited(_gravarRecentes([..._recentes.where((r) => r != termo)])),
      aoLimparRecentes: () => unawaited(_gravarRecentes(const [])),
      titulos: _titulos,
      pessoas: _pessoas,
      buscando: isSearching,
      buscou: hasSearched,
      aviso: _aviso(),
      pedir: lastSearchedQuery.isEmpty ? null : CgflixRequestSection(query: lastSearchedQuery),
      folgaInferior: widget.folgaInferior,
    ),
  );
}
