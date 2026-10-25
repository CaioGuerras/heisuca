// Abertura do modo infantil (pesquisa_apps/marca/animacoes/kids.html, ≈ 3 s; ANIMACOES.md §2).
// Ichigo = morangos, melancias e corações; Sorairo = nuvens, estrelas e aviõezinhos. Mesmo esqueleto.
// Com "reduzir movimento" do sistema, só opacidade (1,6 s), como pede a §4 do documento.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../cgflix/cgflix_palette.dart';

/// (x %, y %, tamanho em vmin, giro em graus, atraso em ms, figura Ichigo, figura Sorairo) — copiado do kids.html.
const _figures = <(double, double, double, double, int, String, String)>[
  (8, 12, 19.5, -12, 0, 'morango', 'nuvem'), (28, 6, 13.0, 18, 60, 'melancia', 'estrela'),
  (72, 8, 15.6, -8, 120, 'morango', 'aviao'), (90, 16, 18.2, 14, 180, 'coracao', 'nuvem'),
  (5, 48, 14.3, 20, 240, 'morango', 'nuvem'), (93, 50, 15.6, -16, 300, 'melancia', 'estrela'),
  (12, 80, 19.5, 8, 90, 'morango', 'aviao'), (32, 88, 13.0, -20, 150, 'coracao', 'nuvem'),
  (68, 86, 16.9, 12, 210, 'morango', 'nuvem'), (88, 82, 19.5, -6, 270, 'melancia', 'estrela'),
  (50, 6, 10.4, 0, 330, 'morango', 'aviao'), (50, 94, 11.7, 10, 30, 'coracao', 'nuvem'),
];

const _bounce = Cubic(.34, 1.45, .64, 1);
const _hold = 1600, _exit = 240;

class HeisucaKidsOpening extends StatefulWidget {
  const HeisucaKidsOpening({super.key, required this.variant, required this.name, this.onFinished});
  final CgflixThemeVariant variant;
  final String name;
  final VoidCallback? onFinished;

  /// Total da animação (o fluxo usa como tempo mínimo da cobertura enquanto troca a sessão).
  static Duration durationFor(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? const Duration(milliseconds: 600) : const Duration(milliseconds: _hold + _exit);

  @override
  State<HeisucaKidsOpening> createState() => _HeisucaKidsOpeningState();
}

class _HeisucaKidsOpeningState extends State<HeisucaKidsOpening> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.duration != null) return;
    _reduced = MediaQuery.disableAnimationsOf(context);
    _c.duration = HeisucaKidsOpening.durationFor(context);
    _c.forward().whenComplete(() { if (mounted) widget.onFinished?.call(); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  /// Progresso 0–1 de uma janela [start, end] em ms da linha do tempo.
  double _w(double ms, int start, int end, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((ms - start) / (end - start)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final palette = CgflixPalette.forVariant(widget.variant);
    final ichigo = widget.variant == CgflixThemeVariant.ichigo;
    final name = widget.name.trim().isEmpty ? '' : ', ${widget.name.trim().characters.take(24)}';
    return Material(color: palette.background, child: LayoutBuilder(builder: (context, box) {
      final vmin = math.min(box.maxWidth, box.maxHeight) / 100;
      return AnimatedBuilder(animation: _c, builder: (context, _) {
        final ms = _c.value * (_c.duration!.inMilliseconds);
        if (_reduced) {
          final o = ms < 120 ? ms / 120 : ms > 480 && widget.onFinished != null ? (600 - ms) / 120 : 1.0;
          return Opacity(opacity: o.clamp(0, 1), child: _center(palette, vmin, name, 1, 1, 1));
        }
        final exit = widget.onFinished == null ? 0.0 : _w(ms, _hold, _hold + _exit, Curves.easeInCubic);
        return Stack(children: [
          for (final f in _figures) () {
            final (x, y, size, rot, delay, a, b) = f;
            final fall = _w(ms, delay, delay + 640, _bounce);
            final float = ms > 1000 ? math.sin((ms - 1000) / 2400 * 2 * math.pi) * 1.2 * vmin : 0.0;
            final dx = (x - 50) / 50, dy = (y - 50) / 50;
            final px = x / 100 * box.maxWidth + dx * exit * 40 * vmin;
            final py = y / 100 * box.maxHeight - (1 - fall) * 30 * vmin + float + dy * exit * 40 * vmin;
            final t = size * vmin;
            return Positioned(left: px - t / 2, top: py - t / 2, width: t, height: t, child: Opacity(
              opacity: (fall * (1 - exit)).clamp(0.0, 1.0),
              child: Transform.rotate(angle: (rot + (1 - fall) * -40) * math.pi / 180,
                child: SvgPicture.asset('assets/heisuca/kids/${ichigo ? a : b}.svg'))));
          }(),
          _center(palette, vmin, name, _w(ms, 520, 1000, _bounce), _w(ms, 760, 1260), _w(ms, 1100, 1500), exit: exit),
        ]);
      });
    }));
  }

  Widget _center(CgflixPalette p, double vmin, String name, double selo, double hi, double sub, {double exit = 0}) {
    final text = p.onGlass;
    return Center(child: Opacity(opacity: 1 - exit, child: Transform.scale(scale: 1 - exit * .12, child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        Transform.scale(scale: selo, child: SizedBox.square(dimension: 22 * vmin,
          child: SvgPicture.asset('assets/heisuca/kids/selo_${widget.variant.name}.svg', semanticsLabel: 'Heisuca infantil'))),
        SizedBox(height: 3 * vmin),
        Opacity(opacity: hi, child: Transform.translate(offset: Offset(0, (1 - hi) * 3 * vmin), child: Text('Oi$name!',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Fredoka', fontVariations: const [FontVariation('wght', 600)],
            fontSize: 9 * vmin, height: 1.1, color: text)))),
        SizedBox(height: 1.2 * vmin),
        Opacity(opacity: sub, child: Transform.translate(offset: Offset(0, (1 - sub) * 2 * vmin), child: Text('Vamos assistir?',
          style: TextStyle(fontFamily: 'Fredoka', fontVariations: const [FontVariation('wght', 500)],
            fontSize: 4 * vmin, color: p.textMuted)))),
      ]))));
  }
}

/// Mostra a abertura por cima de tudo (navegador raiz) enquanto [work] troca a sessão; só sai
/// quando a animação termina E o trabalho acaba (cobertura do plano: esconde a troca).
Future<T> heisucaRunUnderKidsOpening<T>(BuildContext context, {required CgflixThemeVariant variant,
    required String name, required Future<T> Function() work}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final minimum = Future<void>.delayed(HeisucaKidsOpening.durationFor(context));
  final route = MaterialPageRoute<void>(fullscreenDialog: true,
    builder: (_) => PopScope(canPop: false, child: HeisucaKidsOpening(variant: variant, name: name)));
  navigator.push(route);
  try {
    final result = await work();
    await minimum;
    return result;
  } finally {
    if (navigator.mounted && route.isActive) navigator.removeRoute(route);
  }
}
