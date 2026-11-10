import 'dart:math' as math;

import '../media/media_stream.dart';
import '../media/media_version.dart';
import 'video_decode_capabilities.dart';

/// Ranqueador de versões pelo aparelho, comum ao Jellyfin (`MediaSources[]`
/// cru) e ao Plex ([MediaVersion]). Ordem:
/// (a) decodifica por hardware, depois por software (versão que o aparelho não
///     decodifica só vence quando nada mais toca);
/// (b) tem português (áudio por/pt/pob, legenda pt/pb, título "Dublado");
/// (c) resolução mais alta que a tela mostra: numa tela 1080p a faixa 1080p
///     vai até 1088 linhas e o que passa disso fica logo abaixo dela
///     (1080p > 4K > 720p);
/// (d) ordem original (estável).
///
/// A escolha do usuário nunca passa por aqui: quem chama só ranqueia quando
/// não há versão escolhida (id ou assinatura).
List<Map<String, dynamic>> rankMediaSources(List<dynamic> sources, {VideoDecodeCapabilities? capabilities}) {
  final typedSources = sources.whereType<Map<String, dynamic>>().toList();
  if (typedSources.length <= 1) return typedSources;
  final order = _rank([for (final source in typedSources) _factsFromSource(source)], capabilities);
  return [for (final i in order) typedSources[i]];
}

/// Mesmo ranqueador sobre [MediaVersion] (Plex). Devolve os índices de
/// [versions] do melhor para o pior.
List<int> rankMediaVersions(List<MediaVersion> versions, {VideoDecodeCapabilities? capabilities}) {
  if (versions.length <= 1) return [for (var i = 0; i < versions.length; i++) i];
  return _rank([for (final version in versions) _factsFromVersion(version)], capabilities);
}

List<int> _rank(List<_VersionFacts> facts, VideoDecodeCapabilities? capabilities) {
  final caps = capabilities ?? VideoDecodeCapabilities.current;
  final display4k = caps.checkDisplaySupports4k();
  final scored = <_ScoredSource>[
    for (var i = 0; i < facts.length; i++)
      _ScoredSource(
        index: i,
        // Sem prova de tamanho, o ranqueador supõe o pior caso (4K): fonte
        // sem metadados não ganha prioridade de "1080p por hardware".
        decode: _decodeLevel(facts[i], caps, assumeWorstSize: true),
        hasPt: facts[i].hasPortuguese,
        resolutionScore: _resolutionScore(facts[i].width, facts[i].height, display4k: display4k),
      ),
  ];

  scored.sort((a, b) {
    // (a) hardware > software > nenhum
    if (a.decode != b.decode) return a.decode.index.compareTo(b.decode.index);
    // (b) português
    if (a.hasPt != b.hasPt) return a.hasPt ? -1 : 1;
    // (c) resolução que a tela mostra
    if (a.resolutionScore != b.resolutionScore) return b.resolutionScore.compareTo(a.resolutionScore);
    // (d) ordem estável
    return a.index.compareTo(b.index);
  });
  return [for (final s in scored) s.index];
}

/// Pontuação de resolução. A classe vem da altura ou da largura (1920x800,
/// cinemascope, ainda é 1080p). Acima do que a tela mostra, fica logo abaixo
/// da faixa da tela. Sem dimensão nenhuma, fica por último.
double _resolutionScore(int? width, int? height, {required bool display4k}) {
  if ((width == null || width <= 0) && (height == null || height <= 0)) return -1;
  var effective = math.max(height ?? 0, ((width ?? 0) * 9 / 16).round());
  final band = display4k ? 2160 : 1080;
  // 1088 linhas (alinhamento a 16) ainda é 1080p; 2176, ainda 4K.
  final tolerance = band + 16;
  if (effective > tolerance) return band - 0.5;
  if (effective > band) effective = band;
  return effective.toDouble();
}

extension VideoDecodeCapabilitiesExtension on VideoDecodeCapabilities {
  bool checkDisplaySupports4k() => VideoDecodeCapabilities.displaySupports4k;
}

/// O aparelho decodifica por hardware todo stream de vídeo da fonte. Sem
/// prova de tamanho, supõe 4K (serve de portão para reaproveitar uma versão
/// sem escolha do usuário: na dúvida, quem decide é o ranqueador).
bool isSourceHardwareDecodable(Map<String, dynamic> source, [VideoDecodeCapabilities? capabilities]) {
  final caps = capabilities ?? VideoDecodeCapabilities.current;
  return _decodeLevel(_factsFromSource(source), caps, assumeWorstSize: true) == _Decode.hardware;
}

/// Versão do Plex equivalente a [isSourceHardwareDecodable].
bool isVersionHardwareDecodable(MediaVersion version, [VideoDecodeCapabilities? capabilities]) {
  final caps = capabilities ?? VideoDecodeCapabilities.current;
  return _decodeLevel(_factsFromVersion(version), caps, assumeWorstSize: true) == _Decode.hardware;
}

/// A fonte toca no aparelho (hardware ou software) em todos os streams de
/// vídeo. Sem prova de tamanho não acusa o hardware (evita aviso falso), mas
/// também não aprova software em 4K.
bool isSourcePlayable(Map<String, dynamic> source, [VideoDecodeCapabilities? capabilities]) {
  final caps = capabilities ?? VideoDecodeCapabilities.current;
  return _decodeLevel(_factsFromSource(source), caps) != _Decode.none;
}

String formatMediaSourceReason(Map<String, dynamic> source) {
  final video = _extractVideoStream(source);
  final codec = video?['Codec']?.toString().toUpperCase() ?? 'VÍDEO';
  final normalizedCodec = switch (codec.toLowerCase()) {
    'h264' || 'avc' || 'avc1' => 'H.264',
    'hevc' || 'h265' || 'hev1' => 'HEVC',
    'av1' || 'av01' => 'AV1',
    'vp9' => 'VP9',
    _ => codec,
  };

  final bitDepth = _parseInt(video?['BitDepth']);
  final profile = video?['Profile']?.toString().toLowerCase();
  final is10Bit =
      (bitDepth != null && bitDepth > 8) || (profile != null && (profile.contains('10') || profile.contains('hi10p')));

  final width = _parseInt(source['Width']) ?? _parseInt(video?['Width']) ?? 0;
  final height = _parseInt(source['Height']) ?? _parseInt(video?['Height']) ?? 0;

  final String resLabel;
  if (height >= 2160 || width >= 3840) {
    resLabel = '4K';
  } else if (height >= 1080 || width >= 1920) {
    resLabel = '1080p';
  } else if (height >= 720 || width >= 1280) {
    resLabel = '720p';
  } else if (height > 0) {
    resLabel = '${height}p';
  } else {
    resLabel = '';
  }

  final parts = <String>[normalizedCodec];
  if (is10Bit) {
    parts.add('10-bit');
  }
  if (resLabel.isNotEmpty) {
    parts.add('em $resLabel');
  }
  return parts.join(' ');
}

/// A versão toca no aparelho: todo stream de vídeo real, em todas as partes,
/// passa (capa embutida não conta); o primeiro que não passa reprova a
/// versão. Mesmo critério de tamanho do [isSourcePlayable].
bool isVersionPlayable(MediaVersion version, [VideoDecodeCapabilities? capabilities]) {
  final caps = capabilities ?? VideoDecodeCapabilities.current;
  return _decodeLevel(_factsFromVersion(version), caps) != _Decode.none;
}

String formatVersionReason(MediaVersion version) {
  final codec = version.videoCodec?.toUpperCase() ?? 'VÍDEO';
  final normalizedCodec = switch (codec.toLowerCase()) {
    'h264' || 'avc' || 'avc1' => 'H.264',
    'hevc' || 'h265' || 'hev1' => 'HEVC',
    'av1' || 'av01' => 'AV1',
    'vp9' => 'VP9',
    _ => codec,
  };

  // Mesma regra do isVersionPlayable: BitDepth, perfil (Main 10, High 10,
  // Hi10P) ou HDR/DV.
  bool is10Bit = false;
  for (final part in version.parts) {
    for (final stream in part.streams) {
      if (stream.kind != MediaStreamKind.video || _isImageCodec(stream.codec)) continue;
      final profile = stream.profile?.toLowerCase() ?? '';
      // Acumula: basta uma parte em 10-bit; a parte seguinte não apaga a
      // marca da anterior (o `break` só sai do laço interno).
      is10Bit = is10Bit || (stream.bitDepth ?? 0) > 8 || profile.contains('10') || stream.hdr || stream.dolbyVision;
      break;
    }
  }

  final width = version.width ?? 0;
  final height = version.height ?? 0;
  final res = version.videoResolution?.toLowerCase() ?? '';

  final String resLabel;
  if (res == '4k' || height >= 2160 || width >= 3840) {
    resLabel = '4K';
  } else if (res == '1080' || res == '1080p' || height >= 1080 || width >= 1920) {
    resLabel = '1080p';
  } else if (res == '720' || res == '720p' || height >= 720 || width >= 1280) {
    resLabel = '720p';
  } else if (height > 0) {
    resLabel = '${height}p';
  } else {
    resLabel = '';
  }

  final parts = <String>[normalizedCodec];
  if (is10Bit) {
    parts.add('10-bit');
  }
  if (resLabel.isNotEmpty) {
    parts.add('em $resLabel');
  }
  return parts.join(' ');
}

Map<String, dynamic>? _extractVideoStream(Map<String, dynamic> source) {
  final streams = source['MediaStreams'];
  if (streams is! List) return null;
  for (final stream in streams) {
    if (stream is Map<String, dynamic> && _isRealJellyfinVideo(stream)) return stream;
  }
  return null;
}

/// Codecs de imagem: capa embutida (attached_pic) aparece como stream de
/// vídeo em MKV/MP4, mas não é o filme e não passa pelo decodificador.
const _imageCodecs = {'mjpeg', 'mjpg', 'jpeg', 'jpg', 'png', 'bmp', 'gif', 'webp', 'tiff'};

bool _isImageCodec(String? codec) => codec != null && _imageCodecs.contains(codec.toLowerCase());

bool _isRealJellyfinVideo(Map<String, dynamic> stream) =>
    stream['Type']?.toString().toLowerCase() == 'video' && !_isImageCodec(stream['Codec']?.toString());

enum _Decode { hardware, software, none }

/// Um stream de vídeo a decodificar. [width]/[height] nulos = sem prova.
class _VideoTrack {
  final String codec;
  final String? profile;
  final int? bitDepth;
  final int? width;
  final int? height;

  const _VideoTrack({required this.codec, this.profile, this.bitDepth, this.width, this.height});
}

/// O que o ranqueador sabe de uma versão, venha do Jellyfin ou do Plex.
class _VersionFacts {
  final List<_VideoTrack> tracks;
  final int? width;
  final int? height;
  final bool hasPortuguese;

  const _VersionFacts({required this.tracks, this.width, this.height, required this.hasPortuguese});
}

/// Pior nível entre os streams: um stream sem decodificação reprova a versão.
_Decode _decodeLevel(_VersionFacts facts, VideoDecodeCapabilities caps, {bool assumeWorstSize = false}) {
  // Sem faixa de vídeo não há prova de hardware: o ranqueador (e o portão de
  // reaproveitar índice) trata como software, abaixo de quem tem prova; a
  // tocabilidade segue leniente e não acusa a versão.
  if (facts.tracks.isEmpty) return assumeWorstSize ? _Decode.software : _Decode.hardware;
  var worst = _Decode.hardware;
  for (final track in facts.tracks) {
    final sizeKnown = track.width != null || track.height != null;
    // Sem tamanho: o ranqueador supõe 4K; a checagem de tocabilidade só não
    // aprova software (4K em software não roda em TV/celular).
    final hwWidth = sizeKnown || !assumeWorstSize ? track.width : 3840;
    final hwHeight = sizeKnown || !assumeWorstSize ? track.height : 2160;
    final level =
        caps.checkHardwareDecode(
          codec: track.codec,
          profile: track.profile,
          bitDepth: track.bitDepth,
          width: hwWidth,
          height: hwHeight,
        )
        ? _Decode.hardware
        : VideoDecodeCapabilities.canSoftwareDecode(
            codec: track.codec,
            profile: track.profile,
            bitDepth: track.bitDepth,
            width: sizeKnown ? track.width : 3840,
            height: sizeKnown ? track.height : 2160,
          )
        ? _Decode.software
        : _Decode.none;
    if (level.index > worst.index) worst = level;
    if (worst == _Decode.none) break;
  }
  return worst;
}

_VersionFacts _factsFromSource(Map<String, dynamic> source) {
  final streams = source['MediaStreams'];
  final videos = <Map<String, dynamic>>[
    if (streams is List)
      for (final stream in streams)
        if (stream is Map<String, dynamic> && _isRealJellyfinVideo(stream)) stream,
  ];
  final sourceWidth = _parseInt(source['Width']);
  final sourceHeight = _parseInt(source['Height']);
  final sourceInferred = _dimensionsFromText([source['Name']?.toString()]);
  final tracks = <_VideoTrack>[];
  for (final video in videos) {
    var width = sourceWidth ?? _parseInt(video['Width']);
    var height = sourceHeight ?? _parseInt(video['Height']);
    if (width == null && height == null) {
      final inferred =
          _dimensionsFromText([video['DisplayTitle']?.toString(), video['Title']?.toString()]) ?? sourceInferred;
      width = inferred?.$1;
      height = inferred?.$2;
    }
    tracks.add(
      _VideoTrack(
        codec: video['Codec']?.toString() ?? '',
        profile: video['Profile']?.toString(),
        bitDepth: _parseInt(video['BitDepth']),
        width: width,
        height: height,
      ),
    );
  }
  final first = tracks.isEmpty ? null : tracks.first;
  return _VersionFacts(
    tracks: tracks,
    width: first?.width ?? sourceWidth ?? sourceInferred?.$1,
    height: first?.height ?? sourceHeight ?? sourceInferred?.$2,
    hasPortuguese: _hasPortuguese(source),
  );
}

_VersionFacts _factsFromVersion(MediaVersion version) {
  var width = version.width;
  var height = version.height;
  final videos = <MediaStream>[
    for (final part in version.parts)
      for (final stream in part.streams)
        if (stream.kind == MediaStreamKind.video && !_isImageCodec(stream.codec)) stream,
  ];
  if (width == null && height == null) {
    final inferred = _dimensionsFromText([
      version.videoResolution,
      for (final video in videos) video.displayTitle,
      version.name,
    ]);
    width = inferred?.$1;
    height = inferred?.$2;
  }
  final tracks = <_VideoTrack>[
    for (final video in videos)
      _VideoTrack(
        codec: video.codec ?? version.videoCodec ?? '',
        profile: video.profile,
        // Sem BitDepth informado, HDR/DV ainda garante 10 bits.
        bitDepth: video.bitDepth ?? ((video.hdr || video.dolbyVision) ? 10 : null),
        width: width,
        height: height,
      ),
  ];
  // Sem streams detalhados (lista do servidor sem partes): vale o codec da
  // versão.
  if (tracks.isEmpty && (version.videoCodec ?? '').isNotEmpty) {
    tracks.add(_VideoTrack(codec: version.videoCodec!, width: width, height: height));
  }
  return _VersionFacts(tracks: tracks, width: width, height: height, hasPortuguese: _versionHasPortuguese(version));
}

/// Dimensões a partir do texto ("4k", "2160p", "UHD", "1080", "720p", "sd"),
/// quando o servidor não manda largura/altura. O primeiro texto que casar
/// vence; nada casando = sem prova (nulo).
(int, int)? _dimensionsFromText(Iterable<String?> texts) {
  for (final raw in texts) {
    final text = raw?.trim().toLowerCase();
    if (text == null || text.isEmpty) continue;
    if (RegExp(r'(^|[^a-z0-9])(8k|4320p?)([^a-z0-9]|$)').hasMatch(text)) return (7680, 4320);
    if (RegExp(r'(^|[^a-z0-9])(4k|2160p?|uhd)([^a-z0-9]|$)').hasMatch(text)) return (3840, 2160);
    if (RegExp(r'(^|[^a-z0-9])(1080[pi]?|fhd)([^a-z0-9]|$)').hasMatch(text)) return (1920, 1080);
    if (RegExp(r'(^|[^a-z0-9])(720p?|hd)([^a-z0-9]|$)').hasMatch(text)) return (1280, 720);
    // Mesmo delimitador das linhas acima: "Filme 480p" casa, "sdr" não.
    if (RegExp(r'(^|[^a-z0-9])(sd|480[pi]?|576[pi]?)([^a-z0-9]|$)').hasMatch(text)) return (720, 480);
  }
  return null;
}

bool _hasPortuguese(Map<String, dynamic> source) {
  final streams = source['MediaStreams'];
  if (streams is! List) return false;
  for (final stream in streams) {
    if (stream is! Map<String, dynamic>) continue;
    final type = stream['Type']?.toString().toLowerCase();
    final lang = stream['Language']?.toString().toLowerCase() ?? '';
    final title = stream['Title']?.toString().toLowerCase() ?? '';

    final isPt = _isPtLanguage(lang) || title.contains('portug') || title.contains('dublado');
    if (type == 'audio' && isPt) return true;
    if (type == 'subtitle' && (isPt || lang == 'pb')) return true;
  }
  return false;
}

bool _versionHasPortuguese(MediaVersion version) {
  for (final part in version.parts) {
    for (final stream in part.streams) {
      if (stream.kind != MediaStreamKind.audio && stream.kind != MediaStreamKind.subtitle) continue;
      final code = stream.languageCode?.toLowerCase() ?? '';
      final lang = stream.language?.toLowerCase() ?? '';
      final title = '${stream.title ?? ''} ${stream.displayTitle ?? ''}'.toLowerCase();
      if (_isPtLanguage(code) ||
          _isPtLanguage(lang) ||
          lang.startsWith('portug') ||
          title.contains('portug') ||
          title.contains('dublado')) {
        return true;
      }
    }
  }
  return false;
}

bool _isPtLanguage(String lang) {
  return lang == 'por' ||
      lang == 'pt' ||
      lang == 'pob' ||
      lang == 'pb' ||
      lang == 'pt-br' ||
      lang == 'pt_br' ||
      lang == 'pt-pt' ||
      lang == 'pt_pt';
}

int? _parseInt(dynamic val) {
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

class _ScoredSource {
  final int index;
  final _Decode decode;
  final bool hasPt;
  final double resolutionScore;

  _ScoredSource({required this.index, required this.decode, required this.hasPt, required this.resolutionScore});
}
