import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'update_feed_client.dart';

class FalhaAtualizacao implements Exception {
  const FalhaAtualizacao(this.codigo);
  final String codigo;
  @override
  String toString() => 'Falha na atualização: $codigo';
}

class CancelamentoAtualizacao {
  final _sinal = Completer<void>();
  Future<void> get sinal => _sinal.future;
  bool get cancelado => _sinal.isCompleted;
  void cancelar() {
    if (!cancelado) _sinal.complete();
  }

  void conferir() {
    if (cancelado) throw const FalhaAtualizacao('cancelado');
  }
}

class _Resumo implements Sink<Digest> {
  Digest? valor;
  @override
  void add(Digest data) {
    valor = data;
  }

  @override
  void close() {}
}

/// Um download por instância; disco e SHA são alimentados em fluxo, sem APK na memória.
class UpdateDownloader {
  UpdateDownloader({required this.cliente, required this.cache, required this.espacoLivre});
  final UpdateFeedClient cliente;
  final Future<Directory> Function() cache;
  final Future<int> Function() espacoLivre;
  bool _ocupado = false;
  static int _sequencia = 0;
  Future<File> baixar(
    ApkAtualizacao apk, {
    CancelamentoAtualizacao? cancelamento,
    void Function(int, int)? progresso,
  }) async {
    if (_ocupado) throw const FalhaAtualizacao('ocupado');
    _ocupado = true;
    final controle = cancelamento ?? CancelamentoAtualizacao();
    File? parcial;
    File? completo;
    RandomAccessFile? escrita;
    StreamIterator<List<int>>? partes;
    var concluido = false;
    try {
      controle.conferir();
      if (!cliente.config.permite(apk.url) || apk.bytes <= 0) throw const FalhaAtualizacao('arquivoInvalido');
      // Reserva para o arquivo e para a preparação do pacote pelo sistema.
      if (await espacoLivre() < apk.bytes + 64 * 1024 * 1024) throw const FalhaAtualizacao('espaco');
      controle.conferir();
      final pasta = Directory('${(await cache()).path}/updates');
      await pasta.create(recursive: true);
      final nome = 'heisuca-${DateTime.now().microsecondsSinceEpoch}-${_sequencia++}';
      parcial = File('${pasta.path}/$nome.part');
      completo = File('${pasta.path}/$nome.apk');
      final resposta = await Future.any([
        cliente.abrir(apk.url, cancelar: controle.sinal),
        controle.sinal.then<Never>((_) => throw const FalhaAtualizacao('cancelado')),
      ]);
      controle.conferir();
      if (resposta.contentLength != null && resposta.contentLength != apk.bytes) {
        await resposta.stream.listen((_) {}).cancel();
        throw const FalhaAtualizacao('arquivoInvalido');
      }
      escrita = await parcial.open(mode: FileMode.writeOnly);
      final resumo = _Resumo();
      final hash = sha256.startChunkedConversion(resumo);
      partes = StreamIterator(resposta.stream.timeout(const Duration(seconds: 30)));
      var recebidos = 0;
      while (await Future.any([
        partes.moveNext(),
        controle.sinal.then<Never>((_) => throw const FalhaAtualizacao('cancelado')),
      ])) {
        controle.conferir();
        final parte = partes.current;
        if (recebidos + parte.length > apk.bytes) throw const FalhaAtualizacao('arquivoInvalido');
        await escrita.writeFrom(parte);
        hash.add(parte);
        recebidos += parte.length;
        progresso?.call(recebidos, apk.bytes);
      }
      controle.conferir();
      hash.close();
      if (recebidos != apk.bytes || resumo.valor?.toString() != apk.sha256.toLowerCase()) {
        throw const FalhaAtualizacao('arquivoInvalido');
      }
      await escrita.close();
      escrita = null;
      await parcial.rename(completo.path);
      concluido = true;
      return completo;
    } on FalhaAtualizacao {
      rethrow;
    } catch (_) {
      // Não expor URL, caminho do canal ou exceções da rede no log/interface.
      throw FalhaAtualizacao(controle.cancelado ? 'cancelado' : 'arquivoInvalido');
    } finally {
      try {
        await partes?.cancel();
      } catch (_) {
        /* A limpeza do disco ainda deve ocorrer. */
      }
      try {
        await escrita?.close();
      } catch (_) {
        /* Tenta remover o arquivo mesmo após falha de fechamento. */
      }
      if (!concluido) {
        // Só os arquivos transitórios desta tentativa; a spec exige removê-los na falha.
        for (final arquivo in [parcial, completo]) {
          try {
            if (arquivo != null && await arquivo.exists()) await arquivo.delete();
          } catch (_) {
            /* Sem instalação. */
          }
        }
      }
      _ocupado = false;
    }
  }
}
