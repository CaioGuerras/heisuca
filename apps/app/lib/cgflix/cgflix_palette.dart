// Kids altera só o acento; fundo, texto e botão pertencem ao tema adulto.
// Adaptação dos tokens gerados: nenhuma paleta independente. Nomes históricos preservam a API.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../heisuca/theme/temas/tema_shikkoku.dart';
import '../heisuca/theme/temas/tema_hisui.dart';
import '../heisuca/theme/temas/tema_sumi.dart';
import '../heisuca/theme/temas/tema_ichigo.dart';
import '../heisuca/theme/temas/tema_sorairo.dart';
import '../heisuca/theme/temas/tema_ichigo_noite.dart';
import '../heisuca/theme/temas/tema_sorairo_noite.dart';

const heisucaShikkokuCanvas = TemaShikkoku.temaCorFundo;
const heisucaShikkokuSurface = TemaShikkoku.temaCorSuperficie;
const heisucaShikkokuSurface2 = TemaShikkoku.temaCorSuperficie2;
const heisucaShikkokuSurface3 = TemaShikkoku.temaCorSuperficie2;
const heisucaShikkokuAccent = TemaShikkoku.temaCorAcento;
const heisucaShikkokuText = TemaShikkoku.temaCorTexto;
const heisucaShikkokuLine = TemaShikkoku.temaCorBorda;
const heisucaHisuiDarkCanvas = TemaHisui.temaCorFundo;
const heisucaHisuiDarkSurface = TemaHisui.temaCorSuperficie;
const heisucaHisuiDarkSurface2 = TemaHisui.temaCorSuperficie2;
const heisucaHisuiDarkSurface3 = TemaHisui.temaCorAcento;
const heisucaHisuiAccent = TemaHisui.temaCorAcento;
const heisucaTvCanvas = TemaShikkoku.temaCorFundo;
const heisucaTvSurface = TemaShikkoku.temaCorSuperficie;
const heisucaTvSurface2 = TemaShikkoku.temaCorSuperficie2;
const heisucaTvSurface3 = TemaShikkoku.temaCorSuperficie2;
const heisucaTvDetail = TemaShikkoku.temaCorTexto2;
const heisucaTvAccent = TemaShikkoku.temaCorAcento;
const heisucaTvText = TemaShikkoku.temaCorTexto;
const heisucaTvLine = TemaShikkoku.temaCorBorda;

enum CgflixThemeVariant {
  isis,
  heitor,
  sumi,
  ichigo,
  sorairo;

  bool get isKids => this == ichigo || this == sorairo;
}

const cgflixIsisScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: TemaShikkoku.temaCorAcento,
  onPrimary: TemaShikkoku.temaCorFundo,
  primaryContainer: TemaShikkoku.temaCorSuperficie2,
  onPrimaryContainer: TemaShikkoku.temaCorTexto,
  secondary: TemaShikkoku.temaCorAcento,
  onSecondary: TemaShikkoku.temaCorFundo,
  secondaryContainer: TemaShikkoku.temaCorSuperficie2,
  onSecondaryContainer: TemaShikkoku.temaCorTexto,
  tertiary: TemaShikkoku.temaCorAcento,
  onTertiary: TemaShikkoku.temaCorFundo,
  error: TemaShikkoku.temaCorErro,
  errorContainer: TemaShikkoku.temaCorSuperficie2,
  onErrorContainer: TemaShikkoku.temaCorTexto,
  tertiaryContainer: TemaShikkoku.temaCorSuperficie2,
  onTertiaryContainer: TemaShikkoku.temaCorTexto,
  onError: TemaShikkoku.temaCorFundo,
  surface: TemaShikkoku.temaCorFundo,
  onSurface: TemaShikkoku.temaCorTexto,
  onSurfaceVariant: TemaShikkoku.temaCorTexto2,
  surfaceDim: TemaShikkoku.temaCorFundo,
  surfaceBright: TemaShikkoku.temaCorSuperficie,
  surfaceContainerLowest: TemaShikkoku.temaCorSuperficie,
  surfaceContainerLow: TemaShikkoku.temaCorSuperficie,
  surfaceContainer: TemaShikkoku.temaCorSuperficie,
  surfaceContainerHigh: TemaShikkoku.temaCorSuperficie2,
  surfaceContainerHighest: TemaShikkoku.temaCorSuperficie2,
  outline: TemaShikkoku.temaCorBorda,
  outlineVariant: TemaShikkoku.temaCorBorda,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: TemaShikkoku.temaCorTexto,
  onInverseSurface: TemaShikkoku.temaCorFundo,
  inversePrimary: TemaShikkoku.temaCorFundo,
);
const cgflixHeitorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: TemaHisui.temaCorAcento,
  onPrimary: TemaHisui.temaCorFundo,
  primaryContainer: TemaHisui.temaCorSuperficie2,
  onPrimaryContainer: TemaHisui.temaCorTexto,
  secondary: TemaHisui.temaCorAcento,
  onSecondary: TemaHisui.temaCorFundo,
  secondaryContainer: TemaHisui.temaCorSuperficie2,
  onSecondaryContainer: TemaHisui.temaCorTexto,
  tertiary: TemaHisui.temaCorAcento,
  onTertiary: TemaHisui.temaCorFundo,
  error: TemaHisui.temaCorErro,
  errorContainer: TemaHisui.temaCorSuperficie2,
  onErrorContainer: TemaHisui.temaCorTexto,
  tertiaryContainer: TemaHisui.temaCorSuperficie2,
  onTertiaryContainer: TemaHisui.temaCorTexto,
  onError: TemaHisui.temaCorFundo,
  surface: TemaHisui.temaCorFundo,
  onSurface: TemaHisui.temaCorTexto,
  onSurfaceVariant: TemaHisui.temaCorTexto2,
  surfaceDim: TemaHisui.temaCorFundo,
  surfaceBright: TemaHisui.temaCorSuperficie,
  surfaceContainerLowest: TemaHisui.temaCorSuperficie,
  surfaceContainerLow: TemaHisui.temaCorSuperficie,
  surfaceContainer: TemaHisui.temaCorSuperficie,
  surfaceContainerHigh: TemaHisui.temaCorSuperficie2,
  surfaceContainerHighest: TemaHisui.temaCorSuperficie2,
  outline: TemaHisui.temaCorBorda,
  outlineVariant: TemaHisui.temaCorBorda,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: TemaHisui.temaCorTexto,
  onInverseSurface: TemaHisui.temaCorFundo,
  inversePrimary: TemaHisui.temaCorFundo,
);
const cgflixSumiScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: TemaSumi.temaCorAcento,
  onPrimary: TemaSumi.temaCorFundo,
  primaryContainer: TemaSumi.temaCorSuperficie2,
  onPrimaryContainer: TemaSumi.temaCorTexto,
  secondary: TemaSumi.temaCorAcento,
  onSecondary: TemaSumi.temaCorFundo,
  secondaryContainer: TemaSumi.temaCorSuperficie2,
  onSecondaryContainer: TemaSumi.temaCorTexto,
  tertiary: TemaSumi.temaCorAcento,
  onTertiary: TemaSumi.temaCorFundo,
  error: TemaSumi.temaCorErro,
  errorContainer: TemaSumi.temaCorSuperficie2,
  onErrorContainer: TemaSumi.temaCorTexto,
  tertiaryContainer: TemaSumi.temaCorSuperficie2,
  onTertiaryContainer: TemaSumi.temaCorTexto,
  onError: TemaSumi.temaCorFundo,
  surface: TemaSumi.temaCorFundo,
  onSurface: TemaSumi.temaCorTexto,
  onSurfaceVariant: TemaSumi.temaCorTexto2,
  surfaceDim: TemaSumi.temaCorFundo,
  surfaceBright: TemaSumi.temaCorSuperficie,
  surfaceContainerLowest: TemaSumi.temaCorSuperficie,
  surfaceContainerLow: TemaSumi.temaCorSuperficie,
  surfaceContainer: TemaSumi.temaCorSuperficie,
  surfaceContainerHigh: TemaSumi.temaCorSuperficie2,
  surfaceContainerHighest: TemaSumi.temaCorSuperficie2,
  outline: TemaSumi.temaCorBorda,
  outlineVariant: TemaSumi.temaCorBorda,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: TemaSumi.temaCorTexto,
  onInverseSurface: TemaSumi.temaCorFundo,
  inversePrimary: TemaSumi.temaCorFundo,
);
const cgflixIchigoScheme = ColorScheme(
  brightness: Brightness.light,
  primary: TemaIchigo.temaCorAcento,
  onPrimary: TemaHisui.temaCorFundo,
  primaryContainer: TemaHisui.temaCorSuperficie2,
  onPrimaryContainer: TemaHisui.temaCorTexto,
  secondary: TemaIchigo.temaCorAcento,
  onSecondary: TemaHisui.temaCorFundo,
  secondaryContainer: TemaHisui.temaCorSuperficie2,
  onSecondaryContainer: TemaHisui.temaCorTexto,
  tertiary: TemaIchigo.temaCorAcento,
  onTertiary: TemaHisui.temaCorFundo,
  error: TemaHisui.temaCorErro,
  errorContainer: TemaHisui.temaCorSuperficie2,
  onErrorContainer: TemaHisui.temaCorTexto,
  tertiaryContainer: TemaHisui.temaCorSuperficie2,
  onTertiaryContainer: TemaHisui.temaCorTexto,
  onError: TemaHisui.temaCorFundo,
  surface: TemaHisui.temaCorFundo,
  onSurface: TemaHisui.temaCorTexto,
  onSurfaceVariant: TemaHisui.temaCorTexto2,
  surfaceDim: TemaHisui.temaCorFundo,
  surfaceBright: TemaHisui.temaCorSuperficie,
  surfaceContainerLowest: TemaHisui.temaCorSuperficie,
  surfaceContainerLow: TemaHisui.temaCorSuperficie,
  surfaceContainer: TemaHisui.temaCorSuperficie,
  surfaceContainerHigh: TemaHisui.temaCorSuperficie2,
  surfaceContainerHighest: TemaHisui.temaCorSuperficie2,
  outline: TemaHisui.temaCorBorda,
  outlineVariant: TemaHisui.temaCorBorda,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: TemaHisui.temaCorTexto,
  onInverseSurface: TemaHisui.temaCorFundo,
  inversePrimary: TemaHisui.temaCorFundo,
);
const cgflixSorairoScheme = ColorScheme(
  brightness: Brightness.light,
  primary: TemaSorairo.temaCorAcento,
  onPrimary: TemaHisui.temaCorFundo,
  primaryContainer: TemaHisui.temaCorSuperficie2,
  onPrimaryContainer: TemaHisui.temaCorTexto,
  secondary: TemaSorairo.temaCorAcento,
  onSecondary: TemaHisui.temaCorFundo,
  secondaryContainer: TemaHisui.temaCorSuperficie2,
  onSecondaryContainer: TemaHisui.temaCorTexto,
  tertiary: TemaSorairo.temaCorAcento,
  onTertiary: TemaHisui.temaCorFundo,
  error: TemaHisui.temaCorErro,
  errorContainer: TemaHisui.temaCorSuperficie2,
  onErrorContainer: TemaHisui.temaCorTexto,
  tertiaryContainer: TemaHisui.temaCorSuperficie2,
  onTertiaryContainer: TemaHisui.temaCorTexto,
  onError: TemaHisui.temaCorFundo,
  surface: TemaHisui.temaCorFundo,
  onSurface: TemaHisui.temaCorTexto,
  onSurfaceVariant: TemaHisui.temaCorTexto2,
  surfaceDim: TemaHisui.temaCorFundo,
  surfaceBright: TemaHisui.temaCorSuperficie,
  surfaceContainerLowest: TemaHisui.temaCorSuperficie,
  surfaceContainerLow: TemaHisui.temaCorSuperficie,
  surfaceContainer: TemaHisui.temaCorSuperficie,
  surfaceContainerHigh: TemaHisui.temaCorSuperficie2,
  surfaceContainerHighest: TemaHisui.temaCorSuperficie2,
  outline: TemaHisui.temaCorBorda,
  outlineVariant: TemaHisui.temaCorBorda,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: TemaHisui.temaCorTexto,
  onInverseSurface: TemaHisui.temaCorFundo,
  inversePrimary: TemaHisui.temaCorFundo,
);
const cgflixIchigoNoiteScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: TemaIchigoNoite.temaCorAcento,
  onPrimary: TemaShikkoku.temaCorFundo,
  primaryContainer: TemaShikkoku.temaCorSuperficie2,
  onPrimaryContainer: TemaShikkoku.temaCorTexto,
  secondary: TemaIchigoNoite.temaCorAcento,
  onSecondary: TemaShikkoku.temaCorFundo,
  secondaryContainer: TemaShikkoku.temaCorSuperficie2,
  onSecondaryContainer: TemaShikkoku.temaCorTexto,
  tertiary: TemaIchigoNoite.temaCorAcento,
  onTertiary: TemaShikkoku.temaCorFundo,
  error: TemaShikkoku.temaCorErro,
  errorContainer: TemaShikkoku.temaCorSuperficie2,
  onErrorContainer: TemaShikkoku.temaCorTexto,
  tertiaryContainer: TemaShikkoku.temaCorSuperficie2,
  onTertiaryContainer: TemaShikkoku.temaCorTexto,
  onError: TemaShikkoku.temaCorFundo,
  surface: TemaShikkoku.temaCorFundo,
  onSurface: TemaShikkoku.temaCorTexto,
  onSurfaceVariant: TemaShikkoku.temaCorTexto2,
  surfaceDim: TemaShikkoku.temaCorFundo,
  surfaceBright: TemaShikkoku.temaCorSuperficie,
  surfaceContainerLowest: TemaShikkoku.temaCorSuperficie,
  surfaceContainerLow: TemaShikkoku.temaCorSuperficie,
  surfaceContainer: TemaShikkoku.temaCorSuperficie,
  surfaceContainerHigh: TemaShikkoku.temaCorSuperficie2,
  surfaceContainerHighest: TemaShikkoku.temaCorSuperficie2,
  outline: TemaShikkoku.temaCorBorda,
  outlineVariant: TemaShikkoku.temaCorBorda,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: TemaShikkoku.temaCorTexto,
  onInverseSurface: TemaShikkoku.temaCorFundo,
  inversePrimary: TemaShikkoku.temaCorFundo,
);
const cgflixSorairoNoiteScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: TemaSorairoNoite.temaCorAcento,
  onPrimary: TemaShikkoku.temaCorFundo,
  primaryContainer: TemaShikkoku.temaCorSuperficie2,
  onPrimaryContainer: TemaShikkoku.temaCorTexto,
  secondary: TemaSorairoNoite.temaCorAcento,
  onSecondary: TemaShikkoku.temaCorFundo,
  secondaryContainer: TemaShikkoku.temaCorSuperficie2,
  onSecondaryContainer: TemaShikkoku.temaCorTexto,
  tertiary: TemaSorairoNoite.temaCorAcento,
  onTertiary: TemaShikkoku.temaCorFundo,
  error: TemaShikkoku.temaCorErro,
  errorContainer: TemaShikkoku.temaCorSuperficie2,
  onErrorContainer: TemaShikkoku.temaCorTexto,
  tertiaryContainer: TemaShikkoku.temaCorSuperficie2,
  onTertiaryContainer: TemaShikkoku.temaCorTexto,
  onError: TemaShikkoku.temaCorFundo,
  surface: TemaShikkoku.temaCorFundo,
  onSurface: TemaShikkoku.temaCorTexto,
  onSurfaceVariant: TemaShikkoku.temaCorTexto2,
  surfaceDim: TemaShikkoku.temaCorFundo,
  surfaceBright: TemaShikkoku.temaCorSuperficie,
  surfaceContainerLowest: TemaShikkoku.temaCorSuperficie,
  surfaceContainerLow: TemaShikkoku.temaCorSuperficie,
  surfaceContainer: TemaShikkoku.temaCorSuperficie,
  surfaceContainerHigh: TemaShikkoku.temaCorSuperficie2,
  surfaceContainerHighest: TemaShikkoku.temaCorSuperficie2,
  outline: TemaShikkoku.temaCorBorda,
  outlineVariant: TemaShikkoku.temaCorBorda,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: TemaShikkoku.temaCorTexto,
  onInverseSurface: TemaShikkoku.temaCorFundo,
  inversePrimary: TemaShikkoku.temaCorFundo,
);
const cgflixTvScheme = cgflixIsisScheme;

class CgflixPalette extends ThemeExtension<CgflixPalette> {
  const CgflixPalette({
    required this.variant,
    this.light,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.accent,
    required this.accentSoft,
    required this.action,
    required this.onAction,
    required this.progress,
    required this.progressTrack,
    required this.textMuted,
    required this.divider,
    required this.heroVeil,
    required this.topVeil,
    required this.sheetVeil,
    required this.glass,
    required this.glassBorder,
    required this.onGlass,
    required this.chipSelected,
    required this.chipSelectedBorder,
    required this.pressed,
    required this.hovered,
    required this.focused,
    required this.focusRing,
    required this.secondaryAction,
    required this.onSecondaryAction,
    required this.photoButton,
    required this.onPhotoButton,
    required this.badge,
    required this.badgeBorder,
    required this.onBadge,
    required this.success,
    required this.danger,
    required this.dedication,
    required this.rankStroke,
    required this.cardShadow,
    required this.brandArc,
    required this.brandPlay,
    required this.brandGlow,
    required this.brandShine,
    required this.emblemAsset,
  });

  final CgflixThemeVariant variant;
  final bool? light;

  /// Fundo das telas e superfícies (cartões/folhas) e o tom mais alto (esqueleto, campos).
  final Color background;
  final Color surface;
  final Color surfaceHigh;

  /// Destaque (aba/chip ativo, ícones ativos, foco) e o tom suave (gêneros, ícones de menu).
  final Color accent;
  final Color accentSoft;

  /// Botão principal ("Assistir", "Pedir") e o texto dele.
  final Color action;
  final Color onAction;

  /// Barra de progresso dos cartões e o trilho dela.
  final Color progress;
  final Color progressTrack;

  final Color textMuted;
  final Color divider;

  /// Véu sobre a foto do destaque (de cima para baixo), para o texto continuar legível.
  final List<Color> heroVeil;

  /// Véu atrás da barra do topo (translúcido) e o fim da foto na prévia.
  final List<Color> topVeil;
  final List<Color> sheetVeil;

  /// "Vidro" dos chips e botões redondos da barra (por cima de foto ou de tela).
  final Color glass;
  final Color glassBorder;
  final Color onGlass;
  final Color chipSelected;
  final Color chipSelectedBorder;

  /// Estados: pressionado, mouse por cima, foco (teclado/controle) e o anel de foco.
  final Color pressed;
  final Color hovered;
  final Color focused;
  final Color focusRing;

  /// Botão secundário do destaque ("Mais informações").
  final Color secondaryAction;
  final Color onSecondaryAction;

  /// Botão redondo por cima de foto (fechar a prévia): escuro nos dois temas.
  final Color photoButton;
  final Color onPhotoButton;

  /// Selos (Dublado/Legendado, situação do pedido).
  final Color badge;
  final Color badgeBorder;
  final Color onBadge;

  final Color success;
  final Color danger;

  /// Coração verde da dedicatória (Sobre).
  final Color dedication;

  /// Contorno do número do Top 10.
  final Color rankStroke;

  /// Sombra dos cartões (Isis: nenhuma; Heitor: suave, no lugar do brilho roxo).
  final List<BoxShadow> cardShadow;

  /// Degradês do emblema "C com play" (abertura animada) e o brilho em volta.
  final List<Color> brandArc;
  final List<Color> brandPlay;
  final Color brandGlow;
  final Color brandShine;

  /// SVG do emblema (assets/).
  final String emblemAsset;

  bool get isLight => light ?? variant == CgflixThemeVariant.heitor;

  static const isis = CgflixPalette(
    variant: CgflixThemeVariant.isis,
    light: false,
    background: TemaShikkoku.temaCorFundo,
    surface: TemaShikkoku.temaCorSuperficie,
    surfaceHigh: TemaShikkoku.temaCorSuperficie2,
    accent: TemaShikkoku.temaCorAcento,
    accentSoft: TemaShikkoku.temaCorAcentoSuave,
    action: TemaShikkoku.temaCorBotaoFundo,
    onAction: TemaShikkoku.temaCorBotaoTexto,
    progress: TemaShikkoku.temaCorAcento,
    progressTrack: TemaShikkoku.temaCorSuperficie2,
    textMuted: TemaShikkoku.temaCorTexto2,
    divider: TemaShikkoku.temaCorBorda,
    heroVeil: [
      Colors.black54,
      Colors.transparent,
      Colors.transparent,
      TemaShikkoku.temaCorFundo,
      TemaShikkoku.temaCorFundo,
    ],
    topVeil: [TemaShikkoku.temaCorFundo, Colors.transparent],
    sheetVeil: [Colors.transparent, TemaShikkoku.temaCorSuperficie],
    glass: TemaShikkoku.temaCorSuperficie,
    glassBorder: TemaShikkoku.temaCorBorda,
    onGlass: TemaShikkoku.temaCorTexto,
    chipSelected: TemaShikkoku.temaCorSuperficie2,
    chipSelectedBorder: TemaShikkoku.temaCorAcento,
    pressed: TemaShikkoku.temaCorSuperficie2,
    hovered: TemaShikkoku.temaCorSuperficie2,
    focused: TemaShikkoku.temaCorSuperficie2,
    focusRing: TemaShikkoku.temaCorFoco,
    secondaryAction: TemaShikkoku.temaCorSuperficie2,
    onSecondaryAction: TemaShikkoku.temaCorTexto,
    photoButton: Colors.black54,
    onPhotoButton: Colors.white,
    badge: TemaShikkoku.temaCorSuperficie2,
    badgeBorder: TemaShikkoku.temaCorBorda,
    onBadge: TemaShikkoku.temaCorTexto,
    success: TemaShikkoku.temaCorSucesso,
    danger: TemaShikkoku.temaCorErro,
    dedication: TemaShikkoku.temaCorAcento,
    rankStroke: TemaShikkoku.temaCorTexto2,
    cardShadow: [BoxShadow(color: Colors.transparent)],
    brandArc: [TemaShikkoku.temaCorSelo, TemaShikkoku.temaCorSelo],
    brandPlay: [TemaShikkoku.temaCorTexto, TemaShikkoku.temaCorTexto],
    brandGlow: TemaShikkoku.temaCorSelo,
    brandShine: TemaShikkoku.temaCorTexto,
    emblemAsset: 'assets/heisuca/selo_pequeno_shikkoku.svg',
  );
  static const heitor = CgflixPalette(
    variant: CgflixThemeVariant.heitor,
    light: true,
    background: TemaHisui.temaCorFundo,
    surface: TemaHisui.temaCorSuperficie,
    surfaceHigh: TemaHisui.temaCorSuperficie2,
    accent: TemaHisui.temaCorAcento,
    accentSoft: TemaHisui.temaCorAcentoSuave,
    action: TemaHisui.temaCorBotaoFundo,
    onAction: TemaHisui.temaCorBotaoTexto,
    progress: TemaHisui.temaCorAcento,
    progressTrack: TemaHisui.temaCorSuperficie2,
    textMuted: TemaHisui.temaCorTexto2,
    divider: TemaHisui.temaCorBorda,
    heroVeil: [Colors.black54, Colors.transparent, Colors.transparent, TemaHisui.temaCorFundo, TemaHisui.temaCorFundo],
    topVeil: [TemaHisui.temaCorFundo, Colors.transparent],
    sheetVeil: [Colors.transparent, TemaHisui.temaCorSuperficie],
    glass: TemaHisui.temaCorSuperficie,
    glassBorder: TemaHisui.temaCorBorda,
    onGlass: TemaHisui.temaCorTexto,
    chipSelected: TemaHisui.temaCorSuperficie2,
    chipSelectedBorder: TemaHisui.temaCorAcento,
    pressed: TemaHisui.temaCorSuperficie2,
    hovered: TemaHisui.temaCorSuperficie2,
    focused: TemaHisui.temaCorSuperficie2,
    focusRing: TemaHisui.temaCorFoco,
    secondaryAction: TemaHisui.temaCorSuperficie2,
    onSecondaryAction: TemaHisui.temaCorTexto,
    photoButton: Colors.black54,
    onPhotoButton: Colors.white,
    badge: TemaHisui.temaCorSuperficie2,
    badgeBorder: TemaHisui.temaCorBorda,
    onBadge: TemaHisui.temaCorTexto,
    success: TemaHisui.temaCorSucesso,
    danger: TemaHisui.temaCorErro,
    dedication: TemaHisui.temaCorAcento,
    rankStroke: TemaHisui.temaCorTexto2,
    cardShadow: [BoxShadow(color: Colors.transparent)],
    brandArc: [TemaHisui.temaCorSelo, TemaHisui.temaCorSelo],
    brandPlay: [TemaHisui.temaCorTexto, TemaHisui.temaCorTexto],
    brandGlow: TemaHisui.temaCorSelo,
    brandShine: TemaHisui.temaCorTexto,
    emblemAsset: 'assets/heisuca/selo_pequeno_hisui.svg',
  );
  static const sumi = CgflixPalette(
    variant: CgflixThemeVariant.sumi,
    light: false,
    background: TemaSumi.temaCorFundo,
    surface: TemaSumi.temaCorSuperficie,
    surfaceHigh: TemaSumi.temaCorSuperficie2,
    accent: TemaSumi.temaCorAcento,
    accentSoft: TemaSumi.temaCorAcentoSuave,
    action: TemaSumi.temaCorBotaoFundo,
    onAction: TemaSumi.temaCorBotaoTexto,
    progress: TemaSumi.temaCorAcento,
    progressTrack: TemaSumi.temaCorSuperficie2,
    textMuted: TemaSumi.temaCorTexto2,
    divider: TemaSumi.temaCorBorda,
    heroVeil: [Colors.black54, Colors.transparent, Colors.transparent, TemaSumi.temaCorFundo, TemaSumi.temaCorFundo],
    topVeil: [TemaSumi.temaCorFundo, Colors.transparent],
    sheetVeil: [Colors.transparent, TemaSumi.temaCorSuperficie],
    glass: TemaSumi.temaCorSuperficie,
    glassBorder: TemaSumi.temaCorBorda,
    onGlass: TemaSumi.temaCorTexto,
    chipSelected: TemaSumi.temaCorSuperficie2,
    chipSelectedBorder: TemaSumi.temaCorAcento,
    pressed: TemaSumi.temaCorSuperficie2,
    hovered: TemaSumi.temaCorSuperficie2,
    focused: TemaSumi.temaCorSuperficie2,
    focusRing: TemaSumi.temaCorFoco,
    secondaryAction: TemaSumi.temaCorSuperficie2,
    onSecondaryAction: TemaSumi.temaCorTexto,
    photoButton: Colors.black54,
    onPhotoButton: Colors.white,
    badge: TemaSumi.temaCorSuperficie2,
    badgeBorder: TemaSumi.temaCorBorda,
    onBadge: TemaSumi.temaCorTexto,
    success: TemaSumi.temaCorSucesso,
    danger: TemaSumi.temaCorErro,
    dedication: TemaSumi.temaCorAcento,
    rankStroke: TemaSumi.temaCorTexto2,
    cardShadow: [BoxShadow(color: Colors.transparent)],
    brandArc: [TemaSumi.temaCorSelo, TemaSumi.temaCorSelo],
    brandPlay: [TemaSumi.temaCorTexto, TemaSumi.temaCorTexto],
    brandGlow: TemaSumi.temaCorSelo,
    brandShine: TemaSumi.temaCorTexto,
    emblemAsset: 'assets/heisuca/selo_pequeno_sumi.svg',
  );
  static const ichigo = CgflixPalette(
    variant: CgflixThemeVariant.ichigo,
    light: true,
    background: TemaHisui.temaCorFundo,
    surface: TemaHisui.temaCorSuperficie,
    surfaceHigh: TemaHisui.temaCorSuperficie2,
    accent: TemaIchigo.temaCorAcento,
    accentSoft: TemaIchigo.temaCorAcentoSuave,
    action: TemaHisui.temaCorBotaoFundo,
    onAction: TemaHisui.temaCorBotaoTexto,
    progress: TemaIchigo.temaCorAcento,
    progressTrack: TemaHisui.temaCorSuperficie2,
    textMuted: TemaHisui.temaCorTexto2,
    divider: TemaHisui.temaCorBorda,
    heroVeil: [Colors.black54, Colors.transparent, Colors.transparent, TemaHisui.temaCorFundo, TemaHisui.temaCorFundo],
    topVeil: [TemaHisui.temaCorFundo, Colors.transparent],
    sheetVeil: [Colors.transparent, TemaHisui.temaCorSuperficie],
    glass: TemaHisui.temaCorSuperficie,
    glassBorder: TemaHisui.temaCorBorda,
    onGlass: TemaHisui.temaCorTexto,
    chipSelected: TemaHisui.temaCorSuperficie2,
    chipSelectedBorder: TemaIchigo.temaCorAcento,
    pressed: TemaHisui.temaCorSuperficie2,
    hovered: TemaHisui.temaCorSuperficie2,
    focused: TemaHisui.temaCorSuperficie2,
    focusRing: TemaHisui.temaCorFoco,
    secondaryAction: TemaHisui.temaCorSuperficie2,
    onSecondaryAction: TemaHisui.temaCorTexto,
    photoButton: Colors.black54,
    onPhotoButton: Colors.white,
    badge: TemaHisui.temaCorSuperficie2,
    badgeBorder: TemaHisui.temaCorBorda,
    onBadge: TemaHisui.temaCorTexto,
    success: TemaHisui.temaCorSucesso,
    danger: TemaHisui.temaCorErro,
    dedication: TemaIchigo.temaCorAcento,
    rankStroke: TemaHisui.temaCorTexto2,
    cardShadow: [BoxShadow(color: Colors.transparent)],
    brandArc: [TemaHisui.temaCorSelo, TemaHisui.temaCorSelo],
    brandPlay: [TemaHisui.temaCorTexto, TemaHisui.temaCorTexto],
    brandGlow: TemaHisui.temaCorSelo,
    brandShine: TemaHisui.temaCorTexto,
    emblemAsset: 'assets/heisuca/selo_pequeno_ichigo.svg',
  );
  static const sorairo = CgflixPalette(
    variant: CgflixThemeVariant.sorairo,
    light: true,
    background: TemaHisui.temaCorFundo,
    surface: TemaHisui.temaCorSuperficie,
    surfaceHigh: TemaHisui.temaCorSuperficie2,
    accent: TemaSorairo.temaCorAcento,
    accentSoft: TemaSorairo.temaCorAcentoSuave,
    action: TemaHisui.temaCorBotaoFundo,
    onAction: TemaHisui.temaCorBotaoTexto,
    progress: TemaSorairo.temaCorAcento,
    progressTrack: TemaHisui.temaCorSuperficie2,
    textMuted: TemaHisui.temaCorTexto2,
    divider: TemaHisui.temaCorBorda,
    heroVeil: [Colors.black54, Colors.transparent, Colors.transparent, TemaHisui.temaCorFundo, TemaHisui.temaCorFundo],
    topVeil: [TemaHisui.temaCorFundo, Colors.transparent],
    sheetVeil: [Colors.transparent, TemaHisui.temaCorSuperficie],
    glass: TemaHisui.temaCorSuperficie,
    glassBorder: TemaHisui.temaCorBorda,
    onGlass: TemaHisui.temaCorTexto,
    chipSelected: TemaHisui.temaCorSuperficie2,
    chipSelectedBorder: TemaSorairo.temaCorAcento,
    pressed: TemaHisui.temaCorSuperficie2,
    hovered: TemaHisui.temaCorSuperficie2,
    focused: TemaHisui.temaCorSuperficie2,
    focusRing: TemaHisui.temaCorFoco,
    secondaryAction: TemaHisui.temaCorSuperficie2,
    onSecondaryAction: TemaHisui.temaCorTexto,
    photoButton: Colors.black54,
    onPhotoButton: Colors.white,
    badge: TemaHisui.temaCorSuperficie2,
    badgeBorder: TemaHisui.temaCorBorda,
    onBadge: TemaHisui.temaCorTexto,
    success: TemaHisui.temaCorSucesso,
    danger: TemaHisui.temaCorErro,
    dedication: TemaSorairo.temaCorAcento,
    rankStroke: TemaHisui.temaCorTexto2,
    cardShadow: [BoxShadow(color: Colors.transparent)],
    brandArc: [TemaHisui.temaCorSelo, TemaHisui.temaCorSelo],
    brandPlay: [TemaHisui.temaCorTexto, TemaHisui.temaCorTexto],
    brandGlow: TemaHisui.temaCorSelo,
    brandShine: TemaHisui.temaCorTexto,
    emblemAsset: 'assets/heisuca/selo_pequeno_sorairo.svg',
  );
  static const ichigoNoite = CgflixPalette(
    variant: CgflixThemeVariant.ichigo,
    light: false,
    background: TemaShikkoku.temaCorFundo,
    surface: TemaShikkoku.temaCorSuperficie,
    surfaceHigh: TemaShikkoku.temaCorSuperficie2,
    accent: TemaIchigoNoite.temaCorAcento,
    accentSoft: TemaIchigoNoite.temaCorAcentoSuave,
    action: TemaShikkoku.temaCorBotaoFundo,
    onAction: TemaShikkoku.temaCorBotaoTexto,
    progress: TemaIchigoNoite.temaCorAcento,
    progressTrack: TemaShikkoku.temaCorSuperficie2,
    textMuted: TemaShikkoku.temaCorTexto2,
    divider: TemaShikkoku.temaCorBorda,
    heroVeil: [
      Colors.black54,
      Colors.transparent,
      Colors.transparent,
      TemaShikkoku.temaCorFundo,
      TemaShikkoku.temaCorFundo,
    ],
    topVeil: [TemaShikkoku.temaCorFundo, Colors.transparent],
    sheetVeil: [Colors.transparent, TemaShikkoku.temaCorSuperficie],
    glass: TemaShikkoku.temaCorSuperficie,
    glassBorder: TemaShikkoku.temaCorBorda,
    onGlass: TemaShikkoku.temaCorTexto,
    chipSelected: TemaShikkoku.temaCorSuperficie2,
    chipSelectedBorder: TemaIchigoNoite.temaCorAcento,
    pressed: TemaShikkoku.temaCorSuperficie2,
    hovered: TemaShikkoku.temaCorSuperficie2,
    focused: TemaShikkoku.temaCorSuperficie2,
    focusRing: TemaShikkoku.temaCorFoco,
    secondaryAction: TemaShikkoku.temaCorSuperficie2,
    onSecondaryAction: TemaShikkoku.temaCorTexto,
    photoButton: Colors.black54,
    onPhotoButton: Colors.white,
    badge: TemaShikkoku.temaCorSuperficie2,
    badgeBorder: TemaShikkoku.temaCorBorda,
    onBadge: TemaShikkoku.temaCorTexto,
    success: TemaShikkoku.temaCorSucesso,
    danger: TemaShikkoku.temaCorErro,
    dedication: TemaIchigoNoite.temaCorAcento,
    rankStroke: TemaShikkoku.temaCorTexto2,
    cardShadow: [BoxShadow(color: Colors.transparent)],
    brandArc: [TemaShikkoku.temaCorSelo, TemaShikkoku.temaCorSelo],
    brandPlay: [TemaShikkoku.temaCorTexto, TemaShikkoku.temaCorTexto],
    brandGlow: TemaShikkoku.temaCorSelo,
    brandShine: TemaShikkoku.temaCorTexto,
    emblemAsset: 'assets/heisuca/selo_pequeno_ichigo.svg',
  );
  static const sorairoNoite = CgflixPalette(
    variant: CgflixThemeVariant.sorairo,
    light: false,
    background: TemaShikkoku.temaCorFundo,
    surface: TemaShikkoku.temaCorSuperficie,
    surfaceHigh: TemaShikkoku.temaCorSuperficie2,
    accent: TemaSorairoNoite.temaCorAcento,
    accentSoft: TemaSorairoNoite.temaCorAcentoSuave,
    action: TemaShikkoku.temaCorBotaoFundo,
    onAction: TemaShikkoku.temaCorBotaoTexto,
    progress: TemaSorairoNoite.temaCorAcento,
    progressTrack: TemaShikkoku.temaCorSuperficie2,
    textMuted: TemaShikkoku.temaCorTexto2,
    divider: TemaShikkoku.temaCorBorda,
    heroVeil: [
      Colors.black54,
      Colors.transparent,
      Colors.transparent,
      TemaShikkoku.temaCorFundo,
      TemaShikkoku.temaCorFundo,
    ],
    topVeil: [TemaShikkoku.temaCorFundo, Colors.transparent],
    sheetVeil: [Colors.transparent, TemaShikkoku.temaCorSuperficie],
    glass: TemaShikkoku.temaCorSuperficie,
    glassBorder: TemaShikkoku.temaCorBorda,
    onGlass: TemaShikkoku.temaCorTexto,
    chipSelected: TemaShikkoku.temaCorSuperficie2,
    chipSelectedBorder: TemaSorairoNoite.temaCorAcento,
    pressed: TemaShikkoku.temaCorSuperficie2,
    hovered: TemaShikkoku.temaCorSuperficie2,
    focused: TemaShikkoku.temaCorSuperficie2,
    focusRing: TemaShikkoku.temaCorFoco,
    secondaryAction: TemaShikkoku.temaCorSuperficie2,
    onSecondaryAction: TemaShikkoku.temaCorTexto,
    photoButton: Colors.black54,
    onPhotoButton: Colors.white,
    badge: TemaShikkoku.temaCorSuperficie2,
    badgeBorder: TemaShikkoku.temaCorBorda,
    onBadge: TemaShikkoku.temaCorTexto,
    success: TemaShikkoku.temaCorSucesso,
    danger: TemaShikkoku.temaCorErro,
    dedication: TemaSorairoNoite.temaCorAcento,
    rankStroke: TemaShikkoku.temaCorTexto2,
    cardShadow: [BoxShadow(color: Colors.transparent)],
    brandArc: [TemaShikkoku.temaCorSelo, TemaShikkoku.temaCorSelo],
    brandPlay: [TemaShikkoku.temaCorTexto, TemaShikkoku.temaCorTexto],
    brandGlow: TemaShikkoku.temaCorSelo,
    brandShine: TemaShikkoku.temaCorTexto,
    emblemAsset: 'assets/heisuca/selo_pequeno_sorairo.svg',
  );
  static const tv = isis; // Compatibilidade: a TV usa os mesmos tokens.
  ColorScheme get scheme => switch (variant) {
    CgflixThemeVariant.isis => cgflixIsisScheme,
    CgflixThemeVariant.heitor => cgflixHeitorScheme,
    CgflixThemeVariant.sumi => cgflixSumiScheme,
    CgflixThemeVariant.ichigo => isLight ? cgflixIchigoScheme : cgflixIchigoNoiteScheme,
    CgflixThemeVariant.sorairo => isLight ? cgflixSorairoScheme : cgflixSorairoNoiteScheme,
  };
  Color get text => scheme.onSurface;

  /// Escolha de papel de texto pelo fundo real (WCAG AA, texto normal).
  /// Mantém o secundário nas camadas em que há contraste; em camadas altas
  /// usa o principal. Nunca clareia/escurece ou inventa outra cor da marca.
  Color textOn(Color background, {Color? preferred}) {
    final candidate = preferred ?? textMuted;
    final blended = Color.alphaBlend(candidate, background);
    final a = blended.computeLuminance(), b = background.computeLuminance();
    final ratio = (math.max(a, b) + .05) / (math.min(a, b) + .05);
    return ratio >= 4.5 ? candidate : text;
  }

  static CgflixPalette forVariant(CgflixThemeVariant variant, {bool dark = false}) => switch (variant) {
    CgflixThemeVariant.isis => isis,
    CgflixThemeVariant.sumi => sumi,
    CgflixThemeVariant.heitor => heitor,
    CgflixThemeVariant.ichigo => dark ? ichigoNoite : ichigo,
    CgflixThemeVariant.sorairo => dark ? sorairoNoite : sorairo,
  };

  /// Paleta do tema atual. Sem o tema do CGFLIX (testes de peças soltas), cai na Isis.
  static CgflixPalette of(BuildContext context) => Theme.of(context).extension<CgflixPalette>() ?? isis;

  @override
  CgflixPalette copyWith() => this;

  /// Troca seca entre temas (os dois são opostos; misturar cores no meio não ajuda).
  @override
  CgflixPalette lerp(CgflixPalette? other, double t) => other == null || t < 0.5 ? this : other;
}

/// Atalho: `context.cgflix.accent`.
extension CgflixPaletteContext on BuildContext {
  CgflixPalette get cgflix => CgflixPalette.of(this);
}
