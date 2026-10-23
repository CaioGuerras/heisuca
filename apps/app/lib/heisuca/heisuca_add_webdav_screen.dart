import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'heisuca_theme.dart';

/// Diagnóstico WebDAV: ainda não adiciona uma fonte ao catálogo.
class HeisucaAddWebDavScreen extends StatefulWidget {
  const HeisucaAddWebDavScreen({super.key});

  @override
  State<HeisucaAddWebDavScreen> createState() => _HeisucaAddWebDavScreenState();
}

class _HeisucaAddWebDavScreenState extends State<HeisucaAddWebDavScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _pathController = TextEditingController(text: '/');
  bool _conectando = false;
  bool _verSenha = false;

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _conectar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _conectando = true);

    final rawBase = _urlController.text.trim();
    final rawPath = _pathController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text;

    try {
      final baseUri = Uri.parse(rawBase.contains('://') ? rawBase : 'https://$rawBase');
      final targetUri = baseUri.resolve(rawPath.isEmpty ? '/' : rawPath);

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      try {
        final req = await client.openUrl('PROPFIND', targetUri);
        req.headers.set('Depth', '1');
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/xml; charset=utf-8');
        if (user.isNotEmpty) {
          final auth = base64Encode(utf8.encode('$user:$pass'));
          req.headers.set(HttpHeaders.authorizationHeader, 'Basic $auth');
        }
        final resp = await req.close();
        final status = resp.statusCode;
        await resp.drain<void>();
        if (status != 207) {
          throw HttpException('Servidor respondeu HTTP $status no PROPFIND');
        }
      } finally {
        client.close();
      }

      if (!mounted) return;
      setState(() => _conectando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Servidor WebDAV respondeu ao teste. A biblioteca ainda não foi adicionada; esta versão não possui catálogo WebDAV.'),
          backgroundColor: HeisucaTheme.roxoPrimaria,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _conectando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao conectar ao WebDAV: $e'),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testar WebDAV', style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acesso a Nuvens e Seedboxes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'Teste o acesso ao seu servidor. Adicionar arquivos à biblioteca e reproduzir por WebDAV ainda não está disponível.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 28),
                _CampoTexto(
                  controller: _urlController,
                  label: 'Endereço do Servidor WebDAV',
                  hint: 'https://dav.exemplo.com ou http://IP:porta',
                  icon: Icons.link_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Digite o endereço do servidor' : null,
                ),
                const SizedBox(height: 14),
                _CampoTexto(
                  controller: _userController,
                  label: 'Usuário (opcional)',
                  hint: 'Deixe vazio se não houver autenticação',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                _CampoTexto(
                  controller: _passController,
                  label: 'Senha (opcional)',
                  hint: 'Senha de acesso',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_verSenha,
                  suffixIcon: IconButton(
                    icon: Icon(_verSenha ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                    onPressed: () => setState(() => _verSenha = !_verSenha),
                  ),
                ),
                const SizedBox(height: 14),
                _CampoTexto(
                  controller: _pathController,
                  label: 'Caminho Base (Diretório)',
                  hint: '/ ou /remote.php/dav/files/user/',
                  icon: Icons.folder_open_rounded,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _conectando ? null : _conectar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HeisucaTheme.roxoPrimaria,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HeisucaTheme.raioInput),
                      ),
                      elevation: 0,
                    ),
                    child: _conectando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Testar acesso',
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTitulo,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  const _CampoTexto({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: HeisucaTheme.fonteTitulo,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(
            fontFamily: HeisucaTheme.fonteTexto,
            fontSize: 15,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: HeisucaTheme.roxoSuperficie,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HeisucaTheme.raioInput),
              borderSide: const BorderSide(color: HeisucaTheme.roxoLinha),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HeisucaTheme.raioInput),
              borderSide: const BorderSide(color: HeisucaTheme.roxoLinha),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HeisucaTheme.raioInput),
              borderSide: const BorderSide(color: HeisucaTheme.roxoPrimaria, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

