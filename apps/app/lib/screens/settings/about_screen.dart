import '../../heisuca/heisuca_news.dart';
import 'package:flutter/material.dart';
import 'package:heisuca/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../cgflix/apoio/cgflix_apoio_screen.dart';
import '../../cgflix/cgflix_about.dart';
import '../../cgflix/cgflix_dicas.dart';
import '../../cgflix/cgflix_palette.dart';
import '../../heisuca/heisuca_logo.dart';
import '../../cgflix/cgflix_version.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_section.dart';
import '../../i18n/strings.g.dart';
import '../../theme/mono_tokens.dart';
import 'licenses_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static final Future<PackageInfo> _packageInfoFuture = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;

    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final appVersion = snapshot.data?.version ?? '';
        return FocusedScrollScaffold(
          title: Text(t.about.title),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        const HeisucaLogo(height: 64),
                        const SizedBox(height: 6),
                        Text(
                          'Nada entre você e o filme.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: palette.accentSoft,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cgflixVersionLabel(appVersion),
                          semanticsLabel: t.about.versionLabel(version: appVersion),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens(context).textMuted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const HeisucaTributeCards(),
                        const SizedBox(height: 16),
                        const CgflixApoioAboutLine(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  SettingsGroup(
                    margin: EdgeInsets.zero,
                    children: [
                      const CgflixDicasAboutTile(),
                      if (heisucaNewsAvailable(context)) const HeisucaNewsEntry(),
                      FocusableListTile(
                        leading: const AppIcon(Symbols.description_rounded, fill: 1),
                        title: Text(t.about.openSourceLicenses),
                        subtitle: Text(t.about.viewLicensesDescription),
                        trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LicensesScreen()));
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Center(
                    child: CgflixDedication(),
                  ),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}
