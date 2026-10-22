import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../cgflix/cgflix_palette.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import 'heisuca_design_system.dart';
import 'heisuca_seerr_sheet.dart';
import 'heisuca_theme.dart';

/// Menu de Toque Longo 500ms Flagship Heisuca (Esboço 04B).
/// Segurar 500ms dispara Haptic Feedback (mediumImpact), eleva o card e
/// abre o menu flutuante em vidro fosco com rótulo à esquerda e ícone à direita.
class HeisucaContextMenu extends StatelessWidget {
  const HeisucaContextMenu({
    super.key,
    required this.item,
    this.isContinueRow = false,
    this.onPlay,
    this.onOpenDetails,
    this.onToggleWatched,
    this.onToggleFavorite,
    this.onDownload,
  });

  final MediaItem item;
  final bool isContinueRow;
  final VoidCallback? onPlay;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onToggleWatched;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDownload;

  static Future<void> show(
    BuildContext context, {
    required MediaItem item,
    bool isContinueRow = false,
    VoidCallback? onPlay,
    VoidCallback? onOpenDetails,
    VoidCallback? onToggleWatched,
    VoidCallback? onToggleFavorite,
    VoidCallback? onDownload,
  }) {
    HapticFeedback.mediumImpact();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar menu',
      barrierColor: Colors.black.withValues(alpha: 0.65),
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
              isContinueRow: isContinueRow,
              onPlay: onPlay,
              onOpenDetails: onOpenDetails,
              onToggleWatched: onToggleWatched,
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
    final palette = context.cgflix;
    final isLight = palette.isLight;
    final isEpisode = item.kind == MediaKind.episode;
    final isShow = item.kind == MediaKind.show || isEpisode;

    final bgColor = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF151120);
    final borderColor = isLight
        ? const Color(0xFF047857).withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.12);
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final subColor = isLight ? const Color(0xFF047857) : const Color(0xFFA99FBB);
    final rowBgColor = isLight ? const Color(0xFFF2EFE9) : Colors.white.withValues(alpha: 0.04);
    final textActionColor = isLight ? const Color(0xFF164E3E) : const Color(0xFFF4F1FA);
    final iconActionColor = isLight ? const Color(0xFF047857) : const Color(0xFF9D74FF);

    final title = isEpisode ? (item.grandparentTitle ?? item.displayTitle) : item.displayTitle;
    final subtitle = isEpisode ? item.displayTitle : null;

    return Container(
      width: 310.0,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.18 : 0.50),
            blurRadius: 28.0,
            spreadRadius: 4.0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título do Item
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: HeisucaTheme.fonteTitulo,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10.0),
          Divider(color: borderColor, height: 1.0),
          const SizedBox(height: 6.0),

          // Se for na fileira Continuar (Quadro 1 do Esboço 04B):
          if (isContinueRow) ...[
            _buildActionTile(
              label: isShow ? 'Ir para a série' : 'Ir para o filme',
              icon: Symbols.arrow_outward_rounded,
              textColor: textActionColor,
              iconColor: iconActionColor,
              rowBg: rowBgColor,
              onTap: () {
                Navigator.pop(context);
                onOpenDetails?.call();
              },
            ),
          ] else ...[
            if (onPlay != null)
              _buildActionTile(
                label: 'Assistir agora',
                icon: Symbols.play_arrow_rounded,
                textColor: textActionColor,
                iconColor: iconActionColor,
                rowBg: rowBgColor,
                onTap: () {
                  Navigator.pop(context);
                  onPlay?.call();
                },
              ),
            _buildActionTile(
              label: 'Ver detalhes',
              icon: Symbols.info_rounded,
              textColor: textActionColor,
              iconColor: iconActionColor,
              rowBg: rowBgColor,
              onTap: () {
                Navigator.pop(context);
                onOpenDetails?.call();
              },
            ),
          ],

          // Marcar como visto / não visto (ícone ⚑)
          _buildActionTile(
            label: item.isWatched ? 'Marcar como não visto' : 'Marcar como visto',
            icon: Symbols.flag_rounded,
            textColor: textActionColor,
            iconColor: isLight ? const Color(0xFF059669) : const Color(0xFF34D399),
            rowBg: rowBgColor,
            onTap: () {
              Navigator.pop(context);
              onToggleWatched?.call();
            },
          ),

          // Favoritar (ícone ♡)
          _buildActionTile(
            label: 'Favoritar',
            icon: Symbols.favorite_rounded,
            textColor: textActionColor,
            iconColor: const Color(0xFFFF5252),
            rowBg: rowBgColor,
            onTap: () {
              Navigator.pop(context);
              onToggleFavorite?.call();
            },
          ),

          // Baixar (ícone ↓)
          _buildActionTile(
            label: isShow && isEpisode
                ? 'Baixar episódio'
                : (isShow ? 'Baixar episódios' : 'Baixar filme'),
            icon: Symbols.download_rounded,
            textColor: textActionColor,
            iconColor: isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
            rowBg: rowBgColor,
            onTap: () {
              Navigator.pop(context);
              onDownload?.call();
            },
          ),

          // Pedir no Seerr (apenas em pôsteres normais quando relevante)
          if (!isContinueRow)
            _buildActionTile(
              label: 'Pedir no Seerr',
              icon: Symbols.cloud_download_rounded,
              textColor: textActionColor,
              iconColor: isLight ? const Color(0xFF7C3AED) : const Color(0xFFA78BFA),
              rowBg: rowBgColor,
              onTap: () {
                Navigator.pop(context);
                HeisucaSeerrSheet.show(context, title: title, year: item.year);
              },
            ),
        ],
      ),
    );
  }

  /// Constrói a linha com rótulo à esquerda e ícone à direita (padrão Esboço 04B).
  Widget _buildActionTile({
    required String label,
    required IconData icon,
    required Color textColor,
    required Color iconColor,
    required Color rowBg,
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
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
