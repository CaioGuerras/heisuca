// CGFLIX (1.5.0): o ícone do app acompanha o tema (Heitor = verde; Isis e Automático = roxo).
// Aqui só avisamos o Android do tema escolhido; a troca do activity-alias acontece quando o app
// sai da tela (CgflixAppIconChannel.kt), porque alguns aparelhos fecham o app na troca.
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/settings_service.dart' as settings;

const _channel = MethodChannel('br.com.docaio.cgflix/app_icon');

bool? _lastSent;

/// Ícone verde só com o Heitor escolhido de propósito (o Automático fica com o roxo).
bool cgflixWantsHeitorIcon(settings.ThemeMode mode) => mode == settings.ThemeMode.light;

/// Avisa o Android do ícone do tema [mode]. Barato: só manda quando muda. Não vale para a TV
/// (sempre Isis) nem fora do Android.
void cgflixSyncAppIcon(settings.ThemeMode mode) {
  if (kIsWeb || !Platform.isAndroid) return;
  final heitor = cgflixWantsHeitorIcon(mode);
  if (_lastSent == heitor) return;
  _lastSent = heitor;
  unawaited(_channel.invokeMethod<void>('setTheme', {'heitor': heitor}).catchError((Object _) {}));
}
