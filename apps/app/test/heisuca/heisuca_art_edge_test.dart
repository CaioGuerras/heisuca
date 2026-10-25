import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/heisuca/heisuca_home_style.dart';
import 'package:plezy/heisuca/heisuca_motion.dart';
import 'package:plezy/services/device_performance.dart';

/// A2: cores fortes tornam qualquer vazamento de arte distinguível do fundo.
ui.Image _art() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var stripe = 0; stripe < 32; stripe++) {
    canvas.drawRect(
      Rect.fromLTWH(stripe * 16, 0, 16, 512),
      Paint()..color = Color.fromARGB(255, 50 + stripe * 6, 230 - stripe * 5, 80 + stripe * 4),
    );
  }
  final picture = recorder.endRecording();
  final image = picture.toImageSync(512, 512);
  picture.dispose();
  return image;
}

void main() {
  for (final dpr in [2.97, 2.96875]) {
    for (final reduced in [false, true]) {
      for (final detail in [false, true]) {
        testWidgets(
          'A2: borda da arte sem pixels coloridos a DPR $dpr (${detail ? "ficha" : "Início"}, reduzido: $reduced)',
          (tester) async {
            tester.view.physicalSize = const Size(1220, 2712);
            tester.view.devicePixelRatio = dpr;
            addTearDown(tester.view.reset);
            DevicePerformance.debugReset(autoReduced: reduced);
            addTearDown(DevicePerformance.debugReset);
            final controller = ScrollController();
            addTearDown(controller.dispose);
            final image = _art();
            addTearDown(image.dispose);
            final boundaryKey = GlobalKey();
            final logical = tester.view.physicalSize / dpr;
            final height = detail ? (logical.height * .72).clamp(440.0, 760.0) : heisucaHeroHeight(logical.height);
            // Mesma ordem de camadas dos dois chamadores reais, sem metadados/rede.
            await tester.pumpWidget(
              MaterialApp(
                home: RepaintBoundary(
                  key: boundaryKey,
                  child: ColoredBox(
                    color: const Color(0xff2b2241),
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(scrollbars: false, overscroll: false),
                      child: CustomScrollView(
                        controller: controller,
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: height,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  HeisucaArtworkMask(
                                    child: HeisucaParallax(
                                      controller: controller,
                                      child: RawImage(
                                        image: image,
                                        filterQuality: FilterQuality.high,
                                        fit: BoxFit.cover,
                                        alignment: const Alignment(0, -.64),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 2000)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            for (final offset in [
              0.0,
              .01,
              .04,
              .08,
              .125,
              .17,
              .25,
              .333,
              .5,
              .7,
              .9,
              1.01,
              1.125,
              3.333,
              7.17,
              17.125,
              32.125,
              48.333,
              65.17,
              101.1,
              118.3,
              147.5,
              200.75,
            ]) {
              controller.jumpTo(offset);
              await tester.pump();
              await tester.pump();
              await tester.runAsync(() async {
                final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
                final frame = await boundary.toImage(pixelRatio: dpr);
                final bytes = (await frame.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
                // Golden anterior à correção: preserva o recorte e a máscara em repouso.
                // Uma unidade admite somente arredondamento de cor entre composições GPU.
                if (Platform.environment['FLUTTER_TEST_IMPELLER'] == 'true' &&
                    dpr == 2.97 &&
                    !detail &&
                    !reduced &&
                    offset == 0) {
                  final codec = await ui.instantiateImageCodec(
                    await File('test/heisuca/goldens/a2_home_before_fix.png').readAsBytes(),
                  );
                  final golden = (await codec.getNextFrame()).image;
                  expect(frame.width, golden.width);
                  expect(frame.height, golden.height);
                  final expected = (await golden.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
                  var largestDifference = 0;
                  for (var channel = 0; channel < bytes.length; channel++) {
                    final difference = (bytes[channel] - expected[channel]).abs();
                    if (difference > largestDifference) largestDifference = difference;
                  }
                  golden.dispose();
                  codec.dispose();
                  expect(
                    largestDifference,
                    lessThanOrEqualTo(1),
                    reason: 'não mudar o recorte ou a composição aprovada em repouso',
                  );
                }
                final edge = (height - controller.offset) * dpr;
                final reference = ((edge.ceil() + 8) * frame.width) * 4;
                var mismatches = 0;
                for (var y = edge.floor() - 3; y <= edge.ceil() + 3; y++) {
                  for (var x = 0; x < frame.width; x++) {
                    final pixel = (y * frame.width + x) * 4;
                    for (var channel = 0; channel < 4; channel++) {
                      if (bytes[pixel + channel] != bytes[reference + channel]) {
                        mismatches++;
                        break;
                      }
                    }
                  }
                }
                if ((mismatches > 0 || offset == 0 || offset == 32.125) &&
                    Platform.environment['HEISUCA_A2_CAPTURE'] != null) {
                  final png = await frame.toByteData(format: ui.ImageByteFormat.png);
                  File(
                    '${Platform.environment['HEISUCA_A2_CAPTURE']}/${detail ? "ficha" : "inicio"}_dpr${dpr}_reduced${reduced}_$offset.png',
                  ).writeAsBytesSync(png!.buffer.asUint8List());
                }
                frame.dispose();
                expect(
                  mismatches,
                  0,
                  reason: 'offset=$offset, borda física=$edge, DPR=$dpr; arte não deve escapar da máscara',
                );
              });
            }
          },
        );
      }
    }
  }
}
