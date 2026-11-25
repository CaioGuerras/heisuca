import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/dpad_select_long_press_controller.dart';

/// OK curto e longo são mutuamente exclusivos, inclusive quando o controle repete a tecla.
/// Usa o controlador de OK longo do app; sair do cartão cancela o gesto pendente.
class SegurarOkTv extends StatefulWidget {
  const SegurarOkTv({super.key, required this.child, this.aoTocar, this.aoSegurar});

  final Widget child;
  final VoidCallback? aoTocar;
  final VoidCallback? aoSegurar;

  @override
  State<SegurarOkTv> createState() => _SegurarOkTvState();
}

class _SegurarOkTvState extends State<SegurarOkTv> {
  final _pressionar = DpadSelectLongPressController();
  bool _focado = false;

  @override
  void dispose() {
    _pressionar.dispose();
    super.dispose();
  }

  KeyEventResult _tecla(FocusNode _, KeyEvent event) {
    if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
      _pressionar.reset();
      return KeyEventResult.handled;
    }
    if (widget.aoSegurar == null || !event.isTvSelectEvent) return KeyEventResult.ignored;
    return _pressionar.handleKeyEvent(
      event,
      isOwnerActive: () => mounted && _focado,
      onShortPress: () => widget.aoTocar?.call(),
      onLongPress: () => widget.aoSegurar?.call(),
    );
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: _tecla,
    onFocusChange: (focado) {
      _focado = focado;
      if (!focado) _pressionar.reset();
    },
    child: widget.child,
  );
}
