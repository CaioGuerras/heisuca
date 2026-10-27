import 'package:heisuca/mpv/mpv.dart';
import 'watch_together_fakes.dart';

/// Player falso com as faixas de um anime real do acervo (áudio JA/PT, legenda ASS em português).
class HeisucaHudPlayer extends FakeSyncPlayer {
  HeisucaHudPlayer() : super(position: const Duration(minutes: 18, seconds: 42), hasRenderedFrame: true, playing: true);
  static const ja = AudioTrack(id: '1', language: 'jpn', codec: 'eac3', channels: 6);
  static const pt = AudioTrack(id: '2', language: 'por', codec: 'aac', channels: 2);
  static const sub = SubtitleTrack(id: '3', language: 'por', codec: 'ass', title: 'Brazil');
  @override
  bool get supportsSecondarySubtitles => true;
  @override
  Future<bool> isHdrOutputSupported() async => false;
  @override
  PlayerState get state => super.state.copyWith(
    tracks: const Tracks(audio: [ja, pt], subtitle: [sub]),
    track: const TrackSelection(audio: ja, subtitle: sub));
}
