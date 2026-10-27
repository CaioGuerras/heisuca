import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import '../services/device_performance.dart';

/// Tokens M3 do Flutter; transições de página seguem o tema da plataforma.
abstract final class HeisucaMotion {
  static const duration = Durations.medium2;
  static const curve = Easing.standard;
  static bool reduced(BuildContext context) => DevicePerformance.isReduced || MediaQuery.disableAnimationsOf(context);
  static AnimationStyle sheetStyle(BuildContext context) => reduced(context)
    ? AnimationStyle.noAnimation
    : const AnimationStyle(duration: Durations.medium4, reverseDuration: Durations.short4,
        curve: Easing.emphasizedDecelerate, reverseCurve: Easing.emphasizedAccelerate);
  static Duration durationFor(BuildContext context) => reduced(context) ? Duration.zero : duration;
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

/// Fade-through oficial do pacote animations, conservando os estados montados.
class HeisucaTabStack extends StatefulWidget {
  const HeisucaTabStack({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;
  @override
  State<HeisucaTabStack> createState() => _HeisucaTabStackState();
}

class _TabMotion {
  _TabMotion(TickerProvider vsync, {required bool selected})
    : primary = AnimationController(vsync: vsync, duration: HeisucaMotion.duration, value: selected ? 1 : 0),
      secondary = AnimationController(vsync: vsync, duration: HeisucaMotion.duration);
  final AnimationController primary, secondary;
  bool get showing => !primary.isDismissed && !secondary.isCompleted;
  void dispose() { primary.dispose(); secondary.dispose(); }
}

class _HeisucaTabStackState extends State<HeisucaTabStack> with TickerProviderStateMixin {
  final _motions = <Object, _TabMotion>{};
  late Object _active;
  Object _key(int index) => widget.children[index].key ?? index;

  @override void initState() {
    super.initState();
    _active = _key(widget.index);
    _sync(initial: true);
  }
  void _sync({bool initial = false}) {
    final keys = {for (var i = 0; i < widget.children.length; i++) _key(i)};
    for (final key in _motions.keys.where((key) => !keys.contains(key)).toList()) {
      _motions.remove(key)!.dispose();
    }
    for (final key in keys) {
      _motions.putIfAbsent(key, () => _TabMotion(this, selected: initial && key == _active));
    }
  }
  void _settle(Object next) {
    for (final entry in _motions.entries) {
      entry.value.primary.stop(); entry.value.secondary.stop();
      entry.value.primary.value = entry.key == next ? 1 : 0;
      entry.value.secondary.value = 0;
    }
  }
  @override void didChangeDependencies() {
    super.didChangeDependencies();
    if (HeisucaMotion.reduced(context)) _settle(_key(widget.index));
  }
  @override void didUpdateWidget(HeisucaTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    final next = _key(widget.index);
    if (HeisucaMotion.reduced(context)) {
      _settle(next);
    } else if (next != _active) {
      final previous = _motions[_active];
      final incoming = _motions[next]!;
      if (previous == null) {
        incoming.primary.value = 1; incoming.secondary.value = 0;
      } else {
        // Controladores estáveis por aba preservam o quadro atual quando há
        // outro toque antes do fim. Não reinicia nem mostra inteira a aba interrompida.
        previous.primary.forward(); previous.secondary.forward();
        if (incoming.secondary.isCompleted) {
          incoming.primary.value = 0; incoming.secondary.value = 0;
        }
        incoming.secondary.reverse(); incoming.primary.forward();
      }
    }
    _active = next;
  }
  @override void dispose() {
    for (final motion in _motions.values) { motion.dispose(); }
    super.dispose();
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([for (final motion in _motions.values) ...[motion.primary, motion.secondary]]),
    builder: (_, _) => Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: [
      for (var i = 0; i < widget.children.length; i++) Offstage(
        key: ValueKey(_key(i)), offstage: i != widget.index && !_motions[_key(i)]!.showing,
        child: IgnorePointer(ignoring: i != widget.index,
          child: ExcludeSemantics(excluding: i != widget.index,
            child: TickerMode(enabled: i == widget.index,
              child: FadeThroughTransition(animation: _motions[_key(i)]!.primary,
                secondaryAnimation: _motions[_key(i)]!.secondary, fillColor: Colors.transparent,
                child: widget.children[i])))),
      ),
    ]),
  );
}
