// Escolha única de tema, persistida na chave histórica theme_mode.
// TV: Shikkoku e Sumi. Outros aparelhos: também Automático e Hisui.
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../screens/settings/settings_utils.dart';
import '../services/settings_service.dart' as settings;
import '../widgets/setting_tile.dart';
import '../utils/platform_detector.dart';

/// A TV oferece só os dois temas escuros oficiais.
List<settings.ThemeMode> get cgflixThemeChoices => PlatformDetector.isTV()
    ? const [settings.ThemeMode.oled, settings.ThemeMode.sumi]
    : const [settings.ThemeMode.system, settings.ThemeMode.oled, settings.ThemeMode.light, settings.ThemeMode.sumi];
String cgflixThemeName(settings.ThemeMode mode) => switch (mode) {
  settings.ThemeMode.light => 'Hisui',
  settings.ThemeMode.system => 'Automático',
  settings.ThemeMode.sumi => 'Sumi',
  settings.ThemeMode.dark || settings.ThemeMode.oled => 'Shikkoku',
};
String cgflixThemeDescription(settings.ThemeMode mode) => switch (mode) {
  settings.ThemeMode.light => 'Claro',
  settings.ThemeMode.system => 'Segue o modo claro/escuro do aparelho',
  _ => 'Escuro',
};

/// O que aparece na tela (resumo da Aparência e linha "Tema"): só o nome.
String cgflixThemeLabel(settings.ThemeMode mode) => cgflixThemeName(mode);

/// Linha "Tema" das Configurações → Aparência.
class CgflixThemeSelector extends StatelessWidget {
  const CgflixThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // O leitor de tela ouve "Tema, Isis, escuro, roxo"; na tela fica só "Isis".
    return ValueListenableBuilder<settings.ThemeMode>(
      valueListenable: settings.SettingsService.instance.listenable(settings.SettingsService.themeMode),
      builder: (context, mode, child) => Semantics(hint: cgflixThemeDescription(mode), child: child),
      child: SettingSelectionTile<settings.ThemeMode>(
        key: const ValueKey('cgflix-tema'),
        pref: settings.SettingsService.themeMode,
        icon: Symbols.palette_rounded,
        title: 'Tema',
        subtitleBuilder: cgflixThemeLabel,
        options: [
          for (final mode in cgflixThemeChoices)
            DialogOption(value: mode, title: cgflixThemeName(mode), semanticsHint: cgflixThemeDescription(mode)),
        ],
      ),
    );
  }
}
