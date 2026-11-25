import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_avatar.dart';
import '../theme/heisuca_base.dart';

/// Topo oficial do Heisuca na TV: Avatar no canto superior esquerdo com o nome HEISUCA ao lado.
/// Foco no avatar abre o menu principal da TV.
class HeisucaTvHeader extends StatefulWidget {
  const HeisucaTvHeader({
    super.key,
    required this.onOpenMenu,
    this.focusNode,
    this.showLogo = true,
    this.padding = const EdgeInsets.only(left: 48, top: 36),
  });

  final VoidCallback onOpenMenu;

  /// Distância da borda da tela. O Início passa a margem segura da TV (5 % de cada lado).
  final EdgeInsets padding;
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

  /// Lado do avatar no canvas de 1920 da TV.
  static const double _avatar = 64;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final profiles = context.watch<ActiveProfileProvider?>();
    final activeProfile = profiles?.active;
    final nome = activeProfile?.displayName ?? '';
    final initial = nome.isNotEmpty ? nome.characters.first.toUpperCase() : 'H';
    final marca = Tipo.subtitulo(tema);

    return Padding(
      padding: widget.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            label: nome.isEmpty ? 'Abrir o menu' : 'Abrir o menu, perfil $nome',
            excludeSemantics: true,
            child: FocusableActionDetector(
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
                  duration: Movimento.tempo(context, Movimento.toque),
                  curve: Movimento.entra,
                  child: AnimatedContainer(
                    duration: Movimento.tempo(context, Movimento.toque),
                    curve: Movimento.entra,
                    width: _avatar,
                    height: _avatar,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: tema.superficie2,
                      shape: CircleBorder(
                        side: _focused
                            ? BorderSide(color: tema.foco, width: Forma.anelDeFoco)
                            : BorderSide(color: tema.borda),
                      ),
                    ),
                    child: activeProfile != null
                        ? ProfileAvatar(
                            profile: activeProfile,
                            size: _avatar,
                            avatarUrl: profiles?.avatarUrlFor(activeProfile.id),
                          )
                        : Center(
                            child: Text(initial, style: Tipo.titulo(tema).copyWith(fontWeight: FontWeight.w700)),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.showLogo) ...[
            const SizedBox(width: Forma.espaco4),
            // Só o nome; os kanji carmim antes dele ficavam feios na TV (Caio, 31/10).
            ExcludeSemantics(
              child: Text(
                'HEISUCA',
                style: marca.copyWith(
                  fontSize: max(24, (marca.fontSize ?? 16) * 1.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
