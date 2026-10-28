import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/services/jellyfin_client.dart';
import 'package:heisuca/services/jellyfin_mappers.dart';
import 'package:heisuca/media/media_item.dart';

import 'malicious_server_harness.dart';

/// P5 lote 4, caso 4: URLs absolutas vindas do servidor. O app só busca
/// http(s) da MESMA origem do servidor configurado; o resto é descartado sem
/// crash e o token (api_key) jamais acompanha uma URL de outra origem.
void main() {
  const base = 'https://jf.example.com:8920';
  const token = 'TOKEN-SECRETO-P5';

  final foreign = <String>[
    'file:///etc/passwd',
    'content://com.android.providers.contacts/contacts',
    'javascript:alert(1)',
    'data:text/html;base64,PHNjcmlwdD4=',
    'http://169.254.169.254/latest/meta-data/',
    'https://169.254.169.254/latest/meta-data/',
    'http://10.0.0.1/admin',
    'http://192.168.0.1/x.jpg',
    'http://127.0.0.1:9999/x.jpg',
    'https://evil.example.org/x.jpg?api_key=abc',
    'https://jf.example.com/x.jpg', // mesma máquina, porta diferente (443 x 8920)
    'http://jf.example.com:8920/x.jpg', // esquema diferente
    'https://jf.example.com.evil.org:8920/x.jpg',
    'https://jf.example.com:8920@evil.org/x.jpg',
    '//evil.org/x.jpg',
    'ftp://jf.example.com:8920/x',
    r'C:\Windows\win.ini',
  ];

  group('JellyfinImageAbsolutizer', () {
    const absolutizer = JellyfinImageAbsolutizer(baseUrl: base, accessToken: token);

    test('URL de outra origem/esquema é descartada e não recebe o token', () {
      for (final url in foreign) {
        final out = absolutizer.absolutize(url);
        expect(out, isNull, reason: url);
      }
    });

    test('caminho relativo ganha base + api_key; URL da mesma origem passa', () {
      expect(
        absolutizer.absolutize('/Items/1/Images/Primary?tag=a'),
        '$base/Items/1/Images/Primary?tag=a&api_key=$token',
      );
      expect(absolutizer.absolutize('$base/Items/1/Images/Primary'), '$base/Items/1/Images/Primary');
    });

    test('applyTo descarta imagens estrangeiras sem lançar', () {
      final item = JellyfinMappers.mediaItem(
        {'Id': 'a', 'Name': 'x', 'Type': 'Movie'},
        serverId: ServerId('s'),
        absolutizer: absolutizer,
      )!;
      final hostile = item.copyWith(
        thumbPath: 'file:///etc/passwd',
        artPath: 'http://169.254.169.254/x',
        backdropPaths: ['https://evil.org/a.jpg', '/Items/a/Images/Backdrop'],
        clearLogoPath: 'javascript:alert(1)',
      );
      final MediaItem out = absolutizer.applyTo(hostile);
      expect(out.thumbPath, isNull);
      expect(out.clearLogoPath, isNull);
      expect(out.backdropPaths, ['$base/Items/a/Images/Backdrop?api_key=$token']);
      expect(out.toString().contains('evil.org'), isFalse);
      expect(out.toString().contains('169.254'), isFalse);
    });
  });

  group('JellyfinClient com URL absoluta hostil', () {
    late MaliciousServer server;
    late JellyfinClient client;

    setUp(() async {
      initCache();
      server = await MaliciousServer.start();
      client = await clientFor(server.baseUrl);
    });
    tearDown(() async {
      client.close();
      await server.stop();
      await closeCache();
    });

    test('thumbnailUrl/externalImageUrl não devolvem URL estrangeira nem anexam o token', () {
      for (final url in foreign) {
        final thumb = client.thumbnailUrl(url, width: 100, height: 100);
        expect(thumb.contains(maliciousTestToken), isFalse, reason: url);
        expect(thumb, isEmpty, reason: url);
        expect(client.externalImageUrl(url), isEmpty, reason: url);
      }
      expect(client.thumbnailUrl('/Items/1/Images/Primary'), startsWith(server.baseUrl));
    });

    test('legenda externa com DeliveryUrl hostil é descartada no download', () async {
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
              for (var i = 0; i < foreign.length; i++)
                {'Type': 'Subtitle', 'Index': i, 'IsExternal': true, 'Codec': 'srt', 'DeliveryUrl': foreign[i]},
              {
                'Type': 'Subtitle',
                'Index': 99,
                'IsExternal': true,
                'Codec': 'srt',
                'DeliveryUrl': '/Videos/vid/src/Subtitles/99/Stream.srt',
              },
            ],
          },
        ],
      });
      final item = await client.fetchItem('vid');
      final resolution = await client.resolveDownload(item!);
      final urls = resolution.externalSubtitles.map((s) => s.url).toList();
      expect(urls, hasLength(1), reason: urls.toString());
      expect(urls.single, startsWith(server.baseUrl));
      for (final url in urls) {
        expect(Uri.parse(url).origin, Uri.parse(server.baseUrl).origin);
      }
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

    test('nenhum pedido ao servidor falso carrega o token para outra origem', () async {
      // Sanidade do harness: todo pedido visto aqui é do servidor configurado.
      server.jsonObject('/Users/user-1/Items/a', {'Id': 'a', 'Name': 'x', 'Type': 'Movie'});
      await client.fetchItem('a');
      expect(server.seen, isNotEmpty);
      expect(server.seen.first.headers['x-emby-token'], maliciousTestToken);
    });
  });
}
