import 'package:flutter/material.dart';
import '../cgflix/cgflix_palette.dart';
import '../media/ids.dart';
import '../providers/multi_server_provider.dart';
import 'heisuca_theme.dart';

enum HeisucaSourceStatus { online, connecting, offline, error }
HeisucaSourceStatus heisucaSourceStatus(MultiServerProvider servers, String id, {bool binding = false}) {
  if (servers.isServerOnline(ServerId(id))) return HeisucaSourceStatus.online;
  if (servers.serverManager.isServerConnecting(ServerId(id)) || binding) return HeisucaSourceStatus.connecting;
  if (servers.refusedServerIds.contains(id)) return HeisucaSourceStatus.error;
  return HeisucaSourceStatus.offline;
}

/// Três caminhos encontram uma origem: sinal próprio de fonte, sem desenho de hardware.
class HeisucaSourceMark extends StatelessWidget {
  const HeisucaSourceMark({super.key, this.size = 24, this.color});
  final double size;
  final Color? color;
  @override Widget build(BuildContext context) => ExcludeSemantics(child: SizedBox(width: size, height: size,
    child: CustomPaint(painter: _SourcePainter(color ?? context.cgflix.accent))));
}
class _SourcePainter extends CustomPainter {
  const _SourcePainter(this.color);
  final Color color;
  @override void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..moveTo(4, 5)..cubicTo(14, 5, 9, 12, 17, 12)
      ..moveTo(4, 12)..lineTo(17, 12)..moveTo(4, 19)..cubicTo(14, 19, 9, 12, 17, 12), pen);
    canvas.drawCircle(const Offset(19, 12), 2, pen);
  }
  @override bool shouldRepaint(_SourcePainter old) => old.color != color;
}
class HeisucaSourceDot extends StatelessWidget {
  const HeisucaSourceDot({super.key, required this.status});
  final HeisucaSourceStatus status;
  String get label => switch (status) {
    HeisucaSourceStatus.online => 'On-line', HeisucaSourceStatus.connecting => 'Conectando',
    HeisucaSourceStatus.offline => 'Fora do ar', HeisucaSourceStatus.error => 'Erro de acesso',
  };
  @override Widget build(BuildContext context) => Semantics(label: label, child: SizedBox(width: 24, height: 24,
    child: Center(child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: switch (status) {
      HeisucaSourceStatus.online => const Color(0xff16824b), HeisucaSourceStatus.connecting => const Color(0xffb47a16),
      HeisucaSourceStatus.offline => const Color(0xff88838d), HeisucaSourceStatus.error => const Color(0xffce3939),
    }), child: const SizedBox(width: 8, height: 8)))));
}
class HeisucaSourceRow extends StatelessWidget {
  const HeisucaSourceRow({super.key, required this.title, required this.subtitle, this.status,
    this.selected, this.onTap, this.leading});
  final String title, subtitle;
  final HeisucaSourceStatus? status;
  final bool? selected;
  final VoidCallback? onTap;
  final Widget? leading;
  @override Widget build(BuildContext context) {
    final palette = context.cgflix;
    return Semantics(selected: selected, button: onTap != null, child: Material(color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17), child: Row(children: [
          leading ?? const HeisucaSourceMark(), const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 16,
              fontWeight: selected == true ? FontWeight.w700 : FontWeight.w500, color: palette.onGlass)),
            const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontFamily: HeisucaTheme.fonteTexto,
              fontSize: 12, color: palette.textMuted)),
          ])),
          if (status != null) ...[const SizedBox(width: 8), HeisucaSourceDot(status: status!)],
          if (selected == true) ...[const SizedBox(width: 6), Icon(Icons.check_rounded, size: 18, color: palette.accent)],
        ])))));
  }
}

class HeisucaSourceSheet extends StatelessWidget {
  const HeisucaSourceSheet({super.key, required this.title, required this.children, this.subtitle});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  @override Widget build(BuildContext context) => Material(color: context.cgflix.background, child: SafeArea(
    top: false, child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(top: 10, bottom: 14), children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 24, fontWeight: FontWeight.w600, color: context.cgflix.onGlass)),
        if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!, style: TextStyle(color: context.cgflix.textMuted, fontSize: 13))],
      ])), ...children,
    ])));
}
