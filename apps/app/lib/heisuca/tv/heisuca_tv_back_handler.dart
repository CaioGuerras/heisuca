import 'package:flutter/material.dart';

import '../../utils/platform_detector.dart';
import 'heisuca_tv_pecas.dart';

/// Gerenciador de navegação de "Voltar" exclusivo para TV.
/// Regras:
/// - No Início: 1º Voltar leva o foco ao destaque;
/// - No destaque: Voltar sai do app no Google/Android TV e pede confirmação curta na Fire TV (fabricante Amazon);
/// - Em qualquer outra tela, volta um nível;
/// - Nunca sair sem querer.
class HeisucaTvBackHandler {
  HeisucaTvBackHandler({
    this.isFireTv,
    required this.isAtHeroDestaque,
    required this.onScrollToDestaque,
    required this.onExitApp,
    required this.onShowConfirmation,
  });

  final bool? isFireTv;
  final bool Function() isAtHeroDestaque;
  final VoidCallback onScrollToDestaque;
  final VoidCallback onExitApp;
  final VoidCallback onShowConfirmation;

  bool _effectiveIsFireTv() {
    if (isFireTv != null) return isFireTv!;
    return PlatformDetector.isFireTV();
  }

  /// Retorna true se a tecla Back foi tratada/consumida.
  bool handleBack() {
    // Se não estiver no topo / destaque do Início: leva o foco ao destaque
    if (!isAtHeroDestaque()) {
      onScrollToDestaque();
      return true;
    }

    // Já está no destaque
    if (_effectiveIsFireTv()) {
      onShowConfirmation();
      return true;
    } else {
      onExitApp();
      return true;
    }
  }

  /// Confirmação curta de saída da Fire TV: o mesmo diálogo do "Sair" dos Ajustes (foco em Cancelar).
  static Future<bool> showExitConfirmationDialog(BuildContext context) => ConfirmarSaidaTv.mostrar(context);
}
