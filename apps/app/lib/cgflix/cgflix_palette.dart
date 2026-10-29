// Paletas do Heisuca. Os identificadores históricos isis/heitor preservam
// preferências; representam Shikkoku e Hisui. Cores de foto/vidro/estado e
// esquemas Material compartilham estes tokens. Infantil permanece independente.
import 'dart:math' as math;
import 'package:flutter/material.dart';

const heisucaShikkokuCanvas = Color(0xFF17151C);
const heisucaShikkokuSurface = Color(0xFF292531);
const heisucaShikkokuSurface2 = Color(0xFF45404F);
const heisucaShikkokuSurface3 = Color(0xFF5B5465);
const heisucaShikkokuAccent = Color(0xFFC7BBD4);
const heisucaShikkokuText = Color(0xFFE2DDE7);
const heisucaShikkokuLine = Color(0x14E2DDE7);
const heisucaHisuiDarkCanvas = Color(0xFF051F20);
const heisucaHisuiDarkSurface = Color(0xFF0B2B26);
const heisucaHisuiDarkSurface2 = Color(0xFF163832);
const heisucaHisuiAccent = Color(0xFF8EB69B);
const heisucaHisuiDarkSurface3 = Color(0xFF235347);

/// Os dois temas do CGFLIX (nomes de família, escolhidos pelo dono).
enum CgflixThemeVariant {
  isis,
  heitor,
  /// Infantil menina: morangos e melancias (claro).
  ichigo,
  /// Infantil menino: nuvens, estrelas e aviõezinhos (claro).
  sorairo;

  bool get isKids => this == ichigo || this == sorairo;
}

/// P2: cores oficiais. `onSurfaceVariant` escuro usa o texto principal porque
/// widgets Material também o desenham sobre superfícies altas. O secundário
/// original fica em `textMuted`, para canvas/superfície 1; ver textOn.
const cgflixIsisScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: heisucaShikkokuAccent,
  onPrimary: heisucaShikkokuCanvas,
  primaryContainer: heisucaShikkokuSurface2,
  onPrimaryContainer: heisucaShikkokuText,
  secondary: heisucaShikkokuAccent,
  onSecondary: heisucaShikkokuCanvas,
  secondaryContainer: heisucaShikkokuSurface2,
  onSecondaryContainer: heisucaShikkokuText,
  tertiary: heisucaShikkokuAccent,
  onTertiary: heisucaShikkokuCanvas,
  tertiaryContainer: heisucaShikkokuSurface2,
  onTertiaryContainer: heisucaShikkokuText,
  error: Color(0xFFD96B6B),
  onError: heisucaShikkokuCanvas,
  errorContainer: heisucaShikkokuSurface,
  onErrorContainer: heisucaShikkokuText,
  surface: heisucaShikkokuCanvas,
  onSurface: heisucaShikkokuText,
  onSurfaceVariant: heisucaShikkokuText,
  surfaceDim: heisucaShikkokuCanvas,
  surfaceBright: heisucaShikkokuSurface,
  surfaceContainerLowest: heisucaShikkokuSurface,
  surfaceContainerLow: heisucaShikkokuSurface,
  surfaceContainer: heisucaShikkokuSurface,
  surfaceContainerHigh: heisucaShikkokuSurface2,
  surfaceContainerHighest: heisucaShikkokuSurface3,
  outline: Color(0x61FFFFFF),
  outlineVariant: heisucaShikkokuLine,
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: heisucaShikkokuText,
  onInverseSurface: heisucaShikkokuCanvas,
  inversePrimary: heisucaShikkokuCanvas,
);

const cgflixHeitorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: heisucaHisuiDarkSurface3,
  onPrimary: Color(0xFFDAF1DE),
  primaryContainer: heisucaHisuiAccent,
  onPrimaryContainer: heisucaHisuiDarkCanvas,
  secondary: heisucaHisuiDarkSurface3,
  onSecondary: Color(0xFFDAF1DE),
  secondaryContainer: Color(0xFFEBF7EE),
  onSecondaryContainer: heisucaHisuiDarkCanvas,
  tertiary: heisucaHisuiDarkSurface3,
  onTertiary: Color(0xFFDAF1DE),
  tertiaryContainer: heisucaHisuiAccent,
  onTertiaryContainer: heisucaHisuiDarkCanvas,
  error: Color(0xFFB53D3D),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFFFFF),
  onErrorContainer: heisucaHisuiDarkCanvas,
  surface: Color(0xFFDAF1DE),
  onSurface: heisucaHisuiDarkCanvas,
  onSurfaceVariant: heisucaHisuiDarkSurface2,
  surfaceDim: Color(0xFFDAF1DE),
  surfaceBright: Color(0xFFFFFFFF),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFFFFFFF),
  surfaceContainerHigh: Color(0xFFEBF7EE),
  surfaceContainerHighest: Color(0xFFD0EBD6),
  outline: heisucaHisuiDarkSurface3,
  outlineVariant: Color(0x1F0B2B26),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: heisucaHisuiDarkCanvas,
  onInverseSurface: Color(0xFFDAF1DE),
  inversePrimary: Color(0xFFDAF1DE),
);

/// Esquemas Material do modo infantil (mesmo esqueleto do Heitor, cores dos tokens oficiais).
const cgflixIchigoScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFD62D45),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE85A6D),
  onPrimaryContainer: Color(0xFF4A0712),
  secondary: Color(0xFF24803A),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFFD3D9),
  onSecondaryContainer: Color(0xFF3A0B12),
  tertiary: Color(0xFF006495),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFCBE6FF),
  onTertiaryContainer: Color(0xFF001E30),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFFFF5F3),
  onSurface: Color(0xFF2B1B1E),
  onSurfaceVariant: Color(0xFF6B4C52),
  surfaceDim: Color(0xFFF0D9DB),
  surfaceBright: Color(0xFFFFF5F3),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFEDEE),
  surfaceContainer: Color(0xFFFDE7E9),
  surfaceContainerHigh: Color(0xFFFDE4E6),
  surfaceContainerHighest: Color(0xFFF8DCDF),
  outline: Color(0xFFB88A92),
  outlineVariant: Color(0xFFF2C9CE),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF3B2A2D),
  onInverseSurface: Color(0xFFFFF0F1),
  inversePrimary: Color(0xFFFF9AA8),
);

const cgflixSorairoScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF1F6FC5),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF4A9BEF),
  onPrimaryContainer: Color(0xFF0A2A55),
  secondary: Color(0xFF8A5F00),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFCFE4FB),
  onSecondaryContainer: Color(0xFF0B1F3A),
  tertiary: Color(0xFF006495),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFCBE6FF),
  onTertiaryContainer: Color(0xFF001E30),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFF1F7FD),
  onSurface: Color(0xFF14263A),
  onSurfaceVariant: Color(0xFF4A5E73),
  surfaceDim: Color(0xFFD3DFEC),
  surfaceBright: Color(0xFFF1F7FD),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFE9F2FB),
  surfaceContainer: Color(0xFFE4EEF9),
  surfaceContainerHigh: Color(0xFFE1ECF8),
  surfaceContainerHighest: Color(0xFFDAE6F3),
  outline: Color(0xFF8399B0),
  outlineVariant: Color(0xFFC4D6EA),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF26364A),
  onInverseSurface: Color(0xFFEEF5FD),
  inversePrimary: Color(0xFF9CC8F5),
);

/// Camadas do CGFLIX que o [ColorScheme] não descreve. Cada tema ajusta cada camada (foto,
/// véu, sombra, borda, estado, foco): no Heitor não é "trocar roxo por verde".
@immutable
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

  bool get isLight => light ?? variant != CgflixThemeVariant.isis;

  static const isis = CgflixPalette(
    variant: CgflixThemeVariant.isis,
    light: false,
    background: heisucaShikkokuCanvas,
    surface: heisucaShikkokuSurface,
    surfaceHigh: heisucaShikkokuSurface2,
    accent: heisucaShikkokuAccent,
    accentSoft: heisucaShikkokuAccent,
    action: heisucaShikkokuAccent,
    onAction: heisucaShikkokuCanvas,
    progress: heisucaShikkokuAccent,
    progressTrack: heisucaShikkokuSurface3,
    textMuted: Color(0xFFAAA2B3),
    divider: heisucaShikkokuLine,
    heroVeil: [Color(0xB317151C), Color(0x0017151C), Color(0x0017151C), Color(0xF017151C), heisucaShikkokuCanvas],
    topVeil: [Color(0xE617151C), Color(0x9917151C), Color(0x0017151C)],
    sheetVeil: [Color(0x00292531), Color(0x00292531), heisucaShikkokuSurface],
    glass: Color(0xE6292531),
    glassBorder: heisucaShikkokuSurface2,
    onGlass: heisucaShikkokuText,
    chipSelected: heisucaShikkokuSurface2,
    chipSelectedBorder: heisucaShikkokuText,
    pressed: Color(0x24E2DDE7),
    hovered: heisucaShikkokuLine,
    focused: Color(0x24E2DDE7),
    focusRing: heisucaShikkokuText,
    secondaryAction: heisucaShikkokuSurface2,
    onSecondaryAction: heisucaShikkokuText,
    photoButton: Color(0xCC17151C),
    onPhotoButton: heisucaShikkokuText,
    badge: heisucaShikkokuSurface2,
    badgeBorder: heisucaShikkokuSurface2,
    onBadge: heisucaShikkokuText,
    success: heisucaHisuiAccent,
    danger: Color(0xFFD96B6B),
    dedication: heisucaShikkokuAccent,
    rankStroke: heisucaShikkokuAccent,
    cardShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
    brandArc: [heisucaShikkokuText,heisucaShikkokuAccent,Color(0xFFAAA2B3),heisucaShikkokuSurface3],
    brandPlay: [heisucaShikkokuText,heisucaShikkokuAccent,Color(0xFFAAA2B3)],
    brandGlow: Color(0x33C7BBD4),
    brandShine: Color(0x33E2DDE7),
    emblemAsset: 'assets/heisuca/selo_pequeno_shikkoku.svg',
  );

  static const heitor = CgflixPalette(
    variant: CgflixThemeVariant.heitor,
    light: true,
    background: Color(0xFFDAF1DE),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEBF7EE),
    accent: heisucaHisuiDarkSurface3,
    accentSoft: heisucaHisuiDarkSurface3,
    action: heisucaHisuiDarkSurface3,
    onAction: Color(0xFFDAF1DE),
    progress: heisucaHisuiDarkSurface3,
    progressTrack: Color(0xFFD0EBD6),
    textMuted: heisucaHisuiDarkSurface2,
    divider: Color(0x1F0B2B26),
    heroVeil: [Color(0xB3DAF1DE), Color(0x00DAF1DE), Color(0x00DAF1DE), Color(0xF0DAF1DE), Color(0xFFDAF1DE)],
    topVeil: [Color(0xE6DAF1DE), Color(0x99DAF1DE), Color(0x00DAF1DE)],
    sheetVeil: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0xFFFFFFFF)],
    glass: Color(0xE6FFFFFF),
    glassBorder: heisucaHisuiAccent,
    onGlass: heisucaHisuiDarkCanvas,
    chipSelected: Color(0xFFEBF7EE),
    chipSelectedBorder: heisucaHisuiDarkSurface3,
    pressed: Color(0x24051F20),
    hovered: Color(0x14051F20),
    focused: Color(0x24235347),
    focusRing: heisucaHisuiDarkSurface3,
    secondaryAction: Color(0xFFEBF7EE),
    onSecondaryAction: heisucaHisuiDarkCanvas,
    photoButton: Color(0xCCDAF1DE),
    onPhotoButton: heisucaHisuiDarkCanvas,
    badge: heisucaHisuiAccent,
    badgeBorder: heisucaHisuiAccent,
    onBadge: heisucaHisuiDarkCanvas,
    success: heisucaHisuiDarkSurface3,
    danger: Color(0xFFB53D3D),
    dedication: heisucaHisuiDarkSurface3,
    rankStroke: heisucaHisuiDarkSurface3,
    cardShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
    brandArc: [heisucaHisuiDarkCanvas,heisucaHisuiDarkSurface3,heisucaHisuiDarkSurface2,Color(0xFFD0EBD6)],
    brandPlay: [heisucaHisuiDarkCanvas,heisucaHisuiDarkSurface3,heisucaHisuiDarkSurface2],
    brandGlow: Color(0x33235347),
    brandShine: Color(0x33051F20),
    emblemAsset: 'assets/heisuca/selo_pequeno_hisui.svg',
  );

  /// Modo infantil (decisão de 18/10): só entram pelo perfil infantil, nunca no seletor de tema.
  /// Cores dos tokens oficiais da marca (pesquisa_apps/marca/tokens/temas/{ichigo,sorairo}).
  static const ichigo = CgflixPalette(
    variant: CgflixThemeVariant.ichigo,
    background: Color(0xFFFFF5F3),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFFDE4E6),
    accent: Color(0xFFD62D45),
    accentSoft: Color(0xFFD62D45),
    action: Color(0xFFD62D45),
    onAction: Color(0xFFFFFFFF),
    progress: Color(0xFFE85A6D),
    progressTrack: Color(0x4D2B1B1E),
    textMuted: Color(0xFF6B4C52),
    divider: Color(0xFFF2C9CE),
    heroVeil: [Color(0xCCFFF5F3), Color(0x1AFFF5F3), Color(0x33FFF5F3), Color(0xF0FFF5F3), Color(0xFFFFF5F3)],
    topVeil: [Color(0xEBFFF5F3), Color(0xA6FFF5F3), Color(0x00FFF5F3)],
    sheetVeil: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0xFFFFFFFF)],
    glass: Color(0xC7FFFFFF),
    glassBorder: Color(0xFFB88A92),
    onGlass: Color(0xFF2B1B1E),
    chipSelected: Color(0xFFFFD3D9),
    chipSelectedBorder: Color(0xFFD62D45),
    pressed: Color(0x1F2B1B1E),
    hovered: Color(0x0F2B1B1E),
    focused: Color(0x33D62D45),
    focusRing: Color(0xFFD62D45),
    secondaryAction: Color(0xFFFDE4E6),
    onSecondaryAction: Color(0xFF2B1B1E),
    photoButton: Color(0x8A000000),
    onPhotoButton: Color(0xFFFFFFFF),
    badge: Color(0xFFE85A6D),
    badgeBorder: Color(0xFFE85A6D),
    onBadge: Color(0xFFFFFFFF),
    success: Color(0xFFD62D45),
    danger: Color(0xFFBA1A1A),
    dedication: Color(0xFF24803A),
    rankStroke: Color(0xFFD62D45),
    cardShadow: [
      BoxShadow(color: Color(0x1F3A0B12), blurRadius: 12, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x143A0B12), blurRadius: 2, offset: Offset(0, 1)),
    ],
    brandArc: [Color(0xFFFF9AA8), Color(0xFFE85A6D), Color(0xFFD62D45), Color(0xFF8F1428)],
    brandPlay: [Color(0xFF4A2A30), Color(0xFF32181D), Color(0xFF2B1B1E)],
    brandGlow: Color(0x47E85A6D),
    brandShine: Color(0x8CFFFFFF),
    emblemAsset: 'assets/heisuca/selo_pequeno_ichigo.svg',
  );

  static const sorairo = CgflixPalette(
    variant: CgflixThemeVariant.sorairo,
    background: Color(0xFFF1F7FD),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE1ECF8),
    accent: Color(0xFF1F6FC5),
    accentSoft: Color(0xFF1F6FC5),
    action: Color(0xFF1F6FC5),
    onAction: Color(0xFFFFFFFF),
    progress: Color(0xFF4A9BEF),
    progressTrack: Color(0x4D14263A),
    textMuted: Color(0xFF4A5E73),
    divider: Color(0xFFC4D6EA),
    heroVeil: [Color(0xCCF1F7FD), Color(0x1AF1F7FD), Color(0x33F1F7FD), Color(0xF0F1F7FD), Color(0xFFF1F7FD)],
    topVeil: [Color(0xEBF1F7FD), Color(0xA6F1F7FD), Color(0x00F1F7FD)],
    sheetVeil: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0xFFFFFFFF)],
    glass: Color(0xC7FFFFFF),
    glassBorder: Color(0xFF8399B0),
    onGlass: Color(0xFF14263A),
    chipSelected: Color(0xFFCFE4FB),
    chipSelectedBorder: Color(0xFF1F6FC5),
    pressed: Color(0x1F14263A),
    hovered: Color(0x0F14263A),
    focused: Color(0x331F6FC5),
    focusRing: Color(0xFF1F6FC5),
    secondaryAction: Color(0xFFE1ECF8),
    onSecondaryAction: Color(0xFF14263A),
    photoButton: Color(0x8A000000),
    onPhotoButton: Color(0xFFFFFFFF),
    badge: Color(0xFF4A9BEF),
    badgeBorder: Color(0xFF4A9BEF),
    onBadge: Color(0xFFFFFFFF),
    success: Color(0xFF1F6FC5),
    danger: Color(0xFFBA1A1A),
    dedication: Color(0xFF8A5F00),
    rankStroke: Color(0xFF1F6FC5),
    cardShadow: [
      BoxShadow(color: Color(0x1F0B1F3A), blurRadius: 12, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x140B1F3A), blurRadius: 2, offset: Offset(0, 1)),
    ],
    brandArc: [Color(0xFF9CC8F5), Color(0xFF4A9BEF), Color(0xFF1F6FC5), Color(0xFF0F3F7A)],
    brandPlay: [Color(0xFF24384F), Color(0xFF172839), Color(0xFF14263A)],
    brandGlow: Color(0x474A9BEF),
    brandShine: Color(0x8CFFFFFF),
    emblemAsset: 'assets/heisuca/selo_pequeno_sorairo.svg',
  );

  /// Texto principal da paleta; cores de status não são texto universal.
  Color get text => variant == CgflixThemeVariant.ichigo ? cgflixIchigoScheme.onSurface
      : variant == CgflixThemeVariant.sorairo ? cgflixSorairoScheme.onSurface
      : isLight ? cgflixHeitorScheme.onSurface
      : cgflixIsisScheme.onSurface;

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

  static CgflixPalette forVariant(CgflixThemeVariant variant) => switch (variant) {
    CgflixThemeVariant.isis => isis,
    CgflixThemeVariant.heitor => heitor,
    CgflixThemeVariant.ichigo => ichigo,
    CgflixThemeVariant.sorairo => sorairo,
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
