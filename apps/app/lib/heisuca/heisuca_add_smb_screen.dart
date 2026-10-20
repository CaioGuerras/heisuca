import 'package:flutter/material.dart';
import 'heisuca_theme.dart';

/// Tela de conexão SMB (Samba / Rede Local) do Heisuca
class HeisucaAddSmbScreen extends StatefulWidget {
  const HeisucaAddSmbScreen({super.key});

  @override
  State<HeisucaAddSmbScreen> createState() => _HeisucaAddSmbScreenState();
}

class _HeisucaAddSmbScreenState extends State<HeisucaAddSmbScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _shareController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _conectando = false;
  bool _verSenha = false;

  @override
  void dispose() {
    _hostController.dispose();
    _shareController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _conectar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _conectando = true);

    // Simulação do handshake SMB v2/v3
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _conectando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compartilhamento SMB conectado com sucesso!'),
        backgroundColor: HeisucaTheme.roxoPrimaria,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar Rede Local (SMB)', style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 18, fontWeight: FontWeight.w600)),
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
                  'Acesso a NAS e Compartilhamentos Windows',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'Conecte seu Synology, QNAP, TrueNAS ou pasta compartilhada do PC Windows na rede local.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 28),
                _CampoTexto(
                  controller: _hostController,
                  label: 'Endereço IP ou Nome do Host',
                  hint: 'Ex: 192.168.1.100 ou MEU-NAS',
                  icon: Icons.computer_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Digite o IP ou nome do computador' : null,
                ),
                const SizedBox(height: 14),
                _CampoTexto(
                  controller: _shareController,
                  label: 'Nome do Compartilhamento (Share)',
                  hint: 'Ex: Filmes, Series ou video',
                  icon: Icons.folder_shared_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Digite o nome do compartilhamento' : null,
                ),
                const SizedBox(height: 14),
                _CampoTexto(
                  controller: _userController,
                  label: 'Usuário (opcional para Guest)',
                  hint: 'guest ou usuário da rede',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                _CampoTexto(
                  controller: _passController,
                  label: 'Senha (opcional)',
                  hint: 'Senha do usuário da rede',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_verSenha,
                  suffixIcon: IconButton(
                    icon: Icon(_verSenha ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                    onPressed: () => setState(() => _verSenha = !_verSenha),
                  ),
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
                            'Conectar e Listar Arquivos',
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
