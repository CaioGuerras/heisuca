import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:heisuca/services/updates/update_feed_client.dart';
import 'package:heisuca/services/updates/update_downloader.dart';

class _ClienteComFalhaNaLimpeza extends http.BaseClient {
  int chamadas = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (chamadas++ > 0) return http.StreamedResponse(Stream.value(List<int>.generate(128, (i) => i)), 200);
    late StreamController<List<int>> fluxo;
    fluxo = StreamController(
      onListen: () => fluxo.add(List<int>.generate(128, (i) => i)),
      onCancel: () {
        unawaited(fluxo.close());
        throw StateError('falha sintética ao encerrar o fluxo');
      },
    );
    return http.StreamedResponse(fluxo.stream, 200);
  }
}

/// Servidor de mentira para quedas: cada pedido devolve o que o teste mandar e anota o `Range` recebido.
class _ClienteQueCai extends http.BaseClient {
  _ClienteQueCai(this.responder);
  final http.StreamedResponse Function(int pedido, String? range) responder;
  final ranges = <String?>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    ranges.add(request.headers['range']);
    return responder(ranges.length, request.headers['range']);
  }
}

/// Entrega [bytes] e derruba a conexão em seguida.
Stream<List<int>> _cai(List<int> bytes) async* {
  if (bytes.isNotEmpty) yield bytes;
  throw const SocketException('conexão caiu');
}

void main() {
  final conteudo = List<int>.generate(128, (i) => i);
  late Directory cache;
  late ApkAtualizacao apk;
  final config = ConfiguracaoAtualizacao(feed: 'https://feed.example/');
  setUp(() async {
    cache = await Directory.systemTemp.createTemp('heisuca-update-teste-');
    apk = ApkAtualizacao(
      'universal',
      Uri.parse('https://feed.example/app.apk'),
      conteudo.length,
      sha256.convert(conteudo).toString(),
    );
  });
  UpdateDownloader criar(http.Client client, {int livre = 1024 * 1024 * 1024}) => UpdateDownloader(
    cliente: UpdateFeedClient(config, cliente: client),
    cache: () async => cache,
    espacoLivre: () async => livre,
  );
  Future<List<FileSystemEntity>> arquivos() async =>
      await Directory('${cache.path}/updates').exists() ? Directory('${cache.path}/updates').list().toList() : [];

  test('baixa em fluxo, confere tamanho/hash e informa progresso', () async {
    final progresso = <int>[];
    final baixado = await criar(MockClient((_) async => http.Response.bytes(conteudo, 200))).baixar(
      apk,
      progresso: (bytes, total) {
        expect(total, 128);
        progresso.add(bytes);
      },
    );
    expect(await baixado.readAsBytes(), conteudo);
    expect(baixado.path, endsWith('.apk'));
    expect(progresso.last, 128);
    expect((await arquivos()).where((f) => f.path.endsWith('.part')), isEmpty);
  });
  test('SHA inválido remove o arquivo e permite repetir', () async {
    final downloader = criar(MockClient((_) async => http.Response.bytes(conteudo, 200)));
    await expectLater(
      downloader.baixar(ApkAtualizacao(apk.abi, apk.url, apk.bytes, '0' * 64)),
      throwsA(isA<FalhaAtualizacao>().having((e) => e.codigo, 'causa', 'arquivoInvalido')),
    );
    expect(await arquivos(), isEmpty);
    expect(await (await downloader.baixar(apk)).length(), 128);
  });
  test('tamanho truncado ou excedente é recusado e removido', () async {
    for (final bytes in [127, 129]) {
      await expectLater(
        criar(
          MockClient((_) async => http.Response.bytes(conteudo, 200)),
        ).baixar(ApkAtualizacao(apk.abi, apk.url, bytes, apk.sha256)),
        throwsA(isA<FalhaAtualizacao>()),
      );
      expect(await arquivos(), isEmpty);
    }
  });
  test('pouco espaço é informado antes de qualquer requisição', () async {
    var chamadas = 0;
    await expectLater(
      criar(
        MockClient((_) async {
          chamadas++;
          return http.Response.bytes(conteudo, 200);
        }),
        livre: 127,
      ).baixar(apk),
      throwsA(isA<FalhaAtualizacao>().having((e) => e.codigo, 'causa', 'espaco')),
    );
    expect(chamadas, 0);
    expect(await arquivos(), isEmpty);
  });
  test('cancelar antes de começar não abre rede', () async {
    var chamadas = 0;
    final cancelamento = CancelamentoAtualizacao()..cancelar();
    await expectLater(
      criar(
        MockClient((_) async {
          chamadas++;
          return http.Response.bytes(conteudo, 200);
        }),
      ).baixar(apk, cancelamento: cancelamento),
      throwsA(isA<FalhaAtualizacao>()),
    );
    expect(chamadas, 0);
  });
  test('cancelar aguardando cabeçalhos encerra sem arquivo', () async {
    final resposta = Completer<http.Response>();
    final pedido = Completer<void>();
    final cancelamento = CancelamentoAtualizacao();
    final futuro = criar(
      MockClient((_) {
        pedido.complete();
        return resposta.future;
      }),
    ).baixar(apk, cancelamento: cancelamento);
    final espera = expectLater(futuro, throwsA(isA<FalhaAtualizacao>().having((e) => e.codigo, 'causa', 'cancelado')));
    await pedido.future.timeout(const Duration(seconds: 2));
    cancelamento.cancelar();
    await espera.timeout(const Duration(seconds: 2));
    resposta.complete(http.Response.bytes(conteudo, 200));
    expect(await arquivos(), isEmpty);
  });
  test('cancelar durante o download remove o parcial', () async {
    final cancelamento = CancelamentoAtualizacao();
    await expectLater(
      criar(
        MockClient((_) async => http.Response.bytes(conteudo, 200)),
      ).baixar(apk, cancelamento: cancelamento, progresso: (_, _) => cancelamento.cancelar()),
      throwsA(isA<FalhaAtualizacao>()),
    );
    expect(await arquivos(), isEmpty);
  });
  test('redirect para HTTP ou host estranho não faz segunda requisição', () async {
    for (final destino in ['http://feed.example/app.apk', 'https://estranho.example/app.apk']) {
      var chamadas = 0;
      await expectLater(
        criar(
          MockClient((_) async {
            chamadas++;
            return http.Response('', 302, headers: {'location': destino});
          }),
        ).baixar(apk),
        throwsA(isA<FalhaAtualizacao>()),
      );
      expect(chamadas, 1);
      expect(await arquivos(), isEmpty);
    }
  });
  test('erro ao encerrar o fluxo não deixa parcial nem impede nova tentativa', () async {
    final cancelamento = CancelamentoAtualizacao();
    final downloader = criar(_ClienteComFalhaNaLimpeza());
    await expectLater(
      downloader.baixar(apk, cancelamento: cancelamento, progresso: (_, _) => cancelamento.cancelar()),
      throwsA(isA<FalhaAtualizacao>()),
    );
    expect(await arquivos(), isEmpty);
    expect(await (await downloader.baixar(apk)).length(), 128);
  });
  group('queda de rede no meio do download', () {
    UpdateDownloader comQuedas(http.Client client, {int tentativas = 4}) => UpdateDownloader(
      cliente: UpdateFeedClient(config, cliente: client),
      cache: () async => cache,
      espacoLivre: () async => 1024 * 1024 * 1024,
      tentativas: tentativas,
      espera: Duration.zero,
    );

    test('retoma de onde parou, pedindo só o resto, e o arquivo fecha com o SHA certo', () async {
      final cliente = _ClienteQueCai(
        (pedido, range) => pedido == 1
            ? http.StreamedResponse(_cai(conteudo.sublist(0, 50)), 200, contentLength: 128)
            : http.StreamedResponse(
                Stream.value(conteudo.sublist(50)),
                206,
                contentLength: 78,
                headers: {'content-range': 'bytes 50-127/128'},
              ),
      );
      final progresso = <int>[];
      final baixado = await comQuedas(cliente).baixar(apk, progresso: (bytes, _) => progresso.add(bytes));

      expect(cliente.ranges, [null, 'bytes=50-']);
      expect(await baixado.readAsBytes(), conteudo);
      expect(progresso, [50, 128]);
      expect((await arquivos()).map((a) => a.path.split('.').last), ['apk']);
    });

    test('servidor que ignora o pedido de resto e manda tudo de novo: recomeça do zero, sem misturar', () async {
      final cliente = _ClienteQueCai(
        (pedido, range) => pedido == 1
            ? http.StreamedResponse(_cai(conteudo.sublist(0, 50)), 200, contentLength: 128)
            : http.StreamedResponse(Stream.value(conteudo), 200, contentLength: 128),
      );

      final baixado = await comQuedas(cliente).baixar(apk);

      expect(cliente.ranges, [null, 'bytes=50-']);
      expect(await baixado.readAsBytes(), conteudo);
    });

    test('quedas seguidas sem receber nada: desiste com falha de rede, não de arquivo, e não deixa parcial', () async {
      final cliente = _ClienteQueCai((pedido, range) => http.StreamedResponse(_cai(const []), 200, contentLength: 128));

      await expectLater(
        comQuedas(cliente, tentativas: 2).baixar(apk),
        throwsA(isA<FalhaAtualizacao>().having((f) => f.codigo, 'codigo', 'rede')),
      );

      expect(cliente.ranges, hasLength(3));
      expect(await arquivos(), isEmpty);
    });

    test('queda com progresso zera a conta de quedas seguidas', () async {
      // Cai a cada 40 bytes: são 3 quedas, mais do que as 2 seguidas permitidas, mas todas com progresso.
      final cliente = _ClienteQueCai((pedido, range) {
        final inicio = (pedido - 1) * 40;
        if (pedido <= 3) {
          return http.StreamedResponse(
            _cai(conteudo.sublist(inicio, inicio + 40)),
            pedido == 1 ? 200 : 206,
            contentLength: 128 - inicio,
          );
        }
        return http.StreamedResponse(Stream.value(conteudo.sublist(120)), 206, contentLength: 8);
      });

      final baixado = await comQuedas(cliente, tentativas: 2).baixar(apk);

      expect(cliente.ranges, [null, 'bytes=40-', 'bytes=80-', 'bytes=120-']);
      expect(await baixado.readAsBytes(), conteudo);
    });

    test('resto que começa no lugar errado é recusado como arquivo inválido', () async {
      final cliente = _ClienteQueCai(
        (pedido, range) => pedido == 1
            ? http.StreamedResponse(_cai(conteudo.sublist(0, 50)), 200, contentLength: 128)
            : http.StreamedResponse(
                Stream.value(conteudo.sublist(50)),
                206,
                contentLength: 78,
                headers: {'content-range': 'bytes 0-77/128'},
              ),
      );

      await expectLater(
        comQuedas(cliente).baixar(apk),
        throwsA(isA<FalhaAtualizacao>().having((f) => f.codigo, 'codigo', 'arquivoInvalido')),
      );
      expect(await arquivos(), isEmpty);
    });

    test('resposta definitiva do servidor (404) não é tentada de novo', () async {
      final cliente = _ClienteQueCai((pedido, range) => http.StreamedResponse(const Stream.empty(), 404));

      await expectLater(
        comQuedas(cliente).baixar(apk),
        throwsA(isA<FalhaAtualizacao>().having((f) => f.codigo, 'codigo', 'arquivoInvalido')),
      );
      expect(cliente.ranges, hasLength(1));
    });

    test('cancelar durante a pausa entre tentativas encerra como cancelado', () async {
      final cancelamento = CancelamentoAtualizacao();
      final cliente = _ClienteQueCai((pedido, range) {
        scheduleMicrotask(cancelamento.cancelar);
        return http.StreamedResponse(_cai(conteudo.sublist(0, 10)), 200, contentLength: 128);
      });
      final downloader = UpdateDownloader(
        cliente: UpdateFeedClient(config, cliente: cliente),
        cache: () async => cache,
        espacoLivre: () async => 1024 * 1024 * 1024,
        espera: const Duration(seconds: 30),
      );

      await expectLater(
        downloader.baixar(apk, cancelamento: cancelamento),
        throwsA(isA<FalhaAtualizacao>().having((f) => f.codigo, 'codigo', 'cancelado')),
      );
      expect(await arquivos(), isEmpty);
    });
  });
}
