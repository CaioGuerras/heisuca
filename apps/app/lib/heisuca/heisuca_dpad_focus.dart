import 'package:flutter/material.dart';

import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';

/// Anel de foco do D-pad para controles Material/InkWell do Heisuca.
///
/// O realce de tinta do InkWell/IconButton é pintado no Material, por baixo de fundos
/// e imagens da tela, e some. Este widget não cria outro ponto de foco: observa o foco
/// do controle embrulhado e, só no modo teclado/D-pad, pinta por cima a mesma borda do
/// [FocusTheme] (token de foco da paleta) que o FocusableWrapper usa.
class HeisucaDpadFocus extends StatefulWidget {
  const HeisucaDpadFocus({super.key, required this.child, this.borderRadius = 12, this.radii});

  final Widget child;
  final double borderRadius;

  /// Raios por canto; vence [borderRadius] (grupos de linhas com cantos externos maiores).
  final BorderRadius? radii;

  @override
  State<HeisucaDpadFocus> createState() => _HeisucaDpadFocusState();
}

class _HeisucaDpadFocusState extends State<HeisucaDpadFocus> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final show = _focused && InputModeTracker.isKeyboardMode(context);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) { if (mounted) setState(() => _focused = value); },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: FocusTheme.focusDecoration(context, isFocused: show, borderRadius: widget.borderRadius, radii: widget.radii),
        child: widget.child,
      ),
    );
  }
}
