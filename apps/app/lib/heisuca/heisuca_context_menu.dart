import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../media/media_item.dart';
import 'heisuca_design_system.dart';
import 'heisuca_seerr_sheet.dart';
import 'heisuca_theme.dart';

/// Menu de Toque Longo 500ms Flagship Heisuca
/// Disparado após pré-tensão elástica aos 200ms com haptic feedback.
/// Destaca o card selecionado com zoom suave e abre o menu flutuante em vidro fosco.
class HeisucaContextMenu extends StatelessWidget {
  const HeisucaContextMenu({
    super.key,
    required this.item,
    required this.onPlay,
    required this.onToggleFavorite,
    required this.onDownload,
  });

  final MediaItem item;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDownload;

  static Future<void> show(
    BuildContext context, {
    required MediaItem item,
    required VoidCallback onPlay,
    required VoidCallback onToggleFavorite,
    required VoidCallback onDownload,
  }) {
    HapticFeedback.mediumImpact();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar menu',
      barrierColor: Colors.black.withOpacity(0.70),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8.0 * anim1.value, sigmaY: 8.0 * anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: HeisucaContextMenu(
              item: item,
              onPlay: onPlay,
              onToggleFavorite: onToggleFavorite,
              onDownload: onDownload,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310.0,
      decoration: BoxDecoration(
        color: const Color(0xFF151120),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 28.0,
            spreadRadius: 4.0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título do Item
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF4F1FA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Divisor
          Divider(color: Colors.white.withOpacity(0.08), height: 1.0),
          const SizedBox(height: 8.0),

          // Opção 1: Reproduzir Imediatamente
          _buildActionTile(
            icon: Symbols.play_arrow_rounded,
            title: 'Reproduzir Imediatamente',
            color: const Color(0xFF7A40F2),
            onTap: () {
              Navigator.pop(context);
              onPlay();
            },
          ),

          // Opção 2: Marcar como Assistido
          _buildActionTile(
            icon: Symbols.check_circle_rounded,
            title: 'Marcar como Assistido',
            color: const Color(0xFF34D399),
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
          ),

          // Opção 3: Adicionar / Remover dos Favoritos
          _buildActionTile(
            icon: Symbols.favorite_rounded,
            title: 'Favoritar',
            color: const Color(0xFFFF5252),
            onTap: () {
              Navigator.pop(context);
              onToggleFavorite();
            },
          ),

          // Opção 4: Download Offline
          _buildActionTile(
            icon: Symbols.download_rounded,
            title: 'Baixar para o Celular',
            color: const Color(0xFF38BDF8),
            onTap: () {
              Navigator.pop(context);
              onDownload();
            },
          ),

          // Opção 5: Pedir no Seerr
          _buildActionTile(
            icon: Symbols.cloud_download_rounded,
            title: 'Pedir no Seerr',
            color: const Color(0xFFA78BFA),
            onTap: () {
              Navigator.pop(context);
              HeisucaSeerrSheet.show(context, title: item.title ?? '', year: item.year);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: HeisucaSpringPressable(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFF4F1FA),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
