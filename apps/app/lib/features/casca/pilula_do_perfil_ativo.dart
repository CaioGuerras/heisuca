import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/componentes/pilula_de_perfil.dart';
import '../../heisuca/heisuca_profile_screen.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_avatar.dart';

/// O nome curto de quem usa o app: a primeira palavra do nome do perfil.
String primeiroNome(String? nome) {
  final partes = (nome ?? '').trim().split(RegExp(r'[\s._-]+'));
  return partes.firstWhere((parte) => parte.isNotEmpty, orElse: () => '');
}

/// A pílula do topo ligada ao perfil em uso: avatar, primeiro nome e a porta para "Você".
///
/// Sem perfil carregado, mostra só o ícone de pessoa e continua abrindo "Você".
class PilulaDoPerfilAtivo extends StatelessWidget {
  const PilulaDoPerfilAtivo({super.key, this.sobreArte = false, this.soAvatar = false, this.aoAbrir});

  final bool sobreArte;
  final bool soAvatar;

  /// O que o toque faz. `null`: abre a tela "Você".
  final VoidCallback? aoAbrir;

  @override
  Widget build(BuildContext context) {
    final perfis = context.watch<ActiveProfileProvider?>();
    final perfil = perfis?.active;
    return PilulaDePerfil(
      nome: primeiroNome(perfil?.displayName),
      sobreArte: sobreArte,
      soAvatar: soAvatar,
      avatar: perfil == null
          ? null
          : ProfileAvatar(
              profile: perfil,
              size: PilulaDePerfil.tamanhoDoAvatar,
              showLockBadge: false,
              avatarUrl: perfis?.avatarUrlFor(perfil.id),
            ),
      aoTocar:
          aoAbrir ??
          () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HeisucaProfileScreen())),
    );
  }
}
