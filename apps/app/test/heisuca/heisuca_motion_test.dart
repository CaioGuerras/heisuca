import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/heisuca/heisuca_motion.dart';
import 'package:plezy/services/device_performance.dart';

void main() {
  tearDown(DevicePerformance.debugReset);
  test('mola normalizada é contínua, crescente e segura para opacidade', () {
    var previous = 0.0;
    for (var step = 0; step <= 100; step++) {
      final value = HeisucaMotion.curve.transform(step / 100);
      expect(value, inInclusiveRange(previous, 1.0));
      previous = value;
    }
    expect(previous, 1);
  });
  testWidgets('fade-through preserva estado das abas e não permite tocar na saída', (tester) async {
    var index = 0;
    var first = 0;
    var second = 0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return HeisucaTabStack(
              index: index,
              children: [
                Material(child: Column(
                  children: [
                    const TextField(key: ValueKey('rascunho')),
                    TextButton(onPressed: () => first++, child: const Text('primeira')),
                  ],
                )),
                TextButton(onPressed: () => second++, child: const Text('segunda')),
              ],
            );
          },
        ),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('rascunho')), 'estado preservado');
    await tester.tap(find.text('primeira'));
    update(() => index = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final hidden = tester.widgetList<IgnorePointer>(find.byType(IgnorePointer));
    expect(hidden.any((widget) => widget.ignoring), isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('segunda'));
    expect(first, 1);
    expect(second, 1);
    update(() => index = 0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('primeira'));
    expect(first, 2);
    expect(find.text('estado preservado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('parallax respeita o portão de desempenho', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    Widget page() => MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: 50,
              child: HeisucaParallax(controller: controller, child: const Text('arte')),
            ),
            Expanded(
              child: ListView(controller: controller, children: const [SizedBox(height: 2000)]),
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(page());
    controller.jumpTo(100);
    await tester.pump();
    final transform = tester.widget<Transform>(
      find.descendant(of: find.byType(HeisucaParallax), matching: find.byType(Transform)),
    );
    expect(transform.transform.getTranslation().y, 25);
    DevicePerformance.debugReset(autoReduced: true);
    await tester.pumpWidget(page());
    expect(find.descendant(of: find.byType(HeisucaParallax), matching: find.byType(Transform)), findsNothing);
  });
  testWidgets('reduzir movimento do sistema desliga parallax e transições', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              expect(HeisucaMotion.durationFor(context), Duration.zero);
              expect(HeisucaMotion.sheetStyle(context).duration, Duration.zero);
              return HeisucaParallax(controller: controller, child: const Text('arte'));
            },
          ),
        ),
      ),
    );
    expect(find.byType(Transform), findsNothing);
  });
}
