import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../cgflix/cgflix_palette.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import 'heisuca_title_logo.dart';
import 'heisuca_logo.dart';
import 'heisuca_source_scope.dart';
import 'kids/heisuca_kids_flow.dart';
import 'heisuca_title_sheet.dart';

/// A única logo do título acompanha sua posição real e para entre a marca e a busca.
/// O topo é transparente; o véu em degradê aparece somente depois do encaixe.
class HeisucaHomeChrome extends StatefulWidget {
  const HeisucaHomeChrome({super.key, required this.scrollController, required this.logoAnchor,
    required this.pageColor, required this.onSearch, required this.onHome, required this.onDockedChanged,
    this.item, this.client, this.onBack, this.onTitleTap, this.belowHeaderAction, this.titleFontFamily,
    this.expandedLogoWidth, this.expandedLogoHeight = 56, this.expandedTitleSize = 23});
  final ScrollController scrollController;
  final GlobalKey logoAnchor;
  final Color pageColor;
  final MediaItem? item;
  final MediaServerClient? client;
  final VoidCallback? onBack, onTitleTap;
  final Widget? belowHeaderAction;
  final String? titleFontFamily;
  final double? expandedLogoWidth;
  final double expandedLogoHeight, expandedTitleSize;
  final VoidCallback onSearch;
  final VoidCallback onHome;
  final ValueChanged<bool> onDockedChanged;

  @override
  State<HeisucaHomeChrome> createState() => _HeisucaHomeChromeState();
}

class _HeisucaHomeChromeState extends State<HeisucaHomeChrome> {
  Rect? _anchor;
  bool _scheduled = false, _docked = false;

  @override
  void initState() { super.initState(); widget.scrollController.addListener(_scheduleMeasure); _scheduleMeasure(); }
  @override
  void didUpdateWidget(HeisucaHomeChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_scheduleMeasure);
      widget.scrollController.addListener(_scheduleMeasure);
    }
    _scheduleMeasure();
  }
  @override
  void dispose() { widget.scrollController.removeListener(_scheduleMeasure); super.dispose(); }

  void _scheduleMeasure() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final box = widget.logoAnchor.currentContext?.findRenderObject();
      final root = context.findRenderObject();
      if (box is! RenderBox || root is! RenderBox || !box.hasSize || !root.hasSize) return;
      final rect = (box.localToGlobal(Offset.zero) - root.localToGlobal(Offset.zero)) & box.size;
      final docked = rect.center.dy <= MediaQuery.paddingOf(context).top + 30;
      if (_anchor != rect || _docked != docked) setState(() { _anchor = rect; _docked = docked; });
      widget.onDockedChanged(docked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final foreground = context.cgflix.isLight ? const Color(0xFF1C2421) : const Color(0xFFF4F1FA);
    final rect = _anchor;
    final naturalWidth = widget.expandedLogoWidth ?? math.min(width * 0.54, 210.0);
    final brandWidth = 28 * 637.981715 / 206;
    final sideGap = math.min(width / 2 - 14 - brandWidth, width / 2 - 14 - 48);
    final room = (sideGap * 2 - 40).clamp(naturalWidth * 0.3, naturalWidth);
    final dockScale = (room / naturalWidth).clamp(0.3, 1.0);
    final center = rect?.center.dy ?? top + 30;
    final target = top + 30;
    final progress = ((target + 140 - center) / 140).clamp(0.0, 1.0);
    final scale = 1 - (1 - dockScale) * progress;
    final logoWidth = naturalWidth * scale, logoHeight = widget.expandedLogoHeight * scale;
    final tapHeight = math.max(48.0, logoHeight);

    return Stack(clipBehavior: Clip.none, children: [
      if (_docked) Positioned(top: 0, left: 0, right: 0, height: top + 96,
        child: IgnorePointer(child: DecoratedBox(key: const ValueKey('heisuca-top-veil'), decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [widget.pageColor, widget.pageColor, widget.pageColor.withValues(alpha: 0)], stops: const [0, 0.55, 1]),
        )))),
      Positioned(top: top + 6, left: 14, right: 14, height: 48,
        child: Row(children: [
          Semantics(button: true, label: 'Heisuca: trocar fonte', child: InkWell(onTap: heisucaKidsActive(context) ? null : () => heisucaChooseSource(context),
            child: const SizedBox(height: 48, child: Center(widthFactor: 1,
              child: HeisucaLogo(height: 28, siteHeader: true))))),
          const Spacer(),
          IconButton.filledTonal(tooltip: 'Buscar', onPressed: widget.onSearch,
            style: IconButton.styleFrom(backgroundColor: widget.pageColor.withValues(alpha: 0.55), foregroundColor: foreground),
            icon: const Icon(Icons.search_rounded, size: 24)),
        ])),
      if (widget.onBack != null) Positioned(top: top + 62, left: 14, right: 14,
        child: Row(children: [IconButton.filledTonal(tooltip: 'Voltar', onPressed: widget.onBack,
          style: IconButton.styleFrom(backgroundColor: widget.pageColor.withValues(alpha: .55), foregroundColor: foreground),
          icon: const Icon(Icons.arrow_back_rounded)),
          if (widget.belowHeaderAction != null) ...[const SizedBox(width: 10), Expanded(child: widget.belowHeaderAction!)],
        ])),
      if (widget.item != null && rect != null) Positioned(
        key: const ValueKey('heisuca-docking-logo'),
        top: math.max(center, target) - tapHeight / 2, left: (width - logoWidth) / 2,
        width: logoWidth, height: tapHeight,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTitleTap ?? () => HeisucaTitleSheet.show(context, widget.item!),
          child: Center(child: SizedBox(height: logoHeight, child: HeisucaTitleLogo(client: widget.client, item: widget.item!,
            width: logoWidth, height: logoHeight, fallbackWidth: logoWidth, alignment: Alignment.center,
            logoToneTarget: context.cgflix.isLight ? foreground : null,
            fallbackBuilder: (_) => Center(child: Text(widget.item!.displayTitle, maxLines: 2,
              textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: widget.titleFontFamily, fontSize: widget.expandedTitleSize * scale, fontWeight: FontWeight.w600, color: foreground))),
          )))),
      ),
    ]);
  }
}
