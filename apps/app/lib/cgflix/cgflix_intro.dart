// Abertura do CGFLIX (estilo Netflix): o "C" se desenha com um brilho roxo que varre,
// o play aparece com um "tum" opcional e a tela segue suave para a Início. ~1,4 s.
// Em aberturas seguidas (< 30 s) ou com "remover animações" ligado, pula direto.
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/settings_service.dart';
import '../widgets/setting_tile.dart';
import 'cgflix_logo.dart';
import 'cgflix_palette.dart';

/// Chave "Som de abertura" (Configurações › Avançado). Padrão: ligado.
const cgflixIntroSoundPref = BoolPref('cgflix_intro_sound', defaultValue: true);
const _lastOpenPref = IntPref('cgflix_last_open_ms');

const cgflixIntroDuration = Duration(milliseconds: 1400);

/// Aberturas com menos que isso de intervalo pulam a animação.
const cgflixIntroSkipWindow = Duration(seconds: 30);

/// Decide se esta abertura anima: não anima se a anterior foi há menos de 30 s.
@visibleForTesting
bool cgflixShouldAnimateIntro({required int? lastOpenMs, required int nowMs}) {
  if (lastOpenMs == null || lastOpenMs <= 0) return true;
  final elapsed = nowMs - lastOpenMs;
  return elapsed < 0 || elapsed >= cgflixIntroSkipWindow.inMilliseconds;
}

/// Estado da abertura nesta execução do app (uma por processo).
abstract final class CgflixIntro {
  static bool? _animate;
  static Completer<void>? _done;
  static const _sound = MethodChannel('br.com.docaio.cgflix/intro_sound');

  /// Decide uma vez por processo e já marca a hora desta abertura.
  static bool _decide() {
    final cached = _animate;
    if (cached != null) return cached;
    final settings = SettingsService.instanceOrNull;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = settings?.read(_lastOpenPref);
    final animate = cgflixShouldAnimateIntro(lastOpenMs: last, nowMs: now);
    if (settings != null) unawaited(settings.write(_lastOpenPref, now));
    return _animate = animate;
  }

  /// O SetupScreen espera a animação acabar antes de trocar para a Início (para não cortar
  /// no meio). Se a intro nem apareceu, não espera nada; no pior caso, 2 s.
  static Future<void> finished() {
    final done = _done;
    if (done == null || done.isCompleted) return Future.value();
    return done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
  }

  static void _playSound() {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!(SettingsService.instanceOrNull?.read(cgflixIntroSoundPref) ?? true)) return;
    unawaited(_sound.invokeMethod<bool>('play').catchError((Object _) => false));
  }
}

/// Emblema animado da abertura (no lugar do emblema parado do splash do Flutter).
class CgflixIntroEmblem extends StatefulWidget {
  const CgflixIntroEmblem({super.key, required this.size});
  final double size;

  @override
  State<CgflixIntroEmblem> createState() => _CgflixIntroEmblemState();
}

class _CgflixIntroEmblemState extends State<CgflixIntroEmblem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: cgflixIntroDuration);
  bool _animate = false;
  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();
    _animate = CgflixIntro._decide();
    if (!_animate) return;
    CgflixIntro._done ??= Completer<void>();
    _controller.addListener(_onTick);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !(CgflixIntro._done?.isCompleted ?? true)) {
        CgflixIntro._done!.complete();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animate || _controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      if (!(CgflixIntro._done?.isCompleted ?? true)) CgflixIntro._done!.complete();
      return;
    }
    unawaited(_controller.forward());
  }

  void _onTick() {
    // O "tum" sai junto com o play.
    if (!_soundPlayed && _controller.value >= 0.5) {
      _soundPlayed = true;
      CgflixIntro._playSound();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (!(CgflixIntro._done?.isCompleted ?? true)) CgflixIntro._done!.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animate) return CgflixEmblem(size: widget.size);
    return Semantics(
      label: 'CGFLIX',
      child: RepaintBoundary(
        child: CustomPaint(size: Size.square(widget.size), painter: CgflixIntroPainter(_controller, context.cgflix)),
      ),
    );
  }
}

/// Desenha o emblema no progresso [t] (0..1): "C" de 0 a 0,55, brilho varrendo de 0,2 a 0,8,
/// play crescendo de 0,5 a 0,75, leve respiro do conjunto no fim.
class CgflixIntroPainter extends CustomPainter {
  CgflixIntroPainter(this.animation, [this.palette = CgflixPalette.isis]) : super(repaint: animation);
  final Animation<double> animation;

  /// Cores da marca do tema (Isis: roxo; Heitor: verde com o play escuro).
  final CgflixPalette palette;

  static const _arcStops = [0.0, 0.3, 0.7, 1.0];

  double _interval(double t, double begin, double end, Curve curve) =>
      curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final scale = size.width / 1000;
    canvas.save();
    // Respiro final: cresce 4% e volta, como quem "assenta" a marca.
    final breathe = 1 + 0.04 * math.sin(math.pi * _interval(t, 0.7, 1.0, Curves.easeInOut));
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale * breathe);
    canvas.translate(-500, -500);

    // "C": arco de 340 de raio, desenhado do topo, contornando pela esquerda até embaixo.
    final arc = Path()
      ..moveTo(760.9, 281)
      ..arcToPoint(const Offset(760.9, 719), radius: const Radius.circular(340), largeArc: true, clockwise: false);
    final draw = _interval(t, 0.0, 0.55, Curves.easeOutCubic);
    final metric = arc.computeMetrics().first;
    final partial = metric.extractPath(0, metric.length * draw);
    const bounds = Rect.fromLTWH(160, 160, 680, 680);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 128
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: palette.brandArc,
        stops: _arcStops,
      ).createShader(bounds);

    // Brilho da marca por trás (aparece e some).
    final glow = _interval(t, 0.15, 0.6, Curves.easeOut) * (1 - _interval(t, 0.75, 1.0, Curves.easeIn) * 0.6);
    if (draw > 0 && glow > 0) {
      canvas.drawPath(
        partial,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 170
          ..strokeCap = StrokeCap.round
          ..color = palette.brandGlow.withValues(alpha: palette.brandGlow.a * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
      );
    }
    if (draw > 0) canvas.drawPath(partial, stroke);

    // Brilho que varre: faixa clara diagonal passando pelo "C" já desenhado.
    final sweep = _interval(t, 0.2, 0.85, Curves.easeInOut);
    if (draw > 0 && sweep > 0 && sweep < 1) {
      final x = -400 + 1800 * sweep;
      canvas.drawPath(
        partial,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 128
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              palette.brandShine.withValues(alpha: 0),
              palette.brandShine,
              palette.brandShine.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x - 160, 0, 320, 1000)),
      );
    }

    // Play: cresce com um leve passo além (overshoot).
    final pop = _interval(t, 0.5, 0.75, Curves.easeOutBack);
    if (pop > 0) {
      canvas.save();
      canvas.translate(540, 500);
      canvas.scale(pop);
      canvas.translate(-540, -500);
      final triangle = Path()
        ..moveTo(452, 368)
        ..lineTo(452, 632)
        ..lineTo(668, 500)
        ..close();
      final fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.brandPlay,
          stops: const [0.0, 0.55, 1.0],
        ).createShader(const Rect.fromLTWH(420, 340, 280, 320));
      canvas.drawPath(triangle, fill);
      canvas.drawPath(
        triangle,
        Paint()
          ..shader = fill.shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 54
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CgflixIntroPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.palette != palette;
}

/// Chave "Som de abertura" em Configurações › Avançado (só no Android, onde o som existe).
class CgflixIntroSoundTile extends StatelessWidget {
  const CgflixIntroSoundTile({super.key});

  @override
  Widget build(BuildContext context) => const SettingSwitchTile(
    pref: cgflixIntroSoundPref,
    icon: Symbols.music_note_rounded,
    title: 'Som de abertura',
    subtitle: 'Um "tum" curto ao abrir o app (fica mudo no silencioso e no vibrar)',
  );
}
