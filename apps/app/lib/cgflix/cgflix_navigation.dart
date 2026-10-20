// Navegação do CGFLIX no celular (Etapa 1D): UMA barra no topo, sem barra inferior.
//   - à esquerda, o emblema: abre o menu do usuário (conta, Favoritos, Bibliotecas, Baixados, Configurações...);
//   - ao centro: chips Filmes · Séries · Animes e a lupa (Busca).
// A Início é a raiz; Busca, Baixados, Configurações e Meus pedidos abrem como páginas por cima,
// com Voltar (botão e gesto). TV e computador continuam com a navegação do upstream.
// Etapa 1E: sai o ícone "Pedir": os pedidos ficam dentro da busca ("Disponível para pedir") e
// "Meus pedidos" vai para o menu do usuário.
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../navigation/navigation_tabs.dart';
import '../navigation/settings_shortcut.dart';
import '../screens/downloads/downloads_screen.dart';
import '../screens/libraries/libraries_screen.dart';
import '../screens/search_screen.dart';
import '../services/settings_service.dart';
import '../utils/platform_detector.dart';
import '../widgets/settings_section.dart';
import '../widgets/app_icon.dart';
import 'cgflix_logo.dart';
import 'cgflix_palette.dart';
import 'cgflix_style.dart';
import 'cgflix_user_menu.dart';
import 'requests/cgflix_requests_ui.dart';

/// Celular e tablet usam a navegação do CGFLIX (TV e computador ficam como no upstream).
bool cgflixUseYouTab(BuildContext context) => PlatformDetector.isMobile(context);

/// Seção inicial: no celular a raiz é sempre a Início (não há mais abas para escolher);
/// TV e computador seguem a preferência "Seção inicial" do upstream.
NavigationTabId? cgflixStartupSection() {
  final handheld = !PlatformDetector.isTV() && (Platform.isAndroid || Platform.isIOS);
  if (handheld) return null;
  return SettingsService.instanceOrNull?.read(SettingsService.startupSection);
}

/// Testes do upstream ligam isto para ver as Configurações completas (como na TV).
bool cgflixDebugShowUpstreamSettings = false;

/// Celular: esconde as opções que só mexiam na navegação do upstream.
bool cgflixHidesUpstreamSettings(BuildContext context) => !cgflixDebugShowUpstreamSettings && cgflixUseYouTab(context);

/// Aparência: no celular saem Tela inicial, Navegação e TV ao vivo (a Início é a do CGFLIX,
/// sem abas nem TV ao vivo; essas opções só mexiam nas telas do upstream). TV e computador
/// veem tudo.
List<Widget> cgflixAppearanceGroups(BuildContext context, List<Widget> children) {
  if (!cgflixHidesUpstreamSettings(context)) return children;
  final titles = [t.settings.homeScreen, t.settings.navigation, t.settings.liveTv];
  return [
    for (final child in children)
      if (child is! SettingsGroup || !titles.contains(child.title)) child,
  ];
}

/// Sem barra de abas: só a raiz. Conectado é a Início; sem conexão sobra Baixados (o upstream
/// já tira as abas que exigem servidor).
List<NavigationTab> cgflixMobileTabs(List<NavigationTab> visibleTabs) {
  for (final id in const [NavigationTabId.discover, NavigationTabId.downloads]) {
    final tab = visibleTabs.where((t) => t.id == id).firstOrNull;
    if (tab != null) return [tab];
  }
  return visibleTabs.take(1).toList();
}

// ---------------------------------------------------------------------------
// Destinos da barra do topo e do menu do usuário

/// Páginas que a barra do topo e o menu abrem. Ficam aqui (trocáveis) para os testes da
/// navegação não precisarem montar o app inteiro.
abstract final class CgflixPages {
  static WidgetBuilder search = (_) => const SearchScreen();
  static WidgetBuilder downloads = (_) => const DownloadsScreen();

  /// Bibliotecas do upstream (1.5.0: no menu do usuário).
  static WidgetBuilder libraries = (_) => const LibrariesScreen();
  static Route<void> Function() settings = buildSettingsRoute;

  /// "Meus pedidos" (Seerr), em tela nativa.
  static WidgetBuilder myRequests = (_) => const CgflixMyRequestsScreen();
}

/// Busca unificada (1C) como página por cima da Início; o campo já abre com foco.
Future<void> cgflixOpenSearch(BuildContext context) {
  HapticFeedback.selectionClick();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'cgflix/busca'),
      builder: CgflixPages.search,
    ),
  );
}

/// Baixados (saiu da barra inferior e entrou no menu do usuário).
Future<void> cgflixOpenDownloads(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: 'cgflix/baixados'),
    builder: CgflixPages.downloads,
  ),
);

Future<void> cgflixOpenSettings(BuildContext context) => Navigator.of(context).push(CgflixPages.settings());

/// "Meus pedidos" (menu do usuário): o que a pessoa pediu no Seerr e a situação de cada um.
Future<void> cgflixOpenMyRequests(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: 'cgflix/meus-pedidos'),
    builder: CgflixPages.myRequests,
  ),
);

// ---------------------------------------------------------------------------
// Barra do topo

/// Altura da linha da barra (sem a barra de status). Chips e lupa têm a mesma altura
/// visual (36 dp) e alvo de toque de 48 dp.
const cgflixTopBarHeight = 56.0;
const _itemHeight = 36.0;

/// Chip de categoria para a barra do topo (o estado do filtro fica com quem chama).
class CgflixTopBarChip {
  const CgflixTopBarChip({required this.label, required this.selected, required this.onPressed});
  final String label;
  final bool selected;
  final VoidCallback onPressed;
}

/// Barra única do topo: emblema à esquerda; chips e Busca alinhados entre si e centralizados
/// na TELA. Se não couber (celular estreito, fonte grande), só os chips rolam na horizontal: a
/// lupa fica sempre visível e o emblema nunca é empurrado.
/// Transparente: quem chama põe o gradiente e o "some ao rolar".
class CgflixTopBar extends StatelessWidget {
  const CgflixTopBar({super.key, this.chips = const [], this.onClearFilter, this.showActions = true});

  final List<CgflixTopBarChip> chips;

  /// Com um chip ativo, aparece o "×" para voltar a Tudo.
  final VoidCallback? onClearFilter;

  /// Busca (some sem conexão).
  final bool showActions;

  /// Largura natural do grupo do centro (para decidir se dá para centralizar na tela).
  double _groupWidth(BuildContext context) {
    final scaler = _chipTextScaler(context);
    var width = 0.0;
    for (final chip in chips) {
      final painter = TextPainter(
        // Mesmo estilo que o Text do chip recebe (o tema soma espaçamento entre letras).
        text: TextSpan(text: chip.label, style: DefaultTextStyle.of(context).style.merge(_chipTextStyle)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      // + a borda de 1 dp de cada lado (a decoração do chip soma a borda ao tamanho).
      width += painter.width + 2 * (_chipPadding + _slotPadding + 1);
      painter.dispose();
    }
    if (onClearFilter != null) width += 48;
    if (showActions) width += 48;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final chipsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onClearFilter != null)
          _RoundIconButton(
            key: const ValueKey('cgflix-top-clear'),
            icon: Symbols.close_rounded,
            label: 'Voltar para Tudo',
            onPressed: onClearFilter!,
          ),
        for (final chip in chips) _TopChip(key: ValueKey('cgflix-top-chip-${chip.label}'), chip: chip),
      ],
    );
    final actions = [
      if (showActions) ...[
        _RoundIconButton(
          key: const ValueKey('cgflix-top-search'),
          icon: Symbols.search_rounded,
          label: 'Buscar',
          onPressed: () => cgflixOpenSearch(context),
        ),
      ],
    ];
    final group = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: chipsRow),
        ),
        ...actions,
      ],
    );

    return SizedBox(
      height: cgflixTopBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const side = CgflixUserMenuButton.size + 8;
          // Cabe com um espelho do emblema do outro lado? Então o centro do grupo é o centro
          // da tela. Senão, centraliza no espaço à direita do emblema (e, se nem assim
          // couber, os chips rolam).
          final centered = _groupWidth(context) <= constraints.maxWidth - 2 * side;
          return Row(
            children: [
              const CgflixUserMenuButton(),
              const SizedBox(width: 8),
              Expanded(child: Center(child: group)),
              if (centered) const SizedBox(width: side),
            ],
          );
        },
      ),
    );
  }
}

/// Estados visíveis (o tema do upstream desliga o efeito de toque): pressionado, foco
/// (teclado/controle) e mouse por cima, nas cores do tema atual.
WidgetStateProperty<Color?> cgflixPressedOverlay(BuildContext context) {
  final palette = context.cgflix;
  return WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.pressed)) return palette.pressed;
    if (states.contains(WidgetState.focused)) return palette.focused;
    if (states.contains(WidgetState.hovered)) return palette.hovered;
    return null;
  });
}

const _chipPadding = 12.0;
const _slotPadding = 6.0;
const _chipTextStyle = TextStyle(fontSize: 14, height: 1.2, fontWeight: FontWeight.w600, fontFamily: 'Inter');
TextScaler _chipTextScaler(BuildContext context) => MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

/// Emblema do CGFLIX que abre o menu do usuário (o novo lugar do perfil).
class CgflixUserMenuButton extends StatelessWidget {
  const CgflixUserMenuButton({super.key});

  static const size = 48.0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Menu: perfil, Baixados e Configurações',
      child: Semantics(
        button: true,
        label: 'Menu do CGFLIX: perfil, Baixados, Configurações e Sair',
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('cgflix-top-menu'),
            onTap: () {
              HapticFeedback.selectionClick();
              showCgflixUserMenu(context);
            },
            child: const SizedBox.square(
              dimension: size,
              child: Center(child: CgflixEmblem(size: 32)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  const _TopChip({super.key, required this.chip});
  final CgflixTopBarChip chip;

  @override
  Widget build(BuildContext context) {
    final selected = chip.selected;
    final palette = context.cgflix;
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '${chip.label}, filtro ativo' : 'Mostrar só ${chip.label}',
      excludeSemantics: true,
      // Alvo de toque de 48 dp, desenho de 36 dp (mesma linha das lupas); 6 dp de cada lado,
      // como a lupa (48 − 36), dão o mesmo espaço visual (12 dp) entre todos os itens.
      child: GestureDetector(
        // Toque na margem do alvo de 48 dp também vale.
        behavior: HitTestBehavior.opaque,
        onTap: chip.onPressed,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: _slotPadding),
          child: Center(
            child: AnimatedContainer(
              duration: CgflixMotion.fast,
              curve: CgflixMotion.curve,
              height: _itemHeight,
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(color: selected ? palette.chipSelectedBorder : palette.glassBorder),
                ),
                color: selected ? palette.chipSelected : palette.glass,
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: chip.onPressed,
                  overlayColor: cgflixPressedOverlay(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _chipPadding),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        chip.label,
                        maxLines: 1,
                        softWrap: false,
                        textScaler: _chipTextScaler(context),
                        style: _chipTextStyle.copyWith(color: palette.onGlass),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão redondo da barra (lupa, "×"): 36 dp desenhados, 48 dp de toque.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({super.key, required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          // Toque na margem do alvo de 48 dp também vale.
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Material(
                color: context.cgflix.glass,
                shape: CircleBorder(side: BorderSide(color: context.cgflix.glassBorder)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  overlayColor: cgflixPressedOverlay(context),
                  child: SizedBox.square(
                    dimension: _itemHeight,
                    child: Center(child: AppIcon(icon, size: 20, color: context.cgflix.onGlass)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sem conexão (a raiz vira Baixados): o mesmo topo, só com o emblema/menu e "Reconectar".
class CgflixOfflineTopBar extends StatelessWidget {
  const CgflixOfflineTopBar({super.key, required this.reconnecting, required this.onReconnect});
  final bool reconnecting;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: context.cgflix.background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8 + padding.left, padding.top, 8 + padding.right, 0),
        child: SizedBox(
          height: cgflixTopBarHeight,
          child: Row(
            children: [
              const CgflixUserMenuButton(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sem conexão',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.cgflix.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: reconnecting ? null : onReconnect,
                icon: reconnecting
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const AppIcon(Symbols.wifi_rounded, size: 18),
                label: const Text('Reconectar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
