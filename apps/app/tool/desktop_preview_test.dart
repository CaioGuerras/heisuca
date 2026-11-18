// Captures the actual Flutter home. This is a UI preview, not a Windows
// native-video screenshot or a playback acceptance test.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/desktop_app.dart';
import 'package:heisuca/desktop/desktop_preferences.dart';
import 'package:heisuca/desktop/platform/desktop_connection_vault.dart';
import 'package:heisuca/desktop/remote/desktop_servers_controller.dart';
import 'package:heisuca/desktop/ui/desktop_library_screen.dart';

void main() {
  testWidgets('capturar interface desktop sem conteúdo fictício', (tester) async {
    final output = Platform.environment['HEISUCA_PREVIEW_DIR'];
    if (output == null) {
      fail('Defina HEISUCA_PREVIEW_DIR para a pasta de capturas.');
    }
    for (final font in {'Inter': 'assets/fonts/Inter-Regular.ttf', 'Sora': 'assets/fonts/Sora-VF.ttf', 'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'}.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 760);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final theme in ['shikkoku', 'hisui', 'sumi']) {
      final preferences = DesktopPreferences()..setTheme(theme);
      final servers = DesktopServersController(vault: MemoryDesktopConnectionVault());
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: DesktopApp(preferences: preferences, onSetFullScreen: (value) async => value,
          libraryBuilder: (_) => DesktopLibraryScreen(servers: servers, onPlay: (s, i, v) async {})),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File('$output/heisuca-desktop-$theme.png').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      preferences.dispose();
      servers.dispose();
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
