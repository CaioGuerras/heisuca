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

  /// Apaga todas as chaves que começam com [prefix] (usado no logout para as sessões do Seerr).
  Future<void> deleteWithPrefix(String prefix);

  /// Como [read], mas a falha do armazenamento (canal ausente, Keystore indisponível) sobe como
  /// exceção em vez de virar "não há valor". Quem não pode confundir as duas coisas (a chave do
  /// cofre de credenciais) usa esta; o resto continua com [read].
  Future<String?> readOrThrow(String key);

  /// Como [write], mas a falha sobe como exceção.
  Future<void> writeOrThrow(String key, String value);

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

  @override
  Future<void> deleteWithPrefix(String prefix) async => values.removeWhere((key, _) => key.startsWith(prefix));

  @override
  Future<String?> readOrThrow(String key) => read(key);

  @override
  Future<void> writeOrThrow(String key, String value) => write(key, value);
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
  Future<void> deleteWithPrefix(String prefix) async {
    try {
      await _channel.invokeMethod<void>('deletePrefix', {'key': prefix});
    } catch (e) {
      appLogger.w('CGFLIX: não deu para apagar do armazenamento seguro', error: e);
    }
  }

  @override
  Future<String?> readOrThrow(String key) => _channel.invokeMethod<String>('read', {'key': key});

  @override
  Future<void> writeOrThrow(String key, String value) =>
      _channel.invokeMethod<void>('write', {'key': key, 'value': value});

  @override
  Future<void> delete(String key) async {
    try {
      await _channel.invokeMethod<void>('delete', {'key': key});
    } catch (e) {
      appLogger.w('CGFLIX: não deu para apagar do armazenamento seguro', error: e);
    }
  }
}
