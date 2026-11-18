import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'desktop/platform/desktop_metadata_cache.dart';

import 'desktop/desktop_root.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 760),
      minimumSize: Size(800, 600),
      center: true,
      title: 'Heisuca',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setTitle('Heisuca');
      await windowManager.setPreventClose(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await initializeDesktopMetadataCaches();

  runApp(DesktopRoot(initialSource: arguments.isEmpty ? null : arguments.first));
}
