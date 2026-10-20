import 'dart:ui';
import 'package:flutter/material.dart';
import 'heisuca_theme.dart';
import 'heisuca_design_system.dart';

/// Hero Card Cinematográfico do Heisuca
/// Filosofia: "Nada entre você e o filme."
/// ClearLogo oficial flutuante, Scrim Easing Cúbico sem linhas divisórias,
/// Badges técnicos nobres e controles táteis de alta precisão.
class HeisucaHero extends StatelessWidget {
  const HeisucaHero({
    super.key,
    required this.backdropUrl,
    required this.title,
    this.clearLogoUrl,
    required this.year,
    required this.runtime,
    required this.rating,
    required this.technicalBadges,
    required this.onPlay,
    required this.onDetails,
  });

  final String backdropUrl;
  final String? clearLogoUrl;
  final String title;
  final String year;
  final String runtime;
  final String rating;
  final List<String> technicalBadges;
  final VoidCallback onPlay;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.58).clamp(360.0, 560.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagem de fundo em alta fidelidade
          GestureDetector(
            onTap: onDetails,
            child: Image.network(
              backdropUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: HeisucaTheme.roxoFundo,
                child: const Center(
                  child: Icon(Icons.movie_outlined, color: Colors.white24, size: 64),
                ),
              ),
            ),
          ),

          // 2. Scrim Easing Cúbico (sem faixa divisória/Mach banding)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: CubicScrimGradient.create(
                    baseColor: HeisucaTheme.roxoFundo,
                  ),
                ),
              ),
            ),
          ),

          // 3. Conteúdo Hero: ClearLogo + Metadados Nobres + Ações
          Positioned(
            left: 20.0,
            right: 20.0,
            bottom: 24.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ClearLogo com animação de subida suave
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) {
                    final slideAnimation = Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: const Cubic(0.2, 0, 0, 1),
                    ));
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slideAnimation, child: child),
                    );
                  },
                  child: clearLogoUrl != null && clearLogoUrl!.isNotEmpty
                      ? Image.network(
                          clearLogoUrl!,
                          key: ValueKey(clearLogoUrl),
                          height: 64.0,
                          width: 220.0,
                          alignment: Alignment.bottomLeft,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Text(
                            title,
                            key: ValueKey('title_$title'),
                            style: HeisucaTypography.displayCinematic.copyWith(fontSize: 26),
                          ),
                        )
                      : Text(
                          title,
                          key: ValueKey(title),
                          style: HeisucaTypography.displayCinematic.copyWith(fontSize: 26),
                        ),
                ),

                const SizedBox(height: 12.0),

                // Metadados em Linha Única com Números Tabulares
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      Text(
                        year,
                        style: HeisucaTypography.bodyMetadata,
                      ),
                      _buildDotSeparator(),
                      Text(
                        runtime,
                        style: HeisucaTypography.bodyMetadata.copyWith(
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      if (technicalBadges.isNotEmpty) ...[
                        _buildDotSeparator(),
                        ...technicalBadges.map((badge) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: HeisucaNobleBadge(label: badge),
                            )),
                      ],
                      if (rating.isNotEmpty) ...[
                        _buildDotSeparator(),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16.0, color: Color(0xFFFFC107)),
                            const SizedBox(width: 3.0),
                            Text(
                              rating,
                              style: HeisucaTypography.bodyMetadata.copyWith(
                                color: const Color(0xFFF4F1FA),
                                fontWeight: FontWeight.w600,
                                fontFeatures: [const FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18.0),

                // Botões de Ação Cinematográfica
                Row(
                  children: [
                    // Botão Assistir (Primário)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: HeisucaTheme.roxoPrimaria,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                        ),
                        elevation: 0,
                      ),
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22.0),
                      label: const Text(
                        'Assistir',
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    // Botão Detalhes (Secundário em Vidro)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF4F1FA),
                        backgroundColor: Colors.white.withOpacity(0.06),
                        side: BorderSide(color: Colors.white.withOpacity(0.15), width: 0.75),
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                        ),
                      ),
                      onPressed: onDetails,
                      icon: const Icon(Icons.info_outline_rounded, size: 18.0),
                      label: const Text(
                        'Detalhes',
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDotSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Text('•', style: TextStyle(color: Color(0xFF554B66), fontSize: 11.0)),
    );
  }
}
