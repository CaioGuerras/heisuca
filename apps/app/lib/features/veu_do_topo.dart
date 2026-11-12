import 'package:flutter/material.dart';

import '../design/forma.dart';
import '../design/tema.dart';

/// Véu no tom do papel atrás da barra de status, para as horas e os ícones se lerem sobre a arte.
///
/// Vai dentro de um [Stack], por cima da lista. Não recebe toque.
class VeuDoTopo extends StatelessWidget {
  const VeuDoTopo({super.key});

  static const double opacidade = 0.55;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.paddingOf(context).top + Forma.espaco6,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tema.fundo.withValues(alpha: opacidade),
                tema.fundo.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
