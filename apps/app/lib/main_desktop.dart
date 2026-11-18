import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop/desktop_app.dart';

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
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(DesktopApp(initialSource: arguments.isEmpty ? null : arguments.first));
}
