import '../media/media_stream.dart';
import '../media/media_version.dart';
import 'video_decode_capabilities.dart';

/// Pure ranking function for Jellyfin MediaSources based on device capabilities.
///
/// Returns the ordered list of sources by:
/// (a) hardware decodable, then software decodable (an undecodable source
///     only wins when nothing else plays)
/// (b) has Portuguese audio ('por', 'pt', etc.) or subtitle ('por', 'pt', 'pb', etc.)
/// (c) highest resolution the display can show (4K only on a 4K display)
List<Map<String, dynamic>> rankMediaSources(
  List<dynamic> sources, {
  VideoDecodeCapabilities? capabilities,
}) {
  final typedSources = sources.whereType<Map<String, dynamic>>().toList();
  if (typedSources.length <= 1) return typedSources;

  final caps = capabilities ?? VideoDecodeCapabilities.current;
  final display4k = caps.checkDisplaySupports4k();

  // Create an indexed list to preserve stable order
  final scored = <_ScoredSource>[];
  for (var i = 0; i < typedSources.length; i++) {
    final source = typedSources[i];
    final video = _extractVideoStream(source);
    final codec = video?['Codec']?.toString() ?? '';
    final profile = video?['Profile']?.toString();
    final bitDepth = _parseInt(video?['BitDepth']);
    final width = _parseInt(source['Width']) ?? _parseInt(video?['Width']);
    final height = _parseInt(source['Height']) ?? _parseInt(video?['Height']);

    final hwDecodable = caps.checkHardwareDecode(
      codec: codec,
      profile: profile,
      bitDepth: bitDepth,
      width: width,
      height: height,
    );

    final swDecodable = !hwDecodable &&
        VideoDecodeCapabilities.canSoftwareDecode(
          codec: codec,
          profile: profile,
          bitDepth: bitDepth,
          width: width,
          height: height,
        );

    final hasPt = _hasPortuguese(source);

    final h = height ?? 0;
    final int resolutionScore;
    if (display4k) {
      resolutionScore = h;
    } else {
      // Screen only shows up to 1080p: 4K is not counted as higher than 1080p
      if (h <= 1080) {
        resolutionScore = h;
      } else {
        resolutionScore = 0;
      }
    }

    scored.add(_ScoredSource(
      index: i,
      source: source,
      hwDecodable: hwDecodable,
      swDecodable: swDecodable,
      hasPt: hasPt,
      resolutionScore: resolutionScore,
    ));
  }

  scored.sort((a, b) {
    // (a) Decodable by hardware
    if (a.hwDecodable != b.hwDecodable) {
      return a.hwDecodable ? -1 : 1;
    }
    if (a.swDecodable != b.swDecodable) {
      return a.swDecodable ? -1 : 1;
    }
    // (b) Has Portuguese (audio or subtitle)
    if (a.hasPt != b.hasPt) {
      return a.hasPt ? -1 : 1;
    }
    // (c) Highest resolution display can show
    if (a.resolutionScore != b.resolutionScore) {
      return b.resolutionScore.compareTo(a.resolutionScore);
    }
    // Stable order
    return a.index.compareTo(b.index);
  });

  return scored.map((s) => s.source).toList();
}

extension VideoDecodeCapabilitiesExtension on VideoDecodeCapabilities {
  bool checkDisplaySupports4k() => VideoDecodeCapabilities.displaySupports4k;
}

bool isSourceHardwareDecodable(Map<String, dynamic> source, [VideoDecodeCapabilities? capabilities]) {
  final caps = capabilities ?? VideoDecodeCapabilities.current;
  final video = _extractVideoStream(source);
  if (video == null) return true;
  final codec = video['Codec']?.toString() ?? '';
  final profile = video['Profile']?.toString();
  final bitDepth = _parseInt(video['BitDepth']);
  final width = _parseInt(source['Width']) ?? _parseInt(video['Width']);
  final height = _parseInt(source['Height']) ?? _parseInt(video['Height']);

  return caps.checkHardwareDecode(
    codec: codec,
    profile: profile,
    bitDepth: bitDepth,
    width: width,
    height: height,
  );
}

bool isSourcePlayable(Map<String, dynamic> source, [VideoDecodeCapabilities? capabilities]) {
  final caps = capabilities ?? VideoDecodeCapabilities.current;
  final video = _extractVideoStream(source);
  if (video == null) return true;
  final codec = video['Codec']?.toString() ?? '';
  final profile = video['Profile']?.toString();
  final bitDepth = _parseInt(video['BitDepth']);
  final width = _parseInt(source['Width']) ?? _parseInt(video['Width']);
  final height = _parseInt(source['Height']) ?? _parseInt(video['Height']);

  final hw = caps.checkHardwareDecode(
    codec: codec,
    profile: profile,
    bitDepth: bitDepth,
    width: width,
    height: height,
  );
  if (hw) return true;

  return VideoDecodeCapabilities.canSoftwareDecode(
    codec: codec,
    profile: profile,
    bitDepth: bitDepth,
    width: width,
    height: height,
  );
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
  final is10Bit = (bitDepth != null && bitDepth > 8) ||
      (profile != null && (profile.contains('10') || profile.contains('hi10p')));

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

bool isVersionPlayable(MediaVersion version, [VideoDecodeCapabilities? capabilities]) {
  final caps = capabilities ?? VideoDecodeCapabilities.current;
  final codec = version.videoCodec ?? '';
  String? profile;
  int? bitDepth;
  for (final part in version.parts) {
    for (final stream in part.streams) {
      if (stream.kind == MediaStreamKind.video) {
        profile = stream.profile;
        // Sem BitDepth informado, HDR/DV ainda garante 10 bits.
        bitDepth = stream.bitDepth ?? ((stream.hdr || stream.dolbyVision) ? 10 : null);
        break;
      }
    }
  }

  final width = version.width;
  final height = version.height;

  final hw = caps.checkHardwareDecode(
    codec: codec,
    profile: profile,
    bitDepth: bitDepth,
    width: width,
    height: height,
  );
  if (hw) return true;

  return VideoDecodeCapabilities.canSoftwareDecode(
    codec: codec,
    profile: profile,
    bitDepth: bitDepth,
    width: width,
    height: height,
  );
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
      if (stream.kind != MediaStreamKind.video) continue;
      final profile = stream.profile?.toLowerCase() ?? '';
      // Acumula: basta uma parte em 10-bit; a parte seguinte não apaga a
      // marca da anterior (o `break` só sai do laço interno).
      is10Bit = is10Bit ||
          (stream.bitDepth ?? 0) > 8 ||
          profile.contains('10') ||
          stream.hdr ||
          stream.dolbyVision;
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
    if (stream is Map<String, dynamic> && stream['Type']?.toString().toLowerCase() == 'video') {
      return stream;
    }
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
  final Map<String, dynamic> source;
  final bool hwDecodable;
  final bool swDecodable;
  final bool hasPt;
  final int resolutionScore;

  _ScoredSource({
    required this.index,
    required this.source,
    required this.hwDecodable,
    required this.swDecodable,
    required this.hasPt,
    required this.resolutionScore,
  });
}
