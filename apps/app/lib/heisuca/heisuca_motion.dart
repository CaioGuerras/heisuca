import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/device_performance.dart';

/// Ritmo único dos fluxos Heisuca; a mola é amortecida para não recortar conteúdo.
abstract final class HeisucaMotion {
  static const duration = Duration(milliseconds: 420);
  static const curve = HeisucaSpringCurve();
  static AnimationStyle sheetStyle(BuildContext context) => AnimationStyle(
    duration: durationFor(context),
    reverseDuration: durationFor(context),
    curve: curve,
    reverseCurve: curve,
  );
  static Duration durationFor(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : DevicePerformance.reducedDuration(duration);
}

/// O fundo avança 25% menos que o conteúdo, sem mover máscara nem metadados.
class HeisucaParallax extends StatelessWidget {
  const HeisucaParallax({super.key, required this.controller, required this.child});
  final ScrollController controller;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (DevicePerformance.isReduced || MediaQuery.disableAnimationsOf(context)) return child;
    return ClipRect(
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (_, image) => Transform.translate(
          offset: Offset(0, controller.hasClients ? controller.offset.clamp(0.0, 800.0) * .25 : 0),
          child: image,
        ),
      ),
    );
  }
}

/// Mantém as abas montadas, com saída até 30% e entrada depois de 30%.
class HeisucaTabStack extends StatefulWidget {
  const HeisucaTabStack({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;
  @override
  State<HeisucaTabStack> createState() => _HeisucaTabStackState();
}

class _HeisucaTabStackState extends State<HeisucaTabStack> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: HeisucaMotion.duration, value: 1);
  int? _previous;
  @override
  void didUpdateWidget(HeisucaTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _previous = oldWidget.index;
      _controller.duration = HeisucaMotion.durationFor(context);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, _) => Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.index && (i != _previous || _controller.isCompleted),
            child: IgnorePointer(
              ignoring: i != widget.index,
              child: ExcludeSemantics(
                excluding: i != widget.index,
                child: TickerMode(
                  enabled: i == widget.index,
                  child: Opacity(
                    opacity: i == widget.index
                        ? HeisucaMotion.curve.transform(((_controller.value - .3) / .7).clamp(0, 1))
                        : 1 - HeisucaMotion.curve.transform((_controller.value / .3).clamp(0, 1)),
                    child: widget.children[i],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Mola criticamente amortecida, normalizada em 0–1 sem ultrapassar a opacidade.
class HeisucaSpringCurve extends Curve {
  const HeisucaSpringCurve();
  @override
  double transformInternal(double t) => (1 - (1 + 8 * t) * math.exp(-8 * t)) / (1 - 9 * math.exp(-8));
}
