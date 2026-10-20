// CGFLIX (1.5.0, acabamento): avisos (snackbars) nas cores do tema. O upstream pintava sucesso de
// verde e erro de vermelho fixos (fora do esquema e com contraste fraco no Heitor, onde o texto do
// aviso é quase branco). Agora: erro = `error`/`onError` do tema; sucesso = aviso normal do tema.
import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import 'cgflix_palette.dart';

/// Cores (fundo, texto) do aviso a partir da cor que o upstream pediu. Nulo = a do tema.
(Color?, Color?) cgflixSnackBarColors(BuildContext context, Color? upstream) {
  final scheme = Theme.of(context).colorScheme;
  if (identical(upstream, Colors.red)) return (scheme.error, scheme.onError);
  if (identical(upstream, Colors.green)) return (null, null);
  return (upstream, null);
}

/// Destaque do player (sempre escuro): o lilás do CGFLIX no lugar do âmbar do upstream (chaves
/// ligadas, item escolhido, timer ativo).
const cgflixPlayerAccent = Color(0xFFC084FC);

/// Cores dos estados de download (o upstream usava laranja/azul/âmbar/verde/vermelho soltos, quase
/// invisíveis no fundo claro do Heitor). Tudo da paleta do tema.
class CgflixStatusColors {
  const CgflixStatusColors({required this.active, required this.idle, required this.done, required this.failed});
  final Color active;
  final Color idle;
  final Color done;
  final Color failed;

  static CgflixStatusColors of(BuildContext context) {
    final palette = CgflixPalette.of(context);
    return CgflixStatusColors(
      active: palette.accent,
      idle: palette.textMuted,
      done: palette.success,
      failed: palette.danger,
    );
  }
}

/// Motivo curto, em português, de uma falha do player a partir da linha crua do mpv/ffmpeg (que vai
/// inteira para o log). Nada de inglês técnico na tela.
String cgflixPlayerFailureReason(String? raw) {
  // Fora do português, o texto do upstream (a linha já sem dados pessoais).
  if (LocaleSettings.currentLocale != AppLocale.pt) return raw ?? '';
  final text = (raw ?? '').toLowerCase();
  if (text.contains('404') || text.contains('not found')) return 'arquivo não encontrado no servidor';
  if (text.contains('403') || text.contains('401') || text.contains('forbidden')) return 'acesso negado pelo servidor';
  if (text.contains('timed out') || text.contains('timeout')) return 'o servidor demorou para responder';
  if (text.contains('format') || text.contains('codec') || text.contains('decoder')) {
    return 'formato de vídeo que este aparelho não abre';
  }
  if (text.contains('connection') || text.contains('network') || text.contains('resolve')) return 'falha na conexão';
  return 'erro no reprodutor';
}
