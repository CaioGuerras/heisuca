// Navegação do CGFLIX no celular (Etapa 1D): UMA barra no topo, sem barra inferior.
//   - à esquerda, o emblema: abre o menu do usuário (conta, Favoritos, Bibliotecas, Baixados, Configurações...);
//   - ao centro: chips Filmes · Séries · Animes e a lupa (Busca).
// A Início é a raiz; Busca, Baixados, Configurações e Meus pedidos abrem como páginas por cima,
// com Voltar (botão e gesto). TV e computador continuam com a navegação do upstream.
// Etapa 1E: sai o ícone "Pedir": os pedidos ficam dentro da busca ("Disponível para pedir") e
// "Meus pedidos" vai para o menu do usuário.
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../navigation/navigation_tabs.dart';
import '../screens/downloads/downloads_screen.dart';
import '../screens/libraries/libraries_screen.dart';
import '../screens/search_screen.dart';
import '../services/settings_service.dart';
import '../utils/platform_detector.dart';
import '../widgets/settings_section.dart';
import '../widgets/app_icon.dart';
import '../heisuca/heisuca_logo.dart';
import '../heisuca/heisuca_library_screen.dart';
import '../heisuca/heisuca_settings_screen.dart';
import 'cgflix_palette.dart';
import 'cgflix_user_menu.dart';
import 'requests/cgflix_requests_ui.dart';

/// Celular e tablet usam a navegação do CGFLIX (TV e computador ficam como no upstream).
///
/// Lê a plataforma de [defaultTargetPlatform] (a mesma que o tema do app usa, ver `mono_theme.dart`), sem
/// depender do contexto: a tela principal decide as abas no `initState`, onde `Theme.of` é proibido (o debug
/// derrubava a Início na bancada Android).
bool cgflixUseYouTab(BuildContext context) =>
    !PlatformDetector.isTV() &&
    (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

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

/// Abas habilitadas para a Ilha Flutuante Heisuca no celular/tablet:
/// Conectado: Início (discover), Biblioteca (libraries), Busca (search) e Baixados (downloads).
List<NavigationTab> cgflixMobileTabs(List<NavigationTab> visibleTabs) {
  const allowed = {
    NavigationTabId.discover,
    NavigationTabId.libraries,
    NavigationTabId.search,
    NavigationTabId.downloads,
  };
  final filtered = visibleTabs.where((t) => allowed.contains(t.id)).toList();
  return filtered.isNotEmpty ? filtered : visibleTabs.take(1).toList();
}

// ---------------------------------------------------------------------------
// Destinos da barra do topo e do menu do usuário

/// Páginas que a barra do topo e o menu abrem. Ficam aqui (trocáveis) para os testes da
/// navegação não precisarem montar o app inteiro.
abstract final class CgflixPages {
  static WidgetBuilder search = (_) => const SearchScreen();
  static WidgetBuilder downloads = (_) => const DownloadsScreen();

  /// Bibliotecas do upstream (1.5.0: no menu do usuário).
  static WidgetBuilder libraries = (context) => PlatformDetector.isMobile(context) ? const HeisucaLibraryScreen() : const LibrariesScreen();
  static Route<void> Function() settings = () => MaterialPageRoute<void>(builder: (_) => const HeisucaSettingsScreen());

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cgflixTopBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                showCgflixUserMenu(context);
              },
              child: const HeisucaLogo(height: 30),
            ),
            const Spacer(),
            if (showActions)
              _RoundIconButton(
                key: const ValueKey('cgflix-top-search'),
                icon: Symbols.search_rounded,
                label: 'Buscar',
                onPressed: () => cgflixOpenSearch(context),
              ),
          ],
        ),
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
        label: 'Menu do Heisuca: perfil, Baixados, Configurações e Sair',
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
              child: Center(child: HeisucaLogo(height: 32, apenasSelo: true)),
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
