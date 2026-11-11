import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../forma.dart';
import '../movimento.dart';
import '../tema.dart';
import '../tipo.dart';
import '../vibracao.dart';
import 'toque.dart';

/// Um destino da barra flutuante.
@immutable
class DestinoDaBarra {
  const DestinoDaBarra({required this.icone, required this.rotulo});
  final IconData icone;
  final String rotulo;
}

/// A ilha de navegação: uma pílula que flutua sobre o conteúdo, no pé da tela.
///
/// O marcador do destino ativo desliza com mola; o ícone ativo se preenche. Com
/// "remover animações", o marcador troca de lugar sem deslizar.
class BarraFlutuante extends StatefulWidget {
  const BarraFlutuante({
    super.key,
    required this.destinos,
    required this.indice,
    required this.aoMudar,
    this.desfoque = true,
  }) : assert(destinos.length >= 2 && destinos.length <= 5),
       assert(indice >= 0 && indice < destinos.length);

  final List<DestinoDaBarra> destinos;
  final int indice;
  final ValueChanged<int> aoMudar;

  /// Desfoca o conteúdo que passa por baixo. Desligar em telas que já pesam na GPU.
  final bool desfoque;

  static const double altura = 64;
  static const double larguraMaxima = 420;
  static const double _opacidade = 0.86;
  static const double _desfoque = 24;
  static const double _icone = 24;

  /// A letra do rótulo cresce com o sistema só até aqui: a ilha tem altura fixa.
  static const double _letraMaxima = 1.3;

  @override
  State<BarraFlutuante> createState() => _BarraFlutuanteState();
}

class _BarraFlutuanteState extends State<BarraFlutuante> with SingleTickerProviderStateMixin {
  /// Posição do marcador, em "número do destino". Sem limites: a mola passa um pouco e volta.
  late final AnimationController _marcador = AnimationController.unbounded(
    vsync: this,
    value: widget.indice.toDouble(),
  );

  @override
  void didUpdateWidget(BarraFlutuante antiga) {
    super.didUpdateWidget(antiga);
    if (antiga.indice != widget.indice) {
      Movimento.comMola(_marcador, widget.indice.toDouble(), reduzido: Movimento.reduzido(context));
    }
  }

  @override
  void dispose() {
    _marcador.dispose();
    super.dispose();
  }

  void _escolher(int i) {
    if (i == widget.indice) return;
    Vibracao.alternar.tocar();
    widget.aoMudar(i);
  }

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final forma = Forma.pilula(lado: BorderSide(color: tema.borda));
    final n = widget.destinos.length;

    Widget ilha = DecoratedBox(
      decoration: ShapeDecoration(
        color: tema.superficie.withValues(alpha: BarraFlutuante._opacidade),
        shape: forma,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Forma.espaco1),
        child: LayoutBuilder(
          builder: (context, limites) {
            final passo = limites.maxWidth / n;
            return Stack(
              children: [
                AnimatedBuilder(
                  animation: _marcador,
                  builder: (context, child) => Positioned.directional(
                    textDirection: Directionality.of(context),
                    start: _marcador.value * passo,
                    top: 0,
                    bottom: 0,
                    width: passo,
                    child: child!,
                  ),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(color: tema.acentoSuave, shape: Forma.pilula()),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: _Destino(
                          destino: widget.destinos[i],
                          ativo: i == widget.indice,
                          aoTocar: () => _escolher(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
    if (widget.desfoque) {
      ilha = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: BarraFlutuante._desfoque, sigmaY: BarraFlutuante._desfoque),
        child: ilha,
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BarraFlutuante.larguraMaxima),
        child: SizedBox(
          height: BarraFlutuante.altura,
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: forma),
            child: ilha,
          ),
        ),
      ),
    );
  }
}

class _Destino extends StatelessWidget {
  const _Destino({required this.destino, required this.ativo, required this.aoTocar});

  final DestinoDaBarra destino;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final tempo = Movimento.tempo(context, Movimento.troca);
    return Toque(
      forma: Forma.pilula(),
      rotulo: destino.rotulo,
      excluirSemantica: true,
      selecionado: ativo,
      aoTocar: aoTocar,
      escala: 0.94,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: ativo ? 1 : 0),
        duration: tempo,
        curve: Movimento.padrao,
        builder: (context, t, _) {
          final tinta = Color.lerp(tema.texto2, tema.texto, t)!;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(destino.icone, size: BarraFlutuante._icone, color: tinta, fill: t),
              Text(
                destino.rotulo,
                style: Tipo.legenda(tema).copyWith(color: tinta, fontWeight: ativo ? FontWeight.w600 : FontWeight.w500),
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: BarraFlutuante._letraMaxima),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}
