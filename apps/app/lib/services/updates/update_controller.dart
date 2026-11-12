import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../cgflix/requests/cgflix_secure_store.dart';
import '../../utils/log_redaction_manager.dart';
import '../playback_coordinator.dart';
import '../settings_service.dart';
import 'apk_installer.dart';
import 'update_feed_client.dart';
import 'update_checker.dart';
import 'update_downloader.dart';

class UpdateController extends ChangeNotifier {
  UpdateController({
    required this.config,
    required this.feed,
    required this.instalador,
    required this.settings,
    required this.segredos,
    required this.emReproducao,
    this.suporteAndroid = true,
    this.cache,
  });
  factory UpdateController.doApp(SettingsService settings) {
    final config = ConfiguracaoAtualizacao.doBuild();
    return UpdateController(
      config: config,
      feed: UpdateFeedClient(config),
      instalador: const ApkInstaller(),
      settings: settings,
      segredos: CgflixSecureStore.platform(),
      suporteAndroid: Platform.isAndroid,
      emReproducao: () => PlaybackCoordinator.instance.temReproducao,
    );
  }
  final ConfiguracaoAtualizacao config;
  final UpdateFeedClient feed;
  final ApkInstaller instalador;
  final SettingsService settings;
  final CgflixSecureStore segredos;
  final bool Function() emReproducao;
  final bool suporteAndroid;
  final Future<Directory> Function()? cache;
  OfertaAtualizacao? oferta;
  bool get permiteAjustes => suporteAndroid && config.distribuicao != 'play';
  bool get habilitado => permiteAjustes && config.ligado && _estado.habilitado;
  bool get pronto => _arquivo != null;
  bool baixando = false;
  bool verificando = false;
  bool instalando = false;
  int recebidos = 0;
  int total = 0;
  bool get ocupado => baixando || verificando || instalando;
  bool get beta => settings.read(SettingsService.updateBeta);
  String get codigo => _codigo ?? '';
  String get canal => codigo.isNotEmpty
      ? 'Teste'
      : beta
      ? 'Beta'
      : 'Estável';
  String? mensagem;
  EstadoInstalador get estado => _estado;
  EstadoInstalador _estado = const EstadoInstalador();
  UpdateChecker? _checker;
  Future<void>? _inicializacao;
  bool _verificouAbertura = false;
  bool _descartado = false;
  String? _codigo;
  static const _chaveCodigo = 'heisuca_update_test_code_v1';
  File? _arquivo;
  ApkAtualizacao? _apk;
  CancelamentoAtualizacao? _cancelamento;

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  Future<void> iniciar() => _inicializacao ??= _preparar();
  Future<void> _preparar() async {
    if (!permiteAjustes || !config.ligado) return;
    try {
      _estado = await instalador.estado();
      if (_descartado || !_estado.habilitado || _estado.build <= 0) return;
      _codigo = await segredos.readOrThrow(_chaveCodigo);
      if (_codigo?.isEmpty == true) _codigo = null;
      LogRedactionManager.registerToken(_codigo);
      await settings.write(
        SettingsService.updateChannel,
        codigo.isNotEmpty
            ? 'teste'
            : beta
            ? 'beta'
            : 'estavel',
      );
      _checker = UpdateChecker(
        feed: feed,
        buildInstalado: _estado.build,
        emReproducao: emReproducao,
        beta: () => beta,
        codigo: () => _codigo,
        lerUltima: () {
          final data = settings.read(SettingsService.updateLastCheck);
          return data > 0 ? DateTime.fromMillisecondsSinceEpoch(data, isUtc: true) : null;
        },
        gravarUltima: (data) => settings.write(SettingsService.updateLastCheck, data.millisecondsSinceEpoch),
      );
    } catch (_) {
      // Falha ao ler o cofre não muda silenciosamente o usuário do teste para um canal público.
      _estado = const EstadoInstalador();
      mensagem = 'Não foi possível carregar as opções de atualização.';
    }
    _avisar();
  }

  Future<void> aoAbrir() async {
    if (_verificouAbertura || _descartado) return;
    _verificouAbertura = true;
    await verificar();
  }

  Future<void> verificar({bool manual = false}) async {
    await iniciar();
    if (_descartado || ocupado) return;
    if (!habilitado || _checker == null) {
      if (manual) {
        mensagem = 'As atualizações estão indisponíveis nesta instalação.';
        _avisar();
      }
      return;
    }
    if (emReproducao()) {
      if (manual) {
        mensagem = 'Pare a reprodução para verificar atualizações.';
        _avisar();
      }
      return;
    }
    verificando = true;
    mensagem = null;
    _avisar();
    try {
      // Canal de teste: o botão manual sempre consulta (testador precisa da build nova na hora).
      final encontrada = await _checker!.verificar(ignorarLimite: manual && codigo.isNotEmpty);
      if (_descartado || emReproducao()) return;
      oferta = encontrada;
      if (manual) {
        mensagem = _checker!.limitadoHoje
            ? 'Já verificamos hoje. Tente novamente amanhã.'
            : _checker!.falhou
            ? 'Não foi possível verificar.'
            : oferta == null
            ? 'Nenhuma atualização disponível.'
            : null;
      }
    } finally {
      verificando = false;
      _avisar();
    }
  }

  Future<void> baixar() async {
    await iniciar();
    final atualizacao = oferta;
    if (_descartado || ocupado || atualizacao == null || !habilitado) return;
    if (emReproducao()) {
      mensagem = 'Pare a reprodução para baixar a atualização.';
      _avisar();
      return;
    }
    baixando = true;
    mensagem = null;
    recebidos = 0;
    total = 0;
    final cancelamento = _cancelamento = CancelamentoAtualizacao();
    File? recebido;
    _avisar();
    try {
      final apk = await instalador.selecionar(atualizacao);
      cancelamento.conferir();
      await settings.write(SettingsService.updateAbi, apk.abi);
      _apk = apk;
      total = apk.bytes;
      var ultimoPercentual = -1;
      final downloader = UpdateDownloader(
        cliente: feed,
        cache: cache ?? getTemporaryDirectory,
        espacoLivre: () async => (await instalador.estado()).espacoLivre,
      );
      recebido = await downloader.baixar(
        apk,
        cancelamento: cancelamento,
        progresso: (atual, total) {
          recebidos = atual;
          final percentual = atual * 100 ~/ total;
          if (percentual != ultimoPercentual) {
            ultimoPercentual = percentual;
            _avisar();
          }
        },
      );
      cancelamento.conferir();
      await instalador.validar(recebido, atualizacao, apk);
      cancelamento.conferir();
      if (_descartado) return;
      _arquivo = recebido;
      mensagem = 'Pronto para instalar.';
    } catch (erro) {
      await _remover(recebido);
      mensagem = switch (erro) {
        FalhaAtualizacao(codigo: 'cancelado') => 'Download cancelado.',
        FalhaAtualizacao(codigo: 'espaco') => 'Libere espaço no aparelho antes de baixar.',
        FalhaAtualizacao(codigo: 'abi') => 'Esta versão não é compatível com este aparelho.',
        _ => 'Arquivo corrompido ou inválido. Tente de novo.',
      };
    } finally {
      baixando = false;
      _cancelamento = null;
      _avisar();
    }
  }

  Future<void> instalar() async {
    if (_descartado || ocupado || _arquivo == null || oferta == null || _apk == null) return;
    if (emReproducao()) {
      mensagem = 'Pare a reprodução antes de instalar.';
      _avisar();
      return;
    }
    instalando = true;
    _avisar();
    try {
      final acao = await instalador.instalar(_arquivo!, oferta!, _apk!);
      mensagem = switch (acao) {
        'permissao' => 'Permita a instalação nas opções do sistema e toque em Instalar novamente.',
        'permissaoManual' =>
          'Nas configurações do aparelho, vá a Segurança → Instalar apps desconhecidos e permita o Heisuca. Depois volte e toque em Instalar.',
        _ => 'Confirme a atualização no instalador do sistema.',
      };
    } catch (erro) {
      if (erro is FalhaAtualizacao && erro.codigo == 'arquivoInvalido') {
        await _remover(_arquivo);
        _arquivo = null;
        mensagem = 'Arquivo corrompido ou inválido. Tente de novo.';
      } else {
        mensagem = 'Não foi possível abrir o instalador deste aparelho.';
      }
    } finally {
      instalando = false;
      _avisar();
    }
  }

  Future<void> definirBeta(bool valor) async {
    await iniciar();
    if (ocupado || _descartado || !habilitado) return;
    await settings.write(SettingsService.updateBeta, valor);
    await _mudarCanal();
  }

  Future<void> definirCodigo(String valor) async {
    await iniciar();
    if (ocupado || _descartado || !habilitado) return;
    final novo = valor.trim();
    if (novo.isNotEmpty && !RegExp(r'^[A-Za-z0-9_-]{20,256}$').hasMatch(novo)) {
      mensagem = 'Confira o código do canal de teste.';
      _avisar();
      return;
    }
    LogRedactionManager.registerToken(novo);
    try {
      await segredos.writeOrThrow(_chaveCodigo, novo);
      if (await segredos.readOrThrow(_chaveCodigo) != novo) throw const FormatException();
      _codigo = novo.isEmpty ? null : novo;
      await _mudarCanal();
    } catch (_) {
      mensagem = 'Não foi possível salvar o código neste aparelho.';
      _avisar();
    }
  }

  Future<void> _mudarCanal() async {
    oferta = null;
    _checker?.disponivel = null;
    // Canal novo: a consulta do dia feita no canal antigo não vale para este.
    await settings.write(SettingsService.updateLastCheck, 0);
    await _remover(_arquivo);
    _arquivo = null;
    await settings.write(
      SettingsService.updateChannel,
      codigo.isNotEmpty
          ? 'teste'
          : beta
          ? 'beta'
          : 'estavel',
    );
    mensagem = 'Canal salvo. Você pode verificar as atualizações.';
    _avisar();
  }

  Future<void> _remover(File? arquivo) async {
    try {
      if (arquivo != null && await arquivo.exists()) await arquivo.delete();
    } catch (_) {
      /* Cache transitório apenas. */
    }
  }

  void cancelar() => _cancelamento?.cancelar();
  @override
  void dispose() {
    _descartado = true;
    cancelar();
    feed.fechar();
    super.dispose();
  }
}
