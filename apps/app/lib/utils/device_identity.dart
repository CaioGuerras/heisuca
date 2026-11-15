import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:unorm_dart/unorm_dart.dart';

import 'app_logger.dart';
import 'platform_detector.dart';

/// Nome do aparelho para mostrar: não repete a marca quando o modelo já a traz
/// ("motorola" + "motorola edge 60 pro" vira "Motorola Edge 60 Pro") e põe a
/// primeira letra maiúscula só nas palavras escritas todas em minúsculas (e só se o nome começar em minúscula, como vem do sistema)
/// ("SM-S921B" fica como está). Se [nomeSalvo] vier, ele também é limpo.
String nomeDoAparelho(String marca, String modelo, [String? nomeSalvo]) {
  final m = marca.trim(), mod = modelo.trim();
  final jaTemMarca = m.isEmpty || mod.toLowerCase().startsWith(m.toLowerCase());
  final base = (nomeSalvo != null && nomeSalvo.trim().isNotEmpty) ? nomeSalvo : (jaTemMarca ? mod : '$m $mod');
  final palavras = base.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  // Remove palavras repetidas em sequência ("motorola motorola edge" -> "motorola edge").
  final limpas = <String>[];
  for (final p in palavras) {
    if (limpas.isNotEmpty && limpas.last.toLowerCase() == p.toLowerCase()) continue;
    limpas.add(p);
  }
  // Nome que já começa com maiúscula foi escrito por gente: não mexe.
  if (limpas.isEmpty || limpas.first[0] != limpas.first[0].toLowerCase()) return limpas.join(' ');
  return limpas.map((p) => p == p.toLowerCase() && p.isNotEmpty ? p[0].toUpperCase() + p.substring(1) : p).join(' ');
}

/// What this install should call itself when talking to media servers and
/// companion peers: a real platform name, the hardware model, and the
/// user-facing device name (Plex dashboards show it as the "Player";
/// Jellyfin as the "Device").
class DeviceIdentity {
  /// 'Android' | 'iOS' | 'tvOS' | 'macOS' | 'Windows' | 'Linux', falling back
  /// to [Platform.operatingSystem] when detection fails.
  final String platform;

  /// Hardware model for `X-Plex-Device`, e.g. 'AFTKM' (Fire TV), 'iPhone',
  /// 'Apple TV'. Null when unresolvable.
  final String? deviceModel;

  /// Friendly, usually user-assigned name (Settings > About > Device name on
  /// Android, computer name on desktop). Null when unresolvable — callers
  /// pick their own fallback. May contain characters that are not valid in
  /// HTTP headers; pass through [sanitizeHeaderValue] before sending.
  final String? deviceName;

  final bool isTv;

  const DeviceIdentity({required this.platform, this.deviceModel, this.deviceName, this.isTv = false});
}

/// Resolves the device identity once per process and memoizes it. Never
/// throws — platform-channel failures (tests, exotic platforms) degrade to
/// [Platform.operatingSystem] with null name/model.
class DeviceIdentityService {
  DeviceIdentityService._();

  static Future<DeviceIdentity>? _cached;

  static Future<DeviceIdentity> resolve() => _cached ??= _resolve();

  @visibleForTesting
  static void debugOverride(DeviceIdentity? identity) {
    _cached = identity == null ? null : Future.value(identity);
  }

  static Future<DeviceIdentity> _resolve() async {
    final deviceInfo = DeviceInfoPlugin();
    final isTv = PlatformDetector.isTV();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final assignedName = await TvDetectionService.getAndroidDeviceName();
        return DeviceIdentity(
          platform: 'Android',
          deviceModel: androidInfo.model,
          deviceName: nomeDoAparelho(androidInfo.brand, androidInfo.model, assignedName),
          isTv: isTv,
        );
      }
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        if (PlatformDetector.isAppleTV()) {
          return DeviceIdentity(platform: 'tvOS', deviceModel: 'Apple TV', deviceName: iosInfo.name, isTv: true);
        }
        return DeviceIdentity(platform: 'iOS', deviceModel: iosInfo.model, deviceName: iosInfo.name, isTv: isTv);
      }
      if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return DeviceIdentity(
          platform: 'macOS',
          deviceModel: macInfo.model,
          deviceName: macInfo.computerName,
          isTv: isTv,
        );
      }
      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return DeviceIdentity(
          platform: 'Windows',
          deviceModel: 'Windows',
          deviceName: windowsInfo.computerName,
          isTv: isTv,
        );
      }
      if (Platform.isLinux) {
        final host = Platform.localHostname.trim();
        final name = (host.isNotEmpty && host != 'localhost') ? host : (await deviceInfo.linuxInfo).name;
        return DeviceIdentity(platform: 'Linux', deviceModel: 'Linux', deviceName: name, isTv: isTv);
      }
    } catch (e) {
      appLogger.w('DeviceIdentity: failed to resolve device info', error: e);
    }

    return DeviceIdentity(platform: Platform.operatingSystem, isTv: isTv);
  }
}

/// Makes a free-form device name safe to send as an HTTP header value on
/// every transport Heisuca uses: folds Latin letters to their base form
/// (`Bjørn PC` → `Bjorn PC`), drops whatever is still outside printable
/// ASCII, trims, and returns null when nothing usable remains.
///
/// The ASCII restriction is not cosmetic. `dart:io` rejects header values
/// containing anything above 0x7F with a `FormatException`, and CFNetwork
/// puts the raw code unit on the wire as a Latin-1 byte, which HTTP servers
/// decoding headers as UTF-8 (Kestrel, hosting Jellyfin) reject as a
/// malformed request. Headers with a documented percent-encoded wire format
/// carry the name intact instead — see `buildJellyfinAuthHeader`.
String? sanitizeHeaderValue(String? value) {
  if (value == null) return null;
  final buffer = StringBuffer();
  for (final unit in nfd(_foldNonDecomposableLatin(value)).codeUnits) {
    if (unit >= 0x20 && unit < 0x7F) buffer.writeCharCode(unit);
  }
  final trimmed = buffer.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Latin letters NFD leaves alone because they are single code points rather
/// than base + combining mark. Without this, Nordic and Central European
/// device names lose whole letters instead of being transliterated.
const Map<String, String> _nonDecomposableLatin = {
  'æ': 'ae',
  'Æ': 'AE',
  'œ': 'oe',
  'Œ': 'OE',
  'ø': 'o',
  'Ø': 'O',
  'ß': 'ss',
  'đ': 'd',
  'Đ': 'D',
  'ð': 'd',
  'Ð': 'D',
  'þ': 'th',
  'Þ': 'Th',
  'ł': 'l',
  'Ł': 'L',
  'ħ': 'h',
  'Ħ': 'H',
  'ı': 'i',
  'ŧ': 't',
  'Ŧ': 'T',
};

final RegExp _nonDecomposableLatinPattern = RegExp('[${_nonDecomposableLatin.keys.join()}]');

String _foldNonDecomposableLatin(String value) =>
    value.replaceAllMapped(_nonDecomposableLatinPattern, (match) => _nonDecomposableLatin[match[0]]!);
