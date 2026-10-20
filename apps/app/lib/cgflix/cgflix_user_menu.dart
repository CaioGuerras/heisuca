// Menu do usuário (Etapa 1D): abre ao tocar no emblema do topo. É o novo lugar do perfil.
// 1.5.0 (paridade com o CGFLIX Lite 1.4.2): no topo, quem está usando e "Minha conta: foto e
// senha" (só Jellyfin conectado). Ordem: Favoritos · Bibliotecas · Meus pedidos · Baixados ─
// Configurações · Trocar usuário · Sobre · Sair ─ Apoie o CGFLIX. Sem conexão, somem os que
// dependem do servidor (Favoritos, Bibliotecas, Meus pedidos) e o topo não abre nada.
// Folha inferior com rolagem: cabe também com o celular deitado.
// Refino 2: pela frequência de uso. Favoritos · Baixados · Meus pedidos · Bibliotecas ─ "Ajustes e
// ajuda": Configurações · Sobre e dicas ─ "Conta": Trocar usuário · Sair ─ Apoie o CGFLIX (sempre o último).
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile_avatar.dart';
import '../providers/multi_server_provider.dart';
import '../screens/profile/profile_switch_screen.dart';
import '../screens/profile/profile_teardown.dart';
import '../screens/settings/about_screen.dart';
import '../utils/dialogs.dart';
import '../widgets/app_icon.dart';
import 'apoio/apoio.dart';
import 'apoio/cgflix_apoio_screen.dart';
import 'cgflix_navigation.dart';
import 'cgflix_palette.dart';
import 'conta/cgflix_conta.dart';
import 'conta/cgflix_minha_conta_screen.dart';
import 'you/cgflix_favorites_screen.dart';

/// Itens do menu, na ordem em que aparecem (os testes conferem esta lista).
enum CgflixUserMenuItem { favorites, downloads, myRequests, libraries, settings, about, switchUser, signOut, support }

/// Itens que dependem do servidor (somem sem conexão).
const _onlineOnly = {CgflixUserMenuItem.favorites, CgflixUserMenuItem.libraries, CgflixUserMenuItem.myRequests};

/// Testes: força "com/sem conexão" sem montar os servidores.
bool? cgflixUserMenuDebugOnline;

bool _isOnline(BuildContext context) {
  if (cgflixUserMenuDebugOnline case final forced?) return forced;
  try {
    final servers = Provider.of<MultiServerProvider?>(context, listen: false);
    return servers?.serverManager.visibleOnlineClients.isNotEmpty ?? false;
  } on ProviderNotFoundException {
    return false;
  }
}

/// Itens visíveis agora, na ordem (o que os testes e o roteiro do emulador conferem).
List<CgflixUserMenuItem> cgflixUserMenuItems({required bool online, required bool hasFavorites}) => [
  for (final item in CgflixUserMenuItem.values)
    if ((online || !_onlineOnly.contains(item)) &&
        (item != CgflixUserMenuItem.favorites || hasFavorites) &&
        (item != CgflixUserMenuItem.support || cgflixApoioAtual.disponivel))
      item,
];

/// O que o menu devolve ao fechar: um item ou "Minha conta" (topo).
sealed class _MenuPick {
  const _MenuPick();
}

class _PickItem extends _MenuPick {
  const _PickItem(this.item);
  final CgflixUserMenuItem item;
}

class _PickAccount extends _MenuPick {
  const _PickAccount(this.conta);
  final CgflixConta conta;
}

Future<void> showCgflixUserMenu(BuildContext context) async {
  final picked = await showModalBottomSheet<_MenuPick>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.cgflix.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const CgflixUserMenuSheet(),
  );
  if (picked == null || !context.mounted) return;
  if (picked is _PickAccount) return cgflixAbrirMinhaConta(context, picked.conta);
  final item = (picked as _PickItem).item;
  switch (item) {
    case CgflixUserMenuItem.favorites:
      final source = CgflixFavoritesSource.of(context);
      if (source != null) await cgflixOpenFavorites(context, source);
    case CgflixUserMenuItem.libraries:
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'cgflix/bibliotecas'),
          builder: CgflixPages.libraries,
        ),
      );
    case CgflixUserMenuItem.myRequests:
      await cgflixOpenMyRequests(context);
    case CgflixUserMenuItem.downloads:
      await cgflixOpenDownloads(context);
    case CgflixUserMenuItem.settings:
      await cgflixOpenSettings(context);
    case CgflixUserMenuItem.switchUser:
      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute<void>(builder: (_) => const ProfileSwitchScreen()));
    case CgflixUserMenuItem.about:
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
    case CgflixUserMenuItem.signOut:
      final confirm = await showConfirmDialog(
        context,
        title: t.common.logout,
        message: t.messages.logoutConfirm,
        confirmText: t.common.logout,
        isDestructive: true,
      );
      if (confirm && context.mounted) await logoutAllProfiles(context);
    case CgflixUserMenuItem.support:
      await cgflixAbrirApoio(context);
  }
}

/// Conteúdo da folha (separado para os testes montarem sem rota).
class CgflixUserMenuSheet extends StatelessWidget {
  const CgflixUserMenuSheet({super.key});

  /// Último item de cada grupo → cabeçalho do grupo seguinte (null = só o traço).
  static const _groupEnds = {
    CgflixUserMenuItem.libraries: 'Ajustes e ajuda',
    CgflixUserMenuItem.about: 'Conta',
    CgflixUserMenuItem.signOut: null,
  };

  /// Sem conexão, o grupo de cima perde Bibliotecas: o traço vem depois de Baixados.
  static CgflixUserMenuItem? _endOfFirstGroup(List<CgflixUserMenuItem> items) =>
      items.lastWhere((i) => i.index <= CgflixUserMenuItem.libraries.index, orElse: () => CgflixUserMenuItem.libraries);

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ActiveProfileProvider?>();
    final active = profiles?.active;
    final theme = Theme.of(context);
    final online = _isOnline(context);
    final conta = online ? CgflixConta.of(context) : null;
    final hasFavorites = online && CgflixFavoritesSource.of(context) != null;
    final items = cgflixUserMenuItems(online: online, hasFavorites: hasFavorites);

    final header = Row(
      children: [
        if (active != null)
          ProfileAvatar(profile: active, size: 52, avatarUrl: profiles!.avatarUrlFor(active.id))
        else
          AppIcon(Symbols.account_circle_rounded, fill: 1, size: 52, color: context.cgflix.accentSoft),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                active?.displayName ?? 'Você',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (conta != null)
                Text(
                  'Minha conta: foto e senha',
                  style: theme.textTheme.bodyMedium?.copyWith(color: context.cgflix.textMuted),
                ),
            ],
          ),
        ),
        if (conta != null) AppIcon(Symbols.chevron_right_rounded, fill: 1, color: context.cgflix.textMuted),
      ],
    );

    final children = <Widget>[
      // Quem está usando. Com Jellyfin conectado, abre "Minha conta" (foto e senha).
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: conta == null
            ? Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: header)
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const ValueKey('cgflix-menu-account'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(_PickAccount(conta)),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: header),
                ),
              ),
      ),
    ];
    final firstEnd = _endOfFirstGroup(items);
    for (final (i, item) in items.indexed) {
      children.add(_tileFor(context, item));
      final isEnd = item == firstEnd || (item != CgflixUserMenuItem.libraries && _groupEnds.containsKey(item));
      if (isEnd && i < items.length - 1) {
        children.add(Divider(height: 16, color: context.cgflix.divider));
        final header = _groupEnds[item == firstEnd ? CgflixUserMenuItem.libraries : item];
        if (header != null) children.add(_MenuHeader(header));
      }
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _tileFor(BuildContext context, CgflixUserMenuItem item) {
    void pick() => Navigator.of(context).pop(_PickItem(item));
    final (icon, title) = switch (item) {
      CgflixUserMenuItem.favorites => (Symbols.favorite_rounded, 'Favoritos'),
      CgflixUserMenuItem.libraries => (Symbols.video_library_rounded, 'Bibliotecas'),
      CgflixUserMenuItem.myRequests => (Symbols.playlist_add_check_rounded, 'Meus pedidos'),
      CgflixUserMenuItem.downloads => (Symbols.download_rounded, 'Baixados'),
      CgflixUserMenuItem.settings => (Symbols.settings_rounded, 'Configurações'),
      CgflixUserMenuItem.switchUser => (Symbols.switch_account_rounded, 'Trocar usuário'),
      CgflixUserMenuItem.about => (Symbols.info_rounded, 'Sobre e dicas'),
      CgflixUserMenuItem.signOut => (Symbols.logout_rounded, 'Sair'),
      CgflixUserMenuItem.support => (Symbols.favorite_rounded, cgflixApoioTitulo),
    };
    return _MenuTile(
      key: ValueKey('cgflix-menu-${item.name}'),
      icon: icon,
      title: title,
      // Coração rosa do apoio: o mesmo nos dois temas.
      iconColor: item == CgflixUserMenuItem.support ? cgflixApoioRosa : null,
      onTap: pick,
    );
  }
}

/// Cabeçalho curto de um grupo do menu.
class _MenuHeader extends StatelessWidget {
  const _MenuHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: context.cgflix.textMuted, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({super.key, required this.icon, required this.title, required this.onTap, this.iconColor});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 52,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: AppIcon(icon, fill: 1, color: iconColor ?? context.cgflix.accentSoft),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
