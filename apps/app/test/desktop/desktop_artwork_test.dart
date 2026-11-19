import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/ui/desktop_artwork.dart';
import 'package:heisuca/desktop/ui/desktop_cinema_home.dart';
import 'package:heisuca/media/media_server_client.dart';

class ArtworkClient implements MediaServerClient {
  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) =>
    width == null ? 'https://fixture.invalid$path' : 'https://fixture.invalid/resize?width=$width&height=$height&path=$path';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class RejectedArtwork extends ImageProvider<RejectedArtwork> {
  @override
  Future<RejectedArtwork> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(RejectedArtwork key, ImageDecoderCallback decode) =>
    OneFrameImageStreamCompleter(Future.error(const HttpException('HTTP 400')));
}
void main() {
  test('redimensionamento sempre tem largura e altura; original precede próximo caminho', () {
    final urls = desktopArtworkUrls(ArtworkClient(), ['/art', '/thumb', '/art'], width: 400, height: 600);
    expect(urls, [
      'https://fixture.invalid/resize?width=400&height=600&path=/art', 'https://fixture.invalid/art',
      'https://fixture.invalid/resize?width=400&height=600&path=/thumb', 'https://fixture.invalid/thumb',
    ]);
  });
  testWidgets('erro400 na imagem redimensionada tenta original em vez de capa vazia', (tester) async {
    final attempted = <String>[];
    final original = MemoryImage(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a53sAAAAASUVORK5CYII='));
    await tester.pumpWidget(MaterialApp(home: DesktopArtwork(urls: const ['resize','original'], headers: const {}, session: Object(),
      fallback: const Text('Sem imagem'), providerBuilder: (url) { attempted.add(url); return url == 'resize' ? RejectedArtwork() : original; })));
    await tester.pumpAndSettle();
    expect(attempted, ['resize','original']);
    expect(find.text('Sem imagem'), findsNothing);
    expect(tester.widget<Image>(find.byType(Image).last).image, original);
    expect(tester.takeException(), isNull);
  });
  test('localização de fileiras não reescreve nomes particulares', () {
    expect(desktopHubTitle('Trending Now'), 'Em alta');
    expect(desktopHubTitle('Recently Added in Anime'), 'Adicionados em Anime');
    expect(desktopHubTitle('Minha coleção'), 'Minha coleção');
  });
}
