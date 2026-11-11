import 'package:flutter/material.dart';

import '../forma.dart';
import '../movimento.dart';
import '../tema.dart';
import '../vibracao.dart';

/// A resposta ao dedo de todo componente da V2.
///
/// Encolhe com mola ao apertar e volta ao soltar; com "remover animações", só esmaece.
/// Cuida do anel de foco, da semântica e da vibração. Não tem tinta nem onda do Material.
class Toque extends StatefulWidget {
  const Toque({
    super.key,
    required this.child,
    required this.forma,
    this.aoTocar,
    this.aoSegurar,
    this.rotulo,
    this.selecionado,
    this.vibracao,
    this.escala = 0.96,
    this.excluirSemantica = false,
  });

  final Widget child;

  /// Contorno do componente: é a forma do anel de foco.
  final OutlinedBorder forma;
  final VoidCallback? aoTocar;
  final VoidCallback? aoSegurar;

  /// Como o leitor de tela anuncia. Obrigatório quando o filho não tem texto.
  final String? rotulo;

  /// Para abas e interruptores; `null` para um botão comum.
  final bool? selecionado;

  /// Vibração do toque aceito; `null` não vibra.
  final Vibracao? vibracao;

  /// Tamanho do componente apertado, em relação ao normal.
  final double escala;

  /// O [rotulo] substitui a semântica do filho.
  final bool excluirSemantica;

  bool get ativo => aoTocar != null || aoSegurar != null;

  /// Opacidade do componente apertado quando o sistema pede menos movimento.
  static const double opacidadeApertado = 0.72;

  /// Opacidade do componente sem ação.
  static const double opacidadeInativo = 0.38;

  @override
  State<Toque> createState() => _ToqueState();
}

class _ToqueState extends State<Toque> with SingleTickerProviderStateMixin {
  /// 0 = solto, 1 = apertado. Sem limites: a mola pode passar um pouco do alvo.
  late final AnimationController _aperto = AnimationController.unbounded(vsync: this, value: 0);
  bool _apertado = false;
  bool _foco = false;
  bool _reduzido = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Guardado aqui: o cancelamento do toque pode chegar com o widget já fora da árvore.
    _reduzido = Movimento.reduzido(context);
  }

  @override
  void dispose() {
    _aperto.dispose();
    super.dispose();
  }

  void _apertar(bool apertado) {
    if (!mounted || !widget.ativo || _apertado == apertado) return;
    setState(() => _apertado = apertado);
    if (_reduzido) {
      _aperto.value = 0;
      return;
    }
    Movimento.comMola(_aperto, apertado ? 1 : 0, mola: Movimento.molaRapida);
  }

  void _tocar() {
    final acao = widget.aoTocar;
    if (acao == null) return;
    widget.vibracao?.tocar();
    acao();
  }

  void _segurar() {
    final acao = widget.aoSegurar;
    if (acao == null) return;
    Vibracao.confirmar.tocar();
    _apertar(false);
    acao();
  }

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final reduzido = _reduzido;
    final opacidade = !widget.ativo ? Toque.opacidadeInativo : (reduzido && _apertado ? Toque.opacidadeApertado : 1.0);

    Widget filho = AnimatedOpacity(
      opacity: opacidade,
      duration: Movimento.tempo(context, Movimento.toque),
      curve: Movimento.padrao,
      child: widget.child,
    );
    filho = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: ShapeDecoration(
        shape: widget.forma.copyWith(
          side: _foco
              ? BorderSide(color: tema.foco, width: Forma.anelDeFoco, strokeAlign: BorderSide.strokeAlignOutside)
              : BorderSide.none,
        ),
      ),
      child: filho,
    );
    filho = AnimatedBuilder(
      animation: _aperto,
      builder: (context, child) => Transform.scale(scale: 1 - (1 - widget.escala) * _aperto.value, child: child),
      child: filho,
    );

    return Semantics(
      container: true,
      button: widget.selecionado == null,
      selected: widget.selecionado,
      enabled: widget.ativo,
      label: widget.rotulo,
      excludeSemantics: widget.excluirSemantica,
      onTap: widget.aoTocar == null ? null : _tocar,
      onLongPress: widget.aoSegurar == null ? null : _segurar,
      child: FocusableActionDetector(
        enabled: widget.ativo,
        mouseCursor: widget.ativo ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (foco) => setState(() => _foco = foco),
        actions: <Type, Action<Intent>>{ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _tocar())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: (_) => _apertar(true),
          onTapUp: (_) => _apertar(false),
          onTapCancel: () => _apertar(false),
          onTap: widget.aoTocar == null ? null : _tocar,
          onLongPress: widget.aoSegurar == null ? null : _segurar,
          child: filho,
        ),
      ),
    );
  }
}
