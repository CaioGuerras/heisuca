import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import '../../heisuca/heisuca_logo.dart';

import '../../design/tema.dart';
import '../desktop_preferences.dart';

class DesktopSettingsScreen extends StatelessWidget {
  const DesktopSettingsScreen({super.key, required this.preferences});
  final DesktopPreferences preferences;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) {
      final palette = Theme.of(context).extension<TemaHeisuca>() ?? TemaHeisuca.shikkoku;
      return Scaffold(
        backgroundColor: palette.fundo,
        body: SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(alignment: WrapAlignment.spaceBetween, spacing: 24, runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center, children: [
                  TextButton.icon(onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded), label: const Text('Voltar')),
                  const HeisucaLogo(width: 164, height: 48),
                ]),
              const SizedBox(height: 40),
              Text('Ajustes', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 28),
              _section(context, 'Aparência', 'A mesma identidade do Heisuca, no seu tema.',
                Wrap(spacing: 10, runSpacing: 12, children: [
                  for (final theme in const {
                    'system': 'Automático', 'shikkoku': 'Shikkoku · escuro',
                    'hisui': 'Hisui · claro', 'sumi': 'Sumi · preto',
                  }.entries)
                    ChoiceChip(label: Text(theme.value), selected: preferences.theme == theme.key,
                      onSelected: (_) => preferences.setTheme(theme.key)),
                ])),
              _section(context, 'Privacidade',
                Platform.isWindows ? 'Suas conexões ficam protegidas no perfil do Windows. O ZIP permite usar o app sem instalar.'
                  : Platform.isLinux ? 'Quando o cofre do sistema está disponível e desbloqueado, suas conexões ficam salvas e protegidas. Sem ele, valem só nesta sessão.'
                  : 'Nesta prévia, as conexões são mantidas apenas enquanto o app está aberto.',
                Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(
                  onPressed: preferences.recents.isEmpty ? null : preferences.clearRecents,
                  icon: const Icon(Icons.history_rounded), label: const Text('Limpar arquivos recentes')))),
              _section(context, 'Atalhos', 'O teclado continua funcionando nos controles e campos de texto.',
                Wrap(spacing: 16, runSpacing: 12, children: [
                  for (final entry in const {
                    'Ctrl + O': 'Abrir arquivo', 'Ctrl + L': 'Abrir URL', 'Espaço': 'Pausar ou continuar',
                    '← / →': 'Voltar ou avançar', '↑ / ↓': 'Volume', 'F': 'Tela cheia', 'Esc': 'Fechar vídeo ou sair da tela cheia',
                  }.entries)
                    SizedBox(width: 230, child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                        Text(entry.value, style: Theme.of(context).textTheme.bodySmall)])),
                ])),
              _section(context, 'Sobre o Heisuca',
                'Nada entre você e o filme.\nSoftware livre sob GPL-3.0, derivado do Plezy. Reprodução com libmpv.',
                Align(alignment: Alignment.centerLeft, child: OutlinedButton(
                  onPressed: () => showLicensePage(context: context, applicationName: 'Heisuca',
                    applicationLegalese: 'Derivado de Plezy · GNU GPL-3.0'),
                  child: const Text('Licenças de software')))),
              const Text('Revisão: ${String.fromEnvironment('HEISUCA_DESKTOP_REVISION', defaultValue: 'local')}'),
              if (preferences.persistenceError != null)
                Padding(padding: const EdgeInsets.only(top: 12),
                  child: Text(preferences.persistenceError!, style: TextStyle(color: palette.erro))),
            ]),
          )),
        )),
      );
    },
  );

  Widget _section(BuildContext context, String title, String description, Widget child) {
    final palette = Theme.of(context).extension<TemaHeisuca>() ?? TemaHeisuca.shikkoku;
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: palette.superficie, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.borda)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8), Text(description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20), child,
      ]));
  }
}
