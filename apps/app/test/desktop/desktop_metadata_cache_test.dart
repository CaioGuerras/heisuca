import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/prefs.dart';
import 'package:heisuca/desktop/platform/desktop_metadata_cache.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/services/plex_api_cache.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bootstrap desktop inicializa cache persistente dos clientes sem migrar banco legado', () async {
    resetSharedPreferencesForTest();
    final dir = await Directory.systemTemp.createTemp('heisuca-cache-test-');
    final database = await initializeDesktopMetadataCaches(supportDirectory: dir);
    try {
      await PlexApiCache.instance.put(ServerId('plex'), '/fixture', {'proof': 'plex'});
      await JellyfinApiCache.instance.put(ServerId('jellyfin'), '/fixture', {'proof': 'jellyfin'});
      expect((await PlexApiCache.instance.get(ServerId('plex'), '/fixture'))?['proof'], 'plex');
      expect((await JellyfinApiCache.instance.get(ServerId('jellyfin'), '/fixture'))?['proof'], 'jellyfin');
      expect(await File('${dir.path}/heisuca-desktop-cache.db').exists(), isTrue);
      expect(await File('${dir.path}/cgflix.db').exists(), isFalse);
    } finally {
      await database.close();
      await dir.delete(recursive: true);
    }
  });
}
