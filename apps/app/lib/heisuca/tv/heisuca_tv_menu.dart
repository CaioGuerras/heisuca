import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../profiles/active_profile_provider.dart';
import '../../screens/profile/profile_switch_screen.dart';
import '../../profiles/profile_avatar.dart';
import '../heisuca_theme.dart';
import 'heisuca_tv_canvas.dart';

/// Menu oficial do Heisuca na TV (cartão sobreposto à tela).
/// Acionado pelo avatar no topo esquerdo.
/// Itens: Perfil + Trocar perfil, Início, Filmes, Séries, Animes, Buscar, Ajustes.
class HeisucaTvMenu extends StatefulWidget {
  const HeisucaTvMenu({
    super.key,
    required this.onSelectDestination,
    this.initialDestination = 'Início',
    this.onClose,
  });

  final ValueChanged<String> onSelectDestination;
  final String initialDestination;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onSelectDestination,
    String initialDestination = 'Início',
  }) {
    return showDialog(
      context: context,
      barrierColor: const Color(0x990A0C14),
      builder: (ctx) => HeisucaTvCanvas(
        child: HeisucaTvMenu(
          onSelectDestination: (dest) {
            Navigator.of(ctx).pop();
            onSelectDestination(dest);
          },
          initialDestination: initialDestination,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<HeisucaTvMenu> createState() => _HeisucaTvMenuState();
}

class _HeisucaTvMenuState extends State<HeisucaTvMenu> {
  static const _items = [
    'Início',
    'Filmes',
    'Séries',
    'Animes',
    'Buscar',
    'Ajustes',
  ];

  late String _selected = widget.initialDestination;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    final idx = _items.indexOf(widget.initialDestination);
    _focusedIndex = idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ActiveProfileProvider?>();
    final activeProfile = profiles?.active;
    final profileName = activeProfile?.displayName ?? 'Família';
    final initial = profileName.isNotEmpty ? profileName[0].toUpperCase() : 'T';

    // O cartão só escuta o Voltar que sobe dos itens; não pega o foco para si, senão o autofocus do item
    // (Início) perde a vez e o D-Pad não entra na lista (bancada da TV, 30/10: menu preso em Início).
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.goBack) {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.of(context).maybePop();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: Container(
          width: 520,
          height: 640,
          decoration: BoxDecoration(
            color: const Color(0xFF1E263B), // SUP
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 32,
                spreadRadius: 8,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cabeçalho do Perfil
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2F6B4F),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: activeProfile != null
                        ? ProfileAvatar(
                            profile: activeProfile,
                            size: 64,
                            avatarUrl: profiles?.avatarUrlFor(activeProfile.id),
                          )
                        : Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTitulo,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEEF2F8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        _TvMenuItemPill(
                          text: 'Trocar perfil',
                          fontSize: 20,
                          height: 38,
                          onTap: () {
                            Navigator.of(context).maybePop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileSwitchScreen(requireSelection: false),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 1,
                color: const Color(0xFFDCE3EF).withValues(alpha: 0.15),
              ),
              const SizedBox(height: 14),

              // 2. Lista de Itens de Navegação
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isSelected = item == _selected;
                    return _TvMenuItemPill(
                      text: item,
                      fontSize: 26,
                      height: 58,
                      autofocus: index == _focusedIndex,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selected = item);
                        widget.onSelectDestination(item);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              // 3. Dica inferior
              Center(
                child: Text(
                  'OK abre · Voltar fecha o menu',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFABB8CE),
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

class _TvMenuItemPill extends StatefulWidget {
  const _TvMenuItemPill({
    required this.text,
    required this.onTap,
    this.fontSize = 24,
    this.height = 56,
    this.isSelected = false,
    this.autofocus = false,
  });

  final String text;
  final VoidCallback onTap;
  final double fontSize;
  final double height;
  final bool isSelected;
  final bool autofocus;

  @override
  State<_TvMenuItemPill> createState() => _TvMenuItemPillState();
}

class _TvMenuItemPillState extends State<_TvMenuItemPill> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused;

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: active ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: widget.height,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : widget.isSelected
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: active
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: widget.fontSize,
                fontWeight: active ? FontWeight.w700 : (widget.isSelected ? FontWeight.w600 : FontWeight.w500),
                color: active
                    ? const Color(0xFF111522) // Fundo branco -> texto escuro
                    : const Color(0xFFEEF2F8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
