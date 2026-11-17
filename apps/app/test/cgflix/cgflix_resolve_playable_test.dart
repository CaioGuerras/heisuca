import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/home/cgflix_actions.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';

// 17/11: o [Assistir] do destaque da TV mandava a SÉRIE ao player e o servidor respondia sem
// versão ("O servidor não mandou nenhuma versão deste vídeo…", bancada googletv-36, run
// 43900149189). O Início da TV agora usa a mesma resolução do celular (cgflixResolvePlayable).

MediaItem _item(String id, MediaKind kind) =>
    MediaItem.jellyfin(id: id, kind: kind, title: id, serverId: 'srv', durationMs: 1400000);

class _Client extends MediaServerClient {
  _Client({this.onDeck, this.episodes = const [], this.onDeckFails = false});
  final MediaItem? onDeck;
  final List<MediaItem> episodes;
  final bool onDeckFails;
  final calls = <String>[];

  @override
  ServerId get serverId => ServerId('srv');
  @override
  MediaBackend get backend => MediaBackend.jellyfin;
  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem)? onItemReady,
  }) async {
    calls.add('onDeck:$id');
    if (onDeckFails) throw StateError('falha de rede');
    return (item: _item(id, MediaKind.show), onDeckEpisode: onDeck);
  }

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    calls.add('descendants:$parentId');
    return episodes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final serie = _item('serie-1', MediaKind.show);

  test('filme, episódio e clipe tocam como estão, sem chamar o servidor', () async {
    final client = _Client();
    for (final kind in [MediaKind.movie, MediaKind.episode, MediaKind.clip]) {
      final item = _item('x-${kind.name}', kind);
      expect(await cgflixResolvePlayable(client, item), same(item));
    }
    expect(client.calls, isEmpty);
  });

  test('série toca o próximo episódio (onDeck), nunca a própria série', () async {
    final e7 = _item('episodio-7', MediaKind.episode);
    final client = _Client(onDeck: e7, episodes: [_item('episodio-1', MediaKind.episode)]);
    final r = await cgflixResolvePlayable(client, serie);
    expect(r, same(e7));
    expect(r!.kind, isNot(MediaKind.show));
    expect(client.calls, ['onDeck:serie-1']);
  });

  test('série sem onDeck toca o 1º episódio', () async {
    final e1 = _item('episodio-1', MediaKind.episode);
    final client = _Client(episodes: [e1, _item('episodio-2', MediaKind.episode)]);
    expect(await cgflixResolvePlayable(client, serie), same(e1));
    expect(client.calls, ['onDeck:serie-1', 'descendants:serie-1']);
  });

  test('onDeck com erro de rede ainda cai no 1º episódio', () async {
    final e1 = _item('episodio-1', MediaKind.episode);
    final client = _Client(episodes: [e1], onDeckFails: true);
    expect(await cgflixResolvePlayable(client, serie), same(e1));
  });

  test('série sem episódio, sem cliente ou outro tipo devolve null (quem chama abre a ficha)', () async {
    expect(await cgflixResolvePlayable(_Client(), serie), isNull);
    expect(await cgflixResolvePlayable(null, serie), isNull);
    expect(await cgflixResolvePlayable(_Client(), _item('temporada-1', MediaKind.season)), isNull);
  });
}
