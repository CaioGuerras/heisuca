import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/heisuca/heisuca_motion.dart';
import 'package:heisuca/services/device_performance.dart';

void main() {
  tearDown(DevicePerformance.debugReset);
  test('curva M3 é contínua, crescente e segura para opacidade', () {
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
  double alpha(WidgetTester tester, Key key) => tester.widgetList<FadeTransition>(
    find.ancestor(of: find.byKey(key), matching: find.byType(FadeTransition)))
      .fold<double>(1, (value, fade) => value * fade.opacity.value);
  testWidgets('abas têm saída, passagem e entrada visíveis sem eixo horizontal', (tester) async {
    tester.view.physicalSize = const Size(412, 914); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var index = 0; late StateSetter update;
    const first = ValueKey('quadro-primeiro'), second = ValueKey('quadro-segundo');
    await tester.pumpWidget(MaterialApp(home: StatefulBuilder(builder: (_, setState) {
      update = setState;
      return HeisucaTabStack(index: index, children: const [SizedBox.expand(key: first), SizedBox.expand(key: second)]);
    })));
    update(() => index = 1); await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(alpha(tester, first), allOf(greaterThan(0), lessThan(1)));
    expect(alpha(tester, second), 0);
    await tester.pump(const Duration(milliseconds: 30));
    expect(alpha(tester, first), 0); expect(alpha(tester, second), closeTo(0, .001));
    await tester.pump(const Duration(milliseconds: 90));
    expect(alpha(tester, second), allOf(greaterThan(0), lessThan(1)));
    expect(tester.getCenter(find.byKey(second)).dx, closeTo(206, .01));
    expect(tester.getRect(find.byKey(second)).width, lessThan(412));
    await tester.pumpAndSettle(); expect(alpha(tester, second), 1);
  });
  testWidgets('toques rápidos não fazem uma aba ainda invisível piscar inteira', (tester) async {
    var index = 0; late StateSetter update;
    const first = ValueKey('rápida-a'), middle = ValueKey('rápida-b'), last = ValueKey('rápida-c');
    await tester.pumpWidget(MaterialApp(home: StatefulBuilder(builder: (_, setState) {
      update = setState;
      return HeisucaTabStack(index: index, children: const [
        SizedBox.expand(key: first), SizedBox.expand(key: middle), SizedBox.expand(key: last)]);
    })));
    update(() => index = 1); await tester.pump(); await tester.pump(const Duration(milliseconds: 30));
    expect(alpha(tester, middle), 0);
    update(() => index = 2); await tester.pump();
    expect(alpha(tester, middle), 0, reason: 'a aba interrompida não pode reaparecer com opacidade 1');
    await tester.pump(const Duration(milliseconds: 30));
    final before = alpha(tester, first);
    update(() => index = 0); await tester.pump();
    expect(alpha(tester, first), closeTo(before, .001), reason: 'retorno durante a saída conserva a opacidade');
    await tester.pumpAndSettle(); expect(alpha(tester, first), 1);
  });
  for (final system in [false, true]) {
    testWidgets('abas entram imediatamente com movimento reduzido (sistema: $system)', (tester) async {
      DevicePerformance.debugReset(autoReduced: !system);
      var index = 0; late StateSetter update;
      const target = ValueKey('quadro-final');
      await tester.pumpWidget(MaterialApp(home: MediaQuery(data: MediaQueryData(disableAnimations: system),
        child: StatefulBuilder(builder: (_, setState) {
          update = setState;
          return HeisucaTabStack(index: index, children: const [SizedBox.expand(), SizedBox.expand(key: target)]);
        }))));
      update(() => index = 1); await tester.pump();
      expect(alpha(tester, target), 1);
    });
  }
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
