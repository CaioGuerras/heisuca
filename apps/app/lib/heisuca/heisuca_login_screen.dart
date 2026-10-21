import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'heisuca_design_system.dart';
import 'heisuca_logo.dart';
import 'heisuca_theme.dart';
import 'heisuca_add_webdav_screen.dart';
import 'heisuca_add_smb_screen.dart';

/// Tela de Conexão e Login Heisuca (Esboço 02 / 02B Aprovado)
/// Conexão Rápida (Quick Connect), 3 campos limpos e acesso discreto a outras fontes e servidores.
class HeisucaLoginScreen extends StatefulWidget {
  const HeisucaLoginScreen({
    super.key,
    this.onLoginSuccess,
    this.initialServerUrl = 'https://cgserver.docaio.com.br',
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

  void _showSourcesBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF140F22),
      barrierColor: Colors.black.withOpacity(0.65),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
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
                  'Conecte suas pastas locais ou outros servidores de mídia.',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 14.0,
                    color: Color(0xFFA99FBB),
                  ),
                ),
                const SizedBox(height: 20.0),
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
                      MaterialPageRoute(builder: (_) => const HeisucaAddWebdavScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12.0),
                _SourceTile(
                  icon: Icons.dns_rounded,
                  title: 'Outro Servidor Jellyfin / Plex',
                  subtitle: 'Adicionar segundo servidor alternativo',
                  onTap: () {
                    Navigator.pop(ctx);
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

              // 1. Marca Heisuca no Topo
              const Center(
                child: HeisucaLogo(height: 48, comSlogan: true),
              ),

              const SizedBox(height: 44.0),

              // 2. Card de Conexão Rápida (Quick Connect)
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: surf,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: line, width: 1.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, color: accent, size: 24.0),
                        ),
                        const SizedBox(width: 14.0),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conexão Rápida',
                                style: TextStyle(
                                  fontFamily: HeisucaTheme.fonteTitulo,
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w700,
                                  color: text,
                                ),
                              ),
                              SizedBox(height: 2.0),
                              Text(
                                'Digite o código de 4 dígitos da TV',
                                style: TextStyle(
                                  fontFamily: HeisucaTheme.fonteTexto,
                                  fontSize: 13.0,
                                  color: text2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    HeisucaSpringPressable(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        height: 46.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF221A33),
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(color: accent.withOpacity(0.4), width: 1.2),
                        ),
                        child: const Text(
                          'Digitar Código de Conexão ›',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTitulo,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32.0),

              // Separador ou "ou acesse com conta"
              const Row(
                children: [
                  Expanded(child: Divider(color: line, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text(
                      'OU ACESSO DIRETO',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: text2,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: line, thickness: 1)),
                ],
              ),

              const SizedBox(height: 28.0),

              // 3. Campo: Servidor
              _InputLabel(label: 'SERVIDOR HEISUCA'),
              const SizedBox(height: 8.0),
              _GlassTextField(
                controller: _serverController,
                prefixIcon: Icons.dns_outlined,
                hintText: 'https://seuservidor.com',
              ),

              const SizedBox(height: 18.0),

              // 4. Campo: Usuário
              _InputLabel(label: 'USUÁRIO'),
              const SizedBox(height: 8.0),
              _GlassTextField(
                controller: _userController,
                prefixIcon: Icons.person_outline_rounded,
                hintText: 'Nome de usuário',
              ),

              const SizedBox(height: 18.0),

              // 5. Campo: Senha
              _InputLabel(label: 'SENHA'),
              const SizedBox(height: 8.0),
              _GlassTextField(
                controller: _passwordController,
                prefixIcon: Icons.lock_outline_rounded,
                hintText: '••••••••',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: text2,
                    size: 20.0,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 32.0),

              // 6. Botão Primário: Conectar
              HeisucaSpringPressable(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onLoginSuccess?.call();
                },
                child: Container(
                  height: 56.0,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7444E0), Color(0xFF9D74FF)],
                    ),
                    borderRadius: BorderRadius.circular(28.0),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: 20.0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
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
    this.suffixIcon,
  });

  final TextEditingController controller;
  final IconData prefixIcon;
  final String hintText;
  final bool obscureText;
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
        obscureText: obscureText,
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
