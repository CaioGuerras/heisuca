import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cgflix/home/cgflix_actions.dart';
import '../../heisuca/heisuca_home_style.dart';
import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../media/media_item_types.dart';
import '../../models/download_models.dart';
import '../../profiles/active_profile_provider.dart';
import '../../providers/download_provider.dart';
import '../../services/settings_service.dart';
import '../tema_da_v2.dart';
import 'modelo.dart';
import 'tela_baixados.dart';

/// A identidade inclui o servidor: séries de fontes diferentes nunca se misturam.
String grupoDaBaixa(String chave, MediaItem? item) =>
    item?.isEpisode == true && item?.grandparentId != null ? '${item!.serverId}:${item.grandparentId}' : chave;

/// Seleciona apenas episódios completos. O restante da fila nunca é cancelado pela limpeza.
List<String> baixasParaApagar(
  Iterable<({String chave, MediaItem item, DownloadProgress progresso})> baixas, {
  int? manter,
}) {
  final ordenadas = baixas.where((b) => b.item.isEpisode).toList()
    ..sort((a, b) {
      final temporada = (a.item.parentIndex ?? 0).compareTo(b.item.parentIndex ?? 0);
      if (temporada != 0) return temporada;
      final episodio = (a.item.index ?? 0).compareTo(b.item.index ?? 0);
      return episodio != 0 ? episodio : a.chave.compareTo(b.chave);
    });
  var proximos = 0;
  return [
    for (final baixa in ordenadas)
      if ((baixa.item.isWatched || (manter != null && ++proximos > manter)) &&
          baixa.progresso.status == DownloadStatus.completed)
        baixa.chave,
  ];
}

/// Ponte com o downloader existente. A preferência é da série e do perfil ativo.
class LigacaoDosBaixados extends StatefulWidget {
  const LigacaoDosBaixados({super.key, required this.aoExplorar, this.perfil, this.folgaInferior = 96});
  final VoidCallback aoExplorar;
  final Widget? perfil;
  final double folgaInferior;
  @override
  State<LigacaoDosBaixados> createState() => _LigacaoDosBaixadosState();
}

class _LigacaoDosBaixadosState extends State<LigacaoDosBaixados> {
  DownloadProvider? _provider;
  ActiveProfileProvider? _perfis;
  SettingsService? _preferencias;
  bool _carregando = true;
  bool _ocupado = false;
  String? _aviso;
  int _geracao = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<DownloadProvider>();
    final perfis = context.read<ActiveProfileProvider>();
    if (identical(provider, _provider) && identical(perfis, _perfis)) return;
    _provider?.removeListener(_mudou);
    _perfis?.removeListener(_mudouPerfil);
    _provider = provider..addListener(_mudou);
    _perfis = perfis..addListener(_mudouPerfil);
    unawaited(_iniciar());
  }

  Future<void> _iniciar() async {
    try {
      final preferencias = await SettingsService.getInstance();
      await _provider!.ensureInitialized();
      if (!mounted) return;
      setState(() {
        _preferencias = preferencias;
        _carregando = false;
      });
      _mudou();
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _aviso = 'Não foi possível carregar seus baixados.';
        });
      }
    }
  }

  void _mudouPerfil() {
    _geracao++;
    _mudou();
  }

  void _mudou() {
    // O provider também notifica durante a composição da árvore de perfis.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      if (!_ocupado && _preferencias != null) unawaited(_limparRegras());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  String _chaveDaRegra(String grupo) => 'heisuca_v2_baixados_manter:${_perfis!.activeId}:$grupo';
  int? _manter(String grupo) {
    final n = _preferencias?.readInt(_chaveDaRegra(grupo));
    return const [1, 3, 5].contains(n) ? n : null;
  }

  VoidCallback? _acao(Future<void> Function() acao) {
    if (_ocupado) return null;
    final geracao = _geracao;
    return () {
      if (!mounted || geracao != _geracao) return;
      unawaited(_executar(acao));
    };
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado || _perfis?.activeId == null) return;
    setState(() {
      _ocupado = true;
      _aviso = null;
    });
    try {
      await acao();
    } catch (_) {
      if (mounted) setState(() => _aviso = 'Não foi possível concluir. Tente novamente.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _apagar(String grupo, {int? manter, int? geracao}) async {
    final atual = geracao ?? _geracao;
    final provider = _provider!;
    final candidatos = baixasParaApagar([
      for (final baixa in provider.downloads.entries)
        if (provider.getMetadata(baixa.key) case final item?)
          if (grupoDaBaixa(baixa.key, item) == grupo) (chave: baixa.key, item: item, progresso: baixa.value),
    ], manter: manter);
    for (final chave in candidatos) {
      if (!mounted || atual != _geracao) return;
      // Reconfere o estado depois de cada operação assíncrona.
      final item = provider.getMetadata(chave);
      if (item == null || provider.getProgress(chave)?.status != DownloadStatus.completed) continue;
      if (manter == null && !item.isWatched) continue;
      await provider.deleteDownload(chave);
    }
  }

  Future<void> _limparRegras() async {
    final grupos = {
      for (final baixa in _provider!.downloads.entries) grupoDaBaixa(baixa.key, _provider!.getMetadata(baixa.key)),
    };
    final geracao = _geracao;
    final regras = <String, int>{};
    for (final grupo in grupos) {
      final n = _manter(grupo);
      if (n != null) regras[grupo] = n;
    }
    if (regras.isEmpty) return;
    await _executar(() async {
      for (final regra in regras.entries) {
        if (!mounted || geracao != _geracao) return;
        await _apagar(regra.key, manter: regra.value, geracao: geracao);
      }
    });
  }

  Future<void> _salvar(String grupo, int n) async {
    final geracao = _geracao;
    final chave = _chaveDaRegra(grupo);
    await _executar(() async {
      await _preferencias!.writeInt(chave, n);
      if (!mounted || geracao != _geracao) return;
      await _apagar(grupo, manter: n, geracao: geracao);
    });
  }

  @override
  void dispose() {
    _geracao++;
    _provider?.removeListener(_mudou);
    _perfis?.removeListener(_mudouPerfil);
    super.dispose();
  }

  GrupoBaixado _grupo(String chave, List<MapEntry<String, DownloadProgress>> baixas) {
    final provider = _provider!;
    final geracao = _geracao;
    final primeiro = provider.getMetadata(baixas.first.key);
    final poster = provider.getMetadata(chave) ?? primeiro;
    final serie = primeiro?.isEpisode == true;
    final thumb = poster == null ? null : cgflixPosterPath(poster);
    final local = primeiro?.serverId == null
        ? null
        : provider.getArtworkLocalPath(ServerId(primeiro!.serverId!), thumb);
    return GrupoBaixado(
      chave: chave,
      titulo: primeiro?.displayTitle ?? 'Título baixado',
      serie: serie,
      hash: heisucaArtworkHash(poster),
      arte: local == null
          ? null
          : (_, tamanho) => Image.file(
              File(local),
              width: tamanho.width,
              height: tamanho.height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
      bytes: baixas.fold(0, (soma, b) => soma + b.value.downloadedBytes),
      manter: _manter(chave),
      aoApagarVistos: _acao(() => _apagar(chave)),
      aoManter: _ocupado || _preferencias == null
          ? null
          : (n) {
              if (!mounted || geracao != _geracao) return;
              unawaited(_salvar(chave, n));
            },
      itens: [for (final baixa in baixas) _item(baixa)],
    );
  }

  ItemBaixado _item(MapEntry<String, DownloadProgress> baixa) {
    final item = _provider!.getMetadata(baixa.key);
    final estado = switch (baixa.value.status) {
      DownloadStatus.downloading => EstadoDaBaixa.baixando,
      DownloadStatus.queued => EstadoDaBaixa.esperando,
      DownloadStatus.paused => EstadoDaBaixa.pausado,
      DownloadStatus.completed => EstadoDaBaixa.pronto,
      _ => EstadoDaBaixa.interrompido,
    };
    final cliente = item == null ? null : cgflixClientFor(context, item);
    return ItemBaixado(
      chave: baixa.key,
      titulo: item?.title ?? 'Título baixado',
      estado: estado,
      progresso: baixa.value.progress,
      aoPausar: _acao(() => _provider!.pauseDownload(baixa.key)),
      aoRetomar: _ocupado || cliente == null
          ? null
          : _acao(() async {
              if (baixa.value.status == DownloadStatus.paused) {
                await _provider!.resumeDownload(baixa.key, cliente);
              } else if (baixa.value.status == DownloadStatus.failed) {
                await _provider!.retryDownload(baixa.key, cliente);
              } else if (item != null) {
                await _provider!.queueDownload(item, cliente);
              }
            }),
      aoAssistir: item == null ? null : _acao(() => cgflixPlay(context, item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<MapEntry<String, DownloadProgress>>>{};
    for (final baixa in _provider!.downloads.entries) {
      final chave = grupoDaBaixa(baixa.key, _provider!.getMetadata(baixa.key));
      grupos.putIfAbsent(chave, () => []).add(baixa);
    }
    return SobOTemaDaV2(
      child: TelaBaixados(
        grupos: [for (final grupo in grupos.entries) _grupo(grupo.key, grupo.value)],
        totalBytes: _provider!.downloadActivitySnapshot().downloadedBytes,
        perfil: widget.perfil,
        carregando: _carregando,
        aviso: _aviso,
        aoExplorar: widget.aoExplorar,
        folgaInferior: widget.folgaInferior,
      ),
    );
  }
}
