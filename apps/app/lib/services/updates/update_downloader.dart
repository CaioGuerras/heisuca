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
///
/// Queda de rede no meio não joga fora o que já chegou: o download é retomado de onde parou (`Range`), com o mesmo
/// arquivo e o mesmo SHA em andamento. Só desiste depois de [tentativas] quedas seguidas sem receber nada.
class UpdateDownloader {
  UpdateDownloader({
    required this.cliente,
    required this.cache,
    required this.espacoLivre,
    this.tentativas = 4,
    this.espera = const Duration(seconds: 3),
  });
  final UpdateFeedClient cliente;
  final Future<Directory> Function() cache;
  final Future<int> Function() espacoLivre;

  /// Quedas seguidas, sem nenhum byte novo, que o download aguenta antes de falhar com `rede`.
  final int tentativas;

  /// Pausa antes de retomar depois de uma queda.
  final Duration espera;

  /// Teto de retomadas num download, mesmo com progresso: rede que cai a cada pedaço não prende o aparelho.
  static const _retomadasNoTotal = 30;
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
      escrita = await parcial.open(mode: FileMode.writeOnly);
      var resumo = _Resumo();
      var hash = sha256.startChunkedConversion(resumo);
      var recebidos = 0;
      var quedasSeguidas = 0;
      var retomadas = 0;
      Future<Never> cancelou() => controle.sinal.then<Never>((_) => throw const FalhaAtualizacao('cancelado'));
      while (recebidos < apk.bytes) {
        final noComeco = recebidos;
        try {
          final resposta = await Future.any([
            cliente.abrir(apk.url, cancelar: controle.sinal, aPartirDe: recebidos),
            cancelou(),
          ]);
          controle.conferir();
          if (recebidos > 0 && resposta.statusCode != 206) {
            // O servidor mandou o arquivo inteiro de novo: recomeça do zero, sem misturar com o que já havia.
            await escrita.truncate(0);
            await escrita.setPosition(0);
            resumo = _Resumo();
            hash = sha256.startChunkedConversion(resumo);
            recebidos = 0;
          }
          final falta = apk.bytes - recebidos;
          final intervalo = resposta.headers['content-range'];
          if ((resposta.contentLength != null && resposta.contentLength != falta) ||
              (resposta.statusCode == 206 && intervalo != null && !intervalo.startsWith('bytes $recebidos-'))) {
            await resposta.stream.listen((_) {}).cancel();
            throw const FalhaAtualizacao('arquivoInvalido');
          }
          partes = StreamIterator(resposta.stream.timeout(const Duration(seconds: 30)));
          while (await Future.any([partes.moveNext(), cancelou()])) {
            controle.conferir();
            final parte = partes.current;
            if (recebidos + parte.length > apk.bytes) throw const FalhaAtualizacao('arquivoInvalido');
            await escrita.writeFrom(parte);
            hash.add(parte);
            recebidos += parte.length;
            progresso?.call(recebidos, apk.bytes);
          }
          // A conexão fechou antes do fim sem acusar erro: conta como queda.
          if (recebidos < apk.bytes) throw const SocketException('fim antes da hora');
        } on FalhaAtualizacao {
          rethrow;
        } on RecusaDeAtualizacao {
          // Resposta definitiva: tentar de novo não muda nada.
          throw const FalhaAtualizacao('arquivoInvalido');
        } catch (_) {
          if (controle.cancelado) throw const FalhaAtualizacao('cancelado');
          try {
            await partes?.cancel();
          } catch (_) {
            /* A conexão já caiu. */
          }
          partes = null;
          quedasSeguidas = recebidos > noComeco ? 1 : quedasSeguidas + 1;
          if (quedasSeguidas > tentativas || ++retomadas > _retomadasNoTotal) throw const FalhaAtualizacao('rede');
          await Future.any([Future<void>.delayed(espera), cancelou()]);
        }
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
