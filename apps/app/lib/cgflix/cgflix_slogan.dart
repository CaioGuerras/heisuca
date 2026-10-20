// CGFLIX (1.5.0): o slogan "Aperte o play", discreto, no login e na abertura do app.
// Aparece devagar depois do play da abertura; com "remover animações" do sistema, já parado.
import 'dart:async';

import 'package:flutter/material.dart';

import 'cgflix_palette.dart';
import 'cgflix_style.dart';

const cgflixSlogan = 'Aperte o play';

/// Na abertura, o slogan entra logo depois do play do emblema (~1 s de 1,4 s).
const cgflixSloganDelay = Duration(milliseconds: 1000);

class CgflixSlogan extends StatefulWidget {
  const CgflixSlogan({super.key, this.delay = Duration.zero, this.topPadding = 8});

  /// Espera antes de aparecer (na abertura: depois do play do emblema).
  final Duration delay;
  final double topPadding;

  @override
  State<CgflixSlogan> createState() => _CgflixSloganState();
}

class _CgflixSloganState extends State<CgflixSlogan> {
  bool _visible = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visible || _timer != null) return;
    if (MediaQuery.disableAnimationsOf(context) || widget.delay == Duration.zero) {
      _visible = true;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: EdgeInsets.only(top: widget.topPadding),
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: reduceMotion ? Duration.zero : CgflixMotion.slow,
        curve: CgflixMotion.curve,
        child: Text(
          cgflixSlogan,
          key: const ValueKey('cgflix-slogan'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: context.cgflix.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
