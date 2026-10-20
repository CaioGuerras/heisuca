// Tema do CGFLIX por cima do tema "mono" do upstream (Etapa 1C): fonte Inter, os temas Isis
// (escuro, roxo) e Heitor (claro, verde; versão 1.4.0), transições de página de 250–350 ms com ease-out e barras do sistema
// transparentes (ponta a ponta). O upstream chama daqui com um gancho de uma linha.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_service.dart' as settings;
import '../theme/mono_theme.dart';
import '../theme/mono_tokens.dart';
import '../utils/platform_detector.dart';
import 'cgflix_app_icon.dart';
import 'cgflix_configuracoes.dart';
import 'cgflix_palette.dart';
import 'cgflix_style.dart';

export 'cgflix_palette.dart';

const cgflixFontFamily = 'Inter';

/// Tema do app para a [variant] (Isis, escuro e roxo; Heitor, claro e verde). É o ÚNICO
/// ponto de entrada de tema do app (`main.dart` usa só isto). As cores vêm de
/// `cgflix_palette.dart`; os dois passam pelo tema "mono" do upstream (forma, tamanhos,
/// cantos) e recebem por cima o esquema e as camadas do CGFLIX em [cgflixBrandTheme].
ThemeData cgflixAppTheme([CgflixThemeVariant variant = CgflixThemeVariant.isis]) => switch (variant) {
  CgflixThemeVariant.isis => monoTheme(dark: true, oled: true),
  CgflixThemeVariant.heitor => monoTheme(dark: false),
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

/// Troca de página no Android: entra deslizando de leve e aparecendo; a de baixo recua um
/// pouco. 300 ms para ir, 250 ms para voltar. Refino 2b: com o voltar preditivo ligado
/// (`android:enableOnBackInvokedCallback`), o gesto de voltar do Android 13+ arrasta a página
/// junto com o dedo (ela encolhe um pouco e arredonda os cantos, como no sistema) e só fecha se
/// a pessoa soltar; se desistir, volta para o lugar.
class CgflixPageTransitionsBuilder extends PageTransitionsBuilder {
  const CgflixPageTransitionsBuilder();

  @override
  Duration get transitionDuration => CgflixMotion.medium;

  @override
  Duration get reverseTransitionDuration => CgflixMotion.fast;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // "Remover animações" do Android: troca de página seca, sem deslizar.
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _CgflixPredictiveBack(
      route: route,
      builder: (context) {
        if (route.popGestureInProgress) {
          // Durante o gesto a animação segue o dedo (sem curva), como no voltar preditivo do sistema.
          return SlideTransition(
            position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
              child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
            ),
          );
        }
        final enter = CurvedAnimation(parent: animation, curve: CgflixMotion.curve, reverseCurve: Curves.easeInCubic);
        final under = CurvedAnimation(parent: secondaryAnimation, curve: CgflixMotion.curve);
        return SlideTransition(
          position: Tween(begin: Offset.zero, end: const Offset(-0.06, 0)).animate(under),
          child: SlideTransition(
            position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(enter),
            child: FadeTransition(opacity: enter, child: child),
          ),
        );
      },
    );
  }
}

/// Recebe o gesto de voltar preditivo do Android (Flutter → [WidgetsBindingObserver]) e passa para
/// a rota, que move a animação junto com o dedo. Mesma lógica do `PredictiveBackPageTransitionsBuilder`
/// do Flutter, com a transição do CGFLIX.
class _CgflixPredictiveBack extends StatefulWidget {
  const _CgflixPredictiveBack({required this.route, required this.builder});

  final PageRoute<dynamic> route;
  final WidgetBuilder builder;

  @override
  State<_CgflixPredictiveBack> createState() => _CgflixPredictiveBackState();
}

class _CgflixPredictiveBackState extends State<_CgflixPredictiveBack> with WidgetsBindingObserver {
  bool get _enabled => widget.route.isCurrent && widget.route.popGestureEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !_enabled) return false;
    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    setState(() {});
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    widget.route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
  }

  @override
  void handleCancelBackGesture() {
    widget.route.handleCancelBackGesture();
    setState(() {});
  }

  @override
  void handleCommitBackGesture() {
    widget.route.handleCommitBackGesture();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Marca do CGFLIX sobre o tema do upstream. [oled] = Isis; o tema claro do upstream vira o
/// Heitor; o "escuro" comum do upstream (sem uso no CGFLIX) só ganha a fonte e as transições.
ThemeData cgflixBrandTheme(ThemeData theme, {required bool oled}) {
  final palette = oled ? CgflixPalette.isis : (theme.brightness == Brightness.light ? CgflixPalette.heitor : null);
  final accent = palette?.accent ?? CgflixPalette.isis.accent;
  final branded = theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: cgflixFontFamily),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: cgflixFontFamily),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(fontFamily: cgflixFontFamily),
      systemOverlayStyle: cgflixSystemOverlay(theme.brightness),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {...theme.pageTransitionsTheme.builders, TargetPlatform.android: const CgflixPageTransitionsBuilder()},
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
ThemeData _heitor(ThemeData branded) {
  const s = cgflixHeitorScheme;
  const p = CgflixPalette.heitor;
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
