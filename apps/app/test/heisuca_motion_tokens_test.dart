import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/heisuca/heisuca_motion.dart';
import 'package:heisuca/services/device_performance.dart';

void main() {
  tearDown(DevicePerformance.debugReset);

  test('tokens do celular e escada limitada a cinco itens', () {
    expect(HeisucaMotion.toque, const Duration(milliseconds: 120));
    expect(HeisucaMotion.curto, const Duration(milliseconds: 180));
    expect(HeisucaMotion.medio, const Duration(milliseconds: 260));
    expect(HeisucaMotion.tela, const Duration(milliseconds: 320));
    expect(HeisucaMotion.grande, const Duration(milliseconds: 420));
    expect(HeisucaMotion.imagem, const Duration(milliseconds: 200));
    expect(HeisucaMotion.escada(-1), Duration.zero);
    expect(HeisucaMotion.escada(1), const Duration(milliseconds: 30));
    expect(HeisucaMotion.escada(9), const Duration(milliseconds: 150));
    for (final (actual, expected) in [
      (HeisucaMotion.entra, const Cubic(0.05, 0.7, 0.1, 1)),
      (HeisucaMotion.sai, const Cubic(0.3, 0, 0.8, 0.15)),
      (HeisucaMotion.padrao, const Cubic(0.2, 0, 0, 1)),
    ]) {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(actual.transform(t), expected.transform(t));
      }
    }
    for (final (spring, ratio) in [(HeisucaMotion.firme, 0.9), (HeisucaMotion.leve, 0.75)]) {
      expect(spring.mass, 1);
      expect(spring.stiffness, 400);
      expect(spring.damping, closeTo(2 * ratio * math.sqrt(400), 0.00001));
    }
  });

  testWidgets('contrato antigo da TV permanece intacto', (tester) async {
    expect(HeisucaMotion.duration, const Duration(milliseconds: 300));
    expect(HeisucaMotion.duration, Durations.medium2);
    expect(HeisucaMotion.curve, same(Easing.standard));
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      final style = HeisucaMotion.sheetStyle(context);
      expect(style.duration, Durations.medium4);
      expect(style.reverseDuration, Durations.short4);
      expect(style.curve, Easing.emphasizedDecelerate);
      expect(style.reverseCurve, Easing.emphasizedAccelerate);
      return const SizedBox();
    })));
  });

  for (final reduced in [false, true]) {
    testWidgets('folha do celular, movimento reduzido: $reduced', (tester) async {
      await tester.pumpWidget(MaterialApp(home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Builder(builder: (context) {
          final style = HeisucaMotion.folhaCelular(context);
          expect(style.duration, reduced ? HeisucaMotion.curto : HeisucaMotion.tela);
          expect(style.reverseDuration, HeisucaMotion.curto);
          expect(style.curve, reduced ? HeisucaMotion.padrao : HeisucaMotion.entra);
          expect(style.reverseCurve, reduced ? HeisucaMotion.padrao : HeisucaMotion.sai);
          expect(HeisucaMotion.imagemFor(context), reduced ? HeisucaMotion.curto : HeisucaMotion.imagem);
          return const SizedBox();
        }),
      )));
    });
  }

  testWidgets('folha reduzida aparece por fade sem deslizar', (tester) async {
    const content = ValueKey('folha-reduzida');
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Builder(builder: (context) => TextButton(
        onPressed: () => heisucaFolhaCelular<void>(context: context,
          sheetAnimationStyle: HeisucaMotion.folhaCelular(context),
          builder: (_) => const SizedBox(key: content, height: 160, width: double.infinity)),
        child: const Text('Abrir'),
      )),
    )));
    await tester.tap(find.text('Abrir'));
    await tester.pump();
    final initial = tester.getTopLeft(find.byKey(content));
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.getTopLeft(find.byKey(content)), initial);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(content)), initial);
    expect(tester.takeException(), isNull);
  });
}
