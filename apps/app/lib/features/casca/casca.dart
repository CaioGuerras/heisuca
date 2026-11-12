import 'package:flutter/material.dart';

import '../../design/componentes/barra_flutuante.dart';
import '../../design/forma.dart';
import '../tema_da_v2.dart';

/// A casca do app: a tela do destino atual e, por cima dela, a ilha de navegação.
///
/// A ilha flutua no pé da tela, acima da barra de gestos, e some enquanto o teclado está aberto.
/// A tela de baixo ocupa a tela toda e passa por baixo da ilha: ela guarda [reserva] no fim da rolagem.
class Casca extends StatelessWidget {
  const Casca({
    super.key,
    required this.corpo,
    required this.destinos,
    required this.indice,
    required this.aoMudar,
    this.desfoque = true,
  });

  /// A tela do destino atual.
  final Widget corpo;
  final List<DestinoDaBarra> destinos;
  final int indice;

  /// Chamado no toque em outro destino. O toque no destino atual não chama.
  final ValueChanged<int> aoMudar;

  /// Repassado à [BarraFlutuante].
  final bool desfoque;

  /// Distância entre a ilha e a barra de gestos (ou a borda de baixo).
  static const double folgaDaIlha = Forma.espaco3;

  /// Espaço que a ilha toma no pé da tela, acima da barra de gestos.
  static const double reserva = BarraFlutuante.altura + folgaDaIlha * 2;

  @override
  Widget build(BuildContext context) {
    // Lido aqui, acima do Scaffold: dentro dele o teclado já foi descontado.
    final tecladoAberto = MediaQuery.viewInsetsOf(context).bottom > 0;
    final embaixo = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: corpo),
          if (!tecladoAberto)
            Positioned(
              left: Forma.espaco4,
              right: Forma.espaco4,
              bottom: embaixo + folgaDaIlha,
              child: Center(
                child: SobOTemaDaV2(
                  child: BarraFlutuante(destinos: destinos, indice: indice, aoMudar: aoMudar, desfoque: desfoque),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
