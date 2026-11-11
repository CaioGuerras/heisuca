import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../heisuca/theme/heisuca_base.dart';

/// Tempos, curvas e molas da V2.
///
/// Os tempos e as curvas vêm dos tokens gerados. Regra de uso:
/// - posição, escala e forma usam mola ([molaRapida], [molaPadrao], [molaLenta]);
/// - cor e opacidade usam tempo e curva, e nunca quicam;
/// - com "remover animações" ligado no sistema, nada se desloca: só esmaece em [troca].
abstract final class Movimento {
  static const Duration toque = HeisucaBase.movimentoToque;
  static const Duration troca = HeisucaBase.movimentoTroca;
  static const Duration cartao = HeisucaBase.movimentoCartao;
  static const Duration tela = HeisucaBase.movimentoTela;
  static const Duration longe = HeisucaBase.movimentoLonge;
  static const Duration tema = HeisucaBase.movimentoTema;
  static const Duration escada = HeisucaBase.movimentoEscada;

  static const Curve entra = HeisucaBase.movimentoCurvaEntra;
  static const Curve sai = HeisucaBase.movimentoCurvaSai;
  static const Curve padrao = HeisucaBase.movimentoCurvaPadrao;

  /// Molas espaciais do Material 3 Expressive (rigidez e amortecimento do esquema expressivo).
  static final SpringDescription molaRapida = SpringDescription.withDampingRatio(mass: 1, stiffness: 800, ratio: 0.6);
  static final SpringDescription molaPadrao = SpringDescription.withDampingRatio(mass: 1, stiffness: 380, ratio: 0.8);
  static final SpringDescription molaLenta = SpringDescription.withDampingRatio(mass: 1, stiffness: 200, ratio: 0.8);

  /// Quantos itens de uma lista entram em escada; do [_tetoDaEscada] em diante entram juntos.
  static const int _tetoDaEscada = 8;

  /// O sistema pediu para remover animações.
  static bool reduzido(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  /// Tempo a usar: o [cheio], ou no máximo [troca] quando o sistema pede menos movimento.
  static Duration tempo(BuildContext context, Duration cheio) => tempoPara(cheio, reduzido: reduzido(context));

  static Duration tempoPara(Duration cheio, {required bool reduzido}) => reduzido && cheio > troca ? troca : cheio;

  /// Atraso do item [indice] de uma lista que entra em escada.
  static Duration atrasoDaEscada(int indice, {required bool reduzido}) {
    if (reduzido || indice <= 0) return Duration.zero;
    return escada * math.min(indice, _tetoDaEscada);
  }

  /// Leva [controle] até [alvo] com mola. Com [reduzido], vai direto ao alvo, sem deslocamento.
  ///
  /// [velocidade] é a do gesto que soltou o item, em unidades do controle por segundo.
  static TickerFuture comMola(
    AnimationController controle,
    double alvo, {
    SpringDescription? mola,
    double velocidade = 0,
    bool reduzido = false,
  }) {
    assert(
      controle.lowerBound == double.negativeInfinity && controle.upperBound == double.infinity,
      'A mola passa do alvo: crie o controle com AnimationController.unbounded.',
    );
    if (reduzido) {
      controle.value = alvo;
      return TickerFuture.complete();
    }
    return controle.animateWith(SpringSimulation(mola ?? molaPadrao, controle.value, alvo, velocidade));
  }
}
