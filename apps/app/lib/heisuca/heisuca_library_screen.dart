import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../cgflix/cgflix_palette.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../providers/multi_server_provider.dart';
import '../widgets/optimized_media_image.dart';
import 'heisuca_context_menu.dart';
import 'heisuca_design_system.dart';
import 'heisuca_theme.dart';
import 'heisuca_title_sheet.dart';

/// Tela de Biblioteca Flagship do Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Grid Cinematográfico 2:3, Pílulas de Filtro Táteis e Física de Mola.
/// Totalmente compatível com Shikkoku Escuro e Hisui Claro (zero fundos roxos indesejados).
class HeisucaLibraryScreen extends StatefulWidget {
  const HeisucaLibraryScreen({super.key});

  @override
  State<HeisucaLibraryScreen> createState() => _HeisucaLibraryScreenState();
}

class _HeisucaLibraryScreenState extends State<HeisucaLibraryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Todos', 'Filmes', 'Séries', 'Animes', 'Baixados'];

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final isLight = palette.isLight;

    final bg = isLight ? const Color(0xFFF7F3EC) : const Color(0xFF0E0B16);
    final textTitle = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final textMuted = isLight ? const Color(0xFF64748B) : const Color(0xFFA99FBB);
    final accentColor = isLight ? const Color(0xFF047857) : const Color(0xFF7444E0);
    final filterBg = isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.04);
    final filterBorder = isLight ? const Color(0xFFCBD5E1) : Colors.white.withOpacity(0.08);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header da Biblioteca
            Padding(
              padding: const EdgeInsets.only(top: 14.0, left: 20.0, right: 20.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Biblioteca',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTitulo,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: textTitle,
                    ),
                  ),
                  Row(
                    children: [
                      _buildHeaderButton(Symbols.swap_vert_rounded, isLight, textTitle, () {
                        HapticFeedback.lightImpact();
                      }),
                      const SizedBox(width: 8.0),
                      _buildHeaderButton(Symbols.filter_list_rounded, isLight, textTitle, () {
                        HapticFeedback.lightImpact();
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Pílulas de Filtro Horizontais com Elasticidade
            SizedBox(
              height: 44.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const HeisucaSpringPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8.0),
                itemBuilder: (ctx, idx) {
                  final isSelected = _selectedFilterIndex == idx;
                  return HeisucaSpringPressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilterIndex = idx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withOpacity(isLight ? 0.18 : 0.24)
                            : filterBg,
                        borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                        border: Border.all(
                          color: isSelected
                              ? accentColor.withOpacity(0.8)
                              : filterBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        _filters[idx],
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? (isLight ? const Color(0xFF047857) : const Color(0xFFF4F1FA)) : textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8.0),

            // Grid 2:3 de Pôsteres
            Expanded(
              child: GridView.builder(
                physics: const HeisucaSpringPhysics(),
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 120.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2 / 3.1,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 14.0,
                ),
                itemCount: 18,
                itemBuilder: (ctx, idx) {
                  return _buildPosterTile(ctx, idx, isLight, textTitle);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterTile(BuildContext context, int index, bool isLight, Color textTitle) {
    final cardBg = isLight ? Colors.white : const Color(0xFF1E172A);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.08);

    return HeisucaSpringPressable(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                color: cardBg,
                border: Border.all(color: borderColor, width: 0.75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.05 : 0.35),
                    blurRadius: 6.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Symbols.movie_rounded,
                  color: isLight ? const Color(0xFF94A3B8) : Colors.white.withOpacity(0.18),
                  size: 28.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            'Título ${index + 1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: HeisucaTheme.fonteTexto,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, bool isLight, Color iconColor, VoidCallback onTap) {
    return HeisucaSpringPressable(
      onTap: onTap,
      child: Container(
        width: 38.0,
        height: 38.0,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isLight ? const Color(0xFFCBD5E1) : Colors.white.withOpacity(0.08),
            width: 0.6,
          ),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 20.0),
        ),
      ),
    );
  }
}
