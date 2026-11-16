import 'package:flutter/services.dart';

/// Comandos que o proprietário da reprodução autoriza na sessão do sistema.
enum MediaControl { play, pause, stop, next, previous, seek, skipForward, skipBackward, changeSpeed }

enum PlaybackState { none, stopped, paused, playing, buffering, ended, error }

/// Evento de transporte; posições e intervalos da ponte usam milissegundos.
abstract class MediaControlEvent {
  const MediaControlEvent();

  factory MediaControlEvent.fromMap(Map<dynamic, dynamic> mapa) {
    Duration? intervalo() => mapa['interval'] is num ? Duration(milliseconds: (mapa['interval'] as num).round()) : null;
    return switch (mapa['type']) {
      'play' => const PlayEvent(),
      'pause' => const PauseEvent(),
      'stop' => const StopEvent(),
      'togglePlayPause' => const TogglePlayPauseEvent(),
      'next' || 'nextTrack' => const NextTrackEvent(),
      'previous' || 'previousTrack' => const PreviousTrackEvent(),
      'seek' => SeekEvent(Duration(milliseconds: (mapa['position'] as num).round())),
      'skipForward' => SkipForwardEvent(intervalo()),
      'skipBackward' => SkipBackwardEvent(intervalo()),
      'setSpeed' => SetSpeedEvent((mapa['speed'] as num).toDouble()),
      'audioInterruptionBegan' => const AudioInterruptionBeganEvent(),
      'audioInterruptionEnded' => AudioInterruptionEndedEvent(shouldResume: mapa['shouldResume'] == true),
      'audioRouteOldDeviceUnavailable' => const AudioRouteOldDeviceUnavailableEvent(),
      'audioRouteNewDeviceAvailable' => const AudioRouteNewDeviceAvailableEvent(),
      _ => throw ArgumentError('Comando de mídia desconhecido'),
    };
  }
}

class PlayEvent extends MediaControlEvent {
  const PlayEvent();
}

class PauseEvent extends MediaControlEvent {
  const PauseEvent();
}

class StopEvent extends MediaControlEvent {
  const StopEvent();
}

class TogglePlayPauseEvent extends MediaControlEvent {
  const TogglePlayPauseEvent();
}

class NextTrackEvent extends MediaControlEvent {
  const NextTrackEvent();
}

class PreviousTrackEvent extends MediaControlEvent {
  const PreviousTrackEvent();
}

class AudioInterruptionBeganEvent extends MediaControlEvent {
  const AudioInterruptionBeganEvent();
}

class AudioRouteOldDeviceUnavailableEvent extends MediaControlEvent {
  const AudioRouteOldDeviceUnavailableEvent();
}

class AudioRouteNewDeviceAvailableEvent extends MediaControlEvent {
  const AudioRouteNewDeviceAvailableEvent();
}

class AudioInterruptionEndedEvent extends MediaControlEvent {
  const AudioInterruptionEndedEvent({required this.shouldResume});
  final bool shouldResume;
}

class SeekEvent extends MediaControlEvent {
  const SeekEvent(this.position);
  final Duration position;
}

class SkipForwardEvent extends MediaControlEvent {
  const SkipForwardEvent(this.interval);
  final Duration? interval;
}

class SkipBackwardEvent extends MediaControlEvent {
  const SkipBackwardEvent(this.interval);
  final Duration? interval;
}

class SetSpeedEvent extends MediaControlEvent {
  const SetSpeedEvent(this.speed);
  final double speed;
}

/// Metadados pequenos. No Android, a arte é carregada pela camada nativa.
class MediaMetadata {
  const MediaMetadata({
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.artwork,
    this.artworkUrl,
    this.mediaId,
    this.isVideo = true,
  });
  final String title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final Uint8List? artwork;
  final String? artworkUrl;
  final String? mediaId;
  final bool isVideo;

  Map<String, Object?> toMap() => {
    'title': title,
    if (artist != null) 'artist': artist,
    if (album != null) 'album': album,
    if (duration != null) 'duration': duration!.inMilliseconds,
    if (artwork != null) 'artwork': artwork,
    if (artworkUrl != null) 'artworkUrl': artworkUrl,
    if (mediaId != null) 'mediaId': mediaId,
    'isVideo': isVideo,
  };
}

class MediaPlaybackState {
  const MediaPlaybackState({required this.state, required this.position, this.speed = 1.0});
  final PlaybackState state;
  final Duration position;
  final double speed;
  Map<String, Object?> toMap() => {'state': state.name, 'position': position.inMilliseconds, 'speed': speed};
}

/// Porta única para vídeo e música; não cria uma sessão por instância Dart.
abstract final class SessaoMedia {
  static const metodos = MethodChannel('app.heisuca.sessao/metodos');
  static const eventos = EventChannel('app.heisuca.sessao/eventos');
  static final Stream<MediaControlEvent> controlEvents = eventos.receiveBroadcastStream().map((dynamic evento) {
    if (evento is! Map) throw ArgumentError('Evento de mídia inválido');
    return MediaControlEvent.fromMap(evento);
  });

  static Future<void> setMetadata(MediaMetadata metadata) =>
      metodos.invokeMethod<void>('setMetadata', metadata.toMap());
  static Future<void> setPlaybackState(MediaPlaybackState state) =>
      metodos.invokeMethod<void>('setPlaybackState', state.toMap());
  static Future<void> enableControls(List<MediaControl> controls) =>
      metodos.invokeMethod<void>('enableControls', controls.map((c) => c.name).toList());
  static Future<void> disableControls(List<MediaControl> controls) =>
      metodos.invokeMethod<void>('disableControls', controls.map((c) => c.name).toList());
  static Future<void> setSkipIntervals({Duration? forward, Duration? backward}) => metodos.invokeMethod<void>(
    'setSkipIntervals',
    {if (forward != null) 'forward': forward.inSeconds, if (backward != null) 'backward': backward.inSeconds},
  );
  static Future<void> setBackgroundMode(bool enabled) =>
      metodos.invokeMethod<void>('setBackgroundMode', {'enabled': enabled});
  static Future<void> clear() => metodos.invokeMethod<void>('clear');
}
