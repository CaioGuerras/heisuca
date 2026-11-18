import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'cinema.dart';
void main() {
  testWidgets('capturar propostas reais Flutter para aprovação visual', (tester) async {
    final dir = Platform.environment['HEISUCA_VISUAL_DIR']!;
    for (final f in {'Inter':'assets/fonts/Inter-Regular.ttf', 'MaterialIcons':'fonts/MaterialIcons-Regular.otf'}.entries) {
      await (FontLoader(f.key)..addFont(rootBundle.load(f.value))).load();
    }
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final images = <String, ui.Image>{};
    await tester.runAsync(() async {
      for (final file in Directory('$dir/assets').listSync().whereType<File>().where((f) => f.path.endsWith('.jpg'))) {
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
        images[file.uri.pathSegments.last] = (await codec.getNextFrame()).image;
        codec.dispose();
      }
    });
    addTearDown(() { for (final image in images.values) { image.dispose(); } });
    for (final name in ['a-cinema', 'b-biblioteca', 'a-ficha']) {
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: key, child: prototypeApp('$dir/assets', images, lateral: name.startsWith('b'), ficha: name.endsWith('ficha'))));
      await tester.pumpAndSettle();
      await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 600)); });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
