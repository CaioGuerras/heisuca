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
  }) {
    return '${sourceIndex ?? 'auto'}:${sourceId ?? ''}:${preferredSignature ?? ''}';
  }

  bool _matchesKey(PlaybackCacheKey a, PlaybackCacheKey b) {
    if (a.serverId != b.serverId || a.userId != b.userId || a.itemId != b.itemId) {
      return false;
    }
    if (a.versionKey == b.versionKey) return true;
    final aAuto = a.versionKey.startsWith('auto:') || a.versionKey.startsWith('0:');
    final bAuto = b.versionKey.startsWith('auto:') || b.versionKey.startsWith('0:');
    return aAuto && bAuto;
  }

  void put({
    required String serverId,
    required String userId,
    required String itemId,
    int? sourceIndex,
    String? sourceId,
    String? preferredSignature,
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
  }) {
    final key = PlaybackCacheKey(
      serverId: serverId,
      userId: userId,
      itemId: itemId,
      versionKey: makeVersionKey(
        sourceIndex: sourceIndex,
        sourceId: sourceId,
        preferredSignature: preferredSignature,
      ),
    );
    var entry = _cache[key];
    if (entry == null && (sourceId == null || sourceId.isEmpty) && (preferredSignature == null || preferredSignature.isEmpty)) {
      if (sourceIndex == 0) {
        final altKey = PlaybackCacheKey(
          serverId: serverId,
          userId: userId,
          itemId: itemId,
          versionKey: makeVersionKey(sourceIndex: null),
        );
        entry = _cache[altKey];
      } else if (sourceIndex == null) {
        final altKey = PlaybackCacheKey(
          serverId: serverId,
          userId: userId,
          itemId: itemId,
          versionKey: makeVersionKey(sourceIndex: 0),
        );
        entry = _cache[altKey];
      }
    }
    if (entry == null) return null;

    final age = clock().difference(entry.createdAt);
    if (age > cacheValidity) {
      _cache.remove(key);
      return null;
    }
    return entry.bundle;
  }

  Future<JellyfinPlaybackBundle?> getOrWaitInFlight({
    required String serverId,
    required String userId,
    required String itemId,
    int? sourceIndex,
    String? sourceId,
    String? preferredSignature,
  }) async {
    final cached = get(
      serverId: serverId,
      userId: userId,
      itemId: itemId,
      sourceIndex: sourceIndex,
      sourceId: sourceId,
      preferredSignature: preferredSignature,
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
        final bundle = await future;
        _inFlightBundle = null;
        _inFlightKey = null;

        if (requestId != _currentRequestId) return;

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
        _inFlightBundle = null;
        _inFlightKey = null;
        appLogger.d('Jellyfin playback warmup failed silently', error: e, stackTrace: st);
      }
    });
  }
}
