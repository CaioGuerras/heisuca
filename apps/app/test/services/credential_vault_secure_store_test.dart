import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/requests/cgflix_secure_store.dart';
import 'package:heisuca/utils/app_logger.dart' as logging;
import 'package:logger/logger.dart';
import 'package:heisuca/services/base_shared_preferences_service.dart';
import 'package:heisuca/services/credential_vault.dart';
import 'package:heisuca/services/sensitive_prefs.dart';

import '../test_helpers/prefs.dart';

/// Armazenamento seguro que falha em tudo (Keystore indisponível).
class _ThrowingStore extends CgflixMemorySecureStore {
  @override
  Future<String?> readOrThrow(String key) async => throw StateError('keystore indisponível');

  @override
  Future<void> writeOrThrow(String key, String value) async => throw StateError('keystore indisponível');
}

/// Lê normalmente, mas a gravação "some" (não pousa de forma durável).
class _LossyWriteStore extends CgflixMemorySecureStore {
  @override
  Future<void> writeOrThrow(String key, String value) async {}
}

/// A gravação grava outra coisa: a conferência tem de pegar.
class _CorruptingStore extends CgflixMemorySecureStore {
  @override
  Future<void> writeOrThrow(String key, String value) async => values[key] = base64Encode(List<int>.filled(32, 9));
}

const _v2 = 'credential_vault_key_v2';
final _legacyKey = base64Encode(List<int>.generate(32, (i) => i + 1));

Future<String?> _prefsKey() async {
  final prefs = await BaseSharedPreferencesService.sharedCache();
  await prefs.reloadCache();
  return prefs.getString(credentialVaultKeyPref);
}

Future<void> _seedLegacy([String? key]) async {
  final prefs = await BaseSharedPreferencesService.sharedCache();
  await prefs.setString(credentialVaultKeyPref, key ?? _legacyKey);
}

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    CredentialVault.resetKeyForTesting();
    addTearDown(CredentialVault.resetSecureStoreForTesting);
  });

  group('chave do cofre no armazenamento seguro (P5)', () {
    test('chave nova vai direto ao armazenamento seguro e não toca nas prefs', () async {
      final store = CgflixMemorySecureStore();
      CredentialVault.useSecureStoreForTesting(store);

      final protected = await CredentialVault.protect('segredo');

      expect(store.values[_v2], isNotEmpty);
      expect(base64Decode(store.values[_v2]!), hasLength(32));
      expect(await _prefsKey(), isNull);
      expect(await CredentialVault.reveal(protected), 'segredo');
    });

    test('migra a chave v1: grava, confere e só então remove das prefs; texto cifrado antigo segue legível', () async {
      // Cifra com a chave legada (sem armazenamento seguro, como antes da P5).
      CredentialVault.useSecureStoreForTesting(null);
      await _seedLegacy();
      final old = await CredentialVault.protect('token-antigo');
      expect(await _prefsKey(), _legacyKey);

      final store = CgflixMemorySecureStore();
      CredentialVault.useSecureStoreForTesting(store);

      expect(await CredentialVault.reveal(old), 'token-antigo');
      expect(store.values[_v2], _legacyKey);
      expect(await _prefsKey(), isNull);

      // Depois de limpar a memória, a chave vem do armazenamento seguro e continua lendo.
      CredentialVault.resetKeyForTesting();
      expect(await CredentialVault.reveal(old), 'token-antigo');
    });

    test('o armazenamento seguro com a chave vence e a cópia legada é removida', () async {
      final store = CgflixMemorySecureStore();
      final secureKey = base64Encode(List<int>.filled(32, 5));
      store.values[_v2] = secureKey;
      await _seedLegacy();
      CredentialVault.useSecureStoreForTesting(store);

      final protected = await CredentialVault.protect('x');

      expect(await _prefsKey(), isNull);
      expect(store.values[_v2], secureKey);
      CredentialVault.resetKeyForTesting();
      expect(await CredentialVault.reveal(protected), 'x');
    });

    test('armazenamento seguro com falha não perde a chave: segue com a legada e não a apaga', () async {
      CredentialVault.useSecureStoreForTesting(null);
      await _seedLegacy();
      final old = await CredentialVault.protect('token-antigo');

      CredentialVault.useSecureStoreForTesting(_ThrowingStore());
      expect(await CredentialVault.reveal(old), 'token-antigo');
      expect(await _prefsKey(), _legacyKey);

      // Próxima abertura, com o Keystore de volta: migra.
      final store = CgflixMemorySecureStore();
      CredentialVault.useSecureStoreForTesting(store);
      expect(await CredentialVault.reveal(old), 'token-antigo');
      expect(store.values[_v2], _legacyKey);
      expect(await _prefsKey(), isNull);
    });

    test('falha do armazenamento seguro sem chave nenhuma não gera chave "fantasma": guarda na legada', () async {
      CredentialVault.useSecureStoreForTesting(_ThrowingStore());
      final protected = await CredentialVault.protect('segredo');

      expect(await _prefsKey(), isNotNull);
      CredentialVault.resetKeyForTesting();
      expect(await CredentialVault.reveal(protected), 'segredo');
    });

    test('gravação que não pousa no armazenamento seguro mantém a chave legada', () async {
      await _seedLegacy();
      CredentialVault.useSecureStoreForTesting(_LossyWriteStore());
      await CredentialVault.protect('x');
      expect(await _prefsKey(), _legacyKey);
    });

    test('conferência que diverge mantém a cópia legada', () async {
      await _seedLegacy();
      final store = _CorruptingStore();
      CredentialVault.useSecureStoreForTesting(store);
      final protected = await CredentialVault.protect('x');
      expect(await _prefsKey(), _legacyKey);
      expect(await CredentialVault.reveal(protected), 'x');
    });

    test('erro do armazenamento seguro não vaza o valor da chave no log (só o tipo)', () async {
      final original = logging.appLogger;
      final output = MemoryOutput();
      logging.appLogger = Logger(printer: SimplePrinter(), output: output, level: Level.all, filter: ProductionFilter());
      addTearDown(() => logging.appLogger = original);

      await _seedLegacy();
      CredentialVault.useSecureStoreForTesting(_LeakyStore());
      await CredentialVault.protect('x'); // não pode lançar

      final logged = output.buffer.expand((e) => e.lines).join('\n');
      expect(logged, isNotEmpty);
      expect(logged, isNot(contains('SEGREDO-NO-ERRO')));
      expect(logged, isNot(contains(_legacyKey)));
      expect(logged, contains('StateError'));
    });
  });
}

class _LeakyStore extends CgflixMemorySecureStore {
  @override
  Future<String?> readOrThrow(String key) async => throw StateError('SEGREDO-NO-ERRO $_legacyKey');
}
