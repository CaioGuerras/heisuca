// Peças do Sobre: software livre, agradecimentos, selo de parceria e dedicatória.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_icon.dart';
import 'cgflix_palette.dart';

const cgflixDedicationText = 'Feito com amor, para Isis e Heitor';

/// Dedicatória discreta no fim, preservada por decisão do Caio em 08/11.
class CgflixDedication extends StatelessWidget {
  const CgflixDedication({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.cgflix.textMuted, fontWeight: FontWeight.w500);
    return Text(cgflixDedicationText, style: style, textAlign: TextAlign.center);
  }
}

class HeisucaAiSeal extends StatelessWidget {
  const HeisucaAiSeal({super.key});

  @override
  Widget build(BuildContext context) => Text(
    '🤖 Feito em parceria com IA: Claude, Codex e Gemini.',
    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.cgflix.textMuted),
    textAlign: TextAlign.center,
  );
}

class HeisucaOpenSourceCard extends StatelessWidget {
  const HeisucaOpenSourceCard({super.key});

  @override
  Widget build(BuildContext context) => const _AboutCard(
    icon: Symbols.code_rounded,
    title: 'Código aberto',
    subtitle: 'Licença GPL-3.0',
    description: 'O Heisuca é software livre: qualquer pessoa pode ver, estudar e melhorar o código.',
    buttonLabel: 'Ver o código no GitHub',
    url: 'https://github.com/CaioGuerras/heisuca',
  );
}

class HeisucaTributeCards extends StatelessWidget {
  const HeisucaTributeCards({super.key});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 460),
    child: const Column(
      children: [
        _AboutCard(
          icon: Symbols.handshake,
          title: 'Rosiel Victor',
          description: 'Por sempre apoiar a fazer essas coisas rsrs.',
          buttonLabel: 'all.dev.br',
          url: 'https://all.dev.br/',
        ),
        SizedBox(height: 12),
        _AboutCard(
          icon: Symbols.movie_filter_rounded,
          title: 'Locadora',
          description: 'Por até rir às vezes mas sempre me encorajar a evoluir, mesmo que cheio de HnR no site.',
          buttonLabel: 'locadora.cc',
          url: 'https://locadora.cc/',
        ),
      ],
    ),
  );
}

/// Os mesmos tokens e a mesma composição para código aberto e agradecimentos.
class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.description,
    required this.buttonLabel,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String description;
  final String buttonLabel;
  final String url;

  Future<void> _openUrl() async {
    unawaited(HapticFeedback.selectionClick());
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.divider, width: 0.75),
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
                  child: Center(child: AppIcon(icon, fill: 1, size: 20, color: palette.accent)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted, height: 1.45)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openUrl,
                style:
                    TextButton.styleFrom(
                      foregroundColor: palette.accent,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ).copyWith(
                      side: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? BorderSide(color: palette.focusRing, width: 2)
                            : BorderSide.none,
                      ),
                    ),
                icon: AppIcon(Symbols.open_in_new_rounded, size: 16, color: palette.accent),
                label: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
