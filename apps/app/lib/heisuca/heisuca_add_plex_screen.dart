import '../cgflix/cgflix_palette.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/connection_registry.dart';
import '../connection/plex_account_setup.dart';
import '../navigation/profile_session_screen.dart';
import '../profiles/active_profile_binder.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/plex_home_service.dart';
import '../profiles/profile_connection_registry.dart';
import '../profiles/profile_selection_policy.dart';
import '../providers/account_preferences_controller.dart';
import '../screens/auth/plex_pin_auth_flow.dart';
import '../screens/auth_screen.dart';
import '../screens/profile/profile_switch_screen.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/navigation_transitions.dart';
import 'heisuca_theme.dart';

/// Tela de conexão com servidores Plex via PIN / QR Code do Heisuca.
class HeisucaAddPlexScreen extends StatefulWidget {
  const HeisucaAddPlexScreen({super.key, this.onLoginSuccess});

  final VoidCallback? onLoginSuccess;

  @override
  State<HeisucaAddPlexScreen> createState() => _HeisucaAddPlexScreenState();
}

class _HeisucaAddPlexScreenState extends State<HeisucaAddPlexScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleTokenReceived(String token) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connRegistry = context.read<ConnectionRegistry>();
      final pcRegistry = context.read<ProfileConnectionRegistry>();
      final plexHome = context.read<PlexHomeService>();
      final storage = await StorageService.getInstance();

      final registration = await registerPlexAccountFromToken(
        token: token,
        connections: connRegistry,
        profileConnections: pcRegistry,
        storage: storage,
        plexHome: plexHome,
      );

      final connection = registration.connection;
      if (connection.servers.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Nenhum servidor Plex encontrado para esta conta (${registration.username}).';
        });
        unawaited(HapticFeedback.vibrate());
        return;
      }

      if (!mounted) return;
      final activeProfiles = context.read<ActiveProfileProvider>();
      await activeProfiles.initialize();

      final profile = initialPlexHomeProfileFromCache(plexHome, connection);
      if (profile != null) {
        await activeProfiles.activate(profile);
      } else {
        await activeProfiles.clearActiveProfile();
      }

      if (!mounted) return;
      context.read<ActiveProfileBinder>().start();

      final settings = await SettingsService.getInstance();
      if (!mounted) return;

      final promptHandled = shouldPromptForInitialProfileSelection(
        activeProfile: activeProfiles.active,
        hasProfiles: activeProfiles.profiles.isNotEmpty,
        accountHasHomeUsers: plexHome.current[connection.id]?.isNotEmpty == true,
        requireProfileSelectionOnOpen: activeProfiles.requiresSelectionOnOpen(settings),
      );

      if (promptHandled || activeProfiles.active == null) {
        final selected = await Navigator.of(
          context,
        ).push<bool>(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: true)));
        if (!mounted) return;
        if (selected != true || activeProfiles.active == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      await context.read<AccountPreferencesController>().ensureActiveLoaded();

      if (!mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        await Navigator.of(
          context,
        ).pushAndRemoveUntil(fadeRoute(const ProfileSessionScreen(initialPromptHandled: true)), (route) => false);
      }
    } catch (e, st) {
      appLogger.e('Erro ao autenticar conta Plex', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha ao conectar com o Plex: ${e.toString().replaceAll('Exception:', '').trim()}';
      });
      unawaited(HapticFeedback.vibrate());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cgflix.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Conectar Servidor Plex',
          style: TextStyle(
            fontFamily: HeisucaTheme.fonteTitulo,
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: context.cgflix.text,
          ),
        ),
        iconTheme: IconThemeData(color: context.cgflix.text),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  color: context.cgflix.surface,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: context.cgflix.divider, width: 1.4),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: context.cgflix.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Icon(Icons.movie_filter_rounded, color: context.cgflix.accent, size: 32.0),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Autenticação Plex',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTitulo,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w700,
                        color: context.cgflix.text,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Entre com sua conta do Plex para sincronizar seus servidores, bibliotecas e perfis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 14.0,
                        color: context.cgflix.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    if (_isLoading) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 32.0,
                              height: 32.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                valueColor: AlwaysStoppedAnimation<Color>(context.cgflix.accent),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              'Conectando servidores...',
                              style: TextStyle(
                                fontFamily: HeisucaTheme.fonteTexto,
                                fontSize: 14.0,
                                color: context.cgflix.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      PlexPinAuthFlow(
                        onTokenReceived: _handleTokenReceived,
                        autoStartQrOnTV: false,
                        initialButtonsBuilder: (ctx, startBrowser, startQr, busy) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 50.0,
                                child: ElevatedButton.icon(
                                  onPressed: busy ? null : startBrowser,
                                  icon: const Icon(Icons.open_in_browser_rounded, size: 20.0),
                                  label: const Text(
                                    'Entrar pelo Navegador',
                                    style: TextStyle(
                                      fontFamily: HeisucaTheme.fonteTexto,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.cgflix.accent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              SizedBox(
                                height: 50.0,
                                child: OutlinedButton.icon(
                                  onPressed: busy ? null : startQr,
                                  icon: const Icon(Icons.qr_code_rounded, size: 20.0),
                                  label: const Text(
                                    'Exibir Código QR',
                                    style: TextStyle(
                                      fontFamily: HeisucaTheme.fonteTexto,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.cgflix.text,
                                    side: BorderSide(color: context.cgflix.divider, width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16.0),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: context.cgflix.surfaceHigh,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: context.cgflix.danger.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: context.cgflix.danger, size: 20.0),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontFamily: HeisucaTheme.fonteTexto,
                                  fontSize: 13.0,
                                  color: context.cgflix.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
