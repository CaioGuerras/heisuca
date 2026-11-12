import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../cgflix/cgflix_navigation.dart';
import '../../cgflix/home/cgflix_actions.dart';
import '../../cgflix/home/cgflix_home_logic.dart';
import '../../cgflix/home/cgflix_home_repository.dart';
import '../../cgflix/requests/cgflix_requests_ui.dart';
import '../../design/componentes/botao.dart';
import '../../design/componentes/cartao.dart';
import '../../design/tema.dart';
import '../../heisuca/heisuca_context_menu.dart';
import '../../heisuca/heisuca_home_style.dart';
import '../../heisuca/heisuca_motion.dart';
import '../../heisuca/heisuca_plex_home_repository.dart';
import '../../heisuca/heisuca_source_scope.dart';
import '../../heisuca/heisuca_title_logo.dart';
import '../../heisuca/heisuca_title_sheet.dart';
import '../../heisuca/heisuca_upcoming.dart';
import '../../heisuca/kids/heisuca_kids_flow.dart';
import '../../media/media_item.dart';
import '../../media/media_library.dart';
import '../../media/media_server_client.dart';
import '../../mixins/refreshable.dart';
import '../../mixins/tab_visibility_aware.dart';
import '../../providers/discover_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/jellyfin_client.dart';
import '../../services/plex_client.dart';
import '../../utils/download_utils.dart';
import '../../utils/media_image_helper.dart';
import '../../widgets/optimized_media_image.dart';
import '../casca/pilula_do_perfil_ativo.dart';
import '../tema_da_v2.dart';
import 'aviso.dart';
import 'fileira.dart';
import 'modelo.dart';
import 'tela_inicio.dart';

/// Quanto falta de um título já começado: "restam 12 min", "restam 2 h", "restam 1 h 5 min".
///
/// Sem duração, sem ponto de parada ou sem resto, devolve `null` e o cartão não mostra nada.
@visibleForTesting
String? restam(int? duracaoMs, int? vistoMs) {
  if (duracaoMs == null || duracaoMs <= 0 || vistoMs == null || vistoMs <= 0) return null;
  final falta = duracaoMs - vistoMs;
  if (falta <= 0) return null;
  final minutos = (falta / Duration.millisecondsPerMinute).ceil();
  if (minutos < 60) return 'restam $minutos min';
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  return resto == 0 ? 'restam $horas h' : 'restam $horas h $resto min';
}

/// Fração já vista, de 0 a 1. Sem duração ou sem ponto de parada, `null` (o cartão não desenha a barra).
@visibleForTesting
double? progressoDe(int? duracaoMs, int? vistoMs) {
  if (duracaoMs == null || duracaoMs <= 0 || vistoMs == null || vistoMs <= 0) return null;
  return (vistoMs / duracaoMs).clamp(0.0, 1.0);
}

/// Nota com uma casa e vírgula ("8,6"). Sem nota, ou nota zero, `null`.
@visibleForTesting
String? notaDe(double? nota) {
  if (nota == null || nota <= 0) return null;
  return nota.toStringAsFixed(1).replaceAll('.', ',');
}

/// Junta os pedaços que existem com " · ". Sem nenhum, `null`.
@visibleForTesting
String? juntar(Iterable<String?> partes) {
  final presentes = [
    for (final parte in partes)
      if (parte != null && parte.trim().isNotEmpty) parte.trim(),
  ];
  return presentes.isEmpty ? null : presentes.join(' · ');
}

/// Liga a tela Início da V2 ao acervo: servidores, fileiras, player, ficha do título e menu.
///
/// A [TelaInicio] só desenha; aqui ficam os dados e o que cada toque faz.
class LigacaoDoInicio extends StatefulWidget {
  const LigacaoDoInicio({super.key, this.aoAbrirBiblioteca});

  /// Abre a biblioteca de chave dada ("Ver tudo" de uma fileira).
  final ValueChanged<String>? aoAbrirBiblioteca;

  @override
  State<LigacaoDoInicio> createState() => _LigacaoDoInicioState();
}

class _LigacaoDoInicioState extends State<LigacaoDoInicio>
    with Refreshable, FullRefreshable, TabVisibilityAware, WidgetsBindingObserver {
  final _rolagem = ScrollController();
  late final DiscoverProvider _discover;
  late final MultiServerProvider _servidores;
  HeisucaHomeRepository? _repositorio;
  MediaServerClient? _cliente;
  List<JellyfinClient> _fontes = const [];

  /// Muda quando a tela deve recarregar tudo (puxar para atualizar, troca de perfil).
  int _geracao = 0;

  // A conversão do destaque é guardada: lista nova faz a tela reaquecer as cores.
  List<MediaItem>? _itensDoDestaque;
  List<TituloEmDestaque> _destaques = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _discover = context.read<DiscoverProvider>();
    _servidores = context.read<MultiServerProvider>();
    _discover.addListener(_mudou);
    _servidores.addListener(_servidoresMudaram);
    _servidoresMudaram();
    unawaited(_discover.load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _discover.removeListener(_mudou);
    _servidores.removeListener(_servidoresMudaram);
    _repositorio?.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  void _servidoresMudaram() {
    final gerente = _servidores.serverManager;
    final cliente = gerente.navigationOnlineClients.values.firstOrNull;
    final fontes = gerente.visibleOnlineClients.values.whereType<JellyfinClient>().toList();
    var mesmasFontes = fontes.length == _fontes.length;
    for (var i = 0; mesmasFontes && i < fontes.length; i++) {
      mesmasFontes = identical(fontes[i], _fontes[i]);
    }
    if (identical(cliente, _cliente) && mesmasFontes) {
      _mudou();
      return;
    }
    _repositorio?.dispose();
    _geracao++;
    _cliente = cliente;
    _fontes = fontes;
    _repositorio = switch (cliente) {
      final JellyfinClient jellyfin => CgflixHomeRepository(jellyfin),
      final PlexClient plex => HeisucaPlexHomeRepository(plex, feedClients: fontes),
      _ => null,
    };
    _mudou();
  }

  @override
  void refresh() {
    if (_discover.refreshIfStale()) return;
    unawaited(_discover.refreshContinueWatching());
  }

  @override
  void fullRefresh() {
    _repositorio?.forgetMemory();
    unawaited(_discover.load());
    if (mounted) setState(() => _geracao++);
  }

  @override
  void primeRefresh() {
    if (_discover.isLoadInFlight) return;
    fullRefresh();
  }

  @override
  void onTabShown() {
    _discover.refreshIfStale();
  }

  @override
  void onTabHidden() {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_discover.refreshContinueWatching());
  }

  Future<void> _puxarParaAtualizar() async {
    _repositorio?.forgetMemory();
    setState(() => _geracao++);
    // O indicador fica um instante mesmo com resposta imediata, para o gesto ter retorno.
    await Future.wait([_discover.refreshNow(), Future<void>.delayed(const Duration(milliseconds: 600))]);
  }

  // --- O que cada toque faz ------------------------------------------------------
  // As folhas abrem com o contexto desta ligação, acima do tema da V2: seguem com o tema atual do app.

  void _abrir(MediaItem item) {
    if (mounted) unawaited(HeisucaTitleSheet.show(context, item));
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

  void _menu(MediaItem item, {bool continuar = false}) {
    if (!mounted) return;
    unawaited(
      HeisucaContextMenu.show(
        context,
        item: item,
        isContinueRow: continuar,
        onPlay: () => _assistir(item),
        onOpenDetails: () => _abrir(item),
        onDownload: () => _baixar(item),
      ),
    );
  }

  Future<void> _abrirEmBreve(HeisucaHomeRepository repositorio, HeisucaUpcoming item) async {
    try {
      final achado = await repositorio.resolveUpcoming(item);
      if (!mounted) return;
      if (achado != null) {
        _abrir(achado);
        return;
      }
    } catch (_) {
      // Sem correspondência no acervo: segue para o pedido.
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      sheetAnimationStyle: HeisucaMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (folha) => SizedBox(
        height: MediaQuery.sizeOf(folha).height * 0.72,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(folha).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text('Confira a disponibilidade e escolha o título para pedir.'),
              CgflixRequestSection(query: item.title),
            ],
          ),
        ),
      ),
    );
  }

  // --- Do acervo para a tela -----------------------------------------------------

  List<TituloEmDestaque> _destaquesDe(List<MediaItem> itens) {
    if (!identical(itens, _itensDoDestaque)) {
      _itensDoDestaque = itens;
      _destaques = [for (final item in itens) _emDestaque(item)];
    }
    return _destaques;
  }

  TituloEmDestaque _emDestaque(MediaItem item) {
    final generos = item.genres?.where((genero) => genero.trim().isNotEmpty).take(3).join(', ');
    final sinopse = item.summary?.replaceAll('\n', ' ').trim();
    final classificacao = item.contentRating?.trim();
    return TituloEmDestaque(
      chave: item.globalKey,
      titulo: item.displayTitle,
      arte: (context, tamanho) {
        final candidatas = item.heroArtCandidates(containerAspectRatio: tamanho.width / tamanho.height);
        return OptimizedMediaImage(
          key: ValueKey('destaque_arte_${item.globalKey}'),
          client: cgflixClientFor(context, item),
          imagePath: item.artPath ?? candidatas.firstOrNull,
          width: tamanho.width,
          height: tamanho.height,
          imageType: ImageType.art,
          alignment: const Alignment(0, -0.64),
        );
      },
      logo: (context, tamanho, semLogo) => HeisucaTitleLogo(
        item: item,
        client: cgflixClientFor(context, item),
        width: tamanho.width,
        height: tamanho.height,
        fallbackWidth: tamanho.width,
        fallbackBuilder: (_) => semLogo,
        alignment: Alignment.center,
      ),
      nota: notaDe(item.rating),
      anos: item.year?.toString(),
      generos: generos == null || generos.isEmpty ? null : generos,
      classificacao: classificacao == null || classificacao.isEmpty ? null : classificacao,
      sinopse: sinopse == null || sinopse.isEmpty ? null : sinopse,
      hash: heisucaArtworkHash(item),
      aoAbrir: () => _abrir(item),
      aoAssistir: () => _assistir(item),
      aoSegurar: () => _menu(item),
    );
  }

  ItemDaFileira _emContinuar(MediaItem item) => ItemDaFileira(
    chave: item.globalKey,
    titulo: item.displayTitle,
    subtitulo: juntar([cgflixEpisodeLabel(item), item.displaySubtitle]),
    arte: (context, tamanho) => OptimizedMediaImage(
      client: cgflixClientFor(context, item),
      imagePath: cgflixWidePath(item),
      width: tamanho.width,
      height: tamanho.height,
      imageType: ImageType.thumb,
    ),
    hash: heisucaArtworkHash(item),
    progresso: progressoDe(item.durationMs, item.viewOffsetMs),
    tempo: restam(item.durationMs, item.viewOffsetMs),
    aoTocar: () => _assistir(item),
    aoSegurar: () => _menu(item, continuar: true),
  );

  ItemDaFileira _emPoster(MediaItem item) => ItemDaFileira(
    chave: item.globalKey,
    titulo: item.displayTitle,
    arte: (context, tamanho) => OptimizedMediaImage(
      client: cgflixClientFor(context, item),
      imagePath: cgflixPosterPath(item),
      width: tamanho.width,
      height: tamanho.height,
    ),
    hash: heisucaArtworkHash(item),
    nota: notaDe(item.rating),
    aoTocar: () => _abrir(item),
    aoSegurar: () => _menu(item),
  );

  ItemDaFileira _emBreve(HeisucaHomeRepository repositorio, HeisucaUpcoming item) => ItemDaFileira(
    chave: item.id,
    titulo: item.title,
    subtitulo: juntar([item.subtitle]),
    arte: (context, tamanho) => OptimizedMediaImage(
      client: repositorio.upcomingImageClient,
      imagePath: item.imagePath,
      width: tamanho.width,
      height: tamanho.height,
    ),
    aoTocar: () => unawaited(_abrirEmBreve(repositorio, item)),
  );

  Widget _fileiraContinuar(List<MediaItem> itens) => Fileira(
    dados: FileiraDoInicio(
      chave: 'continuar',
      titulo: 'Continuar',
      formato: FormatoDoCartao.paisagem,
      itens: [for (final item in itens) _emContinuar(item)],
    ),
  );

  List<Widget> _fileiras(HeisucaHomeRepository repositorio, String chave) {
    return [
      // O Discover mantém o progresso do Plex em dia ao voltar do player.
      if (repositorio.client is PlexClient)
        _fileiraContinuar(_discover.onDeck)
      else
        _Secao<CgflixRowData>(
          key: ValueKey('continuar:$chave'),
          fonte: () => repositorio.watchRow(CgflixRowKind.continueWatching),
          carregando: const FileiraCarregando(formato: FormatoDoCartao.paisagem),
          pronto: (dados) => _fileiraContinuar(dados.items.isNotEmpty ? dados.items : _discover.onDeck),
        ),
      _Secao<CgflixRowData>(
        key: ValueKey('em-alta:$chave'),
        fonte: repositorio.watchTrending,
        carregando: const FileiraCarregando(),
        pronto: (dados) => Fileira(
          dados: FileiraDoInicio(
            chave: 'em-alta',
            titulo: 'Em alta no Brasil',
            numerada: true,
            itens: [for (final item in dados.items) _emPoster(item)],
          ),
        ),
      ),
      // Mesma ordem e mesmos nomes de biblioteca que o site.
      _Secao<List<MediaLibrary>>(
        key: ValueKey('bibliotecas:$chave'),
        fonte: () => repositorio.videoLibraries().asStream(),
        carregando: const FileiraCarregando(),
        pronto: (bibliotecas) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final biblioteca in bibliotecas)
              _Secao<CgflixRowData>(
                key: ValueKey('biblioteca:${biblioteca.id}:$chave'),
                fonte: () => repositorio.watchLibrary(biblioteca),
                carregando: const FileiraCarregando(),
                pronto: (dados) => Fileira(
                  dados: FileiraDoInicio(
                    chave: 'biblioteca-${biblioteca.id}',
                    titulo: biblioteca.title,
                    itens: [for (final item in dados.items) _emPoster(item)],
                    aoVerTudo: widget.aoAbrirBiblioteca == null
                        ? null
                        : () => widget.aoAbrirBiblioteca!(biblioteca.globalKey),
                  ),
                ),
              ),
          ],
        ),
      ),
      // O calendário vem do servidor inteiro, sem o filtro do perfil infantil: some no kids.
      if (!heisucaKidsActive(context))
        _Secao<List<HeisucaUpcoming>>(
          key: ValueKey('em-breve:$chave'),
          fonte: () => repositorio.upcoming().asStream(),
          carregando: const FileiraCarregando(),
          pronto: (itens) => Fileira(
            dados: FileiraDoInicio(
              chave: 'em-breve',
              titulo: 'Em breve',
              itens: [for (final item in itens) _emBreve(repositorio, item)],
            ),
          ),
        ),
    ];
  }

  Widget _tela({
    List<TituloEmDestaque> destaques = const [],
    List<Widget> fileiras = const [],
    bool carregando = false,
    Widget? noLugarDoDestaque,
  }) => TelaInicio(
    destaques: destaques,
    fileiras: fileiras,
    destaqueCarregando: carregando,
    noLugarDoDestaque: noLugarDoDestaque,
    aoBuscar: () => unawaited(cgflixOpenSearch(context)),
    aoAtualizar: _puxarParaAtualizar,
    controle: _rolagem,
    perfil: const PilulaDoPerfilAtivo(sobreArte: true),
    chaveDeRolagem: const PageStorageKey('heisuca-home-scroll'),
  );

  Widget _fonteForaDoAr() => Builder(
    builder: (context) => ColoredBox(
      color: TemaHeisuca.de(context).fundo,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Aviso(
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
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final gerente = _servidores.serverManager;
    final repositorio = _repositorio;
    final Widget tela;
    if (gerente.navigationServerId != null && gerente.navigationOnlineClients.isEmpty) {
      tela = _fonteForaDoAr();
    } else if (repositorio == null) {
      tela = _tela(carregando: true);
    } else {
      final chave = '${repositorio.client.serverId.value}:$_geracao';
      final fileiras = _fileiras(repositorio, chave);
      tela = _Secao<CgflixRowData>(
        key: ValueKey('destaque:$chave'),
        fonte: repositorio.watchHero,
        carregando: _tela(fileiras: fileiras, carregando: true),
        falhou: _tela(
          fileiras: fileiras,
          noLugarDoDestaque: const Aviso(
            icone: Symbols.cloud_off_rounded,
            titulo: 'Não foi possível conectar ao acervo',
            texto: 'Verifique a conexão ou puxe para atualizar.',
          ),
        ),
        pronto: (dados) => _tela(destaques: _destaquesDe(dados.items), fileiras: fileiras),
      );
    }
    return SobOTemaDaV2(child: tela);
  }
}

/// Um trecho da tela alimentado por um fluxo do acervo.
///
/// O fluxo é aberto uma vez só e vive enquanto a chave do trecho não mudar.
class _Secao<T> extends StatefulWidget {
  const _Secao({super.key, required this.fonte, required this.pronto, this.carregando, this.falhou});

  final Stream<T> Function() fonte;
  final Widget Function(T dados) pronto;
  final Widget? carregando;
  final Widget? falhou;

  @override
  State<_Secao<T>> createState() => _SecaoState<T>();
}

class _SecaoState<T> extends State<_Secao<T>> {
  late final Stream<T> _fluxo = widget.fonte();

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    stream: _fluxo,
    builder: (context, retrato) {
      if (retrato.hasError) return widget.falhou ?? const SizedBox.shrink();
      if (retrato.hasData) return widget.pronto(retrato.data as T);
      return widget.carregando ?? const SizedBox.shrink();
    },
  );
}
