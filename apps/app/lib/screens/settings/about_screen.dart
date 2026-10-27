import 'dart:ui';
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
    final appName = t.app.title;
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
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: palette.accent.withValues(alpha: 0.28),
                                blurRadius: 32,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: const HeisucaLogo(height: 84, apenasSelo: true),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          appName.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                          ),
                        ),
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
                        const SizedBox(height: 16),
                        const CgflixDedication(),
                        const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Text(
                            t.about.appDescription,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const CgflixApoioAboutLine(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  SettingsGroup(
                    margin: EdgeInsets.zero,
                    children: [
                      const CgflixDicasAboutTile(),
                      if (heisucaNewsAvailable(context))
                        FocusableListTile(
                          leading: const AppIcon(Symbols.auto_awesome_rounded, fill: 0),
                          title: const Text('Novidades'),
                          subtitle: const Text('O que mudou no Heisuca.'),
                          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const HeisucaNewsScreen())),
                        ),
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
