// CGFLIX: tela "Apoie o CGFLIX" e as entradas dela (último item das Configurações, menu do
// usuário e uma linha discreta no Sobre). Gorjeta opcional: nada de pop-up nem lembrete.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_section.dart';
import 'apoio.dart';

const cgflixApoioTitulo = 'Apoie o CGFLIX';
const cgflixApoioTexto =
    'O CGFLIX é grátis e vai continuar grátis. Se você gosta de usar, pode dar uma força para manter o projeto.';

/// Rosa do coração do apoio: o mesmo nos dois temas (fora do tom do tema, como no Lite).
const cgflixApoioRosa = Color(0xFFEC4899);

Future<void> cgflixAbrirApoio(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: 'cgflix/apoie'),
    builder: (_) => const CgflixApoioScreen(),
  ),
);

class CgflixApoioScreen extends StatelessWidget {
  const CgflixApoioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(cgflixApoioTitulo)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                const Center(
                  child: ExcludeSemantics(
                    child: AppIcon(Symbols.favorite_rounded, fill: 1, size: 40, color: cgflixApoioRosa),
                  ),
                ),
                const SizedBox(height: 16),
                Text(cgflixApoioTexto, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                cgflixApoioAtual.conteudo(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Item "Apoie o CGFLIX" das Configurações (último cartão), com o coração rosa.
class CgflixApoioSettingsTile extends StatelessWidget {
  const CgflixApoioSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    if (!cgflixApoioAtual.disponivel) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SettingsGroup(
        children: [
          FocusableListTile(
            key: const ValueKey('cgflix-settings-apoio'),
            leading: const AppIcon(Symbols.favorite_rounded, fill: 1, color: cgflixApoioRosa),
            title: const Text(cgflixApoioTitulo),
            subtitle: const Text('Gorjeta opcional, se você quiser'),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => cgflixAbrirApoio(context),
          ),
        ],
      ),
    );
  }
}

/// Linha discreta do Sobre.
class CgflixApoioAboutLine extends StatelessWidget {
  const CgflixApoioAboutLine({super.key});

  @override
  Widget build(BuildContext context) {
    if (!cgflixApoioAtual.disponivel) return const SizedBox.shrink();
    return Center(
      child: TextButton.icon(
        key: const ValueKey('cgflix-about-apoio'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () => cgflixAbrirApoio(context),
        icon: const AppIcon(Symbols.favorite_rounded, fill: 1, size: 18, color: cgflixApoioRosa),
        label: const Text('Gostou? Apoie o CGFLIX'),
      ),
    );
  }
}
