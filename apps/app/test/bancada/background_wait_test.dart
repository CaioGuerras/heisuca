import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../integration_test/support/bancada_clock.dart';

void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
  configureBancadaFrames(binding);
  testWidgets('espera termina sem pedir frames ao app parado em segundo plano', (tester) async {
    await tester.pump();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await binding.delayed(const Duration(milliseconds: 100));
    Future<void>? pending;
    try {
      expect(binding.framesEnabled, isFalse);
      pending = waitBancada(binding, const Duration(milliseconds: 10));
      await pending.timeout(const Duration(milliseconds: 250));
    } finally {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      if (pending != null) await pending;
    }
  });
  testWidgets('app continua desenhando sem pumps artificiais do driver', (tester) async {
    var completed = false;
    await tester.pumpWidget(TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 20),
      onEnd: () => completed = true,
      builder: (_, value, _) => SizedBox(width: value + 1, height: 1),
    ));
    final deadline = DateTime.now().add(const Duration(seconds: 1));
    while (!completed && DateTime.now().isBefore(deadline)) {
      await waitBancada(binding, const Duration(milliseconds: 10));
    }
    expect(completed, isTrue);
  });

}
