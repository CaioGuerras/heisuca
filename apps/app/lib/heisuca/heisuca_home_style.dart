import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../media/media_item.dart';

/// Mesma máscara do site: a arte fica transparente sobre UMA cor de página.
const heisucaHeroMask = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Colors.white, Colors.white, Color(0x8CFFFFFF), Color(0x00FFFFFF)],
  stops: [0, 0.52, 0.74, 0.94],
);

double heisucaHeroHeight(double viewportHeight) => (viewportHeight * 0.645).clamp(480.0, 660.0);

String? heisucaArtworkHash(MediaItem? item) {
  final hashes = item?.raw?['ImageBlurHashes'];
  if (hashes is! Map) return null;
  for (final type in ['Backdrop', 'Primary']) {
    final values = hashes[type];
    if (values is Map) {
      for (final hash in values.values) {
        if (hash is String && hash.isNotEmpty) return hash;
      }
    }
  }
  return null;
}

const _base83 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#\u0024%*+,-.:;=?@[]^_{|}~';
int _decode83(String value) {
  var decoded = 0;
  for (final character in value.split('')) {
    final digit = _base83.indexOf(character);
    if (digit < 0) throw const FormatException('BlurHash inválido');
    decoded = decoded * 83 + digit;
  }
  return decoded;
}

double _linear(int v) => v <= 10 ? v / 3294.6 : math.pow((v / 255 + 0.055) / 1.055, 2.4).toDouble();
int _srgb(double v) => ((v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4) - 0.055) * 255).round().clamp(0, 255);
final _baseColors = <String, Color?>{};

/// Decodifica somente 12×10 pixels e calcula a média dos 40% inferiores, como o site.
Color? heisucaBaseColor(String? hash) {
  if (hash == null || hash.length < 6) return null;
  if (_baseColors.containsKey(hash)) return _baseColors[hash];
  Color? result;
  try {
    final size = _decode83(hash[0]);
    final nx = size % 9 + 1, ny = size ~/ 9 + 1;
    if (ny > 9 || hash.length != 4 + 2 * nx * ny) return null;
    final maximum = (_decode83(hash[1]) + 1) / 166;
    final dc = _decode83(hash.substring(2, 6));
    final factors = <List<double>>[[_linear(dc >> 16), _linear((dc >> 8) & 255), _linear(dc & 255)]];
    double ac(int value) {
      final v = (value - 9) / 9;
      return v.sign * v * v * maximum;
    }
    for (var k = 1; k < nx * ny; k++) {
      final value = _decode83(hash.substring(4 + k * 2, 6 + k * 2));
      factors.add([ac(value ~/ (19 * 19)), ac((value ~/ 19) % 19), ac(value % 19)]);
    }
    final sums = [0, 0, 0];
    for (var y = 6; y < 10; y++) {
      for (var x = 0; x < 12; x++) {
        final channels = [0.0, 0.0, 0.0];
        for (var j = 0; j < ny; j++) {
          for (var i = 0; i < nx; i++) {
            final basis = math.cos(math.pi * x * i / 12) * math.cos(math.pi * y * j / 10);
            for (var c = 0; c < 3; c++) { channels[c] += factors[i + j * nx][c] * basis; }
          }
        }
        for (var c = 0; c < 3; c++) { sums[c] += _srgb(channels[c]); }
      }
    }
    result = Color.fromARGB(255, (sums[0] / 48).round(), (sums[1] / 48).round(), (sums[2] / 48).round());
  } on FormatException {
    result = null;
  }
  if (_baseColors.length >= 64) _baseColors.remove(_baseColors.keys.first);
  _baseColors[hash] = result;
  return result;
}

/// OKLCH com a mesma luminosidade/croma da página web; sem halo nem cor pelo título.
Color heisucaPageColor(MediaItem? item, {required bool isLight}) {
  final base = heisucaBaseColor(heisucaArtworkHash(item));
  if (base == null) return isLight ? const Color(0xFFF7F3EC) : const Color(0xFF0E0B14);
  // Color.r/g/b são normalizados; usa os canais de oito bits para a conversão sRGB.
  final rr = _linear((base.r * 255).round()), gg = _linear((base.g * 255).round()), bb = _linear((base.b * 255).round());
  double cbrt(double v) => v.sign * math.pow(v.abs(), 1 / 3).toDouble();
  final ll = cbrt(0.4122214708 * rr + 0.5363325363 * gg + 0.0514459929 * bb);
  final mm = cbrt(0.2119034982 * rr + 0.6806995451 * gg + 0.1073969566 * bb);
  final ss = cbrt(0.0883024619 * rr + 0.2817188376 * gg + 0.6299787005 * bb);
  final a = 1.9779984951 * ll - 2.4285922050 * mm + 0.4505937099 * ss;
  final ab = 0.0259040371 * ll + 0.7827717662 * mm - 0.8086757660 * ss;
  final hue = math.atan2(ab, a), chroma = math.sqrt(a * a + ab * ab);
  final lightness = isLight ? 0.8 : 0.215;
  final c = (chroma * (isLight ? 0.85 : 0.7)).clamp(0.014, isLight ? 0.075 : 0.06);
  final ca = c * math.cos(hue), cb = c * math.sin(hue);
  final l = math.pow(lightness + 0.3963377774 * ca + 0.2158037573 * cb, 3).toDouble();
  final m = math.pow(lightness - 0.1055613458 * ca - 0.0638541728 * cb, 3).toDouble();
  final s = math.pow(lightness - 0.0894841775 * ca - 1.2914855480 * cb, 3).toDouble();
  final color = Color.fromARGB(255, _srgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
      _srgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
      _srgb(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s));
  return Color.lerp(color, isLight ? const Color(0xFF047857) : const Color(0xFF9D74FF), isLight ? 0.04 : 0.1)!;
}
