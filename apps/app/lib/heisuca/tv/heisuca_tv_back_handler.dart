import 'package:flutter/material.dart';

import '../../utils/platform_detector.dart';

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

  /// Exibe diálogo leve de confirmação de saída para Fire TV
  static Future<bool> showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x990C0B0F),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF292531),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Deseja sair do Heisuca?',
          style: TextStyle(
            color: Color(0xFFF2EFF5),
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFFB9B1C4),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF17151C),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sair',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
