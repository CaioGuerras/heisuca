import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/async_singleton.dart';
import '../utils/device_channel.dart';
import 'settings_service.dart';

/// The video codecs Heisuca negotiates with a media server, most efficient
/// first. Every transcode target lists them in this order so a server able to
/// encode more than one picks the best; the hardware probe and the user's
/// refusals only remove entries, never reorder them.
enum RankedVideoCodec {
  av1('av1'),
  hevc('hevc'),
  h264('h264');

  const RankedVideoCodec(this.id);

  /// Codec name on the wire and in [SettingsService.refusedVideoCodecs].
  final String id;

  /// H.264 is the one output every server can encode to. Refusing it would
  /// leave a transcode with nothing to produce, so it is always accepted.
  bool get isRefusable => this != h264;

  /// The entry a server-reported codec name belongs to, aliases included, or
  /// null for a codec outside the ranked list (VP9, MPEG-2, …).
  static RankedVideoCodec? fromServerCodec(String? codec) => switch (codec?.toLowerCase()) {
    'av1' => av1,
    'hevc' || 'h265' || 'hev1' => hevc,
    'h264' || 'avc' || 'avc1' => h264,
    _ => null,
  };
}

/// Which [RankedVideoCodec]s this device accepts from a media server.
///
/// Two inputs narrow the list. The hardware probe: mpv software-decodes HEVC
/// and AV1 everywhere, so the probe answers "can we decode it without
/// dropping frames", not "can we decode it". Without a hardware decoder a
/// phone or TV box has to ask the server to transcode instead of taking the
/// original stream, and must not offer that codec as a transcode target.
///
/// Only Android (`MediaCodecList`) and iOS/tvOS (`VTIsHardwareDecodeSupported`)
/// answer the probe. Desktop deliberately does not implement it: a
/// pre-Kaby-Lake Mac has no hardware HEVC decoder and an M1 no hardware AV1
/// one, yet both software-decode in real time, so narrowing there would force
/// transcodes for nothing. An unanswered or failed probe reports support — the
/// advertised codec list must never narrow on missing data.
///
/// The user's refusals cover what the probe cannot: a desktop too weak to
/// software-decode a codec (a dual-core Atom, #2443). The setting is shown
/// only on desktop and is device-local, so elsewhere the probe alone decides.
///
/// The probe is latched once during the startup device-capabilities phase;
/// refusals are read live, so a changed setting applies to the next
/// negotiation.
class VideoDecodeCapabilities {
  VideoDecodeCapabilities._();

  static final AsyncSingleton<VideoDecodeCapabilities> _singleton = AsyncSingleton();

  /// Null until the platform answers, so [describeSync] can tell a measured
  /// "yes" from an assumed one. Both are set together or not at all.
  bool? _hardwareHevc;
  bool? _hardwareAv1;
  bool? _displaySupports4k;
  Map<String, List<String>>? _codecProfiles;
  Map<String, String>? _codecMaxResolutions;
  Map<String, bool>? _codecHardware;

  /// Get the singleton, probing the platform's decoders on first call.
  static Future<VideoDecodeCapabilities> getInstance() =>
      _singleton.getInstance(VideoDecodeCapabilities._, (instance) => instance._detect());

  static VideoDecodeCapabilities? get instanceOrNull => _singleton.instance;

  static VideoDecodeCapabilities get current => _singleton.instance ?? VideoDecodeCapabilities._();

  Future<void> _detect() async {
    try {
      final result = await deviceChannel.invokeMapMethod<String, dynamic>('getVideoDecodeCapabilities');
      if (result == null) return;
      _applyResult(result);
    } on MissingPluginException {
      // Desktop, or a stale native build — keep advertising both.
    } on PlatformException {
      // Decoder enumeration failed — keep advertising both.
    }
  }

  void _applyResult(Map<String, dynamic> result) {
    _hardwareHevc = result['hevc'] == true;
    _hardwareAv1 = result['av1'] == true;
    if (result.containsKey('displaySupports4k') || result.containsKey('display_4k')) {
      _displaySupports4k = result['displaySupports4k'] == true || result['display_4k'] == true;
    }
    final rawCodecs = result['codecs'];
    if (rawCodecs is Map) {
      _codecProfiles = {};
      _codecMaxResolutions = {};
      _codecHardware = {};
      rawCodecs.forEach((k, v) {
        if (v is Map) {
          final codecName = k.toString().toLowerCase();
          _codecHardware![codecName] = v['hardware'] == true;
          final profiles = v['profiles'];
          if (profiles is List) {
            _codecProfiles![codecName] = profiles.map((p) => p.toString().toLowerCase()).toList();
          }
          final maxRes = v['max_resolution'];
          if (maxRes != null) {
            _codecMaxResolutions![codecName] = maxRes.toString().toLowerCase();
          }
        }
      });
    }
    final rawProfiles = result['profiles'];
    if (rawProfiles is Map && _codecProfiles == null) {
      _codecProfiles = {};
      rawProfiles.forEach((k, v) {
        if (v is List) {
          _codecProfiles![k.toString().toLowerCase()] = v.map((p) => p.toString().toLowerCase()).toList();
        }
      });
    }
  }

  /// Whether the display supports 4K playback (3840x2160 or higher).
  /// If unprobed or probe failed, defaults to true ("sonda falhou = assume suporte").
  static bool get displaySupports4k => _singleton.instance?._displaySupports4k ?? true;

  /// Check whether hardware decode supports [codec], [profile], [bitDepth] and [width]/[height].
  /// If unprobed or probe failed, defaults to true.
  static bool canHardwareDecode({
    required String codec,
    String? profile,
    int? bitDepth,
    int? width,
    int? height,
  }) {
    final instance = _singleton.instance;
    if (instance == null) return true;
    return instance.checkHardwareDecode(
      codec: codec,
      profile: profile,
      bitDepth: bitDepth,
      width: width,
      height: height,
    );
  }

  bool checkHardwareDecode({
    required String codec,
    String? profile,
    int? bitDepth,
    int? width,
    int? height,
  }) {
    final normCodec = _normalizeCodec(codec);
    if (normCodec == null) return true;

    final ranked = RankedVideoCodec.fromServerCodec(codec);
    if (ranked != null && isRefusedByUser(ranked)) return false;

    if (normCodec == 'hevc') {
      if (_hardwareHevc == false) return false;
    } else if (normCodec == 'av1') {
      if (_hardwareAv1 == false) return false;
    }

    if (_codecHardware != null && _codecHardware![normCodec] == false) {
      return false;
    }

    final is10Bit = (bitDepth != null && bitDepth > 8) ||
        (profile != null && (profile.contains('10') || profile.toLowerCase().contains('hi10p')));

    final profiles = _codecProfiles?[normCodec];
    if (profiles != null) {
      if (normCodec == 'h264') {
        if (is10Bit && !profiles.contains('high10')) return false;
      } else if (normCodec == 'hevc') {
        if (is10Bit && !profiles.contains('main10')) return false;
      } else if (normCodec == 'av1') {
        if (is10Bit && !profiles.contains('main10')) return false;
      } else if (normCodec == 'vp9') {
        if (is10Bit && !profiles.contains('2') && !profiles.contains('profile2')) return false;
      }
    } else {
      if (normCodec == 'h264' && is10Bit) {
        if (_codecHardware != null) return false;
      }
    }

    final is4k = (width != null && width > 1920) || (height != null && height > 1080);
    if (is4k) {
      final maxRes = _codecMaxResolutions?[normCodec];
      if (maxRes != null && maxRes != '4k60' && maxRes != '4k24' && maxRes != 'supported') {
        return false;
      }
    }

    return true;
  }

  /// Check whether the device can smoothly software-decode the stream.
  /// On mobile/TV (Android/iOS), 4K, 10-bit HEVC/H.264, and AV1 drop frames or artifact.
  static bool canSoftwareDecode({
    required String codec,
    String? profile,
    int? bitDepth,
    int? width,
    int? height,
  }) {
    if (kIsWeb) return false;
    // On desktop, CPUs software-decode adequately.
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      return true;
    }

    final is10Bit = (bitDepth != null && bitDepth > 8) ||
        (profile != null && (profile.contains('10') || profile.toLowerCase().contains('hi10p')));
    final is4k = (width != null && width > 1920) || (height != null && height > 1080);

    if (is4k) return false;
    final normCodec = _normalizeCodec(codec);
    if (normCodec == 'hevc' && is10Bit) return false;
    if (normCodec == 'h264' && is10Bit) return false;
    if (normCodec == 'av1') return false;

    return true;
  }

  static String? _normalizeCodec(String? codec) => switch (codec?.toLowerCase()) {
    'h264' || 'avc' || 'avc1' => 'h264',
    'hevc' || 'h265' || 'hev1' => 'hevc',
    'av1' || 'av01' => 'av1',
    'vp9' => 'vp9',
    _ => codec?.toLowerCase(),
  };

  /// Whether [codec] should be advertised to a media server. Safe before init.
  static bool accepts(RankedVideoCodec codec) {
    if (isRefusedByUser(codec)) return false;
    final instance = _singleton.instance;
    return switch (codec) {
      RankedVideoCodec.av1 => instance?._hardwareAv1 ?? true,
      RankedVideoCodec.hevc => instance?._hardwareHevc ?? true,
      RankedVideoCodec.h264 => true,
    };
  }

  /// Transcode outputs to offer, in [RankedVideoCodec] order. Never empty:
  /// H.264 cannot be refused.
  static List<RankedVideoCodec> get transcodeVideoCodecs => [
    for (final codec in RankedVideoCodec.values)
      if (accepts(codec)) codec,
  ];

  /// Whether the user refused [codec] in settings, independent of the probe.
  static bool isRefusedByUser(RankedVideoCodec codec) {
    if (!codec.isRefusable) return false;
    final settings = SettingsService.instanceOrNull;
    return settings != null && settings.read(SettingsService.refusedVideoCodecs).contains(codec.id);
  }

  /// One-line summary for the startup log and bug-report headers, e.g.
  /// `hevc=hw av1=none` on an Apple TV 4K, or `unprobed` on desktop, with
  /// ` refused=hevc` appended when the user refused a codec. Answers "did
  /// this device really report an AV1 decoder" when a transcode stutters.
  static String describeSync() {
    final instance = _singleton.instance;
    if (instance == null) return 'unknown';
    final hevc = instance._hardwareHevc;
    final av1 = instance._hardwareAv1;
    final probe = hevc == null || av1 == null ? 'unprobed' : 'hevc=${hevc ? 'hw' : 'none'} av1=${av1 ? 'hw' : 'none'}';
    final refused = [
      for (final codec in RankedVideoCodec.values)
        if (isRefusedByUser(codec)) codec.id,
    ];
    return refused.isEmpty ? probe : '$probe refused=${refused.join(',')}';
  }

  /// Test-only: drop the memoized probe, optionally seeding measured results
  /// so the sync accessors can be exercised without a platform channel.
  @visibleForTesting
  static void debugReset({
    bool? hardwareHevc,
    bool? hardwareAv1,
    bool? displaySupports4k,
    Map<String, bool>? codecHardware,
    Map<String, List<String>>? codecProfiles,
    Map<String, String>? codecMaxResolutions,
  }) {
    if (hardwareHevc == null &&
        hardwareAv1 == null &&
        displaySupports4k == null &&
        codecHardware == null &&
        codecProfiles == null &&
        codecMaxResolutions == null) {
      _singleton.debugReset();
      return;
    }
    final instance = _singleton.instance ?? VideoDecodeCapabilities._();
    _singleton.debugReset(instance: instance);
    instance._hardwareHevc = hardwareHevc;
    instance._hardwareAv1 = hardwareAv1;
    instance._displaySupports4k = displaySupports4k;
    instance._codecHardware = codecHardware;
    instance._codecProfiles = codecProfiles;
    instance._codecMaxResolutions = codecMaxResolutions;
  }
}
