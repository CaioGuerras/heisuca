import 'dart:convert';
import 'dart:io' show ContentType;

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/exceptions/media_server_exceptions.dart';
import 'package:heisuca/media/library_query.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/services/jellyfin_client.dart';
import 'package:heisuca/services/jellyfin_mappers.dart' show jellyfinMaxTextLength;

import 'malicious_server_harness.dart';

/// P5 lote 4, caso 1: JSON hostil (tipos errados, nulos, objetos vazios,
/// campos gigantes, listas enormes). Aceite: nada além de resultado normal ou
/// [MediaServerException] escapa do cliente; item ruim é descartado.
void main() {
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

  /// Roda [call]; só resultado ou MediaServerException são aceitáveis.
  Future<void> tolerates(Future<Object?> Function() call) async {
    try {
      await call().timeout(const Duration(seconds: 30));
    } on MediaServerException {
      // erro tratado
    }
  }

  final hostile = <String, Object?>{
    'Id numérico': {'Id': 5, 'Name': 'x', 'Type': 'Movie'},
    'Name numérico': {'Id': 'a', 'Name': 12345, 'Type': 'Movie'},
    'Name lista': {'Id': 'a', 'Name': ['x'], 'Type': 'Movie'},
    'Overview objeto': {'Id': 'a', 'Name': 'x', 'Overview': {'a': 1}, 'Type': 'Movie'},
    'Type nulo': {'Id': 'a', 'Name': null, 'Type': null},
    'MediaSources objeto': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'MediaSources': {}},
    'MediaSources com lixo': {
      'Id': 'a',
      'Name': 'x',
      'Type': 'Movie',
      'MediaSources': [1, null, 'x', {'MediaStreams': 5}, {'MediaStreams': [1, null, {'Index': 'x', 'Type': 5}]}],
    },
    'UserData lista': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'UserData': []},
    'ImageTags lista': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'ImageTags': [1]},
    'ImageTags valor numérico': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'ImageTags': {'Primary': 7}},
    'BackdropImageTags misto': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'BackdropImageTags': [1, null, 'ok']},
    'People lixo': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'People': [1, null, {'Name': 5, 'Id': []}]},
    'Genres lixo': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'Genres': [1, null, {}]},
    'Datas inválidas': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'PremiereDate': 5, 'DateCreated': []},
    'RunTimeTicks texto': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'RunTimeTicks': 'muito', 'ProductionYear': 'x'},
    'ticks gigantes': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'RunTimeTicks': 1e300, 'IndexNumber': 1e300},
    'objeto vazio': <String, Object?>{},
    'Chapters lixo': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'Chapters': [1, null, {'StartPositionTicks': 'x'}]},
    'Trickplay lixo': {'Id': 'a', 'Name': 'x', 'Type': 'Movie', 'Trickplay': {'a': 5, 'b': {'c': 'd'}}},
  };

  group('item hostil em /Users/{u}/Items/{id}', () {
    hostile.forEach((nome, corpo) {
      test(nome, () async {
        server.jsonObject('/Users/user-1/Items/a', corpo);
        await tolerates(() => client.fetchItem('a'));
      });
    });
  });

  group('lista hostil em Items/Views', () {
    final raizes = <String, Object?>{
      'lista no lugar de objeto': [1, 2, 3],
      'Items objeto': {'Items': {}},
      'Items null': {'Items': null},
      'Items texto': {'Items': 'x'},
      'Items misto': {
        'Items': [1, null, 'x', [], {'Id': 'ok', 'Name': 'Bom', 'Type': 'Movie'}, {'Id': 7}],
        'TotalRecordCount': 'muitos',
      },
      'TotalRecordCount gigante': {'Items': [], 'TotalRecordCount': 1e300},
      'null': null,
      'texto': 'texto puro',
      'número': 42,
    };
    raizes.forEach((nome, corpo) {
      test('Views: $nome', () async {
        server.jsonObject('/Users/user-1/Views', corpo);
        await tolerates(() => client.fetchLibraries());
      });
      test('Items (biblioteca): $nome', () async {
        server.jsonObject('/Items', corpo);
        await tolerates(
          () => client.fetchLibraryPagedContent('lib', query: const LibraryQuery(), libraryKind: MediaKind.movie),
        );
      });
      test('filhos: $nome', () async {
        server.jsonObject('/Items', corpo);
        server.jsonObject('/Shows/p/Seasons', corpo);
        await tolerates(() => client.fetchChildren('p'));
      });
    });

    test('item bom sobrevive ao lixo ao lado', () async {
      server.jsonObject('/Items', {
        'Items': [
          1,
          null,
          {'Id': 'ok', 'Name': 'Bom', 'Type': 'Movie'},
          {'Id': 7, 'Name': 'ruim'},
        ],
        'TotalRecordCount': 4,
      });
      final page = await client.fetchLibraryPagedContent(
        'lib',
        query: const LibraryQuery(),
        libraryKind: MediaKind.movie,
      );
      expect(page.items.map((e) => e.id), contains('ok'));
    });
  });

  group('tamanhos extremos', () {
    test('Name e Overview de 5 MB não derrubam nem travam', () async {
      final big = 'A' * (5 * 1024 * 1024);
      server.jsonObject('/Users/user-1/Items/a', {'Id': 'a', 'Name': big, 'Overview': big, 'Type': 'Movie'});
      final sw = Stopwatch()..start();
      final item = await client.fetchItem('a');
      expect(sw.elapsed, lessThan(const Duration(seconds: 20)));
      // Título exibido tem teto: texto de 5 MB não vai inteiro para a UI.
      if (item != null) {
        expect((item.title ?? '').length, lessThanOrEqualTo(jellyfinMaxTextLength));
        expect((item.summary ?? '').length, lessThanOrEqualTo(jellyfinMaxTextLength));
      }
    });

    test('100 mil itens: termina em tempo limitado, sem exceção solta', () async {
      final items = List.generate(100000, (i) => {'Id': 'id$i', 'Name': 'N$i', 'Type': 'Movie'});
      server.json('/Items', jsonEncode({'Items': items, 'TotalRecordCount': items.length}));
      final sw = Stopwatch()..start();
      await tolerates(
        () => client.fetchLibraryPagedContent('lib', query: const LibraryQuery(), libraryKind: MediaKind.movie),
      );
      expect(sw.elapsed, lessThan(const Duration(seconds: 60)));
    });

    test('resposta acima do teto (64 MiB) é recusada com erro tratado', () async {
      server.routes['/Users/user-1/Items/a'] = (request) async {
        request.response.headers.contentType = ContentType.json;
        final chunk = '"${'x' * 1048576}",';
        request.response.write('{"Id":"a","Name":"x","Type":"Movie","Lixo":[');
        for (var i = 0; i < 80; i++) {
          request.response.write(chunk);
        }
        request.response.write('1]}');
      };
      await expectLater(client.fetchItem('a'), throwsA(isA<MediaServerException>()));
    });
  });
}
