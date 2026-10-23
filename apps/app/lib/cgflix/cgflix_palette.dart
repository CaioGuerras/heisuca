// Esquemas de cor dos temas do CGFLIX (tema Heitor, versão 1.4.0):
//   - Isis: escuro, preto puro (OLED) e roxo — o tema de sempre;
//   - Heitor: claro (branco esverdeado, nunca branco puro no fundo) e verde.
// Nenhum widget do CGFLIX usa cor solta: tudo vem do [ColorScheme] ou da [CgflixPalette]
// (véus sobre fotos, vidro da barra, sombras, selos, degradês da marca). Trocar de tema é só
// trocar o par esquema + paleta.
import 'package:flutter/material.dart';

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

/// Isis: o esquema que o app já tinha (tema "mono" do upstream no modo OLED + cores do site),
/// escrito à mão. Fundo preto puro (#000) por causa das telas OLED; superfícies #120e1a.
/// O `primary` continua o branco do upstream (botões e chaves brancos); o roxo entra pela
/// [CgflixPalette] e pelos widgets do CGFLIX.
const cgflixIsisScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFEDEDED),
  onPrimary: Color(0xFF000000),
  primaryContainer: Color(0xFF120E1A),
  onPrimaryContainer: Color(0xFFEDEDED),
  secondary: Color(0xFFEDEDED),
  onSecondary: Color(0xFF000000),
  secondaryContainer: Color(0xFF120E1A),
  onSecondaryContainer: Color(0xFFEDEDED),
  tertiary: Color(0xFFEDEDED),
  onTertiary: Color(0xFF000000),
  // 1.5.0: vermelho claro (o mesmo `danger`): o #B00020 dava 2,5:1 sobre o preto.
  error: Color(0xFFF87171),
  onError: Color(0xFF000000),
  surface: Color(0xFF120E1A),
  onSurface: Color(0xFFEDEDED),
  onSurfaceVariant: Color(0xB3FFFFFF),
  surfaceDim: Color(0xFF000000),
  surfaceBright: Color(0xFF120E1A),
  surfaceContainerLowest: Color(0xFF000000),
  surfaceContainerLow: Color(0xFF000000),
  surfaceContainer: Color(0xFF120E1A),
  surfaceContainerHigh: Color(0xFF1C1626),
  surfaceContainerHighest: Color(0xFF1C1626),
  // 1.5.0: borda dos botões com contorno e dos campos visível no preto (3:1); divisores seguem suaves.
  outline: Color(0x61FFFFFF),
  outlineVariant: Color(0x1FFFFFFF),
  shadow: Color(0x00000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFEDEDED),
  onInverseSurface: Color(0xFF000000),
  inversePrimary: Color(0xFF000000),
);

/// Heitor: Material 3, semente #34C759 (systemGreen da Apple), esquema `SchemeContent`, com as
/// cores escritas à mão a partir da tabela oficial (contraste medido em
/// `test/cgflix/cgflix_contraste_test.dart`). Os papéis que a tabela não traz (inverso,
/// containers terciários etc.) vieram do `fromSeed` e foram conferidos.
const cgflixHeitorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF006E28),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF34C759),
  onPrimaryContainer: Color(0xFF004D1A),
  secondary: Color(0xFF3B6939),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFB0EFB0),
  onSecondaryContainer: Color(0xFF002106),
  tertiary: Color(0xFF006495),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFCBE6FF),
  onTertiaryContainer: Color(0xFF001E30),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFF4FCEE),
  onSurface: Color(0xFF161D16),
  onSurfaceVariant: Color(0xFF3D4A3C),
  surfaceDim: Color(0xFFD5DCD0),
  surfaceBright: Color(0xFFF4FCEE),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFEEF6E9),
  surfaceContainer: Color(0xFFE8F0E3),
  surfaceContainerHigh: Color(0xFFE2EBDE),
  surfaceContainerHighest: Color(0xFFDDE5D8),
  outline: Color(0xFF6D7B6B),
  outlineVariant: Color(0xFFBCCBB8),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF2B322A),
  onInverseSurface: Color(0xFFECF4E6),
  inversePrimary: Color(0xFF6BDF83),
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

  bool get isLight => variant != CgflixThemeVariant.isis;

  static const isis = CgflixPalette(
    variant: CgflixThemeVariant.isis,
    background: Color(0xFF000000),
    surface: Color(0xFF120E1A),
    surfaceHigh: Color(0xFF1C1626),
    accent: Color(0xFFA855F7),
    accentSoft: Color(0xFFC084FC),
    action: Color(0xFF9333EA),
    onAction: Color(0xFFFFFFFF),
    progress: Color(0xFFA855F7),
    progressTrack: Color(0x3DFFFFFF),
    textMuted: Color(0xB3FFFFFF),
    divider: Color(0x1FFFFFFF),
    heroVeil: [Color(0xB3000000), Color(0x00000000), Color(0x00000000), Color(0xE6000000), Color(0xFF000000)],
    topVeil: [Color(0xE6000000), Color(0x99000000), Color(0x00000000)],
    sheetVeil: [Color(0x00120E1A), Color(0x00120E1A), Color(0xFF120E1A)],
    glass: Color(0x3307060A),
    glassBorder: Color(0x61FFFFFF),
    onGlass: Color(0xFFFFFFFF),
    chipSelected: Color(0x47A855F7),
    chipSelectedBorder: Color(0xFFA855F7),
    pressed: Color(0x3DFFFFFF),
    hovered: Color(0x1AFFFFFF),
    focused: Color(0x59A855F7),
    focusRing: Color(0xFFA855F7),
    secondaryAction: Color(0x33FFFFFF),
    onSecondaryAction: Color(0xFFFFFFFF),
    photoButton: Color(0x8A000000),
    onPhotoButton: Color(0xFFFFFFFF),
    badge: Color(0x2EA855F7),
    badgeBorder: Color(0xFFC084FC),
    onBadge: Color(0xFFFFFFFF),
    success: Color(0xFF4ADE80),
    danger: Color(0xFFF87171),
    dedication: Color(0xFF22C55E),
    rankStroke: Color(0xFFC084FC),
    cardShadow: [],
    brandArc: [Color(0xFFF3E8FF), Color(0xFFC084FC), Color(0xFF9333EA), Color(0xFF581C87)],
    brandPlay: [Color(0xFFFFFFFF), Color(0xFFEDE9FE), Color(0xFFC4B5FD)],
    brandGlow: Color(0x73A855F7),
    brandShine: Color(0x8CFFFFFF),
    emblemAsset: 'assets/heisuca/selo_pequeno_shikkoku.svg',
  );

  static const heitor = CgflixPalette(
    variant: CgflixThemeVariant.heitor,
    background: Color(0xFFF4FCEE),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE2EBDE),
    accent: Color(0xFF006E28),
    accentSoft: Color(0xFF006E28),
    action: Color(0xFF006E28),
    onAction: Color(0xFFFFFFFF),
    progress: Color(0xFF34C759),
    progressTrack: Color(0x4D161D16),
    textMuted: Color(0xFF3D4A3C),
    divider: Color(0xFFBCCBB8),
    // Véu claro: a foto continua aparecendo no meio e some no branco esverdeado onde fica o
    // texto (o título e a sinopse escuros pedem um fundo bem mais claro que o véu escuro da Isis).
    heroVeil: [Color(0xCCF4FCEE), Color(0x1AF4FCEE), Color(0x33F4FCEE), Color(0xF0F4FCEE), Color(0xFFF4FCEE)],
    topVeil: [Color(0xEBF4FCEE), Color(0xA6F4FCEE), Color(0x00F4FCEE)],
    sheetVeil: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0xFFFFFFFF)],
    glass: Color(0xC7FFFFFF),
    glassBorder: Color(0xFF6D7B6B),
    onGlass: Color(0xFF161D16),
    chipSelected: Color(0xFFB0EFB0),
    chipSelectedBorder: Color(0xFF006E28),
    pressed: Color(0x1F161D16),
    hovered: Color(0x0F161D16),
    focused: Color(0x33006E28),
    focusRing: Color(0xFF006E28),
    secondaryAction: Color(0xFFE2EBDE),
    onSecondaryAction: Color(0xFF161D16),
    photoButton: Color(0x8A000000),
    onPhotoButton: Color(0xFFFFFFFF),
    badge: Color(0xFF34C759),
    badgeBorder: Color(0xFF34C759),
    onBadge: Color(0xFF004D1A),
    success: Color(0xFF006E28),
    danger: Color(0xFFBA1A1A),
    dedication: Color(0xFF1A9443),
    rankStroke: Color(0xFF006E28),
    cardShadow: [
      BoxShadow(color: Color(0x1F0B2A10), blurRadius: 12, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x140B2A10), blurRadius: 2, offset: Offset(0, 1)),
    ],
    brandArc: [Color(0xFF8BE3A1), Color(0xFF34C759), Color(0xFF1A9443), Color(0xFF00531D)],
    brandPlay: [Color(0xFF2B3A2A), Color(0xFF1C261C), Color(0xFF161D16)],
    brandGlow: Color(0x4734C759),
    brandShine: Color(0x8CFFFFFF),
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
