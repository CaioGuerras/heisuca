import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'heisuca_theme.dart';

/// Ilha Flutuante de Navegação Inferior Heisuca (Floating Island)
/// Filosofia: "Nada entre você e o filme."
/// Ergonomia perfeita na zona do polegar, Vidro Líquido (18σ), borda chanfrada zenital e física elástica.
class HeisucaFloatingIsland extends StatefulWidget {
  const HeisucaFloatingIsland({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<HeisucaFloatingIsland> createState() => _HeisucaFloatingIslandState();
}

class _HeisucaFloatingIslandState extends State<HeisucaFloatingIsland>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  double _currentPosition = 0.0;
  double _targetPosition = 0.0;

  static const _items = [
    (icon: Symbols.home_rounded, label: 'Início'),
    (icon: Symbols.movie_rounded, label: 'Filmes'),
    (icon: Symbols.tv_rounded, label: 'Séries'),
    (icon: Symbols.search_rounded, label: 'Buscar'),
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
    final islandWidth = (screenWidth - 48.0).clamp(280.0, 420.0);
    final itemWidth = islandWidth / _items.length;

    return Positioned(
      bottom: bottomInset + 14.0,
      left: (screenWidth - islandWidth) / 2,
      width: islandWidth,
      height: 64.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.40),
              blurRadius: 28.0,
              offset: const Offset(0, 10),
              spreadRadius: -6.0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0E0B14).withOpacity(0.68),
                borderRadius: BorderRadius.circular(32.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 0.75,
                ),
              ),
              child: Stack(
                children: [
                  // Pílula deslizante de foco com física elástica
                  Positioned(
                    left: _currentPosition * itemWidth + (itemWidth - 48.0) / 2,
                    top: 10.0,
                    width: 48.0,
                    height: 44.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: HeisucaTheme.roxoPrimaria.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(22.0),
                        border: Border.all(
                          color: const Color(0xFFC4B5FD).withOpacity(0.25),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Linha com os botões de navegação
                  Row(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];
                      final isSelected = widget.currentIndex == index;
                      return Expanded(
                        child: _IslandButton(
                          icon: item.icon,
                          label: item.label,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onDestinationSelected(index);
                          },
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_IslandButton> createState() => _IslandButtonState();
}

class _IslandButtonState extends State<_IslandButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.90),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: const Cubic(0.2, 0, 0, 1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 24.0,
              fill: widget.isSelected ? 1.0 : 0.0,
              weight: widget.isSelected ? 600.0 : 300.0,
              color: widget.isSelected ? const Color(0xFFF4F1FA) : const Color(0xFFA99FBB).withOpacity(0.70),
            ),
            const SizedBox(height: 2.0),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 10.0,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                color: widget.isSelected ? const Color(0xFFF4F1FA) : const Color(0xFFA99FBB).withOpacity(0.70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
