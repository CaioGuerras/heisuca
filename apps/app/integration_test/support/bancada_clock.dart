import 'package:flutter_test/flutter_test.dart';

/// O app agenda seus próprios frames. A espera do driver não depende de vsync:
/// em segundo plano o Android suspende frames, mas canais/timers/mídia continuam.
void configureBancadaFrames(LiveTestWidgetsFlutterBinding binding) {
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
}

Future<void> waitBancada(LiveTestWidgetsFlutterBinding binding, Duration duration) => binding.delayed(duration);
