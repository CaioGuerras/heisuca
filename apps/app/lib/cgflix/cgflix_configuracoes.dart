// Configurações no padrão do sistema (refino 2b, versão 1.6.1): lista plana como a tela de
// Configurações do Android, no lugar dos cartões-sanfona da 1.6.0. Referências:
//   - developer.android.com/design/ui/mobile/guides/patterns/settings (lista com grupos e
//     cabeçalhos, item = rótulo + texto secundário com o ESTADO atual, switch para liga/desliga,
//     escolhas em diálogo com botões de opção, subtela para grupos grandes, o rótulo do item que
//     abre uma subtela é igual ao título dela);
//   - Material 3: listas (56/72 dp, ícone 24 dp em onSurfaceVariant, título bodyLarge em onSurface,
//     resumo bodyMedium em onSurfaceVariant), switch (trilho primary ligado, contorno outline
//     desligado, check no polegar), divisores outlineVariant e barra de título grande que recolhe.
//
// Os arquivos do Plezy só ganham ganchos curtos: `SettingsGroup`, `SettingsSectionHeader`, as
// linhas (`FocusableListTile`, `_SettingRow`), o `AppIcon` e a barra de título perguntam
// [CgflixSettingsLook.of] e desenham no padrão M3 quando estão dentro de [CgflixSettingsScope].
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../utils/platform_detector.dart';
import 'cgflix_palette.dart';

/// Roxo do tema Isis nas Configurações e nos controles (switch, botão de opção, controle
/// deslizante): o lilás da marca, que no tema escuro faz o papel do `primary` do M3 (tom claro
/// sobre o preto: 9,3:1 no #000 e 8,2:1 no #120e1a). O `primary` global da Isis continua o
/// branco do upstream (botões cheios, foco da TV); só as Configurações e os controles ficam roxos.
const cgflixIsisPrimary = Color(0xFFC084FC);
const cgflixIsisOnPrimary = Color(0xFF3B0764);
const cgflixIsisPrimaryContainer = Color(0xFF581C87);
const cgflixIsisOnPrimaryContainer = Color(0xFFF3E8FF);

/// Esquema das Configurações: o do tema ativo, com o roxo da Isis no `primary`.
ColorScheme cgflixSettingsScheme(ColorScheme scheme, CgflixThemeVariant variant) => switch (variant) {
  CgflixThemeVariant.heitor => scheme,
  CgflixThemeVariant.isis => scheme.copyWith(
    primary: cgflixIsisPrimary,
    onPrimary: cgflixIsisOnPrimary,
    primaryContainer: cgflixIsisPrimaryContainer,
    onPrimaryContainer: cgflixIsisOnPrimaryContainer,
    secondaryContainer: cgflixIsisPrimaryContainer.withValues(alpha: 0.6),
    onSecondaryContainer: cgflixIsisOnPrimaryContainer,
  ),
};

/// Switch M3 com as cores do esquema: ligado = trilho `primary`, polegar `onPrimary` com check;
/// desligado = trilho `surfaceContainerHighest` com contorno `outline` e polegar `outline`.
SwitchThemeData cgflixSwitchTheme(ColorScheme s) => SwitchThemeData(
  thumbColor: WidgetStateProperty.resolveWith((st) {
    if (st.contains(WidgetState.disabled)) {
      return st.contains(WidgetState.selected) ? s.surface : s.onSurface.withValues(alpha: 0.38);
    }
    return st.contains(WidgetState.selected) ? s.onPrimary : s.outline;
  }),
  trackColor: WidgetStateProperty.resolveWith((st) {
    if (st.contains(WidgetState.disabled)) {
      return st.contains(WidgetState.selected)
          ? s.onSurface.withValues(alpha: 0.12)
          : s.surfaceContainerHighest.withValues(alpha: 0.12);
    }
    return st.contains(WidgetState.selected) ? s.primary : s.surfaceContainerHighest;
  }),
  trackOutlineColor: WidgetStateProperty.resolveWith((st) {
    if (st.contains(WidgetState.selected)) return Colors.transparent;
    return st.contains(WidgetState.disabled) ? s.onSurface.withValues(alpha: 0.12) : s.outline;
  }),
  thumbIcon: WidgetStateProperty.resolveWith(
    (st) =>
        st.contains(WidgetState.selected) ? Icon(Symbols.check_rounded, size: 16, color: s.primary, weight: 600) : null,
  ),
);

/// Botões de opção e caixas de seleção na cor `primary` do tema.
RadioThemeData cgflixRadioTheme(ColorScheme s) => RadioThemeData(
  fillColor: WidgetStateProperty.resolveWith(
    (st) => st.contains(WidgetState.selected) ? s.primary : s.onSurfaceVariant,
  ),
);

/// Tema das Configurações por cima do tema do app.
ThemeData cgflixSettingsTheme(ThemeData theme) {
  final variant =
      theme.extension<CgflixPalette>()?.variant ??
      (theme.brightness == Brightness.light ? CgflixThemeVariant.heitor : CgflixThemeVariant.isis);
  final s = cgflixSettingsScheme(theme.colorScheme, variant);
  final text = theme.textTheme;
  return theme.copyWith(
    colorScheme: s,
    // Foco do teclado/controle bem visível na linha inteira (16% da cor primary).
    focusColor: s.primary.withValues(alpha: 0.16),
    switchTheme: cgflixSwitchTheme(s),
    radioTheme: cgflixRadioTheme(s),
    checkboxTheme: theme.checkboxTheme.copyWith(
      fillColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? s.primary : null),
      checkColor: WidgetStatePropertyAll(s.onPrimary),
      side: BorderSide(color: s.onSurfaceVariant, width: 2),
    ),
    sliderTheme: theme.sliderTheme.copyWith(
      activeTrackColor: s.primary,
      thumbColor: s.primary,
      inactiveTrackColor: s.surfaceContainerHighest,
      activeTickMarkColor: s.onPrimary,
      inactiveTickMarkColor: s.onSurfaceVariant,
      valueIndicatorColor: s.primary,
      valueIndicatorTextStyle: TextStyle(color: s.onPrimary),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? s.secondaryContainer : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? s.onSecondaryContainer : s.onSurface,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: s.outline)),
        iconColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? s.onSecondaryContainer : s.onSurfaceVariant,
        ),
      ),
    ),
    listTileTheme: theme.listTileTheme.copyWith(
      dense: false,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 16),
      minVerticalPadding: 8,
      minLeadingWidth: 24,
      horizontalTitleGap: 16,
      iconColor: s.onSurfaceVariant,
      textColor: s.onSurface,
      titleTextStyle: text.bodyLarge?.copyWith(color: s.onSurface, fontSize: 16, fontWeight: FontWeight.w400),
      subtitleTextStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant, fontSize: 14),
      leadingAndTrailingTextStyle: text.labelSmall?.copyWith(color: s.onSurfaceVariant),
    ),
    dividerTheme: theme.dividerTheme.copyWith(color: s.outlineVariant, space: 1, thickness: 1),
    iconTheme: theme.iconTheme.copyWith(color: s.onSurfaceVariant, size: 24),
  );
}

/// Chevron das linhas do upstream (some nas Configurações, como no Android).
const cgflixChevron = Symbols.chevron_right_rounded;

/// Marca a área das Configurações: abaixo dela as linhas, grupos e cabeçalhos desenham no
/// padrão M3 (sem cartões, sem chevron, ícones de contorno). Sem escopo, tudo fica como no upstream.
class CgflixSettingsLook extends InheritedWidget {
  const CgflixSettingsLook({super.key, this.enabled = true, required super.child});

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CgflixSettingsLook>()?.enabled ?? false;

  @override
  bool updateShouldNotify(CgflixSettingsLook oldWidget) => oldWidget.enabled != enabled;
}

/// Tema + marca das Configurações. Gancho de uma linha nas telas (SettingsPage, SettingsScreen, Sobre).
class CgflixSettingsScope extends StatelessWidget {
  const CgflixSettingsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (CgflixSettingsLook.of(context)) return child;
    return Theme(
      data: cgflixSettingsTheme(Theme.of(context)),
      child: CgflixSettingsLook(child: child),
    );
  }
}

/// Barra de título grande do M3 (recolhe ao rolar) nas Configurações do celular. TV e computador
/// ficam com a barra do upstream (o foco do controle remoto e os botões da janela dependem dela).
bool cgflixUsesLargeAppBar(BuildContext context) =>
    CgflixSettingsLook.of(context) && PlatformDetector.isMobile(context) && !PlatformDetector.isDesktopOS();

/// Cabeçalho de seção: `titleSmall` na cor `primary`, 16 dp de margem, lido como cabeçalho.
/// Os grupos se separam pelo espaço acima do cabeçalho (como nas Configurações do Android).
class CgflixSettingsHeader extends StatelessWidget {
  const CgflixSettingsHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Grupo plano: cabeçalho (se houver) e as linhas, sem cartão. O `Material` transparente de cada
/// linha deixa o realce de foco (teclado/controle) e de toque aparecer na largura toda.
class CgflixFlatGroup extends StatelessWidget {
  const CgflixFlatGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) CgflixSettingsHeader(title!),
        for (final child in children) Material(type: MaterialType.transparency, child: child),
      ],
    );
  }
}
