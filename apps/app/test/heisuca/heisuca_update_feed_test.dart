import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:heisuca/services/updates/update_feed_client.dart';
import 'package:heisuca/services/updates/update_checker.dart';

Map<String, Object?> feed({String canal = 'estavel', int build = 43}) => {
  'canal': canal,
  'versao': '2.0.35',
  'build': build,
  'notas': 'Melhorias na TV.',
  'assinatura_sha256': 'a' * 64,
  'apks': [
    {'abi': 'universal', 'url': 'https://apk.example/app.apk', 'bytes': 128, 'sha256': 'b' * 64},
  ],
};

void main() {
  final config = ConfiguracaoAtualizacao(feed: 'https://feed.example/atualizacoes/', hostsApk: 'apk.example');
  test('sem configuração ou na Play fica desligado e não consulta a rede', () async {
    var chamadas = 0;
    final httpClient = MockClient((_) async {
      chamadas++;
      return http.Response('{}', 200);
    });
    for (final c in [
      ConfiguracaoAtualizacao(),
      ConfiguracaoAtualizacao(feed: 'http://feed.example'),
      ConfiguracaoAtualizacao(feed: 'https://feed.example', distribuicao: 'play'),
    ]) {
      expect(await UpdateFeedClient(c, cliente: httpClient).consultar('estavel'), isNull);
    }
    expect(chamadas, 0);
  });
  test('feed válido preserva os campos e restringe os destinos', () async {
    final client = UpdateFeedClient(
      config,
      cliente: MockClient((r) async {
        expect(r.url.toString(), 'https://feed.example/atualizacoes/estavel/latest.json');
        expect(r.followRedirects, isFalse);
        return http.Response(jsonEncode(feed()), 200);
      }),
    );
    final oferta = (await client.consultar('estavel'))!;
    expect(oferta.build, 43);
    expect(oferta.versao, '2.0.35');
    expect(oferta.apks.single.bytes, 128);
    expect(oferta.assinatura, 'a' * 64);
  });
  for (final campo in ['canal', 'versao', 'build', 'notas', 'assinatura_sha256', 'apks']) {
    test('rejeita campo obrigatório ausente: $campo', () async {
      final dados = feed()..remove(campo);
      final client = UpdateFeedClient(config, cliente: MockClient((_) async => http.Response(jsonEncode(dados), 200)));
      await expectLater(client.consultar('estavel'), throwsFormatException);
    });
  }
  for (final url in [
    'http://apk.example/a.apk',
    'https://outro.example/a.apk',
    'https://senha@apk.example/a.apk',
    'https://apk.example:444/a.apk',
  ]) {
    test('rejeita URL de APK não autorizada: $url', () async {
      final dados = feed();
      (dados['apks'] as List).single['url'] = url;
      await expectLater(
        UpdateFeedClient(
          config,
          cliente: MockClient((_) async => http.Response(jsonEncode(dados), 200)),
        ).consultar('estavel'),
        throwsFormatException,
      );
    });
  }
  test('rejeita JSON grande mesmo sem content-length confiável', () async {
    final client = UpdateFeedClient(config, cliente: MockClient((_) async => http.Response(' ' * 65537, 200)));
    await expectLater(client.consultar('estavel'), throwsFormatException);
  });
  test('redirecionamento do feed não vaza o código para outro host', () async {
    var chamadas = 0;
    final client = UpdateFeedClient(
      config,
      cliente: MockClient((_) async {
        chamadas++;
        return http.Response('', 302, headers: {'location': 'https://apk.example/receber'});
      }),
    );
    await expectLater(client.consultar('teste', codigo: 'codigo-sintetico-sem-credencial-123'), throwsFormatException);
    expect(chamadas, 1);
  });
  test('redirecionamento HTTPS no host do feed é limitado e aceito', () async {
    var chamadas = 0;
    final client = UpdateFeedClient(
      config,
      cliente: MockClient((_) async {
        chamadas++;
        return chamadas == 1
            ? http.Response('', 302, headers: {'location': '/novo/latest.json'})
            : http.Response(jsonEncode(feed()), 200);
      }),
    );
    expect((await client.consultar('estavel'))!.build, 43);
    expect(chamadas, 2);
  });
  test('tipo, canal, assinatura e ABI inválidos são recusados', () async {
    for (final dados in [
      feed()..['build'] = 4.5,
      feed(canal: 'beta'),
      feed()..['assinatura_sha256'] = 'invalida',
      feed()
        ..['apks'] = [
          {'abi': 'errada', 'url': 'https://apk.example/a', 'bytes': -1, 'sha256': 'b' * 64},
        ],
    ]) {
      await expectLater(
        UpdateFeedClient(
          config,
          cliente: MockClient((_) async => http.Response(jsonEncode(dados), 200)),
        ).consultar('estavel'),
        throwsFormatException,
      );
    }
  });
  test('checker aceita somente build maior, nunca downgrade', () async {
    for (final build in [40, 41, 42]) {
      final c = UpdateChecker(
        feed: UpdateFeedClient(
          config,
          cliente: MockClient((_) async => http.Response(jsonEncode(feed(build: build)), 200)),
        ),
        buildInstalado: 41,
        emReproducao: () => false,
        lerUltima: () => null,
        gravarUltima: (_) async {},
      );
      expect((await c.verificar())?.build, build > 41 ? build : null);
    }
  });
  test('beta consulta os dois canais e escolhe o maior; teste fica isolado', () async {
    final canais = <String>[];
    final c = UpdateChecker(
      feed: UpdateFeedClient(
        config,
        cliente: MockClient((r) async {
          final canal = r.url.path.contains('/teste/') ? 'teste' : r.url.pathSegments.reversed.skip(1).first;
          canais.add(canal);
          return http.Response(jsonEncode(feed(canal: canal, build: canal == 'estavel' ? 44 : 43)), 200);
        }),
      ),
      buildInstalado: 41,
      emReproducao: () => false,
      lerUltima: () => null,
      gravarUltima: (_) async {},
      beta: () => true,
    );
    expect((await c.verificar())?.build, 44);
    expect(canais, ['estavel', 'beta']);
    canais.clear();
    final teste = UpdateChecker(
      feed: c.feed,
      buildInstalado: 41,
      emReproducao: () => false,
      lerUltima: () => null,
      gravarUltima: (_) async {},
      beta: () => true,
      codigo: () => 'codigo-sintetico-sem-credencial-123',
    );
    expect((await teste.verificar())?.canal, 'teste');
    expect(canais, ['teste']);
  });
  test('uma verificação por 24h, inclusive falha e chamadas simultâneas', () async {
    var chamadas = 0;
    DateTime? ultima;
    var agora = DateTime.utc(2026, 11, 8);
    UpdateChecker criar() => UpdateChecker(
      feed: UpdateFeedClient(
        config,
        cliente: MockClient((_) async {
          chamadas++;
          return http.Response('', 503);
        }),
      ),
      buildInstalado: 41,
      emReproducao: () => false,
      lerUltima: () => ultima,
      gravarUltima: (v) async {
        ultima = v;
      },
      agora: () => agora,
    );
    final c = criar();
    await Future.wait([c.verificar(), c.verificar()]);
    expect(c.falhou, isTrue);
    await criar().verificar();
    expect(chamadas, 1);
    agora = agora.add(const Duration(hours: 24));
    await criar().verificar();
    expect(chamadas, 2);
  });
  test('não consulta nem marca data durante reprodução ou com feed desligado', () async {
    var chamadas = 0;
    var escritas = 0;
    final cliente = MockClient((_) async {
      chamadas++;
      return http.Response('{}', 200);
    });
    for (final ligado in [true, false]) {
      await UpdateChecker(
        feed: UpdateFeedClient(ligado ? config : ConfiguracaoAtualizacao(), cliente: cliente),
        buildInstalado: 41,
        emReproducao: () => ligado,
        lerUltima: () => null,
        gravarUltima: (_) async {
          escritas++;
        },
      ).verificar();
    }
    expect(chamadas, 0);
    expect(escritas, 0);
  });
  test('reprodução iniciada durante a consulta descarta a oferta e impede a segunda consulta', () async {
    var reproduzindo = false;
    var chamadas = 0;
    final c = UpdateChecker(
      feed: UpdateFeedClient(
        config,
        cliente: MockClient((_) async {
          chamadas++;
          reproduzindo = true;
          return http.Response(jsonEncode(feed()), 200);
        }),
      ),
      buildInstalado: 41,
      emReproducao: () => reproduzindo,
      beta: () => true,
      lerUltima: () => null,
      gravarUltima: (_) async {},
    );
    expect(await c.verificar(), isNull);
    expect(chamadas, 1);
  });
}
