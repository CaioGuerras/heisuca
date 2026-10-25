import 'package:flutter/material.dart';

/// Compatibilidade do fluxo de sessão: mantém a composição transparente,
/// mas deixa transição e gesto inteiramente com o tema da plataforma.
Route<T> fadeRoute<T>(Widget page) => _SessionMaterialRoute<T>(builder: (_) => page);

class _SessionMaterialRoute<T> extends MaterialPageRoute<T> {
  _SessionMaterialRoute({required super.builder});
  @override bool get opaque => false;
}
