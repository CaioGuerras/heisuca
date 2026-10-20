// CGFLIX (Minha conta, 1.5.0): foto e senha da própria pessoa no Jellyfin.
// Foto: seletor do sistema → quadrado de 512 px em JPEG → servidor; "Remover foto".
// Senha: atual + nova + confirmar. O servidor derruba as outras sessões e mantém a deste aparelho.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../cgflix_palette.dart';
import 'cgflix_conta.dart';

const _confira = 'Confira a internet e tente de novo.';

Future<void> cgflixAbrirMinhaConta(BuildContext context, CgflixConta conta) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: 'cgflix/minha-conta'),
    builder: (_) => CgflixMinhaContaScreen(conta: conta),
  ),
);

class CgflixMinhaContaScreen extends StatefulWidget {
  const CgflixMinhaContaScreen({super.key, required this.conta});
  final CgflixConta conta;

  @override
  State<CgflixMinhaContaScreen> createState() => _CgflixMinhaContaScreenState();
}

class _CgflixMinhaContaScreenState extends State<CgflixMinhaContaScreen> {
  CgflixPerfil? _perfil;
  bool _carregando = true;
  bool _falhouCarregar = false;
  bool _ocupadoFoto = false;
  bool _ocupadoSenha = false;
  String? _erroSenha;

  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmar = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _falhouCarregar = false;
    });
    try {
      final perfil = await widget.conta.perfil();
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _carregando = false;
      });
    } catch (e) {
      appLogger.w('CGFLIX: Minha conta não carregou', error: e);
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _falhouCarregar = true;
      });
    }
  }

  Future<void> _trocarFoto() async {
    final Uint8List? jpeg;
    try {
      jpeg = await cgflixEscolherFoto();
    } catch (e) {
      appLogger.w('CGFLIX: foto não abriu', error: e);
      if (mounted) showErrorSnackBar(context, 'Não deu para abrir essa imagem. Escolha outra foto.');
      return;
    }
    if (jpeg == null || !mounted) return;
    await _comFoto(() => widget.conta.trocarFoto(jpeg!), ok: 'Foto atualizada.', falha: 'Não deu para trocar a foto.');
  }

  Future<void> _removerFoto() =>
      _comFoto(widget.conta.removerFoto, ok: 'Foto removida.', falha: 'Não deu para remover a foto.');

  Future<void> _comFoto(Future<void> Function() acao, {required String ok, required String falha}) async {
    setState(() => _ocupadoFoto = true);
    try {
      await acao();
      final perfil = await widget.conta.perfil();
      if (!mounted) return;
      setState(() => _perfil = perfil);
      showSuccessSnackBar(context, ok);
    } catch (e) {
      appLogger.w('CGFLIX: foto da conta falhou', error: e);
      if (mounted) showErrorSnackBar(context, '$falha $_confira');
    } finally {
      if (mounted) setState(() => _ocupadoFoto = false);
    }
  }

  Future<void> _salvarSenha() async {
    final atual = _atual.text;
    final nova = _nova.text;
    final validacao = cgflixValidarNovaSenha(atual: atual, nova: nova, confirmar: _confirmar.text);
    if (validacao != null) {
      setState(() => _erroSenha = validacao);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _erroSenha = null;
      _ocupadoSenha = true;
    });
    CgflixSenhaResultado resultado;
    try {
      resultado = await widget.conta.trocarSenha(atual: atual, nova: nova);
    } catch (e) {
      appLogger.w('CGFLIX: troca de senha falhou', error: e);
      resultado = CgflixSenhaResultado.falhou;
    }
    if (!mounted) return;
    setState(() {
      _ocupadoSenha = false;
      switch (resultado) {
        case CgflixSenhaResultado.ok:
          _atual.clear();
          _nova.clear();
          _confirmar.clear();
        case CgflixSenhaResultado.senhaAtualErrada:
          _erroSenha =
              'Senha atual errada. Cuidado: depois de várias tentativas erradas, a conta é bloqueada '
              'e só o administrador desbloqueia.';
        case CgflixSenhaResultado.falhou:
          _erroSenha = 'Não deu para trocar a senha. $_confira';
      }
    });
    if (resultado == CgflixSenhaResultado.ok) {
      showSuccessSnackBar(
        context,
        'Senha trocada. Nos outros aparelhos e no site, entre de novo com a senha nova. Aqui você continua conectado.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: SafeArea(top: false, child: _corpo(context)),
    );
  }

  Widget _corpo(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_falhouCarregar) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(Symbols.cloud_off_rounded, fill: 1, size: 48, color: context.cgflix.textMuted),
              const SizedBox(height: 16),
              const Text('Sem conexão com o servidor agora. $_confira', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
                onPressed: _carregar,
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final perfil = _perfil!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Center(
              child: CgflixAvatarGrande(nome: perfil.nome, fotoUrl: perfil.fotoUrl),
            ),
            const SizedBox(height: 12),
            Text(
              perfil.nome,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('cgflix-conta-trocar-foto'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: _ocupadoFoto ? null : _trocarFoto,
                  icon: _ocupadoFoto
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const AppIcon(Symbols.photo_camera_rounded, fill: 1),
                  label: const Text('Trocar foto'),
                ),
                if (perfil.fotoUrl != null)
                  TextButton.icon(
                    key: const ValueKey('cgflix-conta-remover-foto'),
                    style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: _ocupadoFoto ? null : _removerFoto,
                    icon: const AppIcon(Symbols.delete_rounded, fill: 1),
                    label: const Text('Remover foto'),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Divider(color: context.cgflix.divider),
            const SizedBox(height: 16),
            Text('Trocar senha', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'A senha vale para o app, o site e a TV. Depois da troca, os outros aparelhos pedem para entrar de novo.',
              style: theme.textTheme.bodyMedium?.copyWith(color: context.cgflix.textMuted),
            ),
            const SizedBox(height: 16),
            _CampoSenha(
              key: const ValueKey('cgflix-conta-senha-atual'),
              controller: _atual,
              rotulo: 'Senha atual (vazia se você não tem)',
              autofill: AutofillHints.password,
            ),
            const SizedBox(height: 12),
            _CampoSenha(
              key: const ValueKey('cgflix-conta-senha-nova'),
              controller: _nova,
              rotulo: 'Nova senha',
              autofill: AutofillHints.newPassword,
            ),
            const SizedBox(height: 12),
            _CampoSenha(
              key: const ValueKey('cgflix-conta-senha-confirmar'),
              controller: _confirmar,
              rotulo: 'Confirmar nova senha',
              autofill: AutofillHints.newPassword,
              onSubmitted: (_) => _salvarSenha(),
            ),
            if (_erroSenha != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(_erroSenha!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('cgflix-conta-salvar-senha'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _ocupadoSenha ? null : _salvarSenha,
              child: _ocupadoSenha
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar nova senha'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confere os campos antes de ir ao servidor. Nulo = tudo certo.
String? cgflixValidarNovaSenha({required String atual, required String nova, required String confirmar}) {
  if (nova.isEmpty) return 'Digite a nova senha.';
  if (nova != confirmar) return 'A confirmação não bate com a nova senha.';
  if (nova == atual) return 'A nova senha é igual à atual.';
  return null;
}

class _CampoSenha extends StatefulWidget {
  const _CampoSenha({super.key, required this.controller, required this.rotulo, this.autofill, this.onSubmitted});
  final TextEditingController controller;
  final String rotulo;
  final String? autofill;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<_CampoSenha> {
  bool _visivel = false;

  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.controller,
    obscureText: !_visivel,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: widget.autofill == null ? null : [widget.autofill!],
    textInputAction: widget.onSubmitted == null ? TextInputAction.next : TextInputAction.done,
    onSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      labelText: widget.rotulo,
      suffixIcon: IconButton(
        tooltip: _visivel ? 'Esconder senha' : 'Mostrar senha',
        onPressed: () => setState(() => _visivel = !_visivel),
        icon: AppIcon(_visivel ? Symbols.visibility_off_rounded : Symbols.visibility_rounded, fill: 1),
      ),
    ),
  );
}

/// Foto redonda da pessoa (ou a inicial do nome, sem foto).
class CgflixAvatarGrande extends StatelessWidget {
  const CgflixAvatarGrande({super.key, required this.nome, this.fotoUrl, this.tamanho = 96});
  final String nome;
  final String? fotoUrl;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final inicial = Center(
      child: Text(
        nome.isEmpty ? '?' : nome.characters.first.toUpperCase(),
        style: TextStyle(fontSize: tamanho * 0.42, fontWeight: FontWeight.w700, color: palette.onAction),
      ),
    );
    return Semantics(
      label: fotoUrl == null ? 'Sem foto' : 'Sua foto',
      image: true,
      child: ClipOval(
        child: SizedBox.square(
          dimension: tamanho,
          child: ColoredBox(
            color: palette.action,
            child: fotoUrl == null
                ? inicial
                : Image.network(
                    fotoUrl!,
                    key: ValueKey(fotoUrl),
                    fit: BoxFit.cover,
                    cacheWidth: (tamanho * 3).round(),
                    errorBuilder: (_, _, _) => inicial,
                  ),
          ),
        ),
      ),
    );
  }
}
