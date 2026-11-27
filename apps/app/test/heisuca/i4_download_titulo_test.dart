import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/features/titulo/ligacao.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_file_info.dart';
import 'package:heisuca/media/media_hub.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/providers/download_provider.dart';
import 'package:heisuca/utils/download_version_utils.dart';

import '../design/componentes/apoio.dart';

class _Servidor extends MediaServerClient {
  _Servidor(this.item);
  final MediaItem item;

  @override
  ServerId get serverId => ServerId(item.serverId!);
  @override
  MediaBackend get backend => item.backend;
  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem)? onItemReady,
  }) async => (item: item, onDeckEpisode: null);
  @override
  Future<MediaItem?> fetchItem(String id) async => item;
  @override
  Future<MediaFileInfo?> getFileInfo(MediaItem item) async => null;
  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Fila extends ChangeNotifier implements DownloadProvider {
  final pedidos = <({MediaItem item, MediaServerClient cliente})>[];

  @override
  Future<int> queueDownload(
    MediaItem metadata,
    MediaServerClient client, {
    DownloadVersionConfig? versionConfig,
    DownloadFilter filter = DownloadFilter.all,
    int? maxCount,
    bool includeSpecials = true,
  }) async {
    pedidos.add((item: metadata, cliente: client));
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  for (final backend in [MediaBackend.plex, MediaBackend.jellyfin]) {
    testWidgets('I4: Baixar na ficha enfileira o filme e o cliente de ${backend.name}', (tester) async {
      tester.view.physicalSize = const Size(412, 914);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final item = backend == MediaBackend.plex
          ? MediaItem.plex(id: 'filme-plex', kind: MediaKind.movie, title: 'Filme Plex', serverId: 'plex')
          : MediaItem.jellyfin(
              id: 'filme-jellyfin',
              kind: MediaKind.movie,
              title: 'Filme Jellyfin',
              serverId: 'jellyfin',
            );
      final servidor = _Servidor(item);
      final fila = _Fila();
      addTearDown(fila.dispose);
      final itensConsultados = <MediaItem>[];
      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadProvider>.value(
          value: fila,
          child: naTela(
            LigacaoDoTitulo(
              item: item,
              clienteDe: (_, consultado) {
                itensConsultados.add(consultado);
                return servidor;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Mais opções'));
      await tester.pumpAndSettle();
      expect(fila.pedidos, isEmpty);
      itensConsultados.clear();
      await tester.tap(find.text('Baixar filme'));
      await tester.pumpAndSettle();
      expect(itensConsultados, contains(same(item)));
      expect(fila.pedidos, hasLength(1));
      expect(fila.pedidos.single.item, same(item));
      expect(fila.pedidos.single.cliente, same(servidor));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
