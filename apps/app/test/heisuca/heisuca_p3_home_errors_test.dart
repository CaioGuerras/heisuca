import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/home/cgflix_home_logic.dart';
import 'package:heisuca/cgflix/home/cgflix_home_repository.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/exceptions/media_server_exceptions.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

void main() {
  test('P3 cache vazio conhecido não é apresentado como resposta nova da rede', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final dir = Directory.systemTemp.createTempSync('heisuca-p3-empty-cache-');
    addTearDown(() async { await db.close(); dir.deleteSync(recursive: true); });
    var online = true;
    final client = testJellyfinClient(handler: (_) async => online
        ? jsonResponse({'Items': []}) : jsonResponse({'Message': 'Falha do servidor'}, status: 500));
    addTearDown(client.close);
    final first = CgflixHomeRepository(client, cacheDir: () async => dir);
    expect((await first.watchRow(CgflixRowKind.newMovies).last).items, isEmpty);
    first.dispose();
    await first.flushed;
    online = false;
    final second = CgflixHomeRepository(client, cacheDir: () async => dir);
    try {
      final rows = await second.watchRow(CgflixRowKind.newMovies).toList();
      expect(rows.single.items, isEmpty);
      expect(rows.single.fromCache, isTrue);
    } finally { second.dispose(); await second.flushed; }
  });
  for (final cached in [false, true]) {
    test('P3 falha de rede: ${cached ? "mantém dados do cache" : "não inventa acervo vazio"}', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      JellyfinApiCache.initialize(db);
      final dir = Directory.systemTemp.createTempSync('heisuca-p3-home-error-');
      addTearDown(() async { await db.close(); dir.deleteSync(recursive: true); });
      var online = cached;
      final client = testJellyfinClient(handler: (_) async => online
          ? jsonResponse({'Items': [{'Id': 'filme', 'Name': 'Filme da família', 'Type': 'Movie'}]})
          : jsonResponse({'Message': 'Falha do servidor de teste'}, status: 500));
      addTearDown(client.close);
      if (cached) {
        final first = CgflixHomeRepository(client, cacheDir: () async => dir);
        expect((await first.watchRow(CgflixRowKind.newMovies).last).items.single.id, 'filme');
        first.dispose();
        await first.flushed;
        online = false;
      }
      final repository = CgflixHomeRepository(client, cacheDir: () async => dir);
      try {
        if (cached) {
          final rows = await repository.watchRow(CgflixRowKind.newMovies).toList();
          expect(rows.single.items.single.id, 'filme');
          expect(rows.single.fromCache, isTrue);
        } else {
          await expectLater(repository.watchHero().toList(), throwsA(isA<MediaServerHttpException>()));
        }
      } finally { repository.dispose(); await repository.flushed; }
    });
  }
}
