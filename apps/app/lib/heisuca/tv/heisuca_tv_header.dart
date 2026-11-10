import '../theme/heisuca_base.dart';
import '../../cgflix/cgflix_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_avatar.dart';
import '../heisuca_theme.dart';

/// Topo oficial do Heisuca na TV: Avatar no canto superior esquerdo com o nome HEISUCA ao lado.
/// Foco no avatar abre o menu principal da TV.
class HeisucaTvHeader extends StatefulWidget {
  const HeisucaTvHeader({super.key, required this.onOpenMenu, this.focusNode, this.showLogo = true});

  final VoidCallback onOpenMenu;
  final FocusNode? focusNode;
  final bool showLogo;

  @override
  State<HeisucaTvHeader> createState() => _HeisucaTvHeaderState();
}

class _HeisucaTvHeaderState extends State<HeisucaTvHeader> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ActiveProfileProvider?>();
    final activeProfile = profiles?.active;
    final initial = (activeProfile?.displayName.isNotEmpty == true) ? activeProfile!.displayName[0].toUpperCase() : 'T';

    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 36),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FocusableActionDetector(
            focusNode: _focusNode,
            onShowFocusHighlight: (v) => setState(() => _focused = v),
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onOpenMenu();
                  return null;
                },
              ),
            },
            child: GestureDetector(
              key: const Key('heisuca-tv-avatar-button'),
              onTap: widget.onOpenMenu,
              child: AnimatedScale(
                scale: _focused ? HeisucaBase.focoEscalaTv : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _focused ? context.cgflix.focusRing : context.cgflix.text.withValues(alpha: 0.15),
                      width: _focused ? HeisucaBase.focoBorda : 1.5,
                    ),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: context.cgflix.text.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: activeProfile != null
                        ? ProfileAvatar(
                            profile: activeProfile,
                            size: 58,
                            avatarUrl: profiles?.avatarUrlFor(activeProfile.id),
                          )
                        : Container(
                            color: context.cgflix.accent,
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: context.cgflix.text),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.showLogo) ...[
            const SizedBox(width: 20),
            // Só o nome; os kanji carmim antes dele ficavam feios na TV (Caio, 31/10).
            Text(
              'HEISUCA',
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 4.0,
                color: context.cgflix.text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
