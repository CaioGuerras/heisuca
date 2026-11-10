import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../focus/focusable_text_field.dart';
import '../../heisuca/heisuca_theme.dart';
import '../../services/updates/update_controller.dart';
import '../../utils/platform_detector.dart';
import 'update_layout.dart';
import 'update_screen.dart';

class UpdateSettingsScreen extends StatefulWidget {
  const UpdateSettingsScreen({super.key, this.controlador});
  final UpdateController? controlador;
  @override
  State<UpdateSettingsScreen> createState() => _UpdateSettingsScreenState();
}

class _UpdateSettingsScreenState extends State<UpdateSettingsScreen> {
  late final UpdateController _c;
  final _codigo = TextEditingController();
  final _beta = FocusNode(debugLabel: 'atualizador-beta');
  final _campo = FocusNode(debugLabel: 'atualizador-codigo');
  final _salvar = FocusNode(debugLabel: 'atualizador-salvar');
  final _verificar = FocusNode(debugLabel: 'atualizador-verificar');
  final _nova = FocusNode(debugLabel: 'atualizador-nova');
  final _voltar = FocusNode(debugLabel: 'atualizador-voltar');
  @override
  void initState() {
    super.initState();
    _c = widget.controlador ?? context.read<UpdateController>();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    await _c.iniciar();
    if (mounted) _codigo.text = _c.codigo;
  }

  @override
  void dispose() {
    _codigo.dispose();
    for (final foco in [_beta, _campo, _salvar, _verificar, _nova, _voltar]) {
      foco.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => UpdateLayout(
      titulo: 'Atualizações',
      children: [
        if (!_c.habilitado)
          const UpdateCard(children: [Text('As atualizações estão indisponíveis nesta instalação.')])
        else ...[
          UpdateCard(
            children: [
              Text('Canal: ${_c.canal}'),
              const SizedBox(height: 8),
              const Text('Versões beta podem ter falhas. Você pode voltar ao canal estável quando quiser.'),
            ],
          ),
          UpdateButton(
            texto: 'Receber versões beta: ${_c.beta ? 'ligado' : 'desligado'}',
            foco: _beta,
            autofocus: true,
            abaixo: _campo.requestFocus,
            onPressed: _c.ocupado ? null : () => unawaited(_c.definirBeta(!_c.beta)),
          ),
          UpdateCard(
            children: [
              const Text('Código do canal de teste'),
              const SizedBox(height: 12),
              FocusableTextField(
                key: const ValueKey('atualizador-codigo'),
                controller: _codigo,
                focusNode: _campo,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [LengthLimitingTextInputFormatter(256)],
                textInputAction: TextInputAction.done,
                style: TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: PlatformDetector.isTV() ? 22 : 17),
                decoration: const InputDecoration(hintText: 'Digite ou cole o código', border: OutlineInputBorder()),
                onNavigateUp: _beta.requestFocus,
                onNavigateDown: _salvar.requestFocus,
                onSubmitted: (_) => _salvar.requestFocus(),
              ),
              const SizedBox(height: 12),
              UpdateButton(
                texto: 'Salvar código',
                foco: _salvar,
                acima: _campo.requestFocus,
                abaixo: _verificar.requestFocus,
                onPressed: _c.ocupado ? null : () => unawaited(_c.definirCodigo(_codigo.text)),
              ),
              if (_c.codigo.isNotEmpty) const Text('Remova o código para voltar ao canal público.'),
            ],
          ),
          UpdateButton(
            texto: _c.verificando ? 'Verificando…' : 'Verificar agora',
            foco: _verificar,
            acima: _salvar.requestFocus,
            abaixo: _c.oferta != null ? _nova.requestFocus : _voltar.requestFocus,
            onPressed: _c.ocupado ? null : () => unawaited(_c.verificar(manual: true)),
          ),
          if (_c.oferta != null)
            UpdateButton(
              texto: 'Ver nova versão',
              foco: _nova,
              acima: _verificar.requestFocus,
              abaixo: _voltar.requestFocus,
              primario: true,
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateScreen(controlador: _c))),
            ),
        ],
        if (_c.mensagem != null) UpdateCard(children: [Semantics(liveRegion: true, child: Text(_c.mensagem!))]),
        UpdateButton(
          texto: 'Voltar',
          foco: _voltar,
          autofocus: !_c.habilitado,
          acima: _c.oferta != null ? _nova.requestFocus : _verificar.requestFocus,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    ),
  );
}
