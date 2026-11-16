import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart' show FileInfo;
import 'package:flutter/foundation.dart' show TargetPlatform, Uint8List, defaultTargetPlatform, visibleForTesting;

import 'package:heisuca/services/sessao_media.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../media/media_server_client.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../utils/app_logger.dart';
import 'image_cache_service.dart';

/// Manages OS media controls integration for video playback.
///
/// Handles:
/// - Metadata updates (title, artwork, etc.)
/// - Playback state updates (playing/paused, position, speed)
/// - Control event streaming (play, pause, next, previous, seek)
/// - Position update throttling to prevent excessive API calls
class MediaControlsManager {
  static MediaControlsManager? _proprietario;
  bool _disposed = false;
  bool get _ownsSession => !_disposed && identical(_proprietario, this);

  Stream<MediaControlEvent> get controlEvents => SessaoMedia.controlEvents.where((_) => _ownsSession);

  bool _claimAvailableSession() {
    if (_disposed) return false;
    if (_proprietario == null) {
      _metadataGeneration++;
      _throttledUpdate.cancel();
      _resetControlsCache();
      _proprietario = this;
    }
    return _ownsSession;
  }

  void _resetControlsCache() {
    _lastCanPlayPause = null;
    _lastCanGoNext = null;
    _lastCanGoPrevious = null;
    _lastCanSeek = null;
    _lastCanStop = null;
    _lastCanSkip = null;
    _lastSkipInterval = null;
    _lastCanSetSpeed = null;
  }

  /// Throttled playback state update (1 second interval, leading + trailing)
  late final Throttle _throttledUpdate;

  /// Cached control enabled state to avoid redundant platform calls
  bool? _lastCanPlayPause;
  bool? _lastCanGoNext;
  bool? _lastCanGoPrevious;
  bool? _lastCanSeek;
  bool? _lastCanStop;
  bool? _lastCanSkip;
  bool? _lastCanSetSpeed;
  Duration? _lastSkipInterval;
  bool _updatesSuspended = false;

  /// Bumped by every metadata update and [clear], so artwork bytes that
  /// arrive late never land on a newer item or a cleared session.
  int _metadataGeneration = 0;

  final Future<Uint8List?> Function(String url) _artworkBytesLoader;

  MediaControlsManager({@visibleForTesting Future<Uint8List?> Function(String url)? artworkBytesLoader})
    : _artworkBytesLoader = artworkBytesLoader ?? _loadArtworkFromCache {
    _proprietario = this;
    _throttledUpdate = throttle(
      _doUpdatePlaybackState,
      const Duration(seconds: 1),
      leading: true,
      trailing: true, // Send final position at end of throttle window
    );
  }

  /// Update media metadata displayed in OS media controls
  ///
  /// This includes title, artist, artwork, and duration. Backend-neutral —
  /// the [MediaServerClient.thumbnailUrl] adapter handles per-backend URL
  /// shape (Plex's `/photo/:/transcode` proxy vs. Jellyfin's
  /// self-authenticated image URL).
  Future<void> updateMetadata({required MediaItem metadata, MediaServerClient? client, Duration? duration}) async {
    if (_updatesSuspended || !_claimAvailableSession()) return;
    final generation = ++_metadataGeneration;

    try {
      String? artworkUrl;
      if (client != null && metadata.thumbPath != null) {
        try {
          artworkUrl = client.thumbnailUrl(metadata.thumbPath!);
        } catch (e) {
          appLogger.w('Failed to build artwork URL', error: e);
        }
      }

      MediaMetadata build({String? artworkUrl, Uint8List? artwork}) => MediaMetadata(
        title: metadata.title ?? '',
        mediaId: metadata.globalKey,
        isVideo: metadata.kind != MediaKind.track,
        artist: _buildArtist(metadata),
        // Music-only: null for video content, so video behavior is untouched.
        album: metadata.kind == MediaKind.track ? metadata.albumTitle : null,
        artworkUrl: artworkUrl,
        artwork: artwork,
        duration: duration,
      );

      // The artwork URL embeds the server token. Linux publishes it verbatim
      // as MPRIS `mpris:artUrl` on the session bus, readable by every process
      // of the user, so hand the plugin the bytes instead: it writes them to a
      // private runtime file and publishes that file:// URI. The download
      // must not hold up the title, so the artwork follows in a second update.
      final artworkUrlForBus = artworkUrl != null && defaultTargetPlatform == TargetPlatform.linux ? null : artworkUrl;
      await SessaoMedia.setMetadata(build(artworkUrl: artworkUrlForBus));
      if (artworkUrl != null && artworkUrlForBus == null) {
        unawaited(_publishArtworkBytes(artworkUrl, generation, (bytes) => build(artwork: bytes)));
      }

      appLogger.d('Updated media controls metadata: ${metadata.title}');
    } catch (e) {
      appLogger.w('Failed to update media controls metadata', error: e);
    }
  }

  Future<void> _publishArtworkBytes(String url, int generation, MediaMetadata Function(Uint8List bytes) build) async {
    try {
      final bytes = await _artworkBytesLoader(url);
      // A newer update, clear() or suspension owns the session by now.
      if (bytes == null || bytes.isEmpty || generation != _metadataGeneration || _updatesSuspended || !_ownsSession) {
        return;
      }
      await SessaoMedia.setMetadata(build(bytes));
    } catch (e) {
      appLogger.w('Failed to load media controls artwork', error: e);
    }
  }

  /// Reads [url] through the shared artwork cache, which also keeps the token
  /// out of its own metadata.
  static Future<Uint8List?> _loadArtworkFromCache(String url) async {
    final response = await PlexImageCacheManager.instance.getFileStream(url).firstWhere((r) => r is FileInfo);
    return (response as FileInfo).file.readAsBytes();
  }

  /// Update playback state in OS media controls
  ///
  /// Updates the current playing state, position, and playback speed.
  /// Position updates are throttled to avoid excessive API calls.
  Future<void> updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required double speed,
    bool force = false,
  }) async {
    if (_updatesSuspended || !_claimAvailableSession()) return;

    final params = _PlaybackStateParams(
      state: isPlaying ? PlaybackState.playing : PlaybackState.paused,
      position: position,
      speed: speed,
    );

    if (force) {
      // Cancel any pending throttled update to prevent stale state from overwriting
      _throttledUpdate.cancel();
      await _doUpdatePlaybackState(params);
    } else {
      _throttledUpdate([params]);
    }
  }

  /// Publica estados transitórios e terminais sem reduzir carregamento a pausa.
  Future<void> updateDetailedPlaybackState({
    required PlaybackState state,
    required Duration position,
    required double speed,
    bool force = false,
  }) async {
    if (_updatesSuspended || !_claimAvailableSession()) return;
    final params = _PlaybackStateParams(state: state, position: position, speed: speed);
    if (force) {
      _throttledUpdate.cancel();
      await _doUpdatePlaybackState(params);
    } else {
      _throttledUpdate([params]);
    }
  }

  Future<void> _doUpdatePlaybackState(_PlaybackStateParams params) async {
    if (!_ownsSession || _updatesSuspended) return;
    try {
      await SessaoMedia.setPlaybackState(
        MediaPlaybackState(state: params.state, position: params.position, speed: params.speed),
      );
    } catch (e) {
      appLogger.w('Failed to update media controls playback state', error: e);
    }
  }

  /// Enable or disable transport controls in the OS media session.
  ///
  /// next/previous/seek reflect the content (adjacent episodes, playlist
  /// position, seekability). stop/skip/speed reflect what the active surface
  /// actually handles — the platform sides enable several commands by
  /// default, so anything the caller leaves disabled here is explicitly
  /// un-advertised rather than shown as a dead button.
  ///
  /// [canSkip] on iOS/macOS (and tvOS, which reports [TargetPlatform.iOS])
  /// is honored only when the caller also sets [preferSkipOverTrackButtons]:
  /// the MPRemoteCommandCenter skip commands displace the next/previous
  /// track buttons on the lock screen / Control Center / iPhone remote card.
  /// Video wants exactly that — in-track ±skip is the primary transport
  /// there (#1994) — while music keeps next/previous. Android's
  /// fast-forward/rewind actions are independent of next/previous, so skip
  /// is always safe to advertise.
  ///
  /// [skipInterval] conserva o passo configurável nas plataformas Apple.
  /// No Android, os comandos do sistema e do PiP usam saltos de dez segundos.
  Future<void> setControlsEnabled({
    bool canPlayPause = false,
    bool canGoNext = false,
    bool canGoPrevious = false,
    bool canSeek = false,
    bool canStop = false,
    bool canSkip = false,
    bool canSetSpeed = false,
    bool preferSkipOverTrackButtons = false,
    Duration? skipInterval,
  }) async {
    if (_updatesSuspended || !_claimAvailableSession()) return;

    final isDarwin = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    final effectiveCanSkip = canSkip && (!isDarwin || preferSkipOverTrackButtons);

    try {
      // Intervals go out before the commands are advertised so the first
      // lock-screen render already shows the right glyph. The platform side
      // re-enables the skip commands as part of this call, which is
      // consistent: it only runs while skip is being advertised.
      if (isDarwin && effectiveCanSkip && skipInterval != null && skipInterval != _lastSkipInterval) {
        await SessaoMedia.setSkipIntervals(forward: skipInterval, backward: skipInterval);
        if (!_ownsSession) return;
        _lastSkipInterval = skipInterval;
      }

      final controlsToEnable = <MediaControl>[];
      final controlsToDisable = <MediaControl>[];

      if (canPlayPause != _lastCanPlayPause) {
        (canPlayPause ? controlsToEnable : controlsToDisable)
          ..add(MediaControl.play)
          ..add(MediaControl.pause);
      }
      if (canGoPrevious != _lastCanGoPrevious) {
        (canGoPrevious ? controlsToEnable : controlsToDisable).add(MediaControl.previous);
      }
      if (canGoNext != _lastCanGoNext) {
        (canGoNext ? controlsToEnable : controlsToDisable).add(MediaControl.next);
      }
      if (canSeek != _lastCanSeek) {
        (canSeek ? controlsToEnable : controlsToDisable).add(MediaControl.seek);
      }
      if (canStop != _lastCanStop) {
        (canStop ? controlsToEnable : controlsToDisable).add(MediaControl.stop);
      }
      if (effectiveCanSkip != _lastCanSkip) {
        (effectiveCanSkip ? controlsToEnable : controlsToDisable)
          ..add(MediaControl.skipForward)
          ..add(MediaControl.skipBackward);
      }
      if (canSetSpeed != _lastCanSetSpeed) {
        (canSetSpeed ? controlsToEnable : controlsToDisable).add(MediaControl.changeSpeed);
      }

      if (controlsToEnable.isEmpty && controlsToDisable.isEmpty) return;

      if (controlsToEnable.isNotEmpty) {
        await SessaoMedia.enableControls(controlsToEnable);
        if (!_ownsSession) return;
      }
      if (controlsToDisable.isNotEmpty) {
        await SessaoMedia.disableControls(controlsToDisable);
        if (!_ownsSession) return;
      }

      _lastCanPlayPause = canPlayPause;
      _lastCanGoNext = canGoNext;
      _lastCanGoPrevious = canGoPrevious;
      _lastCanSeek = canSeek;
      _lastCanStop = canStop;
      _lastCanSkip = effectiveCanSkip;
      _lastCanSetSpeed = canSetSpeed;
      appLogger.d(
        'Media controls updated - Play/Pause: $canPlayPause, Previous: $canGoPrevious, '
        'Next: $canGoNext, Seek: $canSeek, Stop: $canStop, Skip: $effectiveCanSkip, '
        'Speed: $canSetSpeed',
      );
    } catch (e) {
      appLogger.w('Failed to set media controls enabled state', error: e);
    }
  }

  /// Mantém o contrato de segundo plano. No Android, o serviço em primeiro
  /// plano acompanha o estado confirmado da sessão Media3.
  Future<void> setBackgroundMode(bool enabled) async {
    if (!_ownsSession) return;
    try {
      await SessaoMedia.setBackgroundMode(enabled);
      appLogger.d('Media controls background mode: $enabled');
    } catch (e) {
      appLogger.w('Failed to set media controls background mode', error: e);
    }
  }

  /// Clear all media controls
  ///
  /// Should be called when playback stops or screen is disposed.
  Future<void> clear() async {
    _metadataGeneration++;
    _throttledUpdate.cancel();
    if (!_ownsSession) return;
    try {
      await SessaoMedia.clear();
      _throttledUpdate.cancel();
      _resetControlsCache();
      appLogger.d('Media controls cleared');
    } catch (e) {
      appLogger.w('Failed to clear media controls', error: e);
    }
  }

  void suspendUpdates() {
    if (_updatesSuspended || !_claimAvailableSession()) return;
    _updatesSuspended = true;
    _throttledUpdate.cancel();
    appLogger.d('Media controls updates suspended');
  }

  void resumeUpdates() {
    if (!_updatesSuspended) return;
    _updatesSuspended = false;
    appLogger.d('Media controls updates resumed');
  }

  /// Dispose resources
  void dispose() {
    _disposed = true;
    _metadataGeneration++;
    if (identical(_proprietario, this)) _proprietario = null;
    _throttledUpdate.cancel();
  }

  /// Build artist string from metadata
  ///
  /// For music tracks: the performing artist
  /// For episodes: "Show Name - Season X Episode Y"
  /// For movies: Director or studio
  /// For other content: Fallback to year or empty
  String _buildArtist(MediaItem metadata) {
    if (metadata.kind == MediaKind.track) {
      // Performing artist with album-artist fallback (compilations store the
      // track's own artist separately).
      return metadata.trackArtistTitle ?? '';
    }
    if (metadata.isEpisode) {
      final parts = <String>[];

      if (metadata.grandparentTitle != null) {
        parts.add(metadata.grandparentTitle!);
      }

      if (metadata.parentIndex != null && metadata.index != null) {
        parts.add('S${metadata.parentIndex} E${metadata.index}');
      } else if (metadata.parentTitle != null) {
        parts.add(metadata.parentTitle!);
      }

      return parts.join(' • ');
    } else if (metadata.isMovie) {
      if (metadata.year != null) {
        return metadata.year.toString();
      }
    }

    return '';
  }
}

/// Parameters for playback state update (used with throttle)
class _PlaybackStateParams {
  final PlaybackState state;
  final Duration position;
  final double speed;

  const _PlaybackStateParams({required this.state, required this.position, required this.speed});
}
