import 'dart:io';
import 'package:flutter/services.dart';
import '../playback_diagnostics.dart';
import 'update_feed_client.dart';
import 'update_downloader.dart';

class EstadoInstalador {
  const EstadoInstalador({this.habilitado = false, this.build = 0, this.versao = '', this.espacoLivre = 0});
  final bool habilitado;
  final int build, espacoLivre;
  final String versao;
}

class ApkInstaller {
  const ApkInstaller({this.diagnosticos});
  final PlaybackDiagnosticStore? diagnosticos;
  static const _canal = MethodChannel('app.heisuca/updates');
  Future<EstadoInstalador> estado() async {
    try {
      final estado = await _canal.invokeMapMethod<String, dynamic>('estado');
      if (estado?['habilitado'] != true) return const EstadoInstalador();
      return EstadoInstalador(
        habilitado: true,
        build: (estado?['build'] as num?)?.toInt() ?? 0,
        versao: estado?['versao'] as String? ?? '',
        espacoLivre: (estado?['espacoLivre'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      // Canal ausente na Play/outras plataformas: desligado, sem consulta de feed.
      return const EstadoInstalador();
    }
  }

  Future<ApkAtualizacao> selecionar(OfertaAtualizacao oferta) async {
    final abi = await _canal.invokeMethod<String>('escolherAbi', {'abis': oferta.apks.map((a) => a.abi).toList()});
    final apk = oferta.apks.where((a) => a.abi == abi).firstOrNull;
    if (apk == null) throw const FalhaAtualizacao('abi');
    await (diagnosticos ?? PlaybackDiagnosticStore.instance).append({'event': 'updateAbi', 'abi': apk.abi});
    return apk;
  }

  Map<String, Object> _argumentos(File arquivo, OfertaAtualizacao oferta, ApkAtualizacao apk) => {
    'arquivo': arquivo.path,
    'build': oferta.build,
    'assinatura': oferta.assinatura,
    'bytes': apk.bytes,
    'sha256': apk.sha256,
  };
  Future<void> validar(File arquivo, OfertaAtualizacao oferta, ApkAtualizacao apk) async {
    try {
      if (await _canal.invokeMethod<bool>('validar', _argumentos(arquivo, oferta, apk)) != true) {
        throw const FalhaAtualizacao('arquivoInvalido');
      }
    } catch (_) {
      throw const FalhaAtualizacao('arquivoInvalido');
    }
  }

  Future<String> instalar(File arquivo, OfertaAtualizacao oferta, ApkAtualizacao apk) async {
    try {
      final acao = await _canal.invokeMethod<String>('instalar', _argumentos(arquivo, oferta, apk));
      if (!{'aberto', 'permissao', 'permissaoManual'}.contains(acao)) throw const FalhaAtualizacao('instalador');
      return acao!;
    } on PlatformException catch (erro) {
      throw FalhaAtualizacao(erro.code == 'arquivoInvalido' ? 'arquivoInvalido' : 'instalador');
    }
  }
}
