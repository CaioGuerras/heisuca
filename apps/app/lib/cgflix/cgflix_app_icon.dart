// O ícone acompanha Shikkoku, Hisui ou Sumi; Automático acompanha o sistema.
// Aqui só avisamos o Android do tema escolhido; a troca do activity-alias acontece quando o app
// sai da tela (CgflixAppIconChannel.kt), porque alguns aparelhos fecham o app na troca.
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart' show Brightness, WidgetsBinding;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/settings_service.dart' as settings;

const _channel = MethodChannel('br.com.docaio.cgflix/app_icon');

String? _lastSent;

/// Hisui explícito ou sistema claro no modo Automático.
bool cgflixWantsHeitorIcon(settings.ThemeMode mode) =>
    mode == settings.ThemeMode.light ||
    mode == settings.ThemeMode.system &&
        WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light;

/// Avisa o Android do ícone do tema [mode]; só manda quando muda.
void cgflixSyncAppIcon(settings.ThemeMode mode) {
  if (kIsWeb || !Platform.isAndroid) return;
  final tema = mode == settings.ThemeMode.sumi
      ? "sumi"
      : cgflixWantsHeitorIcon(mode)
      ? "hisui"
      : "shikkoku";
  if (_lastSent == tema) return;
  _lastSent = tema;
  unawaited(_channel.invokeMethod<void>('setTheme', {'tema': tema}).catchError((Object _) {}));
}
