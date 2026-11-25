import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../cgflix/home/cgflix_actions.dart';
import '../../cgflix/home/cgflix_home_logic.dart';
import '../../cgflix/home/cgflix_home_repository.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../features/inicio/ligacao.dart' show juntar, notaDe, progressoDe, restam;
import '../../features/navegacao_tv/trilho_da_tv.dart';
import '../../media/media_item.dart';
import '../../media/media_library.dart';
import '../../mixins/refreshable.dart';
import '../../mixins/tab_visibility_aware.dart';
import '../../providers/discover_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/jellyfin_client.dart';
import '../../services/plex_client.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/video_player_navigation.dart';
import '../../widgets/optimized_media_image.dart';
import '../heisuca_plex_home_repository.dart';
import '../heisuca_title_logo.dart';
import '../kids/heisuca_kids_flow.dart';
import '../theme/heisuca_base.dart';
import 'heisuca_tv_area_segura.dart';
import 'heisuca_tv_canvas.dart';
import 'heisuca_tv_header.dart';
import 'heisuca_tv_menu.dart';
import 'heisuca_tv_playback_warmup.dart';
import 'heisuca_tv_title_screen.dart';

/// Tempo que o foco precisa ficar parado num cartão antes de a tela trocar a arte e o texto.
///
/// É comportamento, não animação: segurar a seta passa por vários cartões e só o último conta, senão a TV
/// troca a arte de fundo a cada cartão e engasga.
const Duration _focoParado = Duration(milliseconds: 120);

/// Texto da TV: a escala do celular vista a 3 m. Nada abaixo de 24 na tela de referência de 1920.
TextStyle _tv(TextStyle estilo) => estilo.copyWith(fontSize: max(24, (estilo.fontSize ?? 16) * 1.5));

/// Início do Heisuca na TV, no desenho do app de Windows: arte do título em tela cheia, logo, dados reais do acervo,
/// [Assistir] e [Detalhes], "Continuar assistindo" na primeira tela e as fileiras ao descer.
///
/// - Os dados vêm do mesmo repositório do Início do celular (cache primeiro, rede depois); nada é inventado na tela.
/// - A arte de fundo segue o cartão em foco; ao descer para as fileiras, um véu escurece o fundo.
/// - ← na borda esquerda abre o menu; o avatar também.
/// - Tudo dentro da margem segura da TV (5 % de cada lado).
class HeisucaTvHomeScreen extends StatefulWidget {
  const HeisucaTvHomeScreen({
    super.key,
    this.heroItem,
    this.continueWatchingItems,
    this.onOpenMenu,
    this.onSelectDestination,
  });

  /// Destaque fixo (testes e telas de demonstração). Com ele, a tela não abre o repositório do acervo.
  final MediaItem? heroItem;
  final List<MediaItem>? continueWatchingItems;
  final VoidCallback? onOpenMenu;
  final ValueChanged<String>? onSelectDestination;

  @override
  State<HeisucaTvHomeScreen> createState() => HeisucaTvHomeScreenState();
}

class HeisucaTvHomeScreenState extends State<HeisucaTvHomeScreen>
    with WidgetsBindingObserver, Refreshable, FullRefreshable, FocusableTab, TabVisibilityAware {
  final FocusNode heroPlayFocusNode = FocusNode(debugLabel: 'heisuca-tv-hero-play');
  final FocusNode heroDetailsFocusNode = FocusNode(debugLabel: 'heisuca-tv-hero-details');
  final FocusNode avatarFocusNode = FocusNode(debugLabel: 'heisuca-tv-avatar');

  final _rolagem = ScrollController();

  /// Item cuja arte está no fundo; `null` = o destaque.
  final _itemEmFoco = ValueNotifier<MediaItem?>(null);

  /// A tela desceu para as fileiras: o fundo ganha o véu.
  final _rolado = ValueNotifier<bool>(false);

  DiscoverProvider? _discover;
  MultiServerProvider? _servidores;
  HeisucaHomeRepository? _repositorio;
  Object? _cliente;
  List<JellyfinClient> _fontes = const [];
  StreamSubscription<CgflixRowData>? _assinaturaDoDestaque;
  MediaItem? _destaque;
  Timer? _esperaDoFoco;
  int _geracao = 0;

  bool get _fixo => widget.heroItem != null;

  /// O foco está no topo da tela (Assistir, Detalhes ou avatar): o voltar da tela principal sai do app daqui.
  bool get isAtHeroDestaque => heroPlayFocusNode.hasFocus || heroDetailsFocusNode.hasFocus || avatarFocusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rolagem.addListener(_rolou);
    _destaque = widget.heroItem;
    if (_fixo) return;
    _discover = context.read<DiscoverProvider?>();
    _servidores = context.read<MultiServerProvider?>();
    _discover?.addListener(_mudou);
    _servidores?.addListener(_servidoresMudaram);
    _servidoresMudaram();
    unawaited(_discover?.load());
  }

  @override
  void didUpdateWidget(covariant HeisucaTvHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_fixo && widget.heroItem != oldWidget.heroItem) _destaque = widget.heroItem;
  }

  @override
  void dispose() {
    HeisucaTvPlaybackWarmup.onFocusLost();
    WidgetsBinding.instance.removeObserver(this);
    _discover?.removeListener(_mudou);
    _servidores?.removeListener(_servidoresMudaram);
    _assinaturaDoDestaque?.cancel();
    _repositorio?.dispose();
    _esperaDoFoco?.cancel();
    _rolagem
      ..removeListener(_rolou)
      ..dispose();
    _itemEmFoco.dispose();
    _rolado.dispose();
    heroPlayFocusNode.dispose();
    heroDetailsFocusNode.dispose();
    avatarFocusNode.dispose();
    super.dispose();
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  void _rolou() {
    if (!_rolagem.hasClients) return;
    // Passou do meio da primeira tela: as fileiras estão à vista.
    _rolado.value = _rolagem.offset > 200;
  }

  /// Mesma escolha de fonte do Início do celular (`LigacaoDoInicio`): o servidor de navegação abre o repositório;
  /// com Plex, os Jellyfin visíveis alimentam as fileiras que o Plex não tem.
  void _servidoresMudaram() {
    final servidores = _servidores;
    if (servidores == null) return;
    final gerente = servidores.serverManager;
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
    _assinarDestaque();
    _mudou();
  }

  void _assinarDestaque() {
    _assinaturaDoDestaque?.cancel();
    _assinaturaDoDestaque = _repositorio?.watchHero().listen(
      (dados) {
        final primeiro = dados.items.firstOrNull;
        if (primeiro == null || !mounted) return;
        setState(() => _destaque = primeiro);
      },
      // Sem rede, o destaque que já está na tela fica; as fileiras mostram o que o cache tiver.
      onError: (Object _) {},
    );
  }

  // ── Atualização (chamada pela tela principal) ────────────────────────────────────────────────

  @override
  void refresh() {
    final discover = _discover;
    if (discover == null || discover.refreshIfStale()) return;
    unawaited(discover.refreshContinueWatching());
  }

  @override
  void fullRefresh() {
    if (_fixo) return;
    _repositorio?.forgetMemory();
    unawaited(_discover?.load());
    _assinarDestaque();
    if (mounted) setState(() => _geracao++);
  }

  @override
  void primeRefresh() {
    if (_discover?.isLoadInFlight ?? false) return;
    fullRefresh();
  }

  @override
  void onTabShown() {
    _discover?.refreshIfStale();
  }

  @override
  void onTabHidden() {}

  @override
  void focusActiveTabIfReady() {
    if (!mounted) return;
    final dentro = [heroPlayFocusNode, heroDetailsFocusNode, avatarFocusNode];
    if (dentro.any((no) => no.hasFocus)) return;
    final primario = FocusManager.instance.primaryFocus?.context;
    if (primario != null && primario.findAncestorStateOfType<HeisucaTvHomeScreenState>() == this) return;
    heroPlayFocusNode.requestFocus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_discover?.refreshContinueWatching());
  }

  // ── Navegação ─────────────────────────────────────────────────────────────────────────────

  /// Volta ao topo e devolve o foco ao [Assistir] (voltar do controle, item "Início" do menu).
  void scrollToDestaqueAndFocus() {
    _subirAoTopo();
    _itemEmFoco.value = null;
    heroPlayFocusNode.requestFocus();
  }

  void _subirAoTopo() {
    if (!_rolagem.hasClients || _rolagem.offset == 0) return;
    unawaited(_rolagem.animateTo(0, duration: Movimento.tempo(context, Movimento.tela), curve: Movimento.entra));
  }

  void _abrirMenu() {
    final abrir = widget.onOpenMenu;
    if (abrir != null) {
      abrir();
      return;
    }
    unawaited(HeisucaTvMenu.show(context, onSelectDestination: (destino) => widget.onSelectDestination?.call(destino)));
  }

  /// ← na borda esquerda: se não há nada à esquerda do foco, abre o menu (como no app de Windows).
  KeyEventResult _teclou(FocusNode _, KeyEvent evento) {
    if (evento is! KeyDownEvent || evento.logicalKey != LogicalKeyboardKey.arrowLeft) return KeyEventResult.ignored;
    final foco = FocusManager.instance.primaryFocus;
    if (foco == null) return KeyEventResult.ignored;
    if (!foco.focusInDirection(TraversalDirection.left)) _abrirMenu();
    return KeyEventResult.handled;
  }

  Future<void> _assistir(MediaItem item) async {
    final playable = await cgflixResolvePlayable(cgflixClientFor(context, item), item);
    if (!mounted) return;
    if (playable == null) {
      _abrirFicha(item);
      return;
    }
    await navigateToVideoPlayer(context, metadata: playable);
  }

  void _abrirFicha(MediaItem item) {
    unawaited(HeisucaTvTitleScreen.show(context, item));
  }

  /// Foco num cartão da primeira tela (Continuar): a arte do fundo segue o cartão.
  void _focouNoTopo(MediaItem? item) {
    _subirAoTopo();
    _esperaDoFoco?.cancel();
    if (item == null) {
      _itemEmFoco.value = null;
      return;
    }
    HeisucaTvPlaybackWarmup.onCardFocused(context, item);
    _esperaDoFoco = Timer(_focoParado, () => _itemEmFoco.value = item);
  }

  // ── Tela ─────────────────────────────────────────────────────────────────────────────────

  List<MediaItem> get _continuar {
    if (_fixo) return widget.continueWatchingItems ?? const [];
    return widget.continueWatchingItems ?? _discover?.onDeck ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final tema = TrilhoDaTv.escuroDaTv(TemaHeisuca.de(context));
    final kids = heisucaKidsActive(context);
    return HeisucaTvCanvas(
      child: Theme(
        data: Theme.of(context).copyWith(extensions: [...Theme.of(context).extensions.values, tema]),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _teclou,
          child: ColoredBox(
            color: tema.fundo,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Fundo(itemEmFoco: _itemEmFoco, destaque: _destaque, rolado: _rolado),
                Builder(builder: (context) => _conteudo(context, tema, kids)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudo(BuildContext context, TemaHeisuca tema, bool kids) {
    final tela = MediaQuery.sizeOf(context);
    final margem = HeisucaTvAreaSegura.margem(tela);
    final destaque = _destaque;
    final repositorio = _fixo ? null : _repositorio;
    final continuar = _continuar;
    return CustomScrollView(
      controller: _rolagem,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: max(tela.height, 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeisucaTvHeader(
                  padding: EdgeInsets.only(left: margem.left, top: margem.top),
                  focusNode: avatarFocusNode,
                  onOpenMenu: _abrirMenu,
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(left: margem.left, right: margem.right),
                  child: destaque == null
                      ? const SizedBox(height: 360)
                      : _Destaque(
                          item: destaque,
                          tema: tema,
                          assistir: heroPlayFocusNode,
                          detalhes: heroDetailsFocusNode,
                          aoAssistir: () => unawaited(_assistir(destaque)),
                          aoDetalhes: () => _abrirFicha(destaque),
                          aoFocar: () {
                            _focouNoTopo(null);
                            HeisucaTvPlaybackWarmup.onCardFocused(context, destaque);
                          },
                        ),
                ),
                const SizedBox(height: HeisucaBase.espaco8),
                _Continuar(
                  key: const Key('heisuca-tv-continue-row'),
                  itens: continuar,
                  tema: tema,
                  margem: margem.left,
                  aoAssistir: (item) => unawaited(_assistir(item)),
                  aoFocar: _focouNoTopo,
                ),
                SizedBox(height: margem.bottom),
              ],
            ),
          ),
        ),
        if (repositorio != null)
          SliverToBoxAdapter(
            child: _Fileiras(
              key: ValueKey('fileiras:${repositorio.client.serverId.value}:$_geracao:$kids'),
              repositorio: repositorio,
              kids: kids,
              aoAbrir: _abrirFicha,
              aoFocar: (item) => _itemEmFoco.value = item,
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: margem.bottom)),
      ],
    );
  }
}

/// Arte de fundo em tela cheia: a do cartão em foco ou a do destaque, com degradê para o texto ficar legível.
class _Fundo extends StatelessWidget {
  const _Fundo({required this.itemEmFoco, required this.destaque, required this.rolado});

  final ValueListenable<MediaItem?> itemEmFoco;
  final MediaItem? destaque;
  final ValueListenable<bool> rolado;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final fundo = tema.fundo;
    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<MediaItem?>(
          valueListenable: itemEmFoco,
          builder: (context, emFoco, _) {
            final item = emFoco ?? destaque;
            final caminho = item == null
                ? null
                : item.heroArtCandidates(containerAspectRatio: 16 / 9).firstOrNull ?? item.artPath;
            return AnimatedSwitcher(
              duration: Movimento.tempo(context, Movimento.troca),
              switchInCurve: Movimento.entra,
              switchOutCurve: Movimento.sai,
              child: item == null || caminho == null
                  ? const SizedBox.expand(key: ValueKey('sem-arte'))
                  : OptimizedMediaImage(
                      key: ValueKey('arte:${item.globalKey}:$caminho'),
                      client: cgflixClientFor(context, item),
                      imagePath: caminho,
                      imageType: ImageType.art,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.64),
                    ),
            );
          },
        ),
        // Esquerda: o texto do destaque fica sobre o fundo, não sobre a arte.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [fundo.withValues(alpha: 0.92), fundo.withValues(alpha: 0.55), fundo.withValues(alpha: 0)],
              stops: const [0, 0.42, 0.75],
            ),
          ),
        ),
        // Embaixo: a fileira "Continuar" fica sobre o fundo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [fundo.withValues(alpha: 0), fundo.withValues(alpha: 0.7), fundo],
              stops: const [0.35, 0.7, 1],
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: rolado,
          builder: (context, desceu, _) => AnimatedOpacity(
            opacity: desceu ? 1 : 0,
            duration: Movimento.tempo(context, Movimento.troca),
            curve: Movimento.padrao,
            child: ColoredBox(color: fundo.withValues(alpha: 0.72)),
          ),
        ),
      ],
    );
  }
}

/// Bloco do destaque: logo (ou título), dados reais, sinopse e os botões.
class _Destaque extends StatelessWidget {
  const _Destaque({
    required this.item,
    required this.tema,
    required this.assistir,
    required this.detalhes,
    required this.aoAssistir,
    required this.aoDetalhes,
    required this.aoFocar,
  });

  final MediaItem item;
  final TemaHeisuca tema;
  final FocusNode assistir;
  final FocusNode detalhes;
  final VoidCallback aoAssistir;
  final VoidCallback aoDetalhes;
  final VoidCallback aoFocar;

  @override
  Widget build(BuildContext context) {
    final dados = juntar([_tvMetadata(item), notaDe(item.rating), ...?item.genres?.take(2)]);
    final sinopse = item.summary?.trim();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HeisucaTitleLogo(
            item: item,
            client: cgflixClientFor(context, item),
            width: 640,
            height: 180,
            fallbackWidth: 900,
            compactFallback: true,
            fallbackBuilder: (context) =>
                Text(item.displayTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: _tv(Tipo.destaque(tema))),
          ),
          if (dados != null) ...[
            const SizedBox(height: Forma.espaco4),
            Text(
              dados,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _tv(Tipo.pequeno(tema)).copyWith(color: tema.texto),
            ),
          ],
          if (sinopse != null && sinopse.isNotEmpty) ...[
            const SizedBox(height: Forma.espaco3),
            Text(sinopse, maxLines: 2, overflow: TextOverflow.ellipsis, style: _tv(Tipo.texto(tema))),
          ],
          const SizedBox(height: Forma.espaco6),
          Row(
            children: [
              _BotaoTv(
                key: const Key('heisuca-tv-hero-play'),
                focusNode: assistir,
                autofocus: true,
                principal: true,
                icone: Icons.play_arrow_rounded,
                rotulo: 'Assistir',
                tema: tema,
                aoTocar: aoAssistir,
                aoFocar: aoFocar,
              ),
              const SizedBox(width: Forma.espaco4),
              _BotaoTv(
                key: const Key('heisuca-tv-hero-details'),
                focusNode: detalhes,
                icone: Icons.info_outline_rounded,
                rotulo: 'Detalhes',
                tema: tema,
                aoTocar: aoDetalhes,
                aoFocar: aoFocar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botão em pílula da TV: neutro, o principal em destaque; foco = anel + escala.
class _BotaoTv extends StatefulWidget {
  const _BotaoTv({
    super.key,
    required this.focusNode,
    required this.icone,
    required this.rotulo,
    required this.tema,
    required this.aoTocar,
    required this.aoFocar,
    this.principal = false,
    this.autofocus = false,
  });

  final FocusNode focusNode;
  final IconData icone;
  final String rotulo;
  final TemaHeisuca tema;
  final VoidCallback aoTocar;
  final VoidCallback aoFocar;
  final bool principal;
  final bool autofocus;

  @override
  State<_BotaoTv> createState() => _BotaoTvState();
}

class _BotaoTvState extends State<_BotaoTv> {
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final tinta = widget.principal ? tema.botaoTexto : tema.texto;
    return Semantics(
      button: true,
      label: widget.rotulo,
      excludeSemantics: true,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onFocusChange: (focado) {
          if (focado) widget.aoFocar();
        },
        onShowFocusHighlight: (v) => setState(() => _foco = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.aoTocar();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.aoTocar,
          child: AnimatedScale(
            scale: _foco ? HeisucaBase.focoEscalaTv : 1,
            duration: Movimento.tempo(context, Movimento.toque),
            curve: Movimento.entra,
            child: AnimatedContainer(
              duration: Movimento.tempo(context, Movimento.toque),
              curve: Movimento.entra,
              constraints: const BoxConstraints(minHeight: 72, minWidth: 200),
              padding: const EdgeInsets.symmetric(horizontal: HeisucaBase.espaco8),
              decoration: ShapeDecoration(
                shape: Forma.pilula(
                  lado: _foco ? BorderSide(color: tema.foco, width: Forma.anelDeFoco) : BorderSide.none,
                ),
                color: widget.principal ? tema.botaoFundo : tema.superficie2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icone, size: 36, color: tinta),
                  const SizedBox(width: Forma.espaco3),
                  Text(
                    widget.rotulo,
                    style: _tv(Tipo.subtitulo(tema)).copyWith(color: tinta, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Continuar assistindo": cartões 16:9 com o quanto falta e a barra de progresso. Some sem itens.
class _Continuar extends StatelessWidget {
  const _Continuar({
    super.key,
    required this.itens,
    required this.tema,
    required this.margem,
    required this.aoAssistir,
    required this.aoFocar,
  });

  static const double _largura = 384;
  static const double _altura = 216;

  final List<MediaItem> itens;
  final TemaHeisuca tema;
  final double margem;
  final ValueChanged<MediaItem> aoAssistir;
  final ValueChanged<MediaItem?> aoFocar;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: margem),
          child: Text('Continuar assistindo', style: _tv(Tipo.subtitulo(tema))),
        ),
        SizedBox(
          height: _altura + 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: margem, vertical: Forma.espaco4),
            itemCount: itens.length,
            separatorBuilder: (context, _) => const SizedBox(width: Forma.espaco6),
            itemBuilder: (context, i) => _CartaoContinuar(
              item: itens[i],
              tema: tema,
              largura: _largura,
              altura: _altura,
              aoTocar: () => aoAssistir(itens[i]),
              aoFocar: (focado) => aoFocar(focado ? itens[i] : null),
            ),
          ),
        ),
      ],
    );
  }
}

class _CartaoContinuar extends StatefulWidget {
  const _CartaoContinuar({
    required this.item,
    required this.tema,
    required this.largura,
    required this.altura,
    required this.aoTocar,
    required this.aoFocar,
  });

  final MediaItem item;
  final TemaHeisuca tema;
  final double largura;
  final double altura;
  final VoidCallback aoTocar;
  final ValueChanged<bool> aoFocar;

  @override
  State<_CartaoContinuar> createState() => _CartaoContinuarState();
}

class _CartaoContinuarState extends State<_CartaoContinuar> {
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tema = widget.tema;
    final progresso = progressoDe(item.durationMs, item.viewOffsetMs);
    final legenda = juntar([cgflixEpisodeLabel(item), restam(item.durationMs, item.viewOffsetMs)]);
    return SizedBox(
      width: widget.largura,
      child: FocusableActionDetector(
        onFocusChange: (focado) {
          // Só avisa quando ganha o foco; ao sair, o próximo cartão (ou o destaque) assume.
          if (focado) widget.aoFocar(true);
        },
        onShowFocusHighlight: (v) => setState(() => _foco = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.aoTocar();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.aoTocar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: _foco ? HeisucaBase.focoEscalaTv : 1,
                duration: Movimento.tempo(context, Movimento.toque),
                curve: Movimento.entra,
                child: Container(
                  width: widget.largura,
                  height: widget.altura,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: tema.superficie,
                    shape: Forma.superelipse(
                      Forma.raioMedio,
                      lado: _foco ? BorderSide(color: tema.foco, width: Forma.anelDeFoco) : BorderSide.none,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      OptimizedMediaImage(
                        client: cgflixClientFor(context, item),
                        imagePath: cgflixWidePath(item),
                        width: widget.largura,
                        height: widget.altura,
                        imageType: ImageType.thumb,
                        fit: BoxFit.cover,
                      ),
                      if (progresso != null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            height: Forma.espaco2,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ColoredBox(color: tema.superficie2),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progresso,
                                  child: ColoredBox(color: tema.acento),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Forma.espaco3),
              Text(
                item.grandparentTitle ?? item.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _tv(Tipo.texto(tema)).copyWith(fontWeight: FontWeight.w600),
              ),
              if (legenda != null)
                Text(legenda, maxLines: 1, overflow: TextOverflow.ellipsis, style: _tv(Tipo.pequeno(tema))),
            ],
          ),
        ),
      ),
    );
  }
}

/// As fileiras abaixo da primeira tela, na mesma ordem do Início do celular.
///
/// No infantil, só as coleções da turma; fora dele, "Em alta no Brasil" e uma fileira por biblioteca de vídeo.
/// Fileira vazia não aparece.
class _Fileiras extends StatelessWidget {
  const _Fileiras({
    super.key,
    required this.repositorio,
    required this.kids,
    required this.aoAbrir,
    required this.aoFocar,
  });

  final HeisucaHomeRepository repositorio;
  final bool kids;
  final ValueChanged<MediaItem> aoAbrir;
  final ValueChanged<MediaItem> aoFocar;

  Widget _fileira(String titulo, CgflixRowData dados) {
    if (dados.items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: HeisucaBase.espaco8),
      child: HeisucaTvMediaRow(title: titulo, items: dados.items, onItemTap: aoAbrir, aoFocarItem: aoFocar),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (kids)
        for (final nome in cgflixKidsCollections)
          _Trecho<CgflixRowData>(
            key: ValueKey('kids:$nome'),
            fonte: () => repositorio.watchCollection(nome),
            pronto: (dados) => _fileira(nome, dados),
          ),
      if (!kids)
        _Trecho<CgflixRowData>(
          key: const ValueKey('em-alta'),
          fonte: repositorio.watchTrending,
          pronto: (dados) => _fileira('Em alta no Brasil', dados),
        ),
      if (!kids)
        _Trecho<List<MediaLibrary>>(
          key: const ValueKey('bibliotecas'),
          fonte: () => repositorio.videoLibraries().asStream(),
          pronto: (bibliotecas) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final biblioteca in bibliotecas)
                _Trecho<CgflixRowData>(
                  key: ValueKey('biblioteca:${biblioteca.id}'),
                  fonte: () => repositorio.watchLibrary(biblioteca),
                  pronto: (dados) => _fileira(biblioteca.title, dados),
                ),
            ],
          ),
        ),
    ],
  );
}

/// Um trecho da tela alimentado por um fluxo do acervo; o fluxo abre uma vez e vive enquanto a chave não mudar.
/// Erro ou espera não desenham nada: a fileira só entra quando tem o que mostrar.
class _Trecho<T> extends StatefulWidget {
  const _Trecho({super.key, required this.fonte, required this.pronto});

  final Stream<T> Function() fonte;
  final Widget Function(T dados) pronto;

  @override
  State<_Trecho<T>> createState() => _TrechoState<T>();
}

class _TrechoState<T> extends State<_Trecho<T>> {
  late final Stream<T> _fluxo = widget.fonte();

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    stream: _fluxo,
    builder: (context, retrato) {
      if (retrato.hasError || !retrato.hasData) return const SizedBox.shrink();
      return widget.pronto(retrato.data as T);
    },
  );
}

String _tvMetadata(MediaItem item) {
  final parts = <String>[
    if (item.year != null) '${item.year}',
    if (item.contentRating?.isNotEmpty ?? false) item.contentRating!,
  ];
  if ((item.durationMs ?? 0) > 0) {
    final minutes = item.durationMs! ~/ 60000;
    parts.add(minutes >= 60 ? '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}' : '$minutes min');
  }
  return parts.join(' · ');
}

/// Fileira de pôsteres da TV com o painel de informação acima (título, dados e sinopse do cartão em foco).
class HeisucaTvMediaRow extends StatefulWidget {
  const HeisucaTvMediaRow({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
    this.aoFocarItem,
  });
  final String title;
  final List<MediaItem> items;
  final ValueChanged<MediaItem> onItemTap;

  /// Cartão que ficou em foco (depois da espera de [_focoParado]): a tela usa para trocar a arte do fundo.
  final ValueChanged<MediaItem>? aoFocarItem;

  @override
  State<HeisucaTvMediaRow> createState() => _TvMediaRowState();
}

class _TvMediaRowState extends State<HeisucaTvMediaRow> {
  final _focusedItem = ValueNotifier<MediaItem?>(null);
  Timer? _debounce;
  MediaItem? _pendingItem;

  void _focus(MediaItem item, bool focused) {
    if (focused) {
      _alinhar();
      HeisucaTvPlaybackWarmup.onCardFocused(context, item);
    }
    if (!focused && _pendingItem?.id != item.id) return;
    _debounce?.cancel();
    _pendingItem = focused ? item : null;
    if (focused) {
      _debounce = Timer(_focoParado, () {
        _focusedItem.value = item;
        widget.aoFocarItem?.call(item);
      });
    }
  }

  /// Leva a fileira inteira (título, painel e pôsteres) para perto do topo, como no app de Windows.
  void _alinhar() {
    final caixa = context.findRenderObject();
    final vertical = Scrollable.maybeOf(context, axis: Axis.vertical);
    if (caixa == null || vertical == null) return;
    unawaited(
      vertical.position.ensureVisible(
        caixa,
        alignment: 0.08,
        duration: Movimento.tempo(context, Movimento.tela),
        curve: Movimento.entra,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HeisucaTvMediaRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _debounce?.cancel();
      _focusedItem.value = widget.items.where((item) => item.id == _focusedItem.value?.id).firstOrNull;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusedItem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = TrilhoDaTv.escuroDaTv(TemaHeisuca.de(context));
    final margem = HeisucaTvAreaSegura.margem(MediaQuery.sizeOf(context)).left;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: margem),
          child: Text(widget.title, style: _tv(Tipo.subtitulo(tema))),
        ),
        SizedBox(
          key: const ValueKey('tv-row-info'),
          height: 192,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: margem, vertical: Forma.espaco2),
            child: ValueListenableBuilder<MediaItem?>(
              valueListenable: _focusedItem,
              builder: (context, item, child) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item?.displayTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tv(Tipo.texto(tema)).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    item == null ? '' : _tvMetadata(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tv(Tipo.pequeno(tema)).copyWith(color: tema.acento),
                  ),
                  const SizedBox(height: Forma.espaco1),
                  Expanded(
                    child: Text(
                      item?.summary ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _tv(Tipo.pequeno(tema)).copyWith(color: tema.texto),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: _TvPosterCard.altura(context, tema) + 2 * Forma.espaco3,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: margem, vertical: Forma.espaco3),
            scrollDirection: Axis.horizontal,
            itemCount: widget.items.length,
            separatorBuilder: (context, index) => const SizedBox(width: Forma.espaco6),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _TvPosterCard(
                item: item,
                tema: tema,
                onTap: () => widget.onItemTap(item),
                onFocusChange: (focused) => _focus(item, focused),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TvPosterCard extends StatefulWidget {
  const _TvPosterCard({required this.item, required this.tema, required this.onTap, required this.onFocusChange});
  final MediaItem item;
  final TemaHeisuca tema;
  final VoidCallback onTap;
  final ValueChanged<bool> onFocusChange;

  static const double largura = 180;
  static const double alturaDoPoster = 270;

  static TextStyle estiloDoTitulo(TemaHeisuca tema) => _tv(Tipo.pequeno(tema)).copyWith(color: tema.texto);

  /// Altura do cartão (pôster + respiro + uma linha de título), medida com a letra que a pessoa escolheu:
  /// a fileira reserva exatamente isso, sem número mágico que estoura quando a letra cresce.
  static double altura(BuildContext context, TemaHeisuca tema) {
    final linha = TextPainter(
      text: TextSpan(text: 'Hg', style: estiloDoTitulo(tema)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final alturaDaLinha = linha.height;
    linha.dispose();
    return alturaDoPoster + Forma.espaco2 + alturaDaLinha;
  }

  @override
  State<_TvPosterCard> createState() => _TvPosterCardState();
}

class _TvPosterCardState extends State<_TvPosterCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tema = widget.tema;
    return SizedBox(
      width: _TvPosterCard.largura,
      child: FocusableActionDetector(
        onFocusChange: widget.onFocusChange,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            children: [
              AnimatedScale(
                scale: _focused ? HeisucaBase.focoEscalaTv : 1,
                duration: Movimento.tempo(context, Movimento.toque),
                curve: Movimento.entra,
                child: Container(
                  width: _TvPosterCard.largura,
                  height: _TvPosterCard.alturaDoPoster,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: tema.superficie,
                    shape: Forma.superelipse(
                      Forma.raioMedio,
                      lado: _focused ? BorderSide(color: tema.foco, width: Forma.anelDeFoco) : BorderSide.none,
                    ),
                  ),
                  child: OptimizedMediaImage(
                    client: cgflixClientFor(context, item),
                    imagePath: cgflixPosterPath(item) ?? item.artPath,
                    width: _TvPosterCard.largura,
                    height: _TvPosterCard.alturaDoPoster,
                    imageType: ImageType.poster,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: Forma.espaco2),
              Text(
                item.displayTitle,
                key: ValueKey('tv-poster-title-${item.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _TvPosterCard.estiloDoTitulo(tema),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
