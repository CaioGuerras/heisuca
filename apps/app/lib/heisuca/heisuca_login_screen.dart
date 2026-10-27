import '../cgflix/cgflix_login_checks.dart';
import 'heisuca_motion.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../cgflix/cgflix_palette.dart';
import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../exceptions/media_server_exceptions.dart';
import '../media/media_browser_dialect.dart';
import '../navigation/profile_session_screen.dart';
import '../profiles/active_profile_binder.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile.dart';
import '../profiles/profile_connection.dart';
import '../screens/settings/add_jellyfin_screen.dart';
import '../screens/settings/connection_persistence.dart';
import '../services/jellyfin_auth_header.dart';
import '../services/jellyfin_auth_service.dart';
import '../services/jellyfin_endpoint_discovery.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/device_identity.dart';
import '../utils/navigation_transitions.dart';
import 'heisuca_add_plex_screen.dart';
import 'heisuca_design_system.dart';
import 'heisuca_logo.dart';
import 'heisuca_theme.dart';
import 'widgets/heisuca_server_status.dart';

/// Tela de Conexão e Login Heisuca Flagship 2026.
/// Conexão Rápida (Quick Connect), 3 campos limpos, autenticação direta no Jellyfin
/// e acesso discreto a outras fontes e servidores locais/nuvem.
class HeisucaLoginScreen extends StatefulWidget {
  const HeisucaLoginScreen({
    super.key,
    this.onLoginSuccess,
    this.initialServerUrl = '',
  });

  final VoidCallback? onLoginSuccess;
  final String initialServerUrl;

  @override
  State<HeisucaLoginScreen> createState() => _HeisucaLoginScreenState();
}

class _HeisucaLoginScreenState extends State<HeisucaLoginScreen> {
  late final TextEditingController _serverController;
  late final TextEditingController _userController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: widget.initialServerUrl);
    _userController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInDirect() async {
    if (_isLoading) return;

    final rawUrl = _serverController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() => _errorMessage = 'Por favor, informe o endereço do servidor.');
      HapticFeedback.vibrate();
      return;
    }

    var serverUrl = rawUrl;
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'https://$serverUrl';
    }

    if (cgflixIsCleartextRefused(serverUrl)) {
      setState(() => _errorMessage = cgflixHttpsRequiredMessage);
      HapticFeedback.vibrate();
      return;
    }

    final username = _userController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Por favor, informe o seu nome de usuário.');
      HapticFeedback.vibrate();
      return;
    }

    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Resolver versão e identidade do aparelho
      final clientVersion = await resolveJellyfinClientVersion();
      final identity = await DeviceIdentityService.resolve();
      final auth = JellyfinConnectionAuthService(
        clientName: jellyfinClientName(identity),
        clientVersion: clientVersion,
        deviceName: jellyfinDeviceName(identity),
        dialect: MediaBrowserDialect.jellyfin,
      );

      // 2. Descobrir e validar endpoint
      final candidates = JellyfinEndpointDiscovery.buildUserInputCandidates(
        [serverUrl],
        dialect: MediaBrowserDialect.jellyfin,
      );
      if (candidates.probeBaseUrls.isEmpty) {
        throw const MediaServerUrlException('Endereço do servidor inválido.');
      }

      final endpoint = await auth.raceEndpoints(
        candidates.probeBaseUrls,
        baseUrlsToPersist: candidates.explicitBaseUrls,
        baseUrlValidationGroups: candidates.validationBaseUrlGroups,
      );

      // 3. Autenticação direta no servidor
      final storage = await StorageService.getInstance();
      final deviceId = await storage.getOrCreateClientIdentifier();

      final connection = await auth.authenticateByName(
        baseUrl: endpoint.activeBaseUrl,
        baseUrls: endpoint.baseUrls,
        username: username,
        password: password,
        deviceId: deviceId,
        serverInfo: endpoint.serverInfo,
      );

      if (!mounted) return;

      // 4. Vincular ou criar perfil ativo e persistir conexão
      final activeProvider = context.read<ActiveProfileProvider>();
      await activeProvider.initialize();

      Profile? boundProfile = activeProvider.active;
      Profile? firstRunProfile;
      if (boundProfile == null && activeProvider.profiles.isEmpty) {
        final now = DateTime.now();
        firstRunProfile = Profile.local(
          id: 'local-${const Uuid().v4()}',
          displayName: connection.userName.isNotEmpty ? connection.userName : connection.serverName,
          sortOrder: now.millisecondsSinceEpoch,
          createdAt: now,
        );
        boundProfile = firstRunProfile;
      } else if (boundProfile == null) {
        boundProfile = activeProvider.profiles.first;
      }

      await persistAndBindConnection(
        context: context,
        connection: connection,
        bindToProfile: ProfileConnection(
          profileId: boundProfile.id,
          connectionId: connection.id,
          userToken: connection.accessToken,
          userIdentifier: connection.userId,
          tokenAcquiredAt: DateTime.now(),
        ),
        firstRunProfile: firstRunProfile,
      );

      if (boundProfile.id == activeProvider.activeId) {
        await context.read<ActiveProfileBinder>().rebindIfActive(boundProfile.id);
      }

      if (!mounted) return;

      // 5. Transição suave direto para o app sem telas legadas
      HapticFeedback.mediumImpact();
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        await Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(const ProfileSessionScreen(initialPromptHandled: true)),
          (route) => false,
        );
      }
    } catch (e, st) {
      appLogger.e('HeisucaLoginScreen login failed', error: e, stackTrace: st);
      if (!mounted) return;
      String message = 'Não foi possível conectar ao servidor.';
      if (e is MediaServerAuthException) {
        message = e.display ?? 'Usuário ou senha incorretos.';
      } else if (e is MediaServerUrlException) {
        message = e.display ?? 'Servidor não encontrado. Verifique o endereço digitado.';
      } else {
        message = 'Erro ao conectar: ${e.toString().replaceAll('Exception:', '').trim()}';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
      HapticFeedback.vibrate();
    }
  }

  void _showQuickConnectModal() {
    HapticFeedback.lightImpact();
    var serverUrl = _serverController.text.trim();
    if (serverUrl.isEmpty || serverUrl == 'https://') serverUrl = widget.initialServerUrl.trim();
    // Player neutro (Caio, 21/10; regra do fork): nenhum servidor embutido. Sem endereço, pede.
    if (serverUrl.isEmpty || serverUrl == 'https://') {
      setState(() => _errorMessage = 'Digite o endereço do servidor para usar a conexão rápida.');
      return;
    }
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'https://$serverUrl';
    }

    if (cgflixIsCleartextRefused(serverUrl)) {
      setState(() => _errorMessage = cgflixHttpsRequiredMessage);
      return;
    }

    final palette = context.cgflix;

    showModalBottomSheet<void>(
      sheetAnimationStyle: HeisucaMotion.sheetStyle(context), context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (ctx) => _HeisucaQuickConnectModal(serverUrl: serverUrl),
    );
  }

  void _showSourcesBottomSheet() {
    HapticFeedback.lightImpact();
    final palette = context.cgflix;

    final sheetBg = palette.surface;
    final handleColor = palette.divider;
    final titleColor = palette.text;
    final subtitleColor = palette.textOn(palette.surface, preferred: palette.textMuted);

    showModalBottomSheet<void>(
      sheetAnimationStyle: HeisucaMotion.sheetStyle(context), context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      barrierColor: Colors.black.withOpacity(0.65),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48.0,
                    height: 5.0,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Adicionar Fontes e Servidores',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Conecte suas contas de streaming, pastas locais ou outros servidores.',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 14.0,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 20.0),
                _SourceTile(
                  brandColor: const Color(0xFFE5A00D), // Plex Gold
                  icon: Icons.movie_filter_rounded,
                  title: 'Conta Plex',
                  subtitle: 'Acesse servidores locais ou compartilhados via Plex PIN ou QR Code',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HeisucaAddPlexScreen(
                          onLoginSuccess: widget.onLoginSuccess,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12.0),
                _SourceTile(
                  brandColor: const Color(0xFFAA5CC3), // Jellyfin Purple
                  icon: Icons.dns_rounded,
                  title: 'Servidor Jellyfin',
                  subtitle: 'Streaming direto de alta fidelidade via Jellyfin Server',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _serverController.text = '';
                    });
                  },
                ),
                const SizedBox(height: 12.0),
                _SourceTile(
                  brandColor: const Color(0xFF52B54B), // Emby Green
                  icon: Icons.play_circle_filled_rounded,
                  title: 'Servidor Emby',
                  subtitle: 'Conectar a uma biblioteca ou servidor de mídia Emby',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _serverController.text = '';
                    });
                  },
                ),
                const SizedBox(height: 12.0),
                _SourceTile(
                  brandColor: const Color(0xFF3B82F6), // SMB Blue
                  icon: Icons.folder_shared_rounded,
                  title: 'Pasta de Rede Local (SMB / Samba)',
                  subtitle: 'Em breve · ainda não reproduz por aqui',
                  onTap: null,
                ),
                const SizedBox(height: 12.0),
                _SourceTile(
                  brandColor: const Color(0xFF0EA5E9), // WebDAV Sky Blue
                  icon: Icons.cloud_queue_rounded,
                  title: 'Servidor WebDAV',
                  subtitle: 'Em breve · ainda não reproduz por aqui',
                  onTap: null,
                ),
                const SizedBox(height: 12.0),
                _SourceTile(
                  brandColor: const Color(0xFFF97316), // Local Storage Orange
                  icon: Icons.sd_storage_rounded,
                  title: 'Arquivos deste Dispositivo',
                  subtitle: 'Em breve · ainda não reproduz por aqui',
                  onTap: null,
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final bg = palette.background;
    final surf = palette.surface;
    final border = palette.divider;
    final accent = palette.accent;
    final text = palette.text;
    final text2 = palette.textOn(surf, preferred: palette.textMuted);
    final hintColor = text2;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const HeisucaSpringPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Topo: Ícone discreto de Conexão Rápida no canto superior direito
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.qr_code_2_rounded, color: accent, size: 26.0),
                            tooltip: 'Conexão Rápida',
                            onPressed: _showQuickConnectModal,
                          ),
                        ],
                      ),

                      // Bloco Central: Logo Heisuca, Formulário e Botão de Conectar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Center(
                            child: HeisucaLogo(height: 52, comSlogan: true),
                          ),
                          const SizedBox(height: 36.0),

                          // 2. Campo: Servidor
                          _InputLabel(label: 'SERVIDOR', color: accent),
                          const SizedBox(height: 8.0),
                          _GlassTextField(
                            key: const ValueKey('heisuca-login-server'),
                            controller: _serverController,
                            prefixIcon: Icons.dns_outlined,
                            hintText: 'https://seuservidor.com',
                            bgColor: surf,
                            borderColor: border,
                            textColor: text,
                            hintColor: hintColor,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 6.0),
                          HeisucaServerStatus(controller: _serverController),

                          const SizedBox(height: 16.0),

                          // 3. Campo: Usuário
                          _InputLabel(label: 'USUÁRIO', color: accent),
                          const SizedBox(height: 8.0),
                          _GlassTextField(
                            key: const ValueKey('heisuca-login-user'),
                            controller: _userController,
                            prefixIcon: Icons.person_outline_rounded,
                            hintText: 'Nome de usuário',
                            bgColor: surf,
                            borderColor: border,
                            textColor: text,
                            hintColor: hintColor,
                            enabled: !_isLoading,
                          ),

                          const SizedBox(height: 16.0),

                          // 4. Campo: Senha
                          _InputLabel(label: 'SENHA', color: accent),
                          const SizedBox(height: 8.0),
                          _GlassTextField(
                            key: const ValueKey('heisuca-login-password'),
                            controller: _passwordController,
                            prefixIcon: Icons.lock_outline_rounded,
                            hintText: '••••••••',
                            bgColor: surf,
                            borderColor: border,
                            textColor: text,
                            hintColor: hintColor,
                            obscureText: _obscurePassword,
                            enabled: !_isLoading,
                            onSubmitted: (_) => _signInDirect(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: text2,
                                size: 20.0,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),

                          const SizedBox(height: 20.0),

                          // Banner de Erro Elegante em Carmim
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.error,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 20.0),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        fontFamily: HeisucaTheme.fonteTexto,
                                        fontSize: 13.5,
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],

                          // 5. Botão Primário: Conectar ao Servidor
                          HeisucaSpringPressable(
                            onTap: _isLoading ? null : _signInDirect,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 56),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: palette.action,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 22, height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2.4,
                                            color: palette.onAction)),
                                        const SizedBox(width: 12),
                                        Flexible(child: Text('Iniciando sessão...',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontFamily: HeisucaTheme.fonteTexto,
                                            fontSize: 16, fontWeight: FontWeight.w600,
                                            color: palette.onAction))),
                                      ],
                                    )
                                  : Text('Iniciar sessão', textAlign: TextAlign.center,
                                      style: TextStyle(fontFamily: HeisucaTheme.fonteTexto,
                                        fontSize: 16.5, fontWeight: FontWeight.w700,
                                        color: palette.onAction)),
                            ),
                          ),
                        ],
                      ),

                      // Rodapé: + Outros servidores e pastas locais
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _showSourcesBottomSheet,
                            icon: Icon(Icons.add_circle_outline_rounded, size: 18.0, color: text2),
                            label: Text(
                              'Outros servidores e pastas locais',
                              style: TextStyle(
                                fontFamily: HeisucaTheme.fonteTexto,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                                color: text2,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: text2,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: HeisucaTheme.fonteTexto,
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    super.key,
    required this.controller,
    required this.prefixIcon,
    required this.hintText,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.hintColor,
    this.obscureText = false,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final IconData prefixIcon;
  final String hintText;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color hintColor;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(HeisucaTheme.raioInput),
      borderSide: BorderSide(color: borderColor));
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      textInputAction: onSubmitted != null ? TextInputAction.done : TextInputAction.next,
      style: TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 15.5, color: textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: bgColor,
        border: outline,
        enabledBorder: outline,
        disabledBorder: outline,
        focusedBorder: outline.copyWith(borderSide: BorderSide(color: context.cgflix.focusRing, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Icon(prefixIcon, color: hintColor, size: 22),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor, fontSize: 15),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.brandColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final Color brandColor;
  final IconData icon;
  final String title;
  final String subtitle;
  /// Nulo = ainda não implementado: aparece esmaecido com "Em breve" (nada de tela que finge conectar).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;

    return Opacity(opacity: onTap == null ? .45 : 1, child: HeisucaSpringPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: palette.divider,
            width: 1.2,
          ),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(icon, color: brandColor, size: 24.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTitulo,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 12.5,
                      color: palette.textOn(palette.surface, preferred: palette.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.textOn(palette.surface, preferred: palette.textMuted),
            ),
          ],
        ),
      ),
    ));
  }
}

/// Modal do Quick Connect: inicia código e escuta aprovação na web
class _HeisucaQuickConnectModal extends StatefulWidget {
  const _HeisucaQuickConnectModal({required this.serverUrl});
  final String serverUrl;

  @override
  State<_HeisucaQuickConnectModal> createState() => _HeisucaQuickConnectModalState();
}

class _HeisucaQuickConnectModalState extends State<_HeisucaQuickConnectModal> {
  String? _code;
  String? _error;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_startFlow());
  }

  @override
  void dispose() {
    _isCancelled = true;
    super.dispose();
  }

  Future<void> _startFlow() async {
    try {
      var targetUrl = widget.serverUrl.trim();
      if (targetUrl.isEmpty || targetUrl == 'https://') {
        throw StateError('Sem endereço do servidor');
      }
      if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
        targetUrl = 'https://$targetUrl';
      }
      if (cgflixIsCleartextRefused(targetUrl)) {
        throw const MediaServerUrlException(cgflixHttpsRequiredMessage);
      }

      final clientVersion = await resolveJellyfinClientVersion();
      final identity = await DeviceIdentityService.resolve();
      final auth = JellyfinConnectionAuthService(
        clientName: jellyfinClientName(identity),
        clientVersion: clientVersion,
        deviceName: jellyfinDeviceName(identity),
        dialect: MediaBrowserDialect.jellyfin,
      );

      final candidates = JellyfinEndpointDiscovery.buildUserInputCandidates(
        [targetUrl],
        dialect: MediaBrowserDialect.jellyfin,
      );
      if (candidates.probeBaseUrls.isEmpty) {
        throw const MediaServerUrlException('Endereço do servidor inválido.');
      }

      final endpoint = await auth.raceEndpoints(
        candidates.probeBaseUrls,
        baseUrlsToPersist: candidates.explicitBaseUrls,
        baseUrlValidationGroups: candidates.validationBaseUrlGroups,
      );

      final storage = await StorageService.getInstance();
      final deviceId = await storage.getOrCreateClientIdentifier();

      final init = await auth.initiateQuickConnect(
        baseUrl: endpoint.activeBaseUrl,
        deviceId: deviceId,
      );

      if (_isCancelled || !mounted) return;
      setState(() => _code = init.code);

      final connection = await auth.authenticateByQuickConnect(
        baseUrl: endpoint.activeBaseUrl,
        baseUrls: endpoint.baseUrls,
        secret: init.secret,
        deviceId: deviceId,
        serverInfo: endpoint.serverInfo,
        shouldCancel: () => _isCancelled,
      );

      if (_isCancelled || !mounted) return;
      if (connection == null) {
        setState(() => _error = 'O código expirou. Feche e tente novamente.');
        return;
      }

      final activeProvider = context.read<ActiveProfileProvider>();
      await activeProvider.initialize();

      Profile? boundProfile = activeProvider.active;
      Profile? firstRunProfile;
      if (boundProfile == null && activeProvider.profiles.isEmpty) {
        final now = DateTime.now();
        firstRunProfile = Profile.local(
          id: 'local-${const Uuid().v4()}',
          displayName: connection.userName.isNotEmpty ? connection.userName : connection.serverName,
          sortOrder: now.millisecondsSinceEpoch,
          createdAt: now,
        );
        boundProfile = firstRunProfile;
      } else if (boundProfile == null) {
        boundProfile = activeProvider.profiles.first;
      }

      await persistAndBindConnection(
        context: context,
        connection: connection,
        bindToProfile: ProfileConnection(
          profileId: boundProfile.id,
          connectionId: connection.id,
          userToken: connection.accessToken,
          userIdentifier: connection.userId,
          tokenAcquiredAt: DateTime.now(),
        ),
        firstRunProfile: firstRunProfile,
      );

      if (boundProfile.id == activeProvider.activeId) {
        await context.read<ActiveProfileBinder>().rebindIfActive(boundProfile.id);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).pushAndRemoveUntil(
        fadeRoute(const ProfileSessionScreen(initialPromptHandled: true)),
        (route) => false,
      );
    } catch (e, st) {
      appLogger.e('Quick Connect falhou', error: e, stackTrace: st);
      if (!mounted || _isCancelled) return;
      setState(() => _error = 'Não foi possível iniciar o Quick Connect.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;

    final accent = palette.accent;
    final text = palette.text;
    final text2 = palette.textOn(palette.surface, preferred: palette.textMuted);
    final cardBg = palette.surface;
    final handleColor = palette.divider;

    final formattedCode = _code != null && _code!.length == 6
        ? '${_code!.substring(0, 3)} ${_code!.substring(3)}'
        : _code;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48.0,
              height: 5.0,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 24.0),
            Text(
              'Conexão Rápida Heisuca',
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTitulo,
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Acesse sua conta sem precisar digitar sua senha.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 14.0,
                color: text2,
              ),
            ),
            const SizedBox(height: 28.0),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(
                  color: palette.textOn(palette.surface, preferred: palette.danger),
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _code = null;
                  });
                  unawaited(_startFlow());
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
              const SizedBox(height: 16.0),
            ] else if (_code == null) ...[
              Center(
                child: SizedBox(
                  width: 32.0,
                  height: 32.0,
                  child: CircularProgressIndicator(color: accent, strokeWidth: 2.8),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Gerando código de conexão...',
                style: TextStyle(color: text2, fontSize: 13.5),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
                ),
                child: Text(
                  formattedCode!,
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 34.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6.0,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '1. No seu computador ou celular, abra o Jellyfin no navegador\n2. Vá em Configurações > Conexão Rápida\n3. Digite o código acima para autorizar',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 13.5,
                    height: 1.5,
                    color: palette.textOn(palette.surface),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14.0,
                    height: 14.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: accent),
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    'Aguardando aprovação...',
                    style: TextStyle(fontSize: 13.0, color: text2),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24.0),
            HeisucaSpringPressable(
              onTap: () {
                _isCancelled = true;
                Navigator.pop(context);
              },
              child: Container(
                height: 48.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.surfaceHigh,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: palette.divider,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: text2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }
}
