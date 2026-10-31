import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import '../utils/video_player_navigation.dart';
import 'jellyfin_client.dart';
import 'jellyfin_playback_bundle.dart';

@immutable
class PlaybackCacheKey {
  final String serverId;
  final String userId;
  final String itemId;
  final String versionKey;

  const PlaybackCacheKey({
    required this.serverId,
    required this.userId,
    required this.itemId,
    required this.versionKey,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackCacheKey &&
          runtimeType == other.runtimeType &&
          serverId == other.serverId &&
          userId == other.userId &&
          itemId == other.itemId &&
          versionKey == other.versionKey;

  @override
  int get hashCode => Object.hash(serverId, userId, itemId, versionKey);

  @override
  String toString() => 'PlaybackCacheKey($serverId, $userId, $itemId, $versionKey)';
}

class CachedPlaybackBundle {
  final JellyfinPlaybackBundle bundle;
  final DateTime createdAt;

  const CachedPlaybackBundle({
    required this.bundle,
    required this.createdAt,
  });
}

/// Serviço de pré-aquecimento e cache em memória de PlaybackInfo / PlaybackBundle para TV.
///
/// Regras:
/// - Só na TV ([PlatformDetector.isTV()]), só Jellyfin.
/// - Quando o foco para >= 700 ms num cartão de filme/episódio/série, solicita em segundo plano
///   o [JellyfinPlaybackBundle] com os mesmos parâmetros que o play usaria.
/// - Cache em memória por (servidor, usuário, itemId, versão pedida).
/// - Validade 60 s, no máximo 8 itens (LRU).
/// - Um pedido por vez (foco novo cancela/ignora o anterior).
/// - Ao apertar Play dentro da validade, usa o bundle em cache com 0 chamadas novas à rede.
/// - Fora da validade ou com erro: caminho atual inalterado.
class JellyfinPlaybackWarmupService {
  static final JellyfinPlaybackWarmupService instance = JellyfinPlaybackWarmupService._();
  JellyfinPlaybackWarmupService._();

  static const int maxCacheEntries = 8;
  static const Duration cacheValidity = Duration(seconds: 60);

  /// Relógio injetável para testes unitários determinísticos.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  final LinkedHashMap<PlaybackCacheKey, CachedPlaybackBundle> _cache = LinkedHashMap();

  Timer? _debounceTimer;
  int _currentRequestId = 0;
  Future<JellyfinPlaybackBundle?>? _inFlightBundle;
  PlaybackCacheKey? _inFlightKey;

  /// Futuro do aquecimento em voo (para testes e sincronização).
  @visibleForTesting
  Future<void>? get inFlightWarmup => _inFlightBundle;

  static String makeVersionKey({
    int? sourceIndex,
    String? sourceId,
    String? preferredSignature,
    String? inheritedSignature,
  }) {
    final idx = sourceIndex == null ? 'auto' : '$sourceIndex';
    final sid = sourceId ?? '';
    final pref = preferredSignature ?? '';
    final inh = inheritedSignature ?? '';
    return '$idx:$sid:$pref:$inh';
  }

  bool _matchesKey(PlaybackCacheKey a, PlaybackCacheKey b) {
    return a.serverId == b.serverId &&
        a.userId == b.userId &&
        a.itemId == b.itemId &&
        a.versionKey == b.versionKey;
  }

  void put({
    required String serverId,
    required String userId,
    required String itemId,
    int? sourceIndex,
    String? sourceId,
    String? preferredSignature,
    String? inheritedSignature,
    required JellyfinPlaybackBundle bundle,
  }) {
    final key = PlaybackCacheKey(
      serverId: serverId,
      userId: userId,
      itemId: itemId,
      versionKey: makeVersionKey(
        sourceIndex: sourceIndex,
        sourceId: sourceId,
        preferredSignature: preferredSignature,
        inheritedSignature: inheritedSignature,
      ),
    );
    _cache.remove(key);
    if (_cache.length >= maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = CachedPlaybackBundle(
      bundle: bundle,
      createdAt: clock(),
    );
  }

  JellyfinPlaybackBundle? get({
    required String serverId,
    required String userId,
    required String itemId,
    int? sourceIndex,
    String? sourceId,
    String? preferredSignature,
    String? inheritedSignature,
  }) {
    final key = PlaybackCacheKey(
      serverId: serverId,
      userId: userId,
      itemId: itemId,
      versionKey: makeVersionKey(
        sourceIndex: sourceIndex,
        sourceId: sourceId,
        preferredSignature: preferredSignature,
        inheritedSignature: inheritedSignature,
      ),
    );
    final entry = _cache[key];
    if (entry == null) return null;

    final age = clock().difference(entry.createdAt);
    if (age > cacheValidity) {
      _cache.remove(key);
      return null;
    }

    // LRU verdadeiro: ao acessar, move a entrada para o final do LinkedHashMap
    _cache.remove(key);
    _cache[key] = entry;

    return entry.bundle;
  }

  Future<JellyfinPlaybackBundle?> getOrWaitInFlight({
    required String serverId,
    required String userId,
    required String itemId,
    int? sourceIndex,
    String? sourceId,
    String? preferredSignature,
    String? inheritedSignature,
  }) async {
    final cached = get(
      serverId: serverId,
      userId: userId,
      itemId: itemId,
      sourceIndex: sourceIndex,
      sourceId: sourceId,
      preferredSignature: preferredSignature,
      inheritedSignature: inheritedSignature,
    );
    if (cached != null) return cached;

    if (_inFlightBundle != null && _inFlightKey != null) {
      final key = PlaybackCacheKey(
        serverId: serverId,
        userId: userId,
        itemId: itemId,
        versionKey: makeVersionKey(
          sourceIndex: sourceIndex,
          sourceId: sourceId,
          preferredSignature: preferredSignature,
          inheritedSignature: inheritedSignature,
        ),
      );
      if (_matchesKey(_inFlightKey!, key)) {
        try {
          await _inFlightBundle;
        } catch (_) {}
        return get(
          serverId: serverId,
          userId: userId,
          itemId: itemId,
          sourceIndex: sourceIndex,
          sourceId: sourceId,
          preferredSignature: preferredSignature,
          inheritedSignature: inheritedSignature,
        );
      }
    }
    return null;
  }

  void clear() {
    _debounceTimer?.cancel();
    _currentRequestId++;
    _inFlightBundle = null;
    _inFlightKey = null;
    _cache.clear();
  }

  void onFocusLost() {
    _debounceTimer?.cancel();
    _currentRequestId++;
  }

  void onCardFocused({
    required JellyfinClient client,
    required MediaItem item,
    Duration debounce = const Duration(milliseconds: 700),
  }) {
    _debounceTimer?.cancel();
    _currentRequestId++;
    final requestId = _currentRequestId;

    if (!PlatformDetector.isTV()) return;
    if (item.backend != MediaBackend.jellyfin) return;

    _debounceTimer = Timer(debounce, () async {
      if (requestId != _currentRequestId) return;
      try {
        MediaItem target = item;
        if (item.kind == MediaKind.show) {
          final res = await client.fetchItemWithOnDeck(item.id);
          if (requestId != _currentRequestId) return;
          if (res.onDeckEpisode != null) {
            target = res.onDeckEpisode!;
          } else {
            final seasons = await client.fetchChildren(item.id);
            if (requestId != _currentRequestId) return;
            final firstSeason = seasons.where((s) => s.kind == MediaKind.season).firstOrNull;
            if (firstSeason != null) {
              final eps = await client.fetchChildren(firstSeason.id);
              if (requestId != _currentRequestId) return;
              final firstEp = eps.where((e) => e.kind == MediaKind.episode).firstOrNull;
              if (firstEp != null) target = firstEp;
            }
          }
        }

        final saved = await resolveSavedMediaVersionFor(target);
        if (requestId != _currentRequestId) return;

        final key = PlaybackCacheKey(
          serverId: client.connection.serverMachineId,
          userId: client.connection.userId,
          itemId: target.id,
          versionKey: makeVersionKey(
            sourceIndex: saved?.index,
            sourceId: saved?.sourceId,
            preferredSignature: saved?.signature,
          ),
        );
        _inFlightKey = key;
        final future = client.fetchPlaybackBundle(
          target.id,
          sourceIndex: saved?.index,
          sourceId: saved?.sourceId,
          preferredSignature: saved?.signature,
        );
        _inFlightBundle = future;

        JellyfinPlaybackBundle? bundle;
        try {
          bundle = await future;
        } finally {
          // Pedido antigo que termina depois não zera _inFlightBundle do pedido novo
          if (identical(_inFlightBundle, future)) {
            _inFlightBundle = null;
            _inFlightKey = null;
          }
        }

        // onFocusLost não pode descartar o bundle que já está em voo: terminou → put() sempre;
        // o requestId só decide se ele vira o "atual".
        if (bundle != null) {
          put(
            serverId: client.connection.serverMachineId,
            userId: client.connection.userId,
            itemId: target.id,
            sourceIndex: saved?.index,
            sourceId: saved?.sourceId,
            preferredSignature: saved?.signature,
            bundle: bundle,
          );
        }
      } catch (e, st) {
        appLogger.d('Jellyfin playback warmup failed silently', error: e, stackTrace: st);
      }
    });
  }
}
