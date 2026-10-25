// Tema do CGFLIX por cima do tema "mono" do upstream (Etapa 1C): fonte Inter, os temas Isis
// (escuro, roxo) e Heitor (claro, verde), transições oficiais do Flutter e barras
// transparentes (ponta a ponta). O tema base chama daqui.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_service.dart' as settings;
import '../services/device_performance.dart';
import '../theme/mono_theme.dart';
import '../theme/mono_tokens.dart';
import '../utils/platform_detector.dart';
import 'cgflix_app_icon.dart';
import 'cgflix_configuracoes.dart';
import 'cgflix_palette.dart';

export 'cgflix_palette.dart';

const cgflixFontFamily = 'Inter';

/// Tema do app para a [variant] (Isis, escuro e roxo; Heitor, claro e verde). É o ÚNICO
/// ponto de entrada de tema do app (`main.dart` usa só isto). As cores vêm de
/// `cgflix_palette.dart`; os dois passam pelo tema "mono" do upstream (forma, tamanhos,
/// cantos) e recebem por cima o esquema e as camadas do CGFLIX em [cgflixBrandTheme].
ThemeData cgflixAppTheme([CgflixThemeVariant variant = CgflixThemeVariant.isis]) => switch (variant) {
  CgflixThemeVariant.isis => monoTheme(dark: true, oled: true),
  CgflixThemeVariant.heitor => monoTheme(dark: false),
  CgflixThemeVariant.ichigo || CgflixThemeVariant.sorairo => monoTheme(dark: false, kids: variant),
};

/// TV fica sempre na Isis (tema claro na TV está fora do escopo).
bool get _forceIsis => PlatformDetector.isTV();

/// Tema da vaga "clara" do MaterialApp: Heitor (na TV, Isis).
ThemeData cgflixLightTheme() => cgflixAppTheme(_forceIsis ? CgflixThemeVariant.isis : CgflixThemeVariant.heitor);

/// Tema da vaga "escura": sempre Isis.
ThemeData cgflixDarkTheme() => cgflixAppTheme(CgflixThemeVariant.isis);

/// A escolha "Tema" das Configurações reaproveita a preferência `themeMode` do upstream (assim a
/// troca na hora, o "Automático" e a abertura nativa do Android já funcionam):
/// Isis = `oled`, Heitor = `light`, Automático = `system`. O `dark` do upstream não é oferecido
/// e vale como Isis.
ThemeMode cgflixMaterialThemeMode(settings.ThemeMode mode) {
  if (_forceIsis) return ThemeMode.dark;
  cgflixSyncAppIcon(mode); // 1.5.0: ícone do launcher acompanha o tema (só manda quando muda)
  return switch (mode) {
    settings.ThemeMode.light => ThemeMode.light,
    settings.ThemeMode.system => ThemeMode.system,
    settings.ThemeMode.dark || settings.ThemeMode.oled => ThemeMode.dark,
  };
}

/// Quem ficou com o "Escuro" do upstream (1.1.0) passa para a Isis; Heitor (`light`) e
/// Automático (`system`) são escolhas válidas desde a 1.4.0 e ficam como estão.
Future<void> cgflixFixThemePref(settings.SettingsService service) async {
  if (service.read(settings.SettingsService.themeMode) == settings.ThemeMode.dark) {
    await service.write(settings.SettingsService.themeMode, settings.ThemeMode.oled);
  }
}

/// A transição e o gesto pertencem ao Flutter. Só há o portão de movimento
/// reduzido e a cor da marca; nenhuma implementação própria do gesto.
class CgflixPageTransitionsBuilder extends PredictiveBackPageTransitionsBuilder {
  const CgflixPageTransitionsBuilder({super.fallbackColor});
  @override Duration get transitionDuration => DevicePerformance.isReduced ? Duration.zero : super.transitionDuration;
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context,
      Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (DevicePerformance.isReduced || MediaQuery.disableAnimationsOf(context)) return child;
    return super.buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}

/// Marca do CGFLIX sobre o tema do upstream. [oled] = Isis; o tema claro do upstream vira o
/// Heitor; o "escuro" comum do upstream (sem uso no CGFLIX) só ganha a fonte e as transições.
/// [kids] troca o claro do Heitor pela paleta infantil (Ichigo/Sorairo), com o mesmo desenho.
ThemeData cgflixBrandTheme(ThemeData theme, {required bool oled, CgflixThemeVariant? kids}) {
  final palette = kids != null ? CgflixPalette.forVariant(kids)
      : oled ? CgflixPalette.isis : (theme.brightness == Brightness.light ? CgflixPalette.heitor : null);
  final accent = palette?.accent ?? CgflixPalette.isis.accent;
  final branded = theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: cgflixFontFamily),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: cgflixFontFamily),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(fontFamily: cgflixFontFamily),
      systemOverlayStyle: cgflixSystemOverlay(theme.brightness),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {...theme.pageTransitionsTheme.builders, TargetPlatform.android: CgflixPageTransitionsBuilder(fallbackColor: palette?.background ?? theme.scaffoldBackgroundColor)},
    ),
    progressIndicatorTheme: theme.progressIndicatorTheme.copyWith(color: accent),
    textSelectionTheme: theme.textSelectionTheme.copyWith(
      cursorColor: accent,
      selectionColor: accent.withValues(alpha: 0.35),
      selectionHandleColor: accent,
    ),
  );
  return switch (palette?.variant) {
    CgflixThemeVariant.isis => _isis(branded),
    CgflixThemeVariant.heitor => _heitor(branded),
    CgflixThemeVariant.ichigo => _heitor(branded, s: cgflixIchigoScheme, p: CgflixPalette.ichigo),
    CgflixThemeVariant.sorairo => _heitor(branded, s: cgflixSorairoScheme, p: CgflixPalette.sorairo),
    null => branded,
  };
}

/// Isis: o esquema escrito à mão, fundo preto puro e superfícies #120e1a (cores do site).
ThemeData _isis(ThemeData branded) {
  const scheme = cgflixIsisScheme;
  const p = CgflixPalette.isis;
  return branded.copyWith(
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    colorScheme: scheme,
    // Refino 2b: chaves, botões de opção e caixas no roxo da Isis em todo o app (no player também).
    switchTheme: cgflixSwitchTheme(cgflixSettingsScheme(scheme, CgflixThemeVariant.isis)),
    radioTheme: cgflixRadioTheme(cgflixSettingsScheme(scheme, CgflixThemeVariant.isis)),
    appBarTheme: branded.appBarTheme.copyWith(backgroundColor: p.background),
    bottomSheetTheme: branded.bottomSheetTheme.copyWith(backgroundColor: p.surface, modalBackgroundColor: p.surface),
    dialogTheme: branded.dialogTheme.copyWith(backgroundColor: p.surface),
    extensions: [...branded.extensions.values.where((e) => e is! CgflixPalette), p],
  );
}

/// Heitor: cada camada com ajuste próprio (não é só trocar o roxo pelo verde).
///   - fundo branco esverdeado #f4fcee; cartões e folhas brancos com sombra suave;
///   - botões cheios em `primary` (#006e28, 6,1:1 com o branco), texto e ícones em `onSurface`;
///   - campos com borda `outline` e foco com anel `primary` de 2 dp;
///   - aba/navegação ativa com fundo `secondaryContainer` e ícone preenchido em `primary`;
///   - barras do sistema com ícones escuros.
ThemeData _heitor(ThemeData branded, {ColorScheme s = cgflixHeitorScheme, CgflixPalette p = CgflixPalette.heitor}) {
  final clickable = WidgetStateProperty.resolveWith<MouseCursor>(
    (states) => states.contains(WidgetState.disabled) ? MouseCursor.defer : SystemMouseCursors.click,
  );
  final filled = ButtonStyle(
    mouseCursor: clickable,
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? s.onSurface.withValues(alpha: 0.12) : s.primary,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? s.onSurface.withValues(alpha: 0.38) : s.onPrimary,
    ),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed) || states.contains(WidgetState.focused)
          ? s.onPrimary.withValues(alpha: 0.16)
          : null,
    ),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
  );
  final textTheme = branded.textTheme.apply(bodyColor: s.onSurface, displayColor: s.onSurface);
  const fieldRadius = BorderRadius.all(Radius.circular(12));
  final tokens = branded.extension<MonoTokens>();
  return branded.copyWith(
    colorScheme: s,
    scaffoldBackgroundColor: s.surface,
    canvasColor: s.surface,
    focusColor: s.primary.withValues(alpha: 0.12),
    hoverColor: s.onSurface.withValues(alpha: 0.05),
    dividerColor: s.outlineVariant,
    textTheme: textTheme.copyWith(bodySmall: textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
    iconTheme: branded.iconTheme.copyWith(color: s.onSurface),
    // Cabeçalho translúcido: a tela passa por baixo com o mesmo branco esverdeado.
    appBarTheme: branded.appBarTheme.copyWith(
      backgroundColor: s.surface.withValues(alpha: 0.94),
      foregroundColor: s.onSurface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: cgflixSystemOverlay(Brightness.light),
    ),
    cardTheme: branded.cardTheme.copyWith(
      color: s.surfaceContainerLowest,
      elevation: 1,
      shadowColor: p.cardShadow.first.color,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: branded.bottomSheetTheme.copyWith(
      backgroundColor: s.surfaceContainerLowest,
      modalBackgroundColor: s.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: branded.dialogTheme.copyWith(
      backgroundColor: s.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: branded.popupMenuTheme.copyWith(color: s.surfaceContainer, surfaceTintColor: Colors.transparent),
    elevatedButtonTheme: ElevatedButtonThemeData(style: filled),
    filledButtonTheme: FilledButtonThemeData(style: filled),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: s.primary).merge(ButtonStyle(mouseCursor: clickable)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: s.primary,
        side: BorderSide(color: s.outline),
      ).merge(ButtonStyle(mouseCursor: clickable)),
    ),
    inputDecorationTheme: branded.inputDecorationTheme.copyWith(
      fillColor: s.surfaceContainerHigh,
      hintStyle: TextStyle(color: s.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: s.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: s.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: s.primary, width: 2),
      ),
    ),
    sliderTheme: branded.sliderTheme.copyWith(
      activeTrackColor: s.primary,
      thumbColor: s.primary,
      inactiveTrackColor: s.onSurface.withValues(alpha: 0.12),
    ),
    switchTheme: cgflixSwitchTheme(s), // refino 2b: com o check no polegar (M3)
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? s.primary : s.outline),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? s.primary : null),
      checkColor: WidgetStatePropertyAll(s.onPrimary),
      side: BorderSide(color: s.outline, width: 2),
    ),
    dividerTheme: branded.dividerTheme.copyWith(color: s.outlineVariant),
    listTileTheme: branded.listTileTheme.copyWith(
      iconColor: s.onSurfaceVariant,
      textColor: s.onSurface,
      selectedColor: s.primary,
    ),
    navigationBarTheme: branded.navigationBarTheme.copyWith(
      backgroundColor: s.surfaceContainer.withValues(alpha: 0.94),
      indicatorColor: s.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (st) => TextStyle(
          color: st.contains(WidgetState.selected) ? s.onSurface : s.onSurfaceVariant,
          fontSize: 11,
          fontWeight: st.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected)
            ? IconThemeData(size: 22, color: s.primary, fill: 1)
            : IconThemeData(size: 22, color: s.onSurfaceVariant, fill: 0),
      ),
    ),
    navigationRailTheme: branded.navigationRailTheme.copyWith(
      backgroundColor: s.surfaceContainer,
      indicatorColor: s.secondaryContainer,
      selectedIconTheme: IconThemeData(color: s.primary, fill: 1),
      unselectedIconTheme: IconThemeData(color: s.onSurfaceVariant, fill: 0),
    ),
    tabBarTheme: branded.tabBarTheme.copyWith(
      labelColor: s.primary,
      unselectedLabelColor: s.onSurfaceVariant,
      indicatorColor: s.primary,
      dividerColor: s.outlineVariant,
    ),
    chipTheme: branded.chipTheme.copyWith(
      backgroundColor: s.surfaceContainerHigh,
      selectedColor: s.primaryContainer,
      labelStyle: TextStyle(color: s.onSurface),
      secondaryLabelStyle: TextStyle(color: s.onPrimaryContainer),
      side: BorderSide(color: s.outlineVariant),
    ),
    snackBarTheme: branded.snackBarTheme.copyWith(
      backgroundColor: s.inverseSurface,
      contentTextStyle: TextStyle(color: s.onInverseSurface),
      actionTextColor: s.inversePrimary,
    ),
    tooltipTheme: branded.tooltipTheme.copyWith(
      decoration: BoxDecoration(color: s.inverseSurface, borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: s.onInverseSurface, fontFamily: cgflixFontFamily),
    ),
    extensions: [
      ...branded.extensions.values.where((e) => e is! CgflixPalette && e is! MonoTokens),
      if (tokens != null)
        tokens.copyWith(
          bg: s.surface,
          surface: s.surfaceContainerLowest,
          outline: s.outlineVariant,
          text: s.onSurface,
          textMuted: s.onSurfaceVariant,
        ),
      p,
    ],
  );
}

/// Barras do sistema transparentes: ícones claros no tema escuro e escuros no claro.
SystemUiOverlayStyle cgflixSystemOverlay(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    // Navegação de 3 botões: o Android põe uma película atrás dos botões (sem ela somem no
    // conteúdo claro). Com gestos não muda nada.
    systemNavigationBarContrastEnforced: true,
    systemStatusBarContrastEnforced: false,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
  );
}

/// Barras do sistema de acordo com o tema da tela (vale para as telas sem AppBar, como a Início).
/// Gancho no `builder` do MaterialApp.
Widget cgflixSystemBars(BuildContext context, Widget child) =>
    AnnotatedRegion<SystemUiOverlayStyle>(value: cgflixSystemOverlay(Theme.of(context).brightness), child: child);

/// Player, abertura do vídeo e controles do player: sempre escuros (Isis), nos dois temas.
/// Folhas e diálogos abertos de dentro do player herdam este tema.
Widget cgflixAlwaysDark(Widget child) => Theme(
  data: cgflixDarkTheme(),
  child: AnnotatedRegion<SystemUiOverlayStyle>(value: cgflixSystemOverlay(Brightness.dark), child: child),
);

/// Ponta a ponta de verdade no Android: o app desenha atrás da barra de status e da de
/// gestos (as telas respeitam os recuos com SafeArea/MediaQuery).
void cgflixEnableEdgeToEdge() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(cgflixSystemOverlay(Brightness.dark));
}
