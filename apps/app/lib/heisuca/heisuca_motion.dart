import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';
import '../services/device_performance.dart';
import '../utils/platform_detector.dart';

/// Tokens do celular e contrato M3 preservado para a TV.
abstract final class HeisucaMotion {
  static const toque = Duration(milliseconds: 120);
  static const curto = Duration(milliseconds: 180);
  static const medio = Duration(milliseconds: 260);
  static const tela = Duration(milliseconds: 320);
  static const grande = Duration(milliseconds: 420);
  static const imagem = Duration(milliseconds: 200);
  static Duration imagemFor(BuildContext c) => reduced(c) ? curto : imagem;
  static Duration escada(int i) => Duration(milliseconds: 30 * i.clamp(0, 5));

  static const entra = Cubic(0.05, 0.7, 0.1, 1);
  static const sai = Cubic(0.3, 0, 0.8, 0.15);
  static const padrao = Cubic(0.2, 0, 0, 1);
  static final firme = SpringDescription.withDampingRatio(mass: 1, stiffness: 400, ratio: 0.9);
  static final leve = SpringDescription.withDampingRatio(mass: 1, stiffness: 400, ratio: 0.75);

  static AnimationStyle folhaCelular(BuildContext c) => PlatformDetector.isTV() ? sheetStyle(c) : reduced(c)
      ? const AnimationStyle(duration: curto, reverseDuration: curto, curve: padrao, reverseCurve: padrao)
      : const AnimationStyle(duration: tela, reverseDuration: curto, curve: entra, reverseCurve: sai);

  // Contrato antigo preservado para a TV.
  static const duration = Durations.medium2;
  static const curve = Easing.standard;
  static bool reduced(BuildContext context) => DevicePerformance.isReduced || MediaQuery.disableAnimationsOf(context);
  static AnimationStyle sheetStyle(BuildContext context) => reduced(context)
    ? AnimationStyle.noAnimation
    : const AnimationStyle(duration: Durations.medium4, reverseDuration: Durations.short4,
        curve: Easing.emphasizedDecelerate, reverseCurve: Easing.emphasizedAccelerate);
  static Duration durationFor(BuildContext context) => reduced(context) ? Duration.zero : duration;
}

/// Mantém a folha nativa; no modo reduzido, anima apenas a opacidade.
Future<T?> heisucaFolhaCelular<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required AnimationStyle sheetAnimationStyle,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool? showDragHandle,
  Color? backgroundColor,
  Color? barrierColor,
  ShapeBorder? shape,
}) {
  if (PlatformDetector.isTV() || !HeisucaMotion.reduced(context)) {
    return showModalBottomSheet<T>(context: context, builder: builder,
        sheetAnimationStyle: sheetAnimationStyle, isScrollControlled: isScrollControlled,
        useSafeArea: useSafeArea, showDragHandle: showDragHandle,
        backgroundColor: backgroundColor, barrierColor: barrierColor, shape: shape);
  }
  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);
  final controller = AnimationController(vsync: navigator,
      duration: HeisucaMotion.curto, reverseDuration: HeisucaMotion.curto,
      animationBehavior: AnimationBehavior.preserve);
  final route = _FolhaReduzida<T>(
    builder: builder, isScrollControlled: isScrollControlled,
    capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
    useSafeArea: useSafeArea, showDragHandle: showDragHandle,
    backgroundColor: backgroundColor, modalBarrierColor: barrierColor ??
        Theme.of(context).bottomSheetTheme.modalBarrierColor ?? Colors.black54,
    barrierLabel: localizations.scrimLabel, shape: shape,
    sheetAnimationStyle: sheetAnimationStyle, transitionAnimationController: controller,
  );
  final result = navigator.push(route);
  unawaited(route.completed.then<void>((_) => controller.dispose()));
  return result;
}

class _FolhaReduzida<T> extends ModalBottomSheetRoute<T> {
  _FolhaReduzida({required super.builder, required super.isScrollControlled,
    super.capturedThemes, super.useSafeArea, super.showDragHandle,
    super.backgroundColor, super.modalBarrierColor, super.barrierLabel,
    super.shape, super.sheetAnimationStyle, super.transitionAnimationController}) : super(enableDrag: false);

  // O conteúdo já fica no destino; o controlador da rota faz só o fade.
  @override Animation<double> get animation => kAlwaysCompleteAnimation;
  @override Widget buildModalBarrier() => FadeTransition(
      opacity: super.animation!.drive(CurveTween(curve: HeisucaMotion.padrao)),
      child: super.buildModalBarrier());
  @override Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) => FadeTransition(
        opacity: super.animation!.drive(CurveTween(curve: HeisucaMotion.padrao)), child: child);
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

/// Abas montadas, com saída curta e entrada após 60 ms.
class HeisucaTabStack extends StatefulWidget {
  const HeisucaTabStack({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;
  @override
  State<HeisucaTabStack> createState() => _HeisucaTabStackState();
}

class _TabMotion {
  _TabMotion(TickerProvider vsync, {required bool selected})
      : opacity = AnimationController(vsync: vsync, animationBehavior: AnimationBehavior.preserve, value: selected ? 1 : 0);
  final AnimationController opacity;
  Timer? delay;
  void dispose() { delay?.cancel(); opacity.dispose(); }
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
      _motions.putIfAbsent(key, () => _TabMotion(this, selected: initial && key == _key(widget.index)));
    }
  }
  void _transition() {
    final reduced = HeisucaMotion.reduced(context);
    final next = _key(widget.index);
    for (final entry in _motions.entries) {
      final motion = entry.value;
      motion.delay?.cancel();
      motion.opacity.stop();
      if (entry.key == next) {
        void enter() => motion.opacity.animateTo(1,
            duration: reduced ? HeisucaMotion.curto : HeisucaMotion.tela,
            curve: reduced ? HeisucaMotion.padrao : HeisucaMotion.entra);
        if (reduced) {
          enter();
        } else {
          motion.delay = Timer(const Duration(milliseconds: 60), enter);
        }
      } else {
        motion.opacity.animateTo(0, duration: HeisucaMotion.curto,
            curve: reduced ? HeisucaMotion.padrao : HeisucaMotion.sai);
      }
    }
  }
  @override void didChangeDependencies() {
    super.didChangeDependencies();
    if (HeisucaMotion.reduced(context)) _transition();
  }
  @override void didUpdateWidget(HeisucaTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    final next = _key(widget.index);
    if (next != _active) _transition();
    _active = next;
  }
  @override void dispose() {
    for (final motion in _motions.values) { motion.dispose(); }
    super.dispose();
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([for (final motion in _motions.values) motion.opacity]),
    builder: (_, _) => Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: [
      for (var i = 0; i < widget.children.length; i++) Offstage(
        key: ValueKey(_key(i)), offstage: i != widget.index && _motions[_key(i)]!.opacity.value == 0,
        child: IgnorePointer(ignoring: i != widget.index,
          child: ExcludeFocus(excluding: i != widget.index,
            child: ExcludeSemantics(excluding: i != widget.index,
              child: TickerMode(enabled: i == widget.index,
                child: FadeTransition(opacity: _motions[_key(i)]!.opacity, child: widget.children[i]))))),
      ),
    ]),
  );
}
