import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../database/app_database.dart';
import '../../services/plex_api_cache.dart';
import '../../services/jellyfin_api_cache.dart';

/// Initialize the cache required by the existing clients, without migrating
/// any legacy desktop database. Account credentials remain in the DPAPI vault.
Future<AppDatabase> initializeDesktopMetadataCaches({Directory? supportDirectory}) async {
  final support = supportDirectory ?? await getApplicationSupportDirectory();
  final bootstrap = await AppDatabase.open(
    databaseFile: File(path.join(support.path, 'heisuca-desktop-cache.db')),
  );
  PlexApiCache.initialize(bootstrap.database);
  JellyfinApiCache.initialize(bootstrap.database);
  return bootstrap.database;
}
