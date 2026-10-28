import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferencesWithCache;

import '../cgflix/requests/cgflix_secure_store.dart';
import '../utils/app_logger.dart';
import 'base_shared_preferences_service.dart';
import 'sensitive_prefs.dart';

/// Encrypts credentials before they are persisted in Drift config/token
/// columns. The database no longer stores raw server tokens; registries
/// decrypt at their boundaries and rewrite legacy plaintext values on read.
///
/// Security model (P5): on Android the key lives in the Android Keystore-backed
/// [CgflixSecureStore] (`credential_vault_key_v2`), never in SharedPreferences.
/// Keys found in the legacy v1 preference are migrated (write, read back,
/// compare, only then remove the legacy copy); if the secure store is
/// unavailable the legacy key keeps working and migration is retried on the
/// next launch. On the other platforms the key stays in SharedPreferences, so
/// there it is obfuscation-at-rest only (out of the Android P5 scope).
class CredentialVault {
  CredentialVault._();

  static const String _keyPref = credentialVaultKeyPref;
  static const String _secureKeyName = 'credential_vault_key_v2';
  static const String _prefix = 'enc:v1:';
  static final AesGcm _algorithm = AesGcm.with256bits();
  static final Map<String, Future<String?>> _decryptionCache = {};
  static Future<SecretKey>? _secretKey;
  static int _cacheGeneration = 0;

  static CgflixSecureStore? _platformStore;
  static CgflixSecureStore? _storeOverride;
  static bool _storeOverridden = false;

  /// Android: armazenamento seguro do aparelho. Outras plataformas: null (chave em prefs).
  static CgflixSecureStore? _secureStore() {
    if (_storeOverridden) return _storeOverride;
    if (!Platform.isAndroid) return null;
    return _platformStore ??= CgflixSecureStore.platform();
  }

  /// Troca o armazenamento seguro nos testes (null = comportamento legado, só prefs).
  @visibleForTesting
  static void useSecureStoreForTesting(CgflixSecureStore? store) {
    _storeOverride = store;
    _storeOverridden = true;
    invalidateCache();
  }

  /// Volta ao padrão da plataforma.
  @visibleForTesting
  static void resetSecureStoreForTesting() {
    _storeOverride = null;
    _storeOverridden = false;
    invalidateCache();
  }

  /// Invalidates the memoized key and decrypted credentials after the
  /// underlying preference store is repaired or replaced.
  static void invalidateCache() {
    _cacheGeneration++;
    _secretKey = null;
    _decryptionCache.clear();
  }

  /// Drops memoized vault state so tests can simulate key loss/divergence.
  @visibleForTesting
  static void resetKeyForTesting() {
    invalidateCache();
  }

  static bool isProtected(String? value) => value != null && value.startsWith(_prefix);

  static Future<String> protect(String value) async {
    if (value.isEmpty || isProtected(value)) return value;
    while (true) {
      final generation = _cacheGeneration;
      final key = await _getSecretKey();
      final box = await _algorithm.encrypt(utf8.encode(value), secretKey: key);
      if (generation != _cacheGeneration) continue;

      final payload = {
        'n': base64Encode(box.nonce),
        'c': base64Encode(box.cipherText),
        'm': base64Encode(box.mac.bytes),
      };
      final ciphertext = '$_prefix${jsonEncode(payload)}';
      _decryptionCache[ciphertext] = Future.value(value);
      return ciphertext;
    }
  }

  /// Decrypts a protected value, or returns it unchanged when it isn't
  /// protected. Returns null when decryption fails — a failed MAC check
  /// (key/ciphertext divergence: restored backup, clobbered prefs, racing
  /// key generation) or a corrupt payload means the credential is *lost*,
  /// never a reason to crash; callers treat null as "re-acquire the token".
  static Future<String?> reveal(String value) async {
    if (!isProtected(value)) return value;
    while (true) {
      final generation = _cacheGeneration;
      final clear = await _decryptionCache.putIfAbsent(value, () => _decrypt(value, generation));
      if (generation == _cacheGeneration) return clear;
    }
  }

  static Future<String?> _decrypt(String value, int generation) async {
    try {
      final payload = jsonDecode(value.substring(_prefix.length)) as Map<String, dynamic>;
      final box = SecretBox(
        base64Decode(payload['c'] as String),
        nonce: base64Decode(payload['n'] as String),
        mac: Mac(base64Decode(payload['m'] as String)),
      );
      final clear = await _algorithm.decrypt(box, secretKey: await _getSecretKey());
      return utf8.decode(clear);
    } catch (e) {
      if (generation != _cacheGeneration) return null;
      appLogger.w('CredentialVault: failed to decrypt stored credential, treating as lost', error: e);
      return null;
    }
  }

  static Future<Map<String, Object?>> protectConnectionConfig(String kind, Map<String, Object?> config) async {
    final copy = Map<String, Object?>.from(config);
    final tokenKey = _tokenKeyForKind(kind);
    final token = tokenKey == null ? null : copy[tokenKey];
    if (token is String) copy[tokenKey!] = await protect(token);
    if (kind == 'plex') {
      copy['servers'] = await _protectPlexServers(copy['servers']);
    }
    return copy;
  }

  static Future<({Map<String, dynamic> config, bool migrated})> revealConnectionConfig(
    String kind,
    Map<String, dynamic> config,
  ) async {
    final copy = Map<String, dynamic>.from(config);
    final tokenKey = _tokenKeyForKind(kind);
    var migrated = false;
    final token = tokenKey == null ? null : copy[tokenKey];
    if (token is String && token.isNotEmpty) {
      final revealed = await reveal(token);
      // An undecryptable token becomes the empty string — the shared
      // "no credential, re-auth" shape — and must not be rewritten back.
      migrated = revealed != null && !isProtected(token);
      copy[tokenKey!] = revealed ?? '';
    }
    if (kind == 'plex') {
      final result = await _revealPlexServers(copy['servers']);
      copy['servers'] = result.servers;
      migrated = migrated || result.migrated;
    }
    return (config: copy, migrated: migrated);
  }

  /// Config key holding the long-lived credential for a `connections.kind`
  /// value. Returning `null` means "nothing to encrypt", so every new kind MUST
  /// be listed here — an omission silently persists the token in plaintext.
  static String? _tokenKeyForKind(String kind) => switch (kind) {
    'plex' => 'accountToken',
    'jellyfin' || 'emby' => 'accessToken',
    _ => null,
  };

  static Future<Object?> _protectPlexServers(Object? rawServers) async {
    if (rawServers is! List) return rawServers;
    final servers = <Object?>[];
    for (final raw in rawServers) {
      if (raw is! Map) {
        servers.add(raw);
        continue;
      }
      final server = Map<String, Object?>.from(raw);
      final token = server['accessToken'];
      if (token is String) server['accessToken'] = await protect(token);
      servers.add(server);
    }
    return servers;
  }

  static Future<({Object? servers, bool migrated})> _revealPlexServers(Object? rawServers) async {
    if (rawServers is! List) return (servers: rawServers, migrated: false);
    var migrated = false;
    final servers = <Object?>[];
    for (final raw in rawServers) {
      if (raw is! Map) {
        servers.add(raw);
        continue;
      }
      final server = Map<String, dynamic>.from(raw);
      final token = server['accessToken'];
      if (token is String && token.isNotEmpty) {
        final revealed = await reveal(token);
        migrated = migrated || (revealed != null && !isProtected(token));
        server['accessToken'] = revealed ?? '';
      }
      servers.add(server);
    }
    return (servers: servers, migrated: migrated);
  }

  static Future<SecretKey> _getSecretKey() {
    return _secretKey ??= _loadSecretKey();
  }

  /// P5: no Android a chave mora no Android Keystore (via [CgflixSecureStore]). Nas outras
  /// plataformas continua em SharedPreferences (fora do escopo da P5-Android).
  static Future<SecretKey> _loadSecretKey() async {
    final store = _secureStore();
    if (store == null) return _loadLegacyKey();

    // Falha do armazenamento seguro NÃO é "sem chave": confundir as duas geraria uma chave nova
    // por cima e órfã todo texto cifrado do banco. Em caso de falha segue com a chave legada
    // (nada se perde) e a migração é tentada de novo na próxima abertura.
    String? secure;
    try {
      secure = await store.readOrThrow(_secureKeyName);
      if (secure != null && secure.isNotEmpty) base64Decode(secure);
    } catch (e) {
      appLogger.w('CredentialVault: armazenamento seguro indisponível (${e.runtimeType}); usando a chave legada');
      return _loadLegacyKey();
    }

    final prefs = await BaseSharedPreferencesService.sharedCache();
    if (secure != null && secure.isNotEmpty) {
      await _dropLegacyKey(prefs);
      return SecretKey(base64Decode(secure));
    }

    await _reloadPrefs(prefs);
    // Leitura tolerante: tipo errado é falha reparável, não "sem chave" (#1732).
    final legacy = readTolerantString(prefs, _keyPref);
    if (legacy != null && legacy.isNotEmpty) {
      // Migra: grava, relê e só apaga a cópia legada se voltou idêntica.
      try {
        await store.writeOrThrow(_secureKeyName, legacy);
        final check = await store.readOrThrow(_secureKeyName);
        if (check == legacy) {
          await _dropLegacyKey(prefs);
        } else {
          appLogger.w('CredentialVault: conferência da chave migrada falhou; mantendo a cópia legada');
        }
      } catch (e) {
        appLogger.w('CredentialVault: migração da chave falhou (${e.runtimeType}); tenta na próxima abertura');
      }
      return SecretKey(base64Decode(legacy));
    }

    // Nenhuma das duas: chave nova direto no armazenamento seguro, relida para convergir.
    final bytes = _randomKeyBytes();
    try {
      await store.writeOrThrow(_secureKeyName, base64Encode(bytes));
      final settled = await store.readOrThrow(_secureKeyName);
      if (settled != null && settled.isNotEmpty) return SecretKey(base64Decode(settled));
    } catch (e) {
      appLogger.w('CredentialVault: não deu para gravar a chave no armazenamento seguro (${e.runtimeType})');
    }
    // Não pousou de forma durável: guarda na legada para não perder o que for cifrado agora.
    return _loadLegacyKey();
  }

  static List<int> _randomKeyBytes() => List<int>.generate(32, (_) => Random.secure().nextInt(256));

  static Future<void> _reloadPrefs(SharedPreferencesWithCache prefs) async {
    try {
      await prefs.reloadCache();
    } catch (e) {
      appLogger.d('CredentialVault: prefs reload before key check failed', error: e);
    }
  }

  /// Remove a cópia legada da chave (só depois de ela estar no armazenamento seguro).
  static Future<void> _dropLegacyKey(SharedPreferencesWithCache prefs) async {
    try {
      await prefs.remove(_keyPref);
    } catch (e) {
      appLogger.w('CredentialVault: não deu para remover a chave legada (${e.runtimeType})');
    }
  }

  static Future<SecretKey> _loadLegacyKey() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    // The cached snapshot can predate a key written by another isolate
    // (background downloader, first-run migration); generating "fresh" over
    // it would clobber the real key and orphan every stored ciphertext.
    // Reload before deciding, and after writing re-read and adopt whatever
    // actually landed so all isolates converge on a single key.
    await _reloadPrefs(prefs);
    // Tolerant read: a wrong-typed key must surface as a repairable
    // failure, not be mistaken for 'no key yet' and silently replaced —
    // that would orphan every ciphertext in the database (#1732).
    final stored = readTolerantString(prefs, _keyPref);
    if (stored != null && stored.isNotEmpty) {
      return SecretKey(base64Decode(stored));
    }
    final bytes = _randomKeyBytes();
    await prefs.setString(_keyPref, base64Encode(bytes));
    try {
      await prefs.reloadCache();
    } catch (e) {
      appLogger.d('CredentialVault: prefs re-read after key write failed', error: e);
    }
    // Outside the catch: if another isolate raced us and left a wrong-typed
    // value, swallowing it here would return a key that never durably
    // landed, and every ciphertext written under it would be unreadable on
    // the next launch. Surface it for repair instead (#1732).
    final settled = readTolerantString(prefs, _keyPref);
    if (settled != null && settled.isNotEmpty) {
      return SecretKey(base64Decode(settled));
    }
    return SecretKey(bytes);
  }
}
