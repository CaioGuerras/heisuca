import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../cgflix/cgflix_navigation.dart';
import '../../cgflix/home/cgflix_actions.dart';
import '../../cgflix/you/cgflix_favorites_screen.dart';
import '../../design/componentes/botao.dart';
import '../../heisuca/heisuca_context_menu.dart';
import '../../heisuca/heisuca_home_style.dart';
import '../../heisuca/heisuca_source_scope.dart';
import '../../media/library_query.dart';
import '../../media/media_filter.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../media/media_server_client.dart';
import '../../mixins/refreshable.dart';
import '../../providers/download_provider.dart';
import '../../providers/hidden_libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/plex_client.dart';
import '../../utils/download_utils.dart';
import '../../widgets/optimized_media_image.dart';
import '../casca/pilula_do_perfil_ativo.dart';
import '../inicio/aviso.dart';
import '../inicio/ligacao.dart' show notaDe;
import '../tema_da_v2.dart';
import '../titulo/ligacao.dart' show LigacaoDoTitulo;
import 'modelo.dart';
import 'tela_explorar.dart';

/// O nome do campo sem o tipo na frente: o Plex manda `show.genre` quando o campo é de outro tipo.
@visibleForTesting
String campoSemTipo(String campo) => campo.contains('.') ? campo.substring(campo.lastIndexOf('.') + 1) : campo;

/// O filtro de gênero que a biblioteca declara, se houver.
@visibleForTesting
MediaFilter? filtroDeGenero(List<MediaFilter> filtros) =>
    filtros.where((filtro) => campoSemTipo(filtro.filter) == MediaFilterField.genre).firstOrNull;

/// O filtro de "não vistos": em biblioteca de série do Plex ele se chama `unwatchedLeaves`.
@visibleForTesting
MediaFilter? filtroDeNaoVistos(List<MediaFilter> filtros) {
  MediaFilter? com(String nome) => filtros.where((filtro) => campoSemTipo(filtro.filter) == nome).firstOrNull;
  return com(MediaFilterField.unwatched) ?? com('unwatchedLeaves');
}

/// Como cada ordem da tela vira ordem do servidor: nome de A a Z; o resto, do maior para o menor.
@visibleForTesting
LibrarySort ordemDoServidor(OrdemDoExplorar ordem) => switch (ordem) {
  OrdemDoExplorar.titulo => const LibrarySort(field: 'title', direction: LibrarySortDirection.ascending),
  OrdemDoExplorar.recentes => const LibrarySort(field: 'addedAt', direction: LibrarySortDirection.descending),
  OrdemDoExplorar.lancamento => const LibrarySort(
    field: 'originallyAvailableAt',
    direction: LibrarySortDirection.descending,
  ),
  OrdemDoExplorar.nota => const LibrarySort(field: 'rating', direction: LibrarySortDirection.descending),
};

/// Uma biblioteca e o servidor de onde ela vem.
class _Fonte {
  const _Fonte(this.cliente, this.biblioteca);

  final MediaServerClient cliente;
  final MediaLibrary biblioteca;

  String get chave => '${cliente.serverId.value}:${biblioteca.id}';
  bool atende(String? pedido) => pedido != null && (biblioteca.globalKey == pedido || chave == pedido);
}

/// Liga a [TelaExplorar] ao acervo: bibliotecas da fonte ativa, páginas, gêneros, ordem e "não vistos".
class LigacaoDoExplorar extends StatefulWidget {
  const LigacaoDoExplorar({super.key, this.bibliotecaInicial, this.aoEscolherBiblioteca});

  /// Chave global da biblioteca que abre primeiro; sem ela, a primeira da fonte.
  final String? bibliotecaInicial;
  final ValueChanged<String>? aoEscolherBiblioteca;

  /// Quantos títulos cada página traz.
  static const int pagina = 60;

  @override
  State<LigacaoDoExplorar> createState() => _LigacaoDoExplorarState();
}

class _LigacaoDoExplorarState extends State<LigacaoDoExplorar> with Refreshable, LibraryLoadable {
  final _rolagem = ScrollController();
  late final MultiServerProvider _servidores = context.read<MultiServerProvider>();

  List<_Fonte> _fontes = const [];
  List<BibliotecaDoExplorar> _bibliotecas = const [];
  _Fonte? _atual;
  String? _pendente;
  String _assinatura = '';

  List<MediaItem> _itens = const [];
  List<ItemDoExplorar> _cartoes = const [];
  bool _carregando = true;
  bool _mais = false;
  bool _temMais = false;
  bool _falhouNasBibliotecas = false;
  bool _falhouNosTitulos = false;

  MediaFilter? _filtroDeGenero;
  MediaFilter? _filtroDeNaoVistos;
  List<GeneroDoExplorar> _generos = const [];
  String? _genero;
  bool _soNaoVistos = false;
  OrdemDoExplorar _ordem = OrdemDoExplorar.titulo;

  // Cada resposta só vale se ninguém pediu outra coisa enquanto ela vinha.
  int _geracaoDasFontes = 0;
  int _geracaoDosFiltros = 0;
  int _geracao = 0;

  @override
  void initState() {
    super.initState();
    _pendente = widget.bibliotecaInicial;
    _servidores.addListener(_servidoresMudaram);
    unawaited(_carregarFontes());
  }

  @override
  void dispose() {
    _servidores.removeListener(_servidoresMudaram);
    _rolagem.dispose();
    super.dispose();
  }

  @override
  void refresh() => unawaited(_recarregar());

  @override
  void loadLibraryByKey(String libraryGlobalKey) {
    _pendente = libraryGlobalKey;
    final achada = _fontes.where((fonte) => fonte.atende(_pendente)).firstOrNull;
    if (achada == null) return;
    _pendente = null;
    if (achada.chave != _atual?.chave) _escolher(achada, avisar: false);
  }

  String get _assinaturaAgora => _servidores.serverManager.navigationOnlineClients.keys.join('|');

  void _servidoresMudaram() {
    if (!mounted) return;
    if (_assinaturaAgora != _assinatura) {
      unawaited(_carregarFontes());
    } else {
      setState(() {});
    }
  }

  // --- Bibliotecas ---------------------------------------------------------------

  Future<void> _carregarFontes() async {
    final geracao = ++_geracaoDasFontes;
    ++_geracao;
    ++_geracaoDosFiltros;
    final clientes = _servidores.serverManager.navigationOnlineClients.values.toList();
    _assinatura = _assinaturaAgora;
    setState(() {
      _fontes = const [];
      _bibliotecas = const [];
      _atual = null;
      _guardar(const []);
      _carregando = true;
      _mais = false;
      _falhouNasBibliotecas = false;
      _falhouNosTitulos = false;
      _limparFiltrosDaBiblioteca();
    });
    try {
      final ocultas = context.read<HiddenLibrariesProvider?>();
      await ocultas?.ensureInitialized();
      if (!mounted || geracao != _geracaoDasFontes) return;
      bool oculta(MediaLibrary b) => ocultas?.hiddenLibraryKeys.contains(b.globalKey) ?? false;
      bool serve(MediaLibrary b) =>
          !b.hidden &&
          (!oculta(b) || b.globalKey == _pendente) &&
          (b.kind == MediaKind.movie || b.kind == MediaKind.show || b.kind == MediaKind.unknown);
      final listas = await Future.wait(
        clientes.map(
          (cliente) async => [
            for (final biblioteca in await cliente.fetchLibraries())
              if (serve(biblioteca)) _Fonte(cliente, biblioteca),
          ],
        ),
      );
      if (!mounted || geracao != _geracaoDasFontes) return;
      final fontes = listas.expand((lista) => lista).toList();
      final atual = fontes.where((fonte) => fonte.atende(_pendente)).firstOrNull ?? fontes.firstOrNull;
      _pendente = null;
      setState(() {
        _fontes = fontes;
        _bibliotecas = [for (final f in fontes) BibliotecaDoExplorar(chave: f.chave, titulo: f.biblioteca.title)];
        _atual = atual;
        _carregando = atual != null;
      });
      if (atual != null) await _abrirBiblioteca(atual);
    } catch (_) {
      if (!mounted || geracao != _geracaoDasFontes) return;
      setState(() {
        _carregando = false;
        _falhouNasBibliotecas = true;
      });
    }
  }

  void _escolher(_Fonte fonte, {bool avisar = true}) {
    if (avisar) widget.aoEscolherBiblioteca?.call(fonte.biblioteca.globalKey);
    if (_rolagem.hasClients) _rolagem.jumpTo(0);
    setState(() {
      _atual = fonte;
      _limparFiltrosDaBiblioteca();
    });
    unawaited(_abrirBiblioteca(fonte));
  }

  /// O gênero é de cada biblioteca; "não vistos" e a ordem seguem de uma para a outra.
  void _limparFiltrosDaBiblioteca() {
    _filtroDeGenero = null;
    _filtroDeNaoVistos = null;
    _generos = const [];
    _genero = null;
  }

  Future<void> _abrirBiblioteca(_Fonte fonte) async {
    final filtros = _carregarFiltros(fonte);
    // Com "não vistos" ligado, a página precisa saber o nome do filtro nesta biblioteca antes de sair.
    if (_soNaoVistos) {
      ++_geracao;
      setState(() {
        _guardar(const []);
        _carregando = true;
        _falhouNosTitulos = false;
      });
      await filtros;
      if (!mounted || fonte.chave != _atual?.chave) return;
    }
    await _recarregar();
  }

  // --- Filtros -------------------------------------------------------------------

  Future<void> _carregarFiltros(_Fonte fonte) async {
    final geracao = ++_geracaoDosFiltros;
    try {
      final resultado = await fonte.cliente.fetchLibraryFiltersWithValues(
        fonte.biblioteca.id,
        libraryKind: fonte.biblioteca.kind,
      );
      final genero = filtroDeGenero(resultado.filters);
      final naoVistos = filtroDeNaoVistos(resultado.filters);
      var valores = genero == null ? const <MediaFilterValue>[] : (resultado.cachedValues[genero.filter] ?? const []);
      final cliente = fonte.cliente;
      if (genero != null && valores.isEmpty && genero.key.isNotEmpty && cliente is PlexClient) {
        valores = await cliente.getFilterValues(genero.key);
      }
      if (!mounted || geracao != _geracaoDosFiltros) return;
      setState(() {
        _filtroDeGenero = genero;
        _filtroDeNaoVistos = naoVistos;
        _generos = [
          if (genero != null)
            for (final valor in valores)
              if (valor.title.trim().isNotEmpty)
                GeneroDoExplorar(chave: libraryFilterValueId(valor.key, genero.filter), nome: valor.title.trim()),
        ];
      });
    } catch (_) {
      // Sem filtros a biblioteca continua navegável: as faixas de gênero e "não vistos" só não aparecem.
    }
  }

  List<LibraryFilter> get _filtros => [
    if (_genero != null && _filtroDeGenero != null) LibraryFilter(field: _filtroDeGenero!.filter, values: [_genero!]),
    if (_soNaoVistos && _filtroDeNaoVistos != null)
      LibraryFilter(field: _filtroDeNaoVistos!.filter, values: const ['1']),
  ];

  void _escolherGenero(String? genero) {
    if (genero == _genero) return;
    setState(() => _genero = genero);
    _voltarAoTopoERecarregar();
  }

  void _mudarSoNaoVistos(bool ligado) {
    if (ligado == _soNaoVistos) return;
    setState(() => _soNaoVistos = ligado);
    _voltarAoTopoERecarregar();
  }

  void _ordenar(OrdemDoExplorar ordem) {
    if (ordem == _ordem) return;
    setState(() => _ordem = ordem);
    _voltarAoTopoERecarregar();
  }

  void _voltarAoTopoERecarregar() {
    if (_rolagem.hasClients) _rolagem.jumpTo(0);
    unawaited(_recarregar());
  }

  // --- Páginas -------------------------------------------------------------------

  void _guardar(List<MediaItem> itens) {
    _itens = itens;
    _cartoes = [for (final item in itens) _emCartao(item)];
  }

  Future<void> _recarregar() async {
    if (_atual == null) return _carregarFontes();
    ++_geracao;
    setState(() {
      _guardar(const []);
      _carregando = true;
      _mais = false;
      _temMais = true;
      _falhouNosTitulos = false;
    });
    await _pagina();
  }

  void _pertoDoFim() {
    if (!_carregando && !_mais && _temMais && !_falhouNosTitulos) unawaited(_pagina());
  }

  /// A página seguinte falhou e os títulos já carregados seguem na tela: tenta só ela de novo.
  void _tentarMais() {
    if (_mais) return;
    setState(() => _falhouNosTitulos = false);
    unawaited(_pagina());
  }

  Future<void> _pagina() async {
    final fonte = _atual;
    if (fonte == null || _mais) return;
    final geracao = _geracao;
    setState(() => _mais = true);
    try {
      final pagina = await fonte.cliente.fetchLibraryPagedContent(
        fonte.biblioteca.id,
        libraryKind: fonte.biblioteca.kind,
        query: LibraryQuery(
          offset: _itens.length,
          limit: LigacaoDoExplorar.pagina,
          sort: ordemDoServidor(_ordem),
          includeKinds: fonte.biblioteca.defaultBrowseKinds,
          filters: _filtros,
        ),
      );
      if (!mounted || geracao != _geracao) return;
      setState(() {
        _guardar([..._itens, ...pagina.items]);
        _temMais = pagina.items.isNotEmpty && _itens.length < pagina.totalCount;
        _carregando = false;
        _mais = false;
      });
    } catch (_) {
      if (!mounted || geracao != _geracao) return;
      setState(() {
        _falhouNosTitulos = true;
        _carregando = false;
        _mais = false;
      });
    }
  }

  // --- O que cada toque faz ------------------------------------------------------
  // As folhas abrem com o contexto desta ligação, acima do tema da V2: seguem com o tema atual do app.

  void _abrir(MediaItem item) {
    if (mounted) unawaited(LigacaoDoTitulo.abrir(context, item));
  }

  void _assistir(MediaItem item) {
    if (mounted) unawaited(cgflixPlay(context, item));
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

  void _menu(MediaItem item) {
    if (!mounted) return;
    unawaited(
      HeisucaContextMenu.show(
        context,
        item: item,
        onPlay: () => _assistir(item),
        onOpenDetails: () => _abrir(item),
        onDownload: () => _baixar(item),
      ),
    );
  }

  ItemDoExplorar _emCartao(MediaItem item) => ItemDoExplorar(
    chave: item.globalKey,
    titulo: item.displayTitle,
    anos: item.year?.toString(),
    arte: (context, tamanho) => OptimizedMediaImage(
      client: cgflixClientFor(context, item),
      imagePath: cgflixPosterPath(item),
      width: tamanho.width,
      height: tamanho.height,
    ),
    hash: heisucaArtworkHash(item),
    nota: notaDe(item.rating),
    visto: item.isWatched,
    aoTocar: () => _abrir(item),
    aoSegurar: () => _menu(item),
  );

  // --- Tela ----------------------------------------------------------------------

  Widget? _aviso(bool foraDoAr) {
    if (foraDoAr) {
      return Aviso(
        icone: Symbols.cloud_off_rounded,
        titulo: 'Esta fonte está indisponível',
        texto: 'Tente reconectar ou escolha outro servidor.',
        acoes: [
          const HeisucaSourceTile(),
          Botao(
            rotulo: 'Tentar novamente',
            aoTocar: () => unawaited(_servidores.serverManager.reconnectOfflineServers(forceRediscovery: true)),
          ),
        ],
      );
    }
    if (_falhouNasBibliotecas) {
      return Aviso(
        icone: Symbols.cloud_off_rounded,
        titulo: 'Não foi possível carregar as bibliotecas',
        texto: 'Verifique a conexão e tente de novo.',
        acoes: [Botao(rotulo: 'Tentar novamente', aoTocar: () => unawaited(_carregarFontes()))],
      );
    }
    if (_falhouNosTitulos && _itens.isEmpty) {
      return Aviso(
        icone: Symbols.cloud_off_rounded,
        titulo: 'Não foi possível carregar os títulos',
        texto: 'Verifique a conexão e tente de novo.',
        acoes: [Botao(rotulo: 'Tentar novamente', aoTocar: () => unawaited(_recarregar()))],
      );
    }
    if (!_carregando && _fontes.isEmpty) {
      return const Aviso(
        icone: Symbols.video_library_rounded,
        titulo: 'Nenhuma biblioteca nesta fonte',
        texto: 'Escolha outro servidor ou puxe para atualizar.',
        acoes: [HeisucaSourceTile()],
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gerente = _servidores.serverManager;
    final foraDoAr = gerente.navigationServerId != null && gerente.navigationOnlineClients.isEmpty;
    final favoritos = CgflixFavoritesSource.of(context);
    return SobOTemaDaV2(
      child: TelaExplorar(
        bibliotecas: foraDoAr ? const [] : _bibliotecas,
        bibliotecaAtual: _atual?.chave,
        aoEscolherBiblioteca: (chave) {
          final fonte = _fontes.where((fonte) => fonte.chave == chave).firstOrNull;
          if (fonte != null) _escolher(fonte);
        },
        aoAbrirFavoritos: favoritos == null ? null : () => unawaited(cgflixOpenFavorites(context, favoritos)),
        generos: _generos,
        generoAtual: _genero,
        aoEscolherGenero: _escolherGenero,
        // Biblioteca que não sabe filtrar por visto não mostra a pílula.
        soNaoVistos: _filtroDeNaoVistos == null ? null : _soNaoVistos,
        aoMudarSoNaoVistos: _mudarSoNaoVistos,
        ordem: _ordem,
        aoOrdenar: _ordenar,
        itens: foraDoAr ? const [] : _cartoes,
        carregando: !foraDoAr && _carregando,
        carregandoMais: _mais && _itens.isNotEmpty,
        aoChegarPertoDoFim: _pertoDoFim,
        aoTentarMais: _falhouNosTitulos && _itens.isNotEmpty ? _tentarMais : null,
        aviso: _aviso(foraDoAr),
        aoBuscar: () => unawaited(cgflixOpenSearch(context)),
        perfil: const PilulaDoPerfilAtivo(sobreArte: true),
        aoAtualizar: _recarregar,
        controle: _rolagem,
      ),
    );
  }
}
