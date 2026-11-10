import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Os três toques com sentido da V2. Nenhuma tela chama `HapticFeedback` direto.
enum Vibracao {
  /// Uma ação foi aceita: favoritar, marcar como visto, baixar.
  confirmar,

  /// Um interruptor ou uma aba mudou de estado.
  alternar,

  /// A barra de progresso, o brilho ou o volume passou por um passo.
  passo;

  /// Intervalo mínimo entre dois [passo]: arrastar a barra não vira um zumbido.
  static const Duration intervaloDoPasso = Duration(milliseconds: 40);

  static DateTime? _ultimoPasso;

  @visibleForTesting
  static DateTime Function() relogio = DateTime.now;

  @visibleForTesting
  static void zerar() => _ultimoPasso = null;

  Future<void> tocar() {
    switch (this) {
      case Vibracao.confirmar:
        return HapticFeedback.mediumImpact();
      case Vibracao.alternar:
        return HapticFeedback.lightImpact();
      case Vibracao.passo:
        final agora = relogio();
        final ultimo = _ultimoPasso;
        if (ultimo != null && agora.difference(ultimo) < intervaloDoPasso) return Future<void>.value();
        _ultimoPasso = agora;
        return HapticFeedback.selectionClick();
    }
  }
}
