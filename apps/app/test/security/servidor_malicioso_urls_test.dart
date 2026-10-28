import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/services/jellyfin_client.dart';
import 'package:heisuca/services/jellyfin_mappers.dart';
import 'package:heisuca/utils/media_server_http_client.dart';
import 'package:http/io_client.dart';

import 'malicious_server_harness.dart';

/// P5 lote 4/4b, caso 4: política única de URL vinda do servidor
/// (`JellyfinImageAbsolutizer.resolveServerUrl`):
///  1. esquema != http/https: sempre descartado;
///  2. mesma origem: aceita COM token;
///  3. outra origem http(s): aceita SEM token, salvo host de rede interna
///     (descartado, a menos que o servidor configurado também seja interno);
///  4. servidor https: URL externa http (rebaixamento) é descartada.
void main() {
  const token = 'TOKEN-SECRETO-P5';

  // Resultado esperado de cada linha da tabela.
  const reject = 'descarta';
  const same = 'mesma-origem';
  const ext = 'externa-sem-token';

  String classify(String base, String url) {
    final r = JellyfinImageAbsolutizer.resolveServerUrl(baseUrl: base, urlOrPath: url);
    if (r == null) return reject;
    return r.sameOrigin ? same : ext;
  }

  group('tabela esquema x origem x rede interna x servidor na LAN', () {
    // Servidor público em https.
    const pub = 'https://jf.example.com:8920';
    final publicHttps = <String, String>{
      // regra 1: esquema
      'file:///etc/passwd': reject,
      'content://com.android.providers.contacts/contacts': reject,
      'javascript:alert(1)': reject,
      'data:text/html;base64,PHNjcmlwdD4=': reject,
      'intent:#Intent;action=android.intent.action.CALL;end': reject,
      'ftp://jf.example.com:8920/x': reject,
      '//evil.org/x.jpg': reject,
      r'C:\Windows\win.ini': reject,
      'https:///sem-host': reject,
      // regra 2: mesma origem
      '/Items/1/Images/Primary': same,
      'Items/1/Images/Primary': same,
      '$pub/Items/1/Images/Primary': same,
      'HTTPS://JF.EXAMPLE.COM:8920/x': same,
      // regra 3: outra origem pública
      'https://cdn.example.org/logo.png': ext,
      'https://jf.example.com/x.jpg': ext, // porta padrão != 8920
      'https://jf.example.com.evil.org:8920/x.jpg': ext,
      'https://evil.example.org/x.jpg?api_key=abc': ext,
      // user:senha@ nunca acompanha URL de terceiros
      'https://jf.example.com:8920@evil.org/x.jpg': reject,
      'https://user:pw@cdn.example.org/x': reject,
      // regra 3: rede interna (servidor público)
      'https://127.0.0.1/x.jpg': reject,
      'https://127.1.2.3/x.jpg': reject,
      'https://localhost/x.jpg': reject,
      'https://a.localhost/x.jpg': reject,
      'https://[::1]/x.jpg': reject,
      'https://169.254.169.254/latest/meta-data/': reject,
      'https://[fe80::1]/x': reject,
      'https://10.0.0.1/admin': reject,
      'https://172.16.0.1/x': reject,
      'https://172.31.255.255/x': reject,
      'https://192.168.0.1/x.jpg': reject,
      'https://100.64.0.1/x': reject,
      'https://100.127.255.254/x': reject,
      'https://[fd00::1]/x': reject,
      'https://[fc00::1]/x': reject,
      'https://0.0.0.0/x': reject,
      'https://[::]/x': reject,
      'https://[::ffff:127.0.0.1]/x': reject,
      'https://printer.local/x': reject,
      'https://nas.lan/x': reject,
      'https://intranet/x': reject,
      'https://2130706433/x': reject, // 127.0.0.1 em decimal
      'https://0x7f.0.0.1/x': reject,
      'https://0177.0.0.1/x': reject,
      // fora das faixas internas: aceita
      'https://172.15.0.1/x': ext,
      'https://172.32.0.1/x': ext,
      'https://100.63.0.1/x': ext,
      'https://100.128.0.1/x': ext,
      'https://8.8.8.8/x': ext,
      // regra 4: rebaixamento
      'http://cdn.example.org/logo.png': reject,
      'http://jf.example.com:8920/x.jpg': reject,
    };
    publicHttps.forEach((url, expected) {
      test('servidor https público: $url -> $expected', () => expect(classify(pub, url), expected));
    });

    // Servidor público em http: sem exigência de https para externas.
    test('servidor http público aceita externa http, mas não interna', () {
      const httpPub = 'http://jf.example.com:8096';
      expect(classify(httpPub, 'http://cdn.example.org/x.png'), ext);
      expect(classify(httpPub, 'https://cdn.example.org/x.png'), ext);
      expect(classify(httpPub, 'http://169.254.169.254/x'), reject);
      expect(classify(httpPub, 'http://192.168.1.1/x'), reject);
      expect(classify(httpPub, 'file:///x'), reject);
    });

    // Servidor na LAN: rede interna é aceita (sem token), esquemas ruins não.
    final lan = <String, String>{
      'http://192.168.1.10:8096/Items/1/Images/Primary': same,
      '/Items/1/Images/Primary': same,
      'http://192.168.1.20:8096/x.jpg': ext,
      'http://192.168.1.10:9999/x.jpg': ext,
      'http://169.254.169.254/latest/meta-data/': ext,
      'https://127.0.0.1/x': ext,
      'http://nas.local/x': ext,
      'http://cdn.example.org/x.png': ext,
      'file:///etc/passwd': reject,
      'content://x/y': reject,
      'javascript:alert(1)': reject,
      'data:text/plain,a': reject,
      '//evil.org/x': reject,
      'http://user:pw@192.168.1.20/x': reject,
    };
    lan.forEach((url, expected) {
      test('servidor na LAN (http://192.168.1.10:8096): $url -> $expected', () {
        expect(classify('http://192.168.1.10:8096', url), expected);
      });
    });

    test('servidor https em nome interno também conta como LAN', () {
      expect(classify('https://jellyfin.local:8920', 'https://10.0.0.5/x'), ext);
      expect(classify('https://jellyfin.local:8920', 'http://10.0.0.5/x'), reject); // rebaixamento
    });
  });

  group('JellyfinImageAbsolutizer', () {
    const absolutizer = JellyfinImageAbsolutizer(baseUrl: 'https://jf.example.com:8920', accessToken: token);
    const base = 'https://jf.example.com:8920';

    test('descartados viram null; externos passam intactos e SEM token', () {
      for (final url in ['file:///etc/passwd', 'http://169.254.169.254/x', 'javascript:alert(1)', '//evil.org/x']) {
        expect(absolutizer.absolutize(url), isNull, reason: url);
      }
      expect(absolutizer.absolutize('https://cdn.example.org/logo.png?w=10'), 'https://cdn.example.org/logo.png?w=10');
    });

    test('caminho relativo ganha base + api_key; mesma origem passa', () {
      expect(
        absolutizer.absolutize('/Items/1/Images/Primary?tag=a'),
        '$base/Items/1/Images/Primary?tag=a&api_key=$token',
      );
      expect(absolutizer.absolutize('$base/Items/1/Images/Primary'), '$base/Items/1/Images/Primary');
    });

    test('applyTo descarta o proibido, mantém o externo sem token e nunca lança', () {
      final item = JellyfinMappers.mediaItem(
        {'Id': 'a', 'Name': 'x', 'Type': 'Movie'},
        serverId: ServerId('s'),
        absolutizer: absolutizer,
      )!;
      final hostile = item.copyWith(
        thumbPath: 'file:///etc/passwd',
        artPath: 'http://169.254.169.254/x',
        backdropPaths: ['https://cdn.example.org/a.jpg', '/Items/a/Images/Backdrop', 'content://x'],
        clearLogoPath: 'javascript:alert(1)',
      );
      final MediaItem out = absolutizer.applyTo(hostile);
      expect(out.thumbPath, isNull);
      expect(out.clearLogoPath, isNull);
      expect(out.backdropPaths, ['https://cdn.example.org/a.jpg', '$base/Items/a/Images/Backdrop?api_key=$token']);
      expect(out.toString().contains('169.254'), isFalse);
    });
  });

  group('com o servidor Jellyfin falso e um servidor "estrangeiro" que grava cabeçalhos', () {
    late MaliciousServer server;
    late MaliciousServer foreign;
    late JellyfinClient client;

    // Servidor e estrangeiro estão em loopback: o servidor configurado também é
    // de rede interna, então a regra 3 aceita o estrangeiro (sem token).
    String foreignUrl(String path) => 'http://localhost:${foreign.port}$path';

    setUp(() async {
      initCache();
      server = await MaliciousServer.start();
      foreign = await MaliciousServer.start();
      foreign.routes['/img.png'] = (r) => r.response.write('png');
      foreign.routes['/sub.srt'] = (r) => r.response.write('1\n00:00:01,000 --> 00:00:02,000\noi\n');
      client = await clientFor(server.baseUrl);
    });
    tearDown(() async {
      client.close();
      await server.stop();
      await foreign.stop();
      await closeCache();
    });

    void expectNoCredentials(MaliciousServer s) {
      for (final r in s.seen) {
        expect(r.headers.keys.map((k) => k.toLowerCase()), isNot(contains('x-emby-token')));
        expect(r.headers.keys.map((k) => k.toLowerCase()), isNot(contains('authorization')));
        expect(r.headers.keys.map((k) => k.toLowerCase()), isNot(contains('x-emby-authorization')));
        expect(r.carriesToken(maliciousTestToken), isFalse, reason: '${r.uri} ${r.headers}');
      }
    }

    test('thumbnailUrl/externalImageUrl: externa volta sem token; proibida vira vazio', () {
      final external = foreignUrl('/img.png');
      expect(client.thumbnailUrl(external, width: 100, height: 100), external);
      expect(client.externalImageUrl(external), external);
      for (final bad in ['file:///etc/passwd', 'content://x/y', 'javascript:alert(1)', 'data:text/plain,a']) {
        expect(client.thumbnailUrl(bad), isEmpty, reason: bad);
        expect(client.externalImageUrl(bad), isEmpty, reason: bad);
      }
      expect(
        client.thumbnailUrl('/Items/1/Images/Primary'),
        allOf(startsWith(server.baseUrl), contains(maliciousTestToken)),
      );
    });

    test('baixar imagem/legenda externa pelo cliente HTTP não leva cabeçalho de credencial', () async {
      // Cliente COM cabeçalhos de autenticação por padrão, como o do Jellyfin.
      final http = MediaServerHttpClient(
        client: IOClient(HttpClient()),
        baseUrl: server.baseUrl,
        defaultHeaders: {
          'X-Emby-Token': maliciousTestToken,
          'Authorization': 'MediaBrowser Token="$maliciousTestToken"',
          'Accept': 'application/json',
        },
      );
      addTearDown(http.close);
      await http.getBytes(foreignUrl('/img.png'));
      await http.getBytes(foreignUrl('/sub.srt'));
      final dir = await Directory.systemTemp.createTemp('p5_sub_');
      addTearDown(() => dir.delete(recursive: true));
      await http.downloadFile(foreignUrl('/sub.srt'), '${dir.path}/s.srt');
      expect(foreign.seen.length, 3);
      expectNoCredentials(foreign);
      // Sanidade: para o próprio servidor os cabeçalhos continuam indo.
      server.routes['/ok'] = (r) => r.response.write('ok');
      await http.getBytes('${server.baseUrl}/ok');
      expect(server.seen.single.headers['x-emby-token'], maliciousTestToken);
    });

    test('legenda externa de outro host no download: URL sem token; a do servidor, com token', () async {
      server.jsonObject('/Users/user-1/Items/vid', {
        'Id': 'vid',
        'Name': 'Filme',
        'Type': 'Movie',
        'MediaSources': [
          {'Id': 'src', 'Container': 'mkv', 'MediaStreams': []},
        ],
      });
      server.jsonObject('/Items/vid/PlaybackInfo', {
        'MediaSources': [
          {
            'Id': 'src',
            'MediaStreams': [
              {
                'Type': 'Subtitle',
                'Index': 1,
                'IsExternal': true,
                'Codec': 'srt',
                'DeliveryUrl': foreignUrl('/sub.srt'),
              },
              {'Type': 'Subtitle', 'Index': 2, 'IsExternal': true, 'Codec': 'srt', 'DeliveryUrl': 'file:///etc/passwd'},
              {'Type': 'Subtitle', 'Index': 3, 'IsExternal': true, 'Codec': 'srt', 'DeliveryUrl': 'content://x/y'},
              {
                'Type': 'Subtitle',
                'Index': 4,
                'IsExternal': true,
                'Codec': 'srt',
                'DeliveryUrl': 'javascript:alert(1)',
              },
              {
                'Type': 'Subtitle',
                'Index': 5,
                'IsExternal': true,
                'Codec': 'srt',
                'DeliveryUrl': '/Videos/vid/src/Subtitles/5/Stream.srt',
              },
            ],
          },
        ],
      });
      final item = await client.fetchItem('vid');
      final resolution = await client.resolveDownload(item!);
      final byId = {for (final s in resolution.externalSubtitles) s.id: s.url};
      expect(byId.keys.toSet(), {1, 5});
      expect(byId[1], foreignUrl('/sub.srt'));
      expect(byId[1]!.contains(maliciousTestToken), isFalse);
      expect(byId[5], contains(maliciousTestToken));
      expect(Uri.parse(byId[5]!).origin, Uri.parse(server.baseUrl).origin);
    });

    test('PlaybackInfo com MediaSources de tipo errado não lança erro não tratado', () async {
      server.jsonObject('/Users/user-1/Items/vid', {'Id': 'vid', 'Name': 'Filme', 'Type': 'Movie'});
      server.jsonObject('/Items/vid/PlaybackInfo', {
        'MediaSources': {'x': 1},
      });
      final item = await client.fetchItem('vid');
      try {
        await client.resolveDownload(item!);
      } on Exception {
        // erro tratado
      }
    });

    test('nenhum pedido ao estrangeiro carregou o token (resumo)', () {
      expectNoCredentials(foreign);
    });
  });
}
