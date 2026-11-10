import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../media/media_item.dart';
import '../cgflix/cgflix_palette.dart';

/// Mesma máscara do site: a arte fica transparente sobre UMA cor de página.
const heisucaHeroMask = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Colors.white, Colors.white, Color(0x8CFFFFFF), Color(0x00FFFFFF)],
  stops: [0, 0.52, 0.74, 0.94],
);

/// Mascara toda a cobertura rasterizada da arte, inclusive a célula física da borda.
/// No Impeller, o parallax pode pintar a última célula parcialmente fora do rect
/// lógico do ShaderMask. O recorte externo sozinho não garante que dstIn a cubra.
/// Estendemos somente a área de composição da máscara por um pixel físico;
/// imagem, quadro e coordenadas do gradiente mantêm suas medidas originais.
class HeisucaArtworkMask extends StatelessWidget {
  const HeisucaArtworkMask({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      assert(constraints.hasBoundedWidth && constraints.hasBoundedHeight);
      final size = constraints.biggest;
      final pixel = 1 / View.of(context).devicePixelRatio;
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height + pixel,
          maxHeight: size.height + pixel,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (_) => heisucaHeroMask.createShader(Offset.zero & size),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(size: size, child: child),
            ),
          ),
        ),
      );
    },
  );
}

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
int _srgb(double v) =>
    ((v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4) - 0.055) * 255).round().clamp(0, 255);
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
    final factors = <List<double>>[
      [_linear(dc >> 16), _linear((dc >> 8) & 255), _linear(dc & 255)],
    ];
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
            for (var c = 0; c < 3; c++) {
              channels[c] += factors[i + j * nx][c] * basis;
            }
          }
        }
        for (var c = 0; c < 3; c++) {
          sums[c] += _srgb(channels[c]);
        }
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
Color heisucaPageColor(MediaItem? item, {required bool isLight, CgflixPalette? palette}) {
  final theme = palette ?? (isLight ? CgflixPalette.heitor : CgflixPalette.isis);
  return theme.background;
}
