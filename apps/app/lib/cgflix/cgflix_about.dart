// Peças da página Sobre do Heisuca: dedicatória, cartões de tributo (Rosiel Victor e Locadora)
// e créditos ao código aberto (GPL-3.0).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../heisuca/heisuca_design_system.dart';
import '../widgets/app_icon.dart';
import 'cgflix_palette.dart';

const cgflixDedicationText = 'Feito com amor, para Isis e Heitor';

/// Coração roxo (Shikkoku/Isis) e verde (Hisui/Heitor), os dois em qualquer tema.
class CgflixDedicationHearts extends StatelessWidget {
  const CgflixDedicationHearts({super.key, this.size = 22, this.spacing = 8});
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(Symbols.favorite_rounded, fill: 1, color: CgflixPalette.isis.accent, size: size),
        SizedBox(width: spacing),
        AppIcon(Symbols.favorite_rounded, fill: 1, color: context.cgflix.dedication, size: size),
      ],
    ),
  );
}

/// Dedicatória, centralizada abaixo da versão: coração roxo e coração verde.
class CgflixDedication extends StatelessWidget {
  const CgflixDedication({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(cgflixDedicationText, style: style, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const CgflixDedicationHearts(),
        const SizedBox(height: 20),
        const _HeisucaTributeCards(),
      ],
    );
  }
}

class _HeisucaTributeCards extends StatelessWidget {
  const _HeisucaTributeCards();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: const Column(
        children: [
          _TributeCard(
            icon: Symbols.terminal_rounded,
            title: 'Rosiel Victor',
            description: 'Agradecimento especial ao amigo Rosiel Victor pelo apoio, generosidade e parceria técnica.',
            buttonLabel: 'all.dev.br',
            url: 'https://all.dev.br/',
          ),
          SizedBox(height: 12),
          _TributeCard(
            icon: Symbols.movie_filter_rounded,
            title: 'Comunidade da Locadora',
            description: 'Agradecimento à comunidade da Locadora pela preservação incansável da cultura e do cinema.',
            buttonLabel: 'locadora.cc',
            url: 'https://locadora.cc/',
          ),
        ],
      ),
    );
  }
}

class _TributeCard extends StatelessWidget {
  const _TributeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final String url;

  Future<void> _openUrl() async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final theme = Theme.of(context);
    return HeisucaSpringPressable(
      onTap: _openUrl,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: palette.isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.10),
            width: 0.75,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: palette.isLight ? 0.06 : 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: AppIcon(icon, fill: 1, size: 20, color: palette.accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.accent.withValues(alpha: 0.30), width: 0.75),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonLabel,
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AppIcon(Symbols.open_in_new_rounded, size: 14, color: palette.accent),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

/// Créditos ao projeto original (GPL-3.0). Só aparecem no Sobre e no README.
class CgflixCredits extends StatelessWidget {
  const CgflixCredits({super.key});

  @override
  Widget build(BuildContext context) => Text(
    'O Heisuca para Android incorpora tecnologia aberta baseada no Plezy (github.com/edde746/plezy), software livre sob a licença GPL-3.0.',
    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.cgflix.textMuted),
    textAlign: TextAlign.center,
  );
}
