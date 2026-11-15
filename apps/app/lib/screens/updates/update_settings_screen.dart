import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/componentes/botao.dart';
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
  final _acao = FocusNode(debugLabel: 'atualizador-acao');
  final _estavel = FocusNode(debugLabel: 'atualizador-estavel');
  final _beta = FocusNode(debugLabel: 'atualizador-beta');
  final _voltar = FocusNode(debugLabel: 'atualizador-voltar');

  @override
  void initState() {
    super.initState();
    _c = widget.controlador ?? context.read<UpdateController>();
    unawaited(_c.iniciar());
  }

  @override
  void dispose() {
    for (final foco in [_acao, _estavel, _beta, _voltar]) {
      foco.dispose();
    }
    super.dispose();
  }

  void _escolher({required bool beta}) {
    if (_c.beta != beta) unawaited(_c.definirBeta(beta));
  }

  /// Dois canais: Estável (versões aprovadas) e Beta (qualquer pessoa pode ligar; chega antes).
  List<Widget> _canal() {
    final livre = !_c.ocupado;
    return [
      UpdateChoice(
        key: const ValueKey('atualizador-canal-estavel'),
        titulo: 'Estável',
        texto: 'Versões já aprovadas.',
        escolhida: !_c.beta,
        foco: _estavel,
        aoTocar: livre ? () => _escolher(beta: false) : null,
      ),
      UpdateChoice(
        key: const ValueKey('atualizador-canal-beta'),
        titulo: 'Beta',
        texto: 'Chega antes; pode ter falhas.',
        escolhida: _c.beta,
        foco: _beta,
        aoTocar: livre ? () => _escolher(beta: true) : null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => UpdateLayout(
      titulo: 'Atualizações',
      children: [
        UpdateStatusCard(controlador: _c, foco: _acao),
        if (_c.habilitado)
          UpdateCard(titulo: 'Versões que você recebe', children: _canal()),
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
