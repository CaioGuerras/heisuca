import 'package:flutter/material.dart';
import '../../cgflix/cgflix_palette.dart';
import '../../heisuca/heisuca_logo.dart';
import '../../heisuca/heisuca_sources_ui.dart';
import '../../heisuca/heisuca_theme.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_browser_dialect.dart';
import '../../profiles/profile.dart';
import '../profile/borrow_connection_screen.dart';
import 'add_jellyfin_screen.dart';
import 'add_plex_account_screen.dart';

/// Picker shown when the user taps "Add connection".
///
/// When [targetProfile] is provided, also offers a "Borrow from another
/// profile" option that opens [BorrowConnectionScreen] for the target. The
/// global Connections screen invokes this without a target — Plex auto-
/// surfaces its Home users as new profiles, while MediaBrowser servers bind
/// to the active profile via [AddJellyfinScreen].
///
/// Pops with `true` after the underlying flow succeeds so the parent list
/// refreshes; pops with `null` (the default) when the user backs out.
class AddConnectionScreen extends StatelessWidget {
  final Profile? targetProfile;

  const AddConnectionScreen({super.key, this.targetProfile});

  @override
  Widget build(BuildContext context) {
    final scoped = targetProfile != null;
    const jellyfinDialect = MediaBrowserDialect.jellyfin;
    const embyDialect = MediaBrowserDialect.emby;
    final options = <_BackendOption>[
      _BackendOption(
        title: t.addServer.signInWithPlexCard,
        subtitle: scoped ? t.addServer.signInWithPlexCardSubtitleScoped : t.addServer.signInWithPlexCardSubtitle,
        builder: (_) => AddPlexAccountScreen(targetProfile: targetProfile),
      ),
      _BackendOption(
        title: t.addServer.connectToMediaBrowserCard(product: jellyfinDialect.productName),
        subtitle: scoped
            ? t.addServer.connectToMediaBrowserCardSubtitleScoped(
                product: jellyfinDialect.productName,
                name: targetProfile!.displayName,
              )
            : t.addServer.connectToMediaBrowserCardSubtitle,
        builder: (_) => AddJellyfinScreen(targetProfile: targetProfile, dialect: jellyfinDialect),
      ),
      _BackendOption(
        title: t.addServer.connectToMediaBrowserCard(product: embyDialect.productName),
        subtitle: scoped
            ? t.addServer.connectToMediaBrowserCardSubtitleScoped(
                product: embyDialect.productName,
                name: targetProfile!.displayName,
              )
            : t.addServer.connectToMediaBrowserCardSubtitle,
        builder: (_) => AddJellyfinScreen(targetProfile: targetProfile, dialect: embyDialect),
      ),
      if (scoped)
        _BackendOption(
          title: t.addServer.borrowFromAnotherProfile,
          subtitle: t.addServer.borrowFromAnotherProfileSubtitle,
          builder: (_) => BorrowConnectionScreen(targetProfile: targetProfile!),
        ),
    ];
    return Scaffold(backgroundColor: context.cgflix.background, body: SafeArea(child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 20, 18), child: Row(children: [
        IconButton(tooltip: 'Voltar', onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded)),
        const SizedBox(width: 8), const HeisucaLogo(siteHeader: true, height: 26),
      ]))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Text(
        scoped ? t.addServer.addConnectionTitleScoped(name: targetProfile!.displayName) : t.addServer.addConnectionTitle,
        style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 28, fontWeight: FontWeight.w600, color: context.cgflix.onGlass)))),
      SliverList.list(children: [for (final option in options) HeisucaSourceRow(title: option.title,
        subtitle: option.subtitle, onTap: () async {
          final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: option.builder));
          if (added == true && context.mounted) Navigator.of(context).pop(true);
        })]),
    ])));
  }
}

class _BackendOption {
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  const _BackendOption({required this.title, required this.subtitle, required this.builder});
}
