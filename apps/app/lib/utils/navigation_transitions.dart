import 'package:flutter/material.dart';

/// Compatibilidade do fluxo de sessão: mantém a composição transparente,
/// mas deixa transição e gesto inteiramente com o tema da plataforma.
Route<T> fadeRoute<T>(Widget page) => _SessionMaterialRoute<T>(builder: (_) => page);

/// [MaterialPageRoute] exige rota opaca (`assert(opaque)` no construtor; derrubava o debug na bancada).
/// Mesma base dela, [PageRoute] + [MaterialRouteTransitionMixin], com a transparência que a sessão precisa.
class _SessionMaterialRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  _SessionMaterialRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;
}
