import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../design/forma.dart';
import '../design/movimento.dart';
import '../design/tema.dart';

/// Área de uma tela com véu no topo: escuta a rolagem vertical da lista e avisa o [VeuDoTopo]
/// de dentro quando o conteúdo passa por baixo dos botões do topo.
///
/// Envolve o [Stack] da tela (a lista e o véu ficam dentro dele). [limite] é quantos pixels a lista
/// pode rolar antes de o conteúdo chegar aos botões: na Início, o destaque fica por baixo de propósito
/// (os botões são feitos para ficar sobre a arte), então o limite é o fim do destaque.
class AreaDoVeu extends StatefulWidget {
  const AreaDoVeu({super.key, this.limite = 0, required this.child});

  final double limite;
  final Widget child;

  @override
  State<AreaDoVeu> createState() => _AreaDoVeuState();
}

class _AreaDoVeuState extends State<AreaDoVeu> {
  final _sobConteudo = ValueNotifier(false);

  @override
  void dispose() {
    _sobConteudo.dispose();
    super.dispose();
  }

  bool _rolou(ScrollNotification aviso) {
    // Só a lista principal: as fileiras horizontais e listas internas não contam.
    if (aviso.depth == 0 && aviso.metrics.axis == Axis.vertical) {
      _sobConteudo.value = aviso.metrics.pixels > widget.limite;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
    onNotification: _rolou,
    child: _SobConteudo(notifier: _sobConteudo, child: widget.child),
  );
}

class _SobConteudo extends InheritedNotifier<ValueNotifier<bool>> {
  const _SobConteudo({required super.notifier, required super.child});
}

/// Véu no tom do papel atrás da barra de status, para as horas e os ícones se lerem sobre a arte.
///
/// Vai dentro de um [Stack], por cima da lista. Não recebe toque. Dentro de uma [AreaDoVeu], vira
/// barra (papel quase opaco com desfoque, cobrindo também a pílula do perfil e a busca) quando o
/// conteúdo rola por baixo do topo; sem ela, fica só o degradê da barra de status.
class VeuDoTopo extends StatelessWidget {
  const VeuDoTopo({super.key});

  static const double opacidade = 0.55;

  /// Opacidade do papel quando o véu vira barra: o texto que passa por baixo não compete com a pílula.
  static const double opacidadeDaBarra = 0.86;

  static const double desfoque = 24;

  /// Altura da barra: a barra de status mais a fileira da pílula e da busca.
  static double alturaDaBarra(BuildContext context) =>
      MediaQuery.paddingOf(context).top + Forma.espaco2 + Forma.toqueMinimo + Forma.espaco2;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final degrade = IgnorePointer(
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
    );
    final aviso = context.dependOnInheritedWidgetOfExactType<_SobConteudo>()?.notifier;
    if (aviso == null) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: MediaQuery.paddingOf(context).top + Forma.espaco6,
        child: degrade,
      );
    }
    final sob = aviso.value;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: alturaDaBarra(context),
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.paddingOf(context).top + Forma.espaco6,
              child: degrade,
            ),
            AnimatedOpacity(
              key: const ValueKey('veu-do-topo-barra'),
              opacity: sob ? 1 : 0,
              duration: Movimento.tempo(context, Movimento.troca),
              curve: Movimento.padrao,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: desfoque, sigmaY: desfoque),
                  child: ColoredBox(color: tema.fundo.withValues(alpha: opacidadeDaBarra)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
