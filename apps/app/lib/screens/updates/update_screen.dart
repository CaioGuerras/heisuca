import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/componentes/botao.dart';
import '../../services/updates/update_controller.dart';
import '../../utils/platform_detector.dart';
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
    // Sair da tela não cancela: o download é do app e continua; ao voltar, a tela mostra onde ele está.
    _acao.dispose();
    _voltar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => UpdateLayout(
      titulo: 'Atualizações',
      children: [
        UpdateStatusCard(controlador: _c, foco: _acao),
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
