// Etapa 1E: armazenamento seguro do cookie de sessão do Seerr. No Android vai para o canal
// nativo (AES-GCM com chave do Android Keystore, ver CgflixSecureStoreChannel.kt); nos outros
// sistemas fica só na memória (o app entra de novo sozinho pelo Quick Connect a cada abertura).
// Nunca em SharedPreferences em texto.
import 'dart:io';

import 'package:flutter/services.dart';

import '../../utils/app_logger.dart';

abstract class CgflixSecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  /// O do aparelho: canal nativo no Android, memória nos outros.
  static CgflixSecureStore platform() => Platform.isAndroid ? _AndroidSecureStore() : CgflixMemorySecureStore();
}

/// Só na memória (outros sistemas e testes).
class CgflixMemorySecureStore implements CgflixSecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _AndroidSecureStore implements CgflixSecureStore {
  static const _channel = MethodChannel('br.com.docaio.cgflix/secure_store');

  @override
  Future<String?> read(String key) async {
    try {
      return await _channel.invokeMethod<String>('read', {'key': key});
    } catch (e) {
      appLogger.w('CGFLIX: armazenamento seguro ilegível', error: e);
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _channel.invokeMethod<void>('write', {'key': key, 'value': value});
    } catch (e) {
      appLogger.w('CGFLIX: não deu para gravar no armazenamento seguro', error: e);
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _channel.invokeMethod<void>('delete', {'key': key});
    } catch (e) {
      appLogger.w('CGFLIX: não deu para apagar do armazenamento seguro', error: e);
    }
  }
}
