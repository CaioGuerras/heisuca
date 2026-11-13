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
import '../../heisuca/heisuca_media_category.dart';
import '../../media/media_item.dart';
import '../../mixins/refreshable.dart';
import '../../providers/download_provider.dart';
import '../../utils/download_utils.dart';
import '../../widgets/optimized_media_image.dart';
import '../casca/pilula_do_perfil_ativo.dart';
import '../inicio/aviso.dart';
import '../inicio/ligacao.dart' show notaDe;
import '../inicio/modelo.dart';
import '../tema_da_v2.dart';
import '../titulo/ligacao.dart' show LigacaoDoTitulo;
import 'tela_minha_lista.dart';

/// Um grupo de favoritos do mesmo tipo, na ordem em que a fonte os entregou.
typedef GrupoDeFavoritos = ({String chave, String titulo, List<MediaItem> itens});

/// Separa os favoritos em Séries, Filmes e Animes, nesta ordem. Grupo sem título não entra.
List<GrupoDeFavoritos> agruparFavoritos(Iterable<MediaItem> favoritos) {
  final porTipo = <HeisucaMediaCategory, List<MediaItem>>{};
  for (final item in favoritos) {
    porTipo.putIfAbsent(heisucaMediaCategory(item), () => []).add(item);
  }
  const ordem = [
    (HeisucaMediaCategory.shows, 'series', 'Séries'),
    (HeisucaMediaCategory.movies, 'filmes', 'Filmes'),
    (HeisucaMediaCategory.anime, 'animes', 'Animes'),
  ];
  return [
    for (final (tipo, chave, titulo) in ordem)
      if (porTipo[tipo] case final itens?) (chave: chave, titulo: titulo, itens: itens),
  ];
}

/// Liga a tela Minha lista da V2 aos favoritos do servidor, à ficha do título e ao menu.
class LigacaoDaMinhaLista extends StatefulWidget {
  const LigacaoDaMinhaLista({super.key, required this.fonte, this.folgaInferior = 96});

  final CgflixFavoritesSource fonte;

  /// Espaço no fim da lista para a barra flutuante.
  final double folgaInferior;

  @override
  State<LigacaoDaMinhaLista> createState() => _LigacaoDaMinhaListaState();
}

class _LigacaoDaMinhaListaState extends State<LigacaoDaMinhaLista> with Refreshable {
  List<FileiraDoInicio> _fileiras = const [];
  bool _carregando = true;
  bool _falhou = false;

  /// Só a resposta do pedido mais novo vale.
  int _geracao = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  @override
  void didUpdateWidget(LigacaoDaMinhaLista antiga) {
    super.didUpdateWidget(antiga);
    if (!identical(antiga.fonte.client, widget.fonte.client)) unawaited(_carregar());
  }

  @override
  void refresh() => unawaited(_carregar());

  Future<void> _carregar() async {
    final geracao = ++_geracao;
    if (_fileiras.isEmpty && !_carregando) setState(() => _carregando = true);
    List<MediaItem>? favoritos;
    try {
      favoritos = await widget.fonte.load();
    } catch (_) {
      favoritos = null;
    }
    if (!mounted || geracao != _geracao) return;
    setState(() {
      _carregando = false;
      _falhou = favoritos == null;
      // Falha com a lista na tela: a lista fica.
      if (favoritos != null) _fileiras = [for (final grupo in agruparFavoritos(favoritos)) _emFileira(grupo)];
    });
  }

  FileiraDoInicio _emFileira(GrupoDeFavoritos grupo) => FileiraDoInicio(
    chave: grupo.chave,
    titulo: grupo.titulo,
    itens: [for (final item in grupo.itens) _emPoster(item)],
  );

  ItemDaFileira _emPoster(MediaItem item) => ItemDaFileira(
    chave: item.globalKey,
    titulo: item.displayTitle,
    subtitulo: item.year?.toString(),
    arte: (context, tamanho) => OptimizedMediaImage(
      client: cgflixClientFor(context, item) ?? widget.fonte.client,
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

  /// Abre a ficha; na volta pede a lista de novo, porque o título pode ter saído dela.
  Future<void> _abrir(MediaItem item) async {
    if (!mounted) return;
    await LigacaoDoTitulo.abrir(context, item);
    if (mounted) unawaited(_carregar());
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
        onPlay: () => unawaited(cgflixPlay(context, item)),
        onOpenDetails: () => unawaited(_abrir(item)),
        onDownload: () => _baixar(item),
      ).whenComplete(() {
        if (mounted) unawaited(_carregar());
      }),
    );
  }

  Widget? _aviso() {
    if (_fileiras.isNotEmpty || _carregando) return null;
    if (_falhou) {
      return Aviso(
        icone: Symbols.cloud_off_rounded,
        titulo: 'Não foi possível carregar a sua lista',
        texto: 'Verifique a conexão e tente de novo.',
        acoes: [Botao(rotulo: 'Tentar novamente', aoTocar: () => unawaited(_carregar()))],
      );
    }
    return const Aviso(
      icone: Symbols.favorite_rounded,
      titulo: 'Nenhum favorito ainda',
      texto: 'Abra um filme ou uma série e toque em "Minha lista" para guardar aqui.',
    );
  }

  @override
  Widget build(BuildContext context) => SobOTemaDaV2(
    child: TelaMinhaLista(
      fileiras: _fileiras,
      carregando: _carregando,
      aviso: _aviso(),
      aoBuscar: () => unawaited(cgflixOpenSearch(context)),
      perfil: const PilulaDoPerfilAtivo(sobreArte: true),
      aoAtualizar: _carregar,
      folgaInferior: widget.folgaInferior,
    ),
  );
}
