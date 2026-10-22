import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
import 'heisuca_add_smb_screen.dart';
import 'heisuca_add_webdav_screen.dart';
import 'heisuca_design_system.dart';
import 'heisuca_logo.dart';
import 'heisuca_theme.dart';

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
    if (serverUrl.isEmpty) serverUrl = widget.initialServerUrl;
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'https://$serverUrl';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140F22),
      barrierColor: Colors.black.withOpacity(0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (ctx) => _HeisucaQuickConnectModal(serverUrl: serverUrl),
    );
  }

  void _showSourcesBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140F22),
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
                      color: const Color(0xFF382C52),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Adicionar Fontes e Servidores',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF4F1FA),
                  ),
                ),
                const SizedBox(height: 6.0),
                const Text(
                  'Conecte suas contas de streaming, pastas locais ou outros servidores.',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 14.0,
                    color: Color(0xFFA99FBB),
                  ),
                ),
                const SizedBox(height: 20.0),
                _SourceTile(
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
                  icon: Icons.dns_rounded,
                  title: 'Outro Servidor Jellyfin / Emby',
                  subtitle: 'Conectar a uma URL personalizada de servidor de mídia',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _serverController.text = '';
                    });
                  },
                ),
                const SizedBox(height: 12.0),
                _SourceTile(
                  icon: Icons.folder_shared_rounded,
                  title: 'Pasta de Rede Local (SMB / Samba)',
                  subtitle: 'Acesse pastas compartilhadas no seu roteador, PC ou NAS',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HeisucaAddSmbScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12.0),
                _SourceTile(
                  icon: Icons.cloud_queue_rounded,
                  title: 'Servidor WebDAV',
                  subtitle: 'Streaming direto de nuvens privadas compatíveis',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HeisucaAddWebDavScreen()),
                    );
                  },
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
    const bg = Color(0xFF0E0B16);
    const surf = Color(0xFF181324);
    const line = Color(0xFF2A203D);
    const accent = Color(0xFF9D74FF);
    const text = Color(0xFFF4F1FA);
    const text2 = Color(0xFFA99FBB);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const HeisucaSpringPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24.0),

              // 1. Marca Heisuca no Topo com botão discreto de Conexão Rápida no canto superior direito (Foto 286)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 44.0), // Equilíbrio óptico com o ícone da direita
                  const Expanded(
                    child: Center(
                      child: HeisucaLogo(height: 48, comSlogan: true),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_2_rounded, color: accent, size: 26.0),
                    tooltip: 'Conexão Rápida',
                    onPressed: _showQuickConnectModal,
                  ),
                ],
              ),

              const SizedBox(height: 36.0),

              // 2. Campo: Servidor
              const _InputLabel(label: 'SERVIDOR'),
              const SizedBox(height: 8.0),
              _GlassTextField(
                controller: _serverController,
                prefixIcon: Icons.dns_outlined,
                hintText: 'https://seuservidor.com',
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16.0),

              // 4. Campo: Usuário
              const _InputLabel(label: 'USUÁRIO'),
              const SizedBox(height: 8.0),
              _GlassTextField(
                controller: _userController,
                prefixIcon: Icons.person_outline_rounded,
                hintText: 'Nome de usuário',
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16.0),

              // 5. Campo: Senha
              const _InputLabel(label: 'SENHA'),
              const SizedBox(height: 8.0),
              _GlassTextField(
                controller: _passwordController,
                prefixIcon: Icons.lock_outline_rounded,
                hintText: '••••••••',
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
                    color: const Color(0xFF3B1219),
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: const Color(0xFFE53935).withOpacity(0.5), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 20.0),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: HeisucaTheme.fonteTexto,
                            fontSize: 13.5,
                            color: Color(0xFFFFCDD2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],

              // 6. Botão Primário: Conectar ao Servidor
              HeisucaSpringPressable(
                onTap: _isLoading ? null : _signInDirect,
                child: Container(
                  height: 56.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [const Color(0xFF4C3078), const Color(0xFF5B3E96)]
                          : [const Color(0xFF7444E0), const Color(0xFF9D74FF)],
                    ),
                    borderRadius: BorderRadius.circular(28.0),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: accent.withOpacity(0.35),
                              blurRadius: 20.0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22.0,
                              height: 22.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12.0),
                            Text(
                              'Conectando ao Servidor...',
                              style: TextStyle(
                                fontFamily: HeisucaTheme.fonteTitulo,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Conectar ao Servidor',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTitulo,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24.0),

              // 7. Botão Discreto: + Outros servidores e pastas locais
              Center(
                child: TextButton.icon(
                  onPressed: _showSourcesBottomSheet,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18.0, color: text2),
                  label: const Text(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: HeisucaTheme.fonteTexto,
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Color(0xFF9D74FF),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.prefixIcon,
    required this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final IconData prefixIcon;
  final String hintText;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181324),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFF2A203D), width: 1.4),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        textInputAction: onSubmitted != null ? TextInputAction.done : TextInputAction.next,
        style: const TextStyle(
          fontFamily: HeisucaTheme.fonteTexto,
          fontSize: 15.5,
          color: Color(0xFFF4F1FA),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFFA99FBB), size: 22.0),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF5A526E),
            fontSize: 15.0,
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HeisucaSpringPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1730),
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: const Color(0xFF2E2248), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: const Color(0xFF9D74FF).withOpacity(0.16),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(icon, color: const Color(0xFF9D74FF), size: 24.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: HeisucaTheme.fonteTitulo,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF4F1FA),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 12.5,
                      color: Color(0xFFA99FBB),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFA99FBB)),
          ],
        ),
      ),
    );
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
      final clientVersion = await resolveJellyfinClientVersion();
      final identity = await DeviceIdentityService.resolve();
      final auth = JellyfinConnectionAuthService(
        clientName: jellyfinClientName(identity),
        clientVersion: clientVersion,
        deviceName: jellyfinDeviceName(identity),
        dialect: MediaBrowserDialect.jellyfin,
      );

      final candidates = JellyfinEndpointDiscovery.buildUserInputCandidates(
        [widget.serverUrl],
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
    } catch (e) {
      if (!mounted || _isCancelled) return;
      setState(() => _error = 'Não foi possível iniciar o Quick Connect.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF9D74FF);
    const text = Color(0xFFF4F1FA);
    const text2 = Color(0xFFA99FBB);

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
                color: const Color(0xFF382C52),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Conexão Rápida Heisuca',
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTitulo,
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
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
                style: const TextStyle(color: Color(0xFFFF5252), fontSize: 14.0, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
            ] else if (_code == null) ...[
              const Center(
                child: SizedBox(
                  width: 32.0,
                  height: 32.0,
                  child: CircularProgressIndicator(color: accent, strokeWidth: 2.8),
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Gerando código de conexão...',
                style: TextStyle(color: text2, fontSize: 13.5),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1730),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
                ),
                child: Text(
                  _code!,
                  style: const TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 34.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6.0,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '1. No seu computador ou celular, abra o Jellyfin no navegador\n2. Vá em Configurações > Conexão Rápida\n3. Digite o código acima para autorizar',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFFC7C0D6),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14.0,
                    height: 14.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: accent),
                  ),
                  SizedBox(width: 10.0),
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
                  color: const Color(0xFF221A33),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFF382C52), width: 1.2),
                ),
                child: const Text(
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
