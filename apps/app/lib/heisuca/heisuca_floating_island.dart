import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../cgflix/cgflix_palette.dart';

/// Ilha Flutuante de Navegação Inferior Heisuca (Floating Island)
/// Filosofia: "Nada entre você e o filme."
/// Ergonomia perfeita na zona do polegar, Vidro Líquido (18σ), borda chanfrada zenital e física elástica.
class HeisucaFloatingIsland extends StatefulWidget {
  const HeisucaFloatingIsland({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.onLibrariesLongPress,
    this.userLabel = 'Você',
    this.userAvatar,
    this.kids = false,
  });

  /// Modo infantil: o 3º botão continua sendo Favoritos (Baixados fica fora do perfil infantil).
  final bool kids;

  final String userLabel;
  final Widget? userAvatar;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onLibrariesLongPress;

  @override
  State<HeisucaFloatingIsland> createState() => _HeisucaFloatingIslandState();
}

class _HeisucaFloatingIslandState extends State<HeisucaFloatingIsland>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  double _currentPosition = 0.0;
  double _targetPosition = 0.0;

  // Caio, 24/10: só ícones (o nome espremia a bolha) e Baixados no lugar de Favoritos; Favoritos foi para a
  // Biblioteca, como mais um botão. O nome continua para o leitor de tela (Semantics).
  List<({IconData icon, String label})> get _items => [
    (icon: Symbols.home_rounded, label: 'Início'),
    (icon: Symbols.video_library_rounded, label: 'Biblioteca'),
    widget.kids ? (icon: Symbols.favorite_rounded, label: 'Favoritos') : (icon: Symbols.download_rounded, label: 'Baixados'),
    (icon: Symbols.person_rounded, label: 'Você'),
  ];

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentIndex.toDouble();
    _targetPosition = _currentPosition;
    _springController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() => _currentPosition = _springController.value);
      });
  }

  @override
  void didUpdateWidget(HeisucaFloatingIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateTo(widget.currentIndex.toDouble());
    }
  }

  void _animateTo(double target) {
    _targetPosition = target;
    const springDesc = SpringDescription(
      mass: 1.0,
      stiffness: 180.0,
      damping: 20.0,
    );
    final springSimulation = SpringSimulation(
      springDesc,
      _currentPosition,
      _targetPosition,
      0.0,
    );
    _springController.animateWith(springSimulation);
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final islandWidth = (screenWidth - 56.0).clamp(240.0, 290.0);
    final itemWidth = islandWidth / _items.length;
    final palette = context.cgflix;
    final isLight = palette.isLight;

    final glassBg = isLight
        ? const Color(0xFFF6FBF7).withValues(alpha: 0.82)
        : const Color(0xFF0E0B14).withValues(alpha: 0.72);
    final borderSpecular = isLight
        ? const Color(0xFF006E28).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.14);
    final pillColor = palette.accent.withValues(alpha: isLight ? 0.15 : 0.24);
    final pillBorder = palette.accentSoft.withValues(alpha: isLight ? 0.40 : 0.32);

    return Positioned(
      bottom: bottomInset + 14.0,
      left: (screenWidth - islandWidth) / 2,
      width: islandWidth,
      height: 54.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.14 : 0.52),
              blurRadius: 32.0,
              offset: const Offset(0, 12),
              spreadRadius: -4.0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
            child: Container(
              decoration: BoxDecoration(
                color: glassBg,
                borderRadius: BorderRadius.circular(32.0),
                border: Border.all(
                  color: borderSpecular,
                  width: 0.75,
                ),
              ),
              child: Stack(
                children: [
                  // Pílula magnética deslizante com deformação por mola (Morphing Liquid Pill)
                  Builder(
                    builder: (context) {
                      final velocityDiff = (_targetPosition - _currentPosition).abs();
                      final dynamicStretch = (velocityDiff * 14.0).clamp(0.0, 16.0);
                      final dynamicWidth = 56.0 + dynamicStretch;
                      final dynamicLeft = _currentPosition * itemWidth + (itemWidth - dynamicWidth) / 2;

                      return Positioned(
                        left: dynamicLeft,
                        top: 4.0,
                        width: dynamicWidth,
                        height: 46.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: pillColor,
                            borderRadius: BorderRadius.circular(23.0),
                            border: Border.all(
                              color: pillBorder,
                              width: 0.75,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Linha com os botões de navegação
                  Row(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];
                      final isSelected = widget.currentIndex == index;
                      return Expanded(
                        child: _IslandButton(
                          icon: item.icon,
                          label: index == 3 ? widget.userLabel : item.label,
                          avatar: index == 3 ? widget.userAvatar : null,
                          isSelected: isSelected,
                          isLight: isLight,
                          activeColor: isLight ? palette.accent : const Color(0xFFF4F1FA),
                          mutedColor: isLight
                              ? const Color(0xFF3E4A42).withValues(alpha: 0.75)
                              : const Color(0xFFA99FBB).withValues(alpha: 0.72),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onDestinationSelected(index);
                          },
                          onLongPress: index == 1 ? widget.onLibrariesLongPress : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IslandButton extends StatefulWidget {
  const _IslandButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isLight,
    required this.activeColor,
    required this.mutedColor,
    required this.onTap,
    this.avatar,
    this.onLongPress,
  });

  final Widget? avatar;
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isLight;
  final Color activeColor;
  final Color mutedColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_IslandButton> createState() => _IslandButtonState();
}

class _IslandButtonState extends State<_IslandButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final fg = widget.isSelected ? widget.activeColor : widget.mutedColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.88),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        label: widget.label,
        excludeSemantics: true,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 140),
          curve: const ElasticOutCurve(0.9),
          child: Center(
            child: widget.avatar ?? Icon(
              widget.icon,
              size: 26.0,
              fill: widget.isSelected ? 1.0 : 0.0,
              weight: widget.isSelected ? 600.0 : 350.0,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

