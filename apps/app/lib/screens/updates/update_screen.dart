import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/updates/update_controller.dart';
import 'update_layout.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key, this.controlador});
  final UpdateController? controlador;
  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  late final UpdateController _c;
  final _acao = FocusNode(debugLabel: 'atualizador-acao');
  final _voltar = FocusNode(debugLabel: 'atualizador-voltar');
  @override
  void initState() {
    super.initState();
    _c = widget.controlador ?? context.read<UpdateController>();
    unawaited(_c.iniciar());
  }

  @override
  void dispose() {
    _c.cancelar();
    _acao.dispose();
    _voltar.dispose();
    super.dispose();
  }

  void _executar() {
    if (_c.baixando) {
      _c.cancelar();
    } else if (_c.pronto) {
      unawaited(_c.instalar());
    } else if (_c.oferta != null) {
      unawaited(_c.baixar());
    } else {
      unawaited(_c.verificar(manual: true));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final oferta = _c.oferta;
      final rotulo = _c.baixando
          ? 'Cancelar'
          : _c.instalando
          ? 'Preparando instalação…'
          : _c.verificando
          ? 'Verificando…'
          : _c.pronto
          ? 'Instalar'
          : oferta != null
          ? 'Baixar'
          : 'Verificar agora';
      return UpdateLayout(
        titulo: 'Atualizações',
        children: [
          UpdateCard(
            children: [
              Text('Versão instalada: ${_c.estado.versao} (${_c.estado.build})'),
              if (oferta != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Nova versão: ${oferta.versao} (${oferta.build})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(oferta.notas),
              ] else ...[
                const SizedBox(height: 12),
                const Text('Quando houver uma versão nova, você poderá baixar por aqui.'),
              ],
              if (_c.baixando) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(value: _c.total > 0 ? _c.recebidos / _c.total : 0),
                const SizedBox(height: 8),
                Text('Baixando: ${_c.total > 0 ? _c.recebidos * 100 ~/ _c.total : 0}%'),
              ],
              if (_c.mensagem != null) ...[
                const SizedBox(height: 16),
                Semantics(liveRegion: true, child: Text(_c.mensagem!)),
              ],
            ],
          ),
          if (_c.habilitado)
            UpdateButton(
              key: const ValueKey('atualizador-acao'),
              texto: rotulo,
              foco: _acao,
              autofocus: true,
              primario: true,
              onPressed: _executar,
              abaixo: _voltar.requestFocus,
            ),
          UpdateButton(
            texto: 'Voltar',
            foco: _voltar,
            autofocus: !_c.habilitado,
            acima: _acao.requestFocus,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const UpdateCard(children: [Text('Após instalar, abra o app de novo.')]),
        ],
      );
    },
  );
}
