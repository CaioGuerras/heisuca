import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../design/componentes/botao.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../focus/focusable_text_field.dart';
import '../../services/updates/update_controller.dart';
import '../../utils/platform_detector.dart';
import 'update_layout.dart';

/// Atualizações, a partir dos ajustes: o estado da versão, a ação principal e de qual canal as versões chegam.
class UpdateSettingsScreen extends StatefulWidget {
  const UpdateSettingsScreen({super.key, this.controlador});
  final UpdateController? controlador;
  @override
  State<UpdateSettingsScreen> createState() => _UpdateSettingsScreenState();
}

class _UpdateSettingsScreenState extends State<UpdateSettingsScreen> {
  late final UpdateController _c;
  final _codigo = TextEditingController();
  final _acao = FocusNode(debugLabel: 'atualizador-acao');
  final _estavel = FocusNode(debugLabel: 'atualizador-estavel');
  final _beta = FocusNode(debugLabel: 'atualizador-beta');
  final _comCodigo = FocusNode(debugLabel: 'atualizador-com-codigo');
  final _campo = FocusNode(debugLabel: 'atualizador-codigo');
  final _salvar = FocusNode(debugLabel: 'atualizador-salvar');
  final _voltar = FocusNode(debugLabel: 'atualizador-voltar');

  /// A pessoa escolheu "Com código" e ainda não salvou um: o campo fica aberto.
  bool _digitando = false;

  @override
  void initState() {
    super.initState();
    _c = widget.controlador ?? context.read<UpdateController>();
    unawaited(_c.iniciar());
  }

  @override
  void dispose() {
    _codigo.dispose();
    for (final foco in [_acao, _estavel, _beta, _comCodigo, _campo, _salvar, _voltar]) {
      foco.dispose();
    }
    super.dispose();
  }

  Future<void> _salvarCodigo() async {
    await _c.definirCodigo(_codigo.text);
    if (!mounted || _c.codigo.isEmpty) return;
    // Salvo: o código não fica na tela.
    _codigo.clear();
    setState(() => _digitando = false);
    _focarNoCanal();
  }

  Future<void> _removerCodigo() async {
    await _c.definirCodigo('');
    if (!mounted) return;
    setState(() => _digitando = false);
    _focarNoCanal();
  }

  /// O botão que estava com o foco some depois de salvar ou remover o código. Na TV o foco iria para lugar nenhum
  /// e o controle remoto ficaria sem rumo: ele volta para "Com código".
  void _focarNoCanal() {
    if (!PlatformDetector.isTV()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _comCodigo.requestFocus();
    });
  }

  /// Estável ou Beta: fecha o campo do código, se estiver aberto, e muda o canal se for outro.
  void _escolher({required bool beta}) {
    setState(() => _digitando = false);
    if (_c.beta != beta) unawaited(_c.definirBeta(beta));
  }

  List<Widget> _canal(TemaHeisuca tema) {
    final comCodigo = _c.codigo.isNotEmpty;
    final livre = !_c.ocupado;
    return [
      UpdateChoice(
        key: const ValueKey('atualizador-canal-estavel'),
        titulo: 'Estável',
        texto: 'Versões já aprovadas.',
        escolhida: !comCodigo && !_digitando && !_c.beta,
        foco: _estavel,
        aoTocar: livre && !comCodigo ? () => _escolher(beta: false) : null,
      ),
      UpdateChoice(
        key: const ValueKey('atualizador-canal-beta'),
        titulo: 'Beta',
        texto: 'Chega antes; pode ter falhas.',
        escolhida: !comCodigo && !_digitando && _c.beta,
        foco: _beta,
        aoTocar: livre && !comCodigo ? () => _escolher(beta: true) : null,
      ),
      UpdateChoice(
        key: const ValueKey('atualizador-canal-codigo'),
        titulo: 'Com código',
        texto: comCodigo ? 'Código salvo neste aparelho.' : 'Para quem recebeu um código de teste.',
        // Com o campo aberto, a marca fica aqui; tocar de novo fecha o campo sem mudar nada.
        escolhida: comCodigo || _digitando,
        foco: _comCodigo,
        aoTocar: livre && !comCodigo ? () => setState(() => _digitando = !_digitando) : null,
      ),
      if (comCodigo) ...[
        const SizedBox(height: Forma.espaco3),
        Text('Para escolher Estável ou Beta, remova o código.', style: Tipo.pequeno(tema)),
        const SizedBox(height: Forma.espaco3),
        Botao(
          rotulo: 'Remover código',
          tipo: TipoDeBotao.secundario,
          expandido: true,
          foco: _salvar,
          aoTocar: livre ? () => unawaited(_removerCodigo()) : null,
        ),
      ] else if (_digitando) ...[
        const SizedBox(height: Forma.espaco3),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: tema.superficie2,
            shape: Forma.superelipse(
              Forma.raioMedio,
              lado: BorderSide(color: _campo.hasFocus ? tema.foco : tema.borda),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Forma.espaco3),
            child: FocusableTextField(
              key: const ValueKey('atualizador-codigo'),
              controller: _codigo,
              focusNode: _campo,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [LengthLimitingTextInputFormatter(256)],
              textInputAction: TextInputAction.done,
              style: Tipo.texto(tema),
              decoration: InputDecoration(
                hintText: 'Digite ou cole o código',
                hintStyle: Tipo.texto(tema).copyWith(color: tema.texto2),
                border: InputBorder.none,
              ),
              onNavigateUp: _comCodigo.requestFocus,
              onNavigateDown: _salvar.requestFocus,
              onSubmitted: (_) => _salvar.requestFocus(),
            ),
          ),
        ),
        const SizedBox(height: Forma.espaco3),
        Botao(
          rotulo: 'Salvar código',
          tipo: TipoDeBotao.secundario,
          expandido: true,
          foco: _salvar,
          aoTocar: livre ? () => unawaited(_salvarCodigo()) : null,
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_c, _campo]),
    builder: (context, _) => UpdateLayout(
      titulo: 'Atualizações',
      children: [
        UpdateStatusCard(controlador: _c, foco: _acao),
        if (_c.habilitado)
          Builder(
            builder: (context) =>
                UpdateCard(titulo: 'Versões que você recebe', children: _canal(TemaHeisuca.de(context))),
          ),
        if (PlatformDetector.isTV())
          Botao(
            rotulo: 'Voltar',
            tipo: TipoDeBotao.secundario,
            expandido: true,
            foco: _voltar,
            focoInicial: !_c.habilitado,
            aoTocar: () => unawaited(Navigator.of(context).maybePop()),
          ),
      ],
    ),
  );
}
