import 'dart:async';

import 'package:flutter/material.dart';

import '../../cgflix/home/cgflix_actions.dart';
import '../../design/componentes/botao.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../heisuca/heisuca_context_menu.dart';
import '../../heisuca/heisuca_home_style.dart';
import '../../heisuca/heisuca_state_store.dart';
import '../../heisuca/heisuca_title_logo.dart';
import '../../heisuca/heisuca_title_sheet.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../services/settings_service.dart';
import '../../utils/media_image_helper.dart';
import '../../widgets/optimized_media_image.dart';
import '../inicio/ligacao.dart' show juntar, notaDe, progressoDe;
import '../tema_da_v2.dart';
import 'episodios.dart';
import 'modelo.dart';
import 'tela_titulo.dart';

/// O texto do botão principal. "Continuar" só quando há posição salva; em série, leva o código do episódio.
@visibleForTesting
String rotuloDeAssistirDe(MediaItem item, MediaItem? alvo) {
  if (item.kind != MediaKind.show) return (item.viewOffsetMs ?? 0) > 0 ? 'Continuar' : 'Assistir';
  if (alvo == null) return 'Assistir';
  final verbo = (alvo.viewOffsetMs ?? 0) > 0 ? 'Continuar' : 'Assistir';
  final codigo = cgflixEpisodeCode(alvo);
  return codigo.isEmpty ? verbo : '$verbo $codigo';
}

/// Duração para ler de relance: "24 min", "2 h", "1 h 45 min". Menos de um minuto, `null`.
@visibleForTesting
String? duracaoDe(int? ms) {
  if (ms == null || ms < Duration.millisecondsPerMinute) return null;
  final minutos = ms ~/ Duration.millisecondsPerMinute;
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  return resto == 0 ? '$horas h' : '$horas h $resto min';
}

/// A temporada que abre primeiro: a pedida, senão a do episódio que vai tocar, senão a primeira que não é
/// de especiais, senão a primeira. Devolve o índice na lista; lista vazia, 0.
@visibleForTesting
int temporadaInicialDe(List<MediaItem> temporadas, {String? pedida, MediaItem? alvo}) {
  int onde(bool Function(MediaItem) serve) => temporadas.indexWhere(serve);
  final candidatas = [
    if (pedida != null) onde((t) => t.id == pedida),
    if (alvo != null) onde((t) => t.id == alvo.parentId || (alvo.parentIndex != null && t.index == alvo.parentIndex)),
    onde((t) => (t.index ?? 0) > 0),
  ];
  for (final indice in candidatas) {
    if (indice >= 0) return indice;
  }
  return 0;
}

/// O nome próprio do episódio; vazio quando o servidor só repete o nome da série ou não tem nome.
@visibleForTesting
String nomeDoEpisodio(MediaItem episodio) {
  final nome = episodio.title?.trim() ?? '';
  return nome == episodio.grandparentTitle?.trim() ? '' : nome;
}

/// Só as temporadas, na ordem do número.
@visibleForTesting
List<MediaItem> soTemporadas(Iterable<MediaItem> filhos) =>
    filhos.where((filho) => filho.kind == MediaKind.season).toList()
      ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

/// Só os episódios, na ordem do número.
@visibleForTesting
List<MediaItem> soEpisodios(Iterable<MediaItem> filhos) =>
    filhos.where((filho) => filho.kind == MediaKind.episode).toList()
      ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

/// De onde sai o cliente do servidor de um item. Os testes trocam por um de mentira.
typedef ClienteDe = MediaServerClient? Function(BuildContext context, MediaItem item);

/// Liga a tela Título da V2 ao acervo e ao player.
///
/// Recebe o item tocado (filme, série, temporada ou episódio). Episódio e temporada abrem a página da série,
/// com aquele episódio como o próximo a tocar ou aquela temporada aberta.
class LigacaoDoTitulo extends StatefulWidget {
  const LigacaoDoTitulo({super.key, required this.item, this.episodio, this.clienteDe = cgflixClientFor});

  final MediaItem item;

  /// O episódio que o botão principal deve tocar, quando quem abriu já sabe qual é.
  final MediaItem? episodio;

  final ClienteDe clienteDe;

  /// Abre a página do título por cima da tela atual.
  static Future<void> abrir(BuildContext context, MediaItem item, {MediaItem? episodio}) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LigacaoDoTitulo(item: item, episodio: episodio),
    ),
  );

  @override
  State<LigacaoDoTitulo> createState() => _LigacaoDoTituloState();
}

class _LigacaoDoTituloState extends State<LigacaoDoTitulo> {
  late MediaItem _item = widget.item;
  MediaItem? _alvo;
  List<MediaItem>? _temporadas;
  final Map<String, List<MediaItem>> _episodios = {};
  int _aberta = 0;
  bool _falhou = false;
  bool _entradaUsada = false;
  int _geracao = 0;

  @override
  void initState() {
    super.initState();
    final entrada = widget.item;
    _alvo = widget.episodio ?? (entrada.kind == MediaKind.episode ? entrada : null);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_carregar()));
  }

  bool get _ehSerie => _item.kind == MediaKind.show;

  Future<void> _carregar({bool denovo = false}) async {
    final geracao = ++_geracao;
    bool velho() => !mounted || geracao != _geracao;
    if (_falhou) setState(() => _falhou = false);
    try {
      final cliente = widget.clienteDe(context, _item);
      if (cliente == null) throw StateError('sem servidor');
      final entrada = widget.item;
      final serie = _ehSerie ? null : heisucaSeriesIdFor(entrada);
      // As temporadas saem junto com o item: a página não espera uma ida ao servidor depois da outra.
      final conhecida = serie ?? (_ehSerie ? _item.id : null);
      final filhos = conhecida == null || (denovo && _temporadas != null)
          ? null
          : Future.sync(() => cliente.fetchChildren(conhecida));
      filhos?.ignore();

      var resposta = await cliente.fetchItemWithOnDeck(
        serie ?? _item.id,
        onItemReady: (pronto) {
          if (velho()) return;
          if (serie == null || pronto.kind == MediaKind.show) setState(() => _item = pronto);
        },
      );
      if (velho()) return;
      // Só vira a página da série se o servidor confirmou a série; senão fica no próprio item.
      if (serie != null && resposta.item?.kind != MediaKind.show) {
        resposta = await cliente.fetchItemWithOnDeck(entrada.id);
        if (velho()) return;
        setState(() {
          _item = resposta.item ?? entrada;
          _alvo = null;
          _temporadas = null;
        });
        return;
      }
      setState(() {
        _item = resposta.item ?? _item;
        // Na primeira abertura vale o episódio tocado; depois de assistir, o próximo que o servidor indicar.
        final tocado = _entradaUsada ? null : (widget.episodio ?? (entrada.kind == MediaKind.episode ? entrada : null));
        _alvo = _ehSerie ? (tocado ?? resposta.onDeckEpisode ?? (denovo ? null : _alvo)) : null;
      });
      if (!_ehSerie) return;

      if (filhos != null || _temporadas == null) {
        final temporadas = soTemporadas(await (filhos ?? cliente.fetchChildren(_item.id)));
        if (velho()) return;
        setState(() {
          _temporadas = temporadas;
          _aberta = temporadaInicialDe(
            temporadas,
            pedida: !_entradaUsada && entrada.kind == MediaKind.season ? entrada.id : null,
            alvo: _alvo,
          );
        });
      }
      _entradaUsada = true;
      await _carregarTemporada(_aberta, denovo: denovo);
    } catch (_) {
      if (!velho()) setState(() => _falhou = true);
    }
  }

  Future<void> _carregarTemporada(int indice, {bool denovo = false}) async {
    final temporadas = _temporadas;
    if (temporadas == null || indice < 0 || indice >= temporadas.length) return;
    final temporada = temporadas[indice];
    if (!denovo && _episodios.containsKey(temporada.id)) return;
    final geracao = _geracao;
    try {
      final cliente = widget.clienteDe(context, _item);
      if (cliente == null) throw StateError('sem servidor');
      final episodios = soEpisodios(await cliente.fetchChildren(temporada.id));
      if (!mounted || geracao != _geracao) return;
      setState(() {
        _episodios[temporada.id] = episodios;
        if (indice == _aberta) {
          _alvo ??= episodios.where((e) => e.isUnwatchedOrInProgress).firstOrNull ?? episodios.firstOrNull;
        }
      });
    } catch (_) {
      // A temporada continua como "carregando" e tenta de novo na próxima vez que for aberta.
      if (mounted && geracao == _geracao && indice == _aberta) setState(() => _falhou = true);
    }
  }

  void _mudarTemporada(int indice) {
    _aberta = indice;
    unawaited(_carregarTemporada(indice));
  }

  // --- O que cada toque faz ------------------------------------------------------
  // O player e os menus abrem com o contexto desta ligação, acima do tema da V2.

  Future<void> _assistir(MediaItem alvo) async {
    await cgflixPlay(context, alvo);
    if (mounted) await _carregar(denovo: true);
  }

  Future<void> _alternarVisto() async {
    await HeisucaStateStore.instance.toggleWatched(context, _alvo ?? _item);
    if (mounted) await _carregar(denovo: true);
  }

  Future<void> _alternarLista() async {
    await HeisucaStateStore.instance.toggleFavorite(context, _item);
    if (mounted) setState(() {});
  }

  void _menu(MediaItem item, {VoidCallback? aoAssistir}) {
    unawaited(
      HeisucaContextMenu.show(
        context,
        item: item,
        onPlay: aoAssistir,
        onToggleWatched: identical(item, _item) ? () => unawaited(_alternarVisto()) : null,
        onToggleFavorite: identical(item, _item) ? () => unawaited(_alternarLista()) : null,
      ),
    );
  }

  // --- Do acervo para a tela -----------------------------------------------------

  bool get _escondeSpoilers => SettingsService.instanceOrNull?.read(SettingsService.hideSpoilers) ?? true;

  PaginaDoTitulo _pagina() {
    final item = _item;
    final alvo = _ehSerie ? _alvo : item;
    final estado = HeisucaStateStore.instance;
    final generos = item.genres?.where((genero) => genero.trim().isNotEmpty).take(3).join(', ');
    final sinopse = item.summary?.trim();
    final classificacao = item.contentRating?.trim();
    final temporadas = _temporadas?.where((t) => (t.index ?? 0) > 0).length ?? 0;
    return PaginaDoTitulo(
      chave: item.globalKey,
      titulo: item.displayTitle,
      arte: (context, tamanho) {
        final candidatas = item.heroArtCandidates(containerAspectRatio: tamanho.width / tamanho.height);
        return OptimizedMediaImage(
          key: ValueKey('titulo_arte_${item.globalKey}'),
          client: widget.clienteDe(context, item),
          imagePath: item.artPath ?? candidatas.firstOrNull,
          width: tamanho.width,
          height: tamanho.height,
          imageType: ImageType.art,
          alignment: const Alignment(0, -0.64),
        );
      },
      logo: (context, tamanho, semLogo) => HeisucaTitleLogo(
        item: item,
        client: widget.clienteDe(context, item),
        width: tamanho.width,
        height: tamanho.height,
        fallbackWidth: tamanho.width,
        fallbackBuilder: (_) => semLogo,
        alignment: Alignment.center,
      ),
      hash: heisucaArtworkHash(item),
      nota: notaDe(item.rating),
      anos: item.year?.toString(),
      generos: generos == null || generos.isEmpty ? null : generos,
      classificacao: classificacao == null || classificacao.isEmpty ? null : classificacao,
      detalhes: [
        if (_ehSerie && temporadas > 0) temporadas == 1 ? '1 temporada' : '$temporadas temporadas',
        if (!_ehSerie) ?duracaoDe(item.durationMs),
      ],
      sinopse: sinopse == null || sinopse.isEmpty ? null : sinopse,
      rotuloDeAssistir: rotuloDeAssistirDe(item, _alvo),
      progresso: alvo == null ? null : progressoDe(alvo.durationMs, alvo.viewOffsetMs),
      aoAssistir: alvo == null ? null : () => unawaited(_assistir(alvo)),
      naLista: estado.isFavorite(item),
      aoAlternarLista: () => unawaited(_alternarLista()),
      visto: estado.isWatched(alvo ?? item),
      aoAlternarVisto: () => unawaited(_alternarVisto()),
    );
  }

  EpisodioDoTitulo _emEpisodio(MediaItem episodio) {
    final escondido = _escondeSpoilers && !episodio.isWatched && !episodio.hasActiveProgress;
    final caminho = escondido ? null : (cgflixWidePath(episodio) ?? episodio.thumbPath);
    return EpisodioDoTitulo(
      chave: episodio.globalKey,
      numero: episodio.index ?? 0,
      nome: escondido ? '' : nomeDoEpisodio(episodio),
      arte: caminho == null
          ? null
          : (context, tamanho) => OptimizedMediaImage(
              client: widget.clienteDe(context, episodio),
              imagePath: caminho,
              width: tamanho.width,
              height: tamanho.height,
              imageType: ImageType.thumb,
            ),
      duracao: juntar([duracaoDe(episodio.durationMs)]),
      progresso: progressoDe(episodio.durationMs, episodio.viewOffsetMs),
      atual: episodio.id == _alvo?.id,
      aoTocar: () => unawaited(_assistir(episodio)),
      aoSegurar: () => _menu(episodio, aoAssistir: () => unawaited(_assistir(episodio))),
    );
  }

  List<TemporadaDoTitulo> _emTemporadas(List<MediaItem> temporadas) => [
    for (final temporada in temporadas)
      TemporadaDoTitulo(
        chave: temporada.id,
        nome: heisucaSeasonLabel(temporada),
        episodios: _episodios[temporada.id]?.map(_emEpisodio).toList(),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final temporadas = _temporadas;
    final alvo = _ehSerie ? _alvo : _item;
    return SobOTemaDaV2(
      child: Scaffold(
        body: TelaTitulo(
          pagina: _pagina(),
          aoAbrirMenu: () => _menu(_item, aoAssistir: alvo == null ? null : () => unawaited(_assistir(alvo))),
          secoes: [
            if (_ehSerie && temporadas != null && temporadas.isNotEmpty)
              Episodios(
                // Monta de novo quando as temporadas chegam: a temporada aberta é escolhida ao montar.
                key: ValueKey('episodios-${_item.id}-${temporadas.length}'),
                temporadas: _emTemporadas(temporadas),
                inicial: _aberta,
                aoMudarTemporada: _mudarTemporada,
              ),
            if (_falhou) _Falha(aoTentar: () => unawaited(_carregar())),
          ],
        ),
      ),
    );
  }
}

/// O aviso de que o servidor não respondeu, com o caminho para tentar de novo.
class _Falha extends StatelessWidget {
  const _Falha({required this.aoTentar});

  final VoidCallback aoTentar;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4, vertical: Forma.espaco4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Não deu para carregar tudo deste título.', style: Tipo.texto(tema).copyWith(color: tema.texto2)),
          const SizedBox(height: Forma.espaco3),
          Botao(rotulo: 'Tentar de novo', tipo: TipoDeBotao.secundario, aoTocar: aoTentar),
        ],
      ),
    );
  }
}
