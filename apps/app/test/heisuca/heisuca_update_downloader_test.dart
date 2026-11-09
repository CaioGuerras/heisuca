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
}
