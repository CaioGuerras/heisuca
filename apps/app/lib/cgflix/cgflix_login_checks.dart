// CGFLIX (1.5.0): mensagens claras no login antes de ir ao servidor. Com campo vazio ou endereço
// torto, o servidor devolvia erro técnico (ou o "Falha ao entrar: ..." com o texto da exceção).
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../widgets/app_icon.dart';

const cgflixLoginMissingMessage = 'Preencha o usuário.';
const cgflixServerEmptyMessage = 'Digite o endereço do servidor, por exemplo https://seu.servidor.com';
const cgflixServerInvalidMessage =
    'Esse endereço não parece certo. Confira se digitou tudo, por exemplo https://seu.servidor.com';

/// Usuário vazio. Nulo = pode ir ao servidor. A senha pode ficar vazia: o Jellyfin tem conta sem
/// senha (Caio, 16/10/2026: o 1.5.0 recusava esses usuários).
String? cgflixLoginMissing(String username) => username.trim().isEmpty ? cgflixLoginMissingMessage : null;

/// Endereço do servidor vazio ou que não tem como ser um endereço (espaço no meio, sem nome,
/// símbolos). Aceita sem `https://` (o app completa) e com porta. Nulo = pode procurar.
String? cgflixServerAddressProblem(Iterable<String> enteredUrls) {
  final urls = enteredUrls.map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
  if (urls.isEmpty) return cgflixServerEmptyMessage;
  for (final url in urls) {
    if (!_looksLikeAddress(url)) return cgflixServerInvalidMessage;
  }
  return null;
}

final _hostChars = RegExp(r'^[A-Za-z0-9._\-~%]+$');

bool _looksLikeAddress(String url) {
  if (url.contains(RegExp(r'\s'))) return false;
  final withScheme = url.contains('://') ? url : 'https://$url';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return false;
  final host = uri.host;
  if (host.isEmpty) return false;
  // IPv6 entre colchetes: o Uri já validou.
  if (withScheme.contains('[')) return true;
  return _hostChars.hasMatch(host) && !host.startsWith('.') && !host.endsWith('..');
}

/// Olho do campo de senha (mostrar/esconder), com dica para o leitor de tela.
Widget cgflixPasswordToggle(bool visible, VoidCallback onToggle) => IconButton(
  tooltip: visible ? 'Esconder senha' : 'Mostrar senha',
  onPressed: onToggle,
  icon: AppIcon(visible ? Symbols.visibility_off_rounded : Symbols.visibility_rounded, fill: 1),
);
