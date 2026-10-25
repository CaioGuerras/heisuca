import 'dart:ui' as ui;
import '../cgflix/conta/cgflix_conta.dart';
import '../cgflix/conta/cgflix_minha_conta_screen.dart';
import 'package:flutter/material.dart';
import 'heisuca_source_scope.dart';
import 'heisuca_security.dart';
import 'kids/heisuca_kids.dart';
import 'kids/heisuca_kids_identity.dart';
import 'kids/heisuca_kids_flow.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../cgflix/cgflix_navigation.dart';
import '../cgflix/cgflix_palette.dart';
import '../cgflix/you/cgflix_favorites_screen.dart';
import '../i18n/strings.g.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile_avatar.dart';
import '../screens/profile/profile_switch_screen.dart';
import '../screens/profile/profile_teardown.dart';
import '../screens/settings/about_screen.dart';
import '../utils/dialogs.dart';
import 'heisuca_design_system.dart';
import 'heisuca_settings_screen.dart';
import 'heisuca_device_screen.dart';
import 'heisuca_theme.dart';

/// Tela de Perfil e Hub "Você" Flagship do Heisuca (炳素華) — Esboço 03B & 05
/// Inspirada na sofisticação do VidHub e Infuse:
/// - Header de Usuário com Avatar nobre e Status do Servidor em Tempo Real
/// - Cartões de Vidro Translúcido com Cantos Squircle
/// - Baixados & Armazenamento, Favoritos e Bibliotecas
/// - Configurações Nativas Heisuca (com aba Básica e Avançada)
/// - Totalmente limpa: SEM "Apoie o CGFLIX" e sem seletores de tema desalinhados
class HeisucaProfileScreen extends StatelessWidget {
  const HeisucaProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final isLight = palette.isLight;
    final profiles = context.watch<ActiveProfileProvider?>();
    final active = profiles?.active;

    // Heisuca: no modo infantil a tela usa a paleta do perfil (Ichigo/Sorairo) e fica enxuta.
    final kids = heisucaKidsActive(context);
    final kidsRecord = HeisucaKids.instance.forParent(active?.id);
    final bg = kids
        ? palette.background
        : isLight
        ? const Color(0xFFF7F3EC)
        : const Color(0xFF0E0B16);
    final cardBg = kids
        ? palette.surface
        : isLight
        ? Colors.white
        : Colors.white.withOpacity(0.045);
    final cardBorder = kids
        ? palette.divider
        : isLight
        ? const Color(0xFFE2E8F0)
        : Colors.white.withOpacity(0.08);
    final textTitle = kids
        ? palette.onGlass
        : isLight
        ? const Color(0xFF134E4A)
        : const Color(0xFFF4F1FA);
    final textSub = kids
        ? palette.textMuted
        : isLight
        ? const Color(0xFF64748B)
        : const Color(0xFFA99FBB);
    final dividerColor = kids
        ? palette.divider
        : isLight
        ? const Color(0xFFF1F5F9)
        : Colors.white.withOpacity(0.05);

    // Um cartão por assunto, com o título acima e divisores entre os itens.
    List<Widget> secao(String? titulo, List<Widget> itens) => [
      const SliverToBoxAdapter(child: SizedBox(height: 20.0)),
      if (titulo != null) SliverToBoxAdapter(child: _buildSectionHeader(titulo, isLight, textSub)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
              border: Border.all(color: cardBorder, width: 0.8),
            ),
            child: Column(
              children: [
                for (var i = 0; i < itens.length; i++) ...[
                  if (i > 0) Divider(color: dividerColor, height: 1.0, indent: 56.0),
                  itens[i],
                ],
              ],
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const HeisucaSpringPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Topbar com botão voltar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(20.0),
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isLight ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(color: cardBorder, width: 0.8),
                            ),
                            child: Icon(Symbols.arrow_back_rounded, color: textTitle, size: 22.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Text(
                      'Você',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTitulo,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: textTitle,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Header do Usuário Ativo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 20.0),
                child: Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                    border: Border.all(color: cardBorder, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isLight ? 0.04 : 0.25),
                        blurRadius: 18.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      if (active != null)
                        ProfileAvatar(profile: active, size: 58.0, avatarUrl: profiles?.avatarUrlFor(active.id))
                      else
                        Container(
                          width: 58.0,
                          height: 58.0,
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFF047857).withOpacity(0.12)
                                : const Color(0xFF7A40F2).withOpacity(0.20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Symbols.person_rounded,
                            color: isLight ? const Color(0xFF047857) : const Color(0xFFC4B5FD),
                            size: 32.0,
                          ),
                        ),
                      const SizedBox(width: 16.0),
                      // Nome e Chip de Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              active?.displayName ?? 'Usuário',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: HeisucaTheme.fonteTitulo,
                                fontSize: 19.0,
                                fontWeight: FontWeight.w700,
                                color: textTitle,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            const HeisucaCurrentSourceCaption(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Seção 1: Mídia e Armazenamento (VidHub Style)
            SliverToBoxAdapter(child: _buildSectionHeader('Mídia & Biblioteca', isLight, textSub)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                    border: Border.all(color: cardBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      if (!kids) ...[
                        _buildProfileTile(
                          icon: Symbols.download_rounded,
                          title: 'Baixados & Offline',
                          subtitle: 'Gerenciar mídias salvas no dispositivo',
                          textColor: textTitle,
                          subColor: textSub,
                          iconColor: isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            cgflixOpenDownloads(context);
                          },
                        ),
                        Divider(color: dividerColor, height: 1.0, indent: 56.0),
                      ],
                      _buildProfileTile(
                        icon: Symbols.favorite_rounded,
                        iconFill: 1.0,
                        title: 'Favoritos',
                        subtitle: 'Títulos marcados na sua lista pessoal',
                        textColor: textTitle,
                        subColor: textSub,
                        iconColor: const Color(0xFFFF5252),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final source = CgflixFavoritesSource.of(context);
                          if (source != null) {
                            cgflixOpenFavorites(context, source);
                          }
                        },
                      ),
                      Divider(color: dividerColor, height: 1.0, indent: 56.0),
                      _buildProfileTile(
                        icon: Symbols.video_library_rounded,
                        title: 'Todas as Bibliotecas',
                        subtitle: 'Navegar por pastas de Filmes, Séries e Animes',
                        textColor: textTitle,
                        subColor: textSub,
                        iconColor: isLight ? const Color(0xFF059669) : const Color(0xFF34D399),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(name: 'cgflix/bibliotecas'),
                              builder: CgflixPages.libraries,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Caio, 24/10: menu por assunto. Conta, família, segurança e app em cartões separados; sair fica sozinho no fim.
            if (!kids) ...[
              ...secao('Conta', [
                if (CgflixConta.of(context) case final conta?)
                  _buildProfileTile(
                    icon: Symbols.manage_accounts_rounded,
                    title: 'Minha conta: foto e senha',
                    subtitle: 'Na fonte selecionada',
                    textColor: textTitle,
                    subColor: textSub,
                    iconColor: textTitle,
                    onTap: () => cgflixAbrirMinhaConta(context, conta),
                  ),
                const HeisucaSourceTile(),
                _buildProfileTile(
                  icon: Symbols.switch_account_rounded,
                  title: 'Trocar perfil',
                  subtitle: 'Alternar entre usuários salvos',
                  textColor: textTitle,
                  subColor: textSub,
                  iconColor: isLight ? const Color(0xFF047857) : const Color(0xFFE2E8F0),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileSwitchScreen()));
                  },
                ),
              ]),
              ...secao('Família', [
                _buildProfileTile(
                  icon: Symbols.child_care_rounded,
                  title: 'Modo infantil',
                  subtitle: kidsRecord != null
                      ? 'Entrar no perfil ${kidsRecord.name}'
                      : 'Só desenhos e filmes de família, filtrados pelo servidor',
                  textColor: textTitle,
                  subColor: textSub,
                  iconColor: const Color(0xFFE85A6D),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    heisucaEnterKids(context);
                  },
                ),
                if (kidsRecord != null)
                  _buildProfileTile(
                    icon: Symbols.edit_rounded,
                    title: 'Perfil infantil',
                    subtitle: '${kidsRecord.name} · nome, foto, tema, classificação e PIN',
                    textColor: textTitle,
                    subColor: textSub,
                    iconColor: textTitle,
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => HeisucaKidsIdentityScreen(record: kidsRecord))),
                  ),
              ]),
              if (active != null)
                ...secao('Privacidade e segurança', [
                  _buildProfileTile(
                    icon: Symbols.fingerprint_rounded,
                    title: 'Segurança e biometria',
                    subtitle: 'Bloqueio do app e saída infantil',
                    textColor: textTitle,
                    subColor: textSub,
                    iconColor: textTitle,
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => HeisucaSecurityScreen(parentId: active.id))),
                  ),
                ]),
              ...secao('App', [
                _buildProfileTile(
                  icon: Symbols.smartphone_rounded,
                  title: 'Este aparelho',
                  subtitle: 'Desempenho e recursos informados pelo sistema',
                  textColor: textTitle,
                  subColor: textSub,
                  iconColor: textTitle,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const HeisucaDeviceScreen(),
                  )),
                ),
                _buildProfileTile(
                  icon: Symbols.tune_rounded,
                  title: 'Configurações Heisuca',
                  subtitle: 'Reprodução, vídeo, áudio, legendas e fontes',
                  textColor: textTitle,
                  subColor: textSub,
                  iconColor: isLight ? const Color(0xFF047857) : const Color(0xFFC084FC),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HeisucaSettingsScreen()));
                  },
                ),
                _buildProfileTile(
                  icon: Symbols.info_rounded,
                  title: 'Sobre o Heisuca',
                  subtitle: 'Versão, licenças e arquitetura',
                  textColor: textTitle,
                  subColor: textSub,
                  iconColor: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
                  },
                ),
              ]),
              ...secao(null, [
                _buildProfileTile(
                  icon: Symbols.logout_rounded,
                  title: 'Sair da Conta',
                  subtitle: 'Encerrar a sessão neste dispositivo',
                  textColor: const Color(0xFFEF4444),
                  subColor: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  iconColor: const Color(0xFFEF4444),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final confirm = await showConfirmDialog(
                      context,
                      title: t.common.logout,
                      message: t.messages.logoutConfirm,
                      confirmText: t.common.logout,
                      isDestructive: true,
                    );
                    if (confirm && context.mounted) {
                      await logoutAllProfiles(context);
                    }
                  },
                ),
              ]),
            ] else
              ...secao('Modo infantil', [
                _buildProfileTile(
                  icon: Symbols.lock_open_rounded,
                  title: 'Sair do modo infantil',
                  subtitle: 'Pede o PIN do responsável',
                  textColor: textTitle,
                  subColor: textSub,
                  iconColor: palette.accent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    heisucaExitKids(context);
                  },
                ),
              ]),

            // Espaçamento do rodapé
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 40.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isLight, Color subColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: HeisucaTheme.fonteTexto,
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: subColor,
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    double? iconFill,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10.0)),
              child: Icon(icon, color: iconColor, size: 22.0, fill: iconFill),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right_rounded, color: subColor.withOpacity(0.6), size: 20.0),
          ],
        ),
      ),
    );
  }
}
