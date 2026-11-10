/// Cor em Oklab/Oklch, sem depender do Flutter (roda em isolate e em teste puro).
///
/// As cores entram e saem como inteiros ARGB (0xAARRGGBB).
library;

import 'dart:math' as math;

double _paraLinear(int canal) {
  final v = canal / 255.0;
  return v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

double _deLinear(double v) => v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4).toDouble() - 0.055;

double _raizCubica(double v) => v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();

/// Um ponto no espaço Oklab. [l] vai de 0 (preto) a 1 (branco).
class Oklab {
  const Oklab(this.l, this.a, this.b);

  /// Monta a partir de luminosidade, croma e matiz em graus.
  factory Oklab.deLch(double l, double croma, double matizGraus) {
    final h = matizGraus * math.pi / 180;
    return Oklab(l, croma * math.cos(h), croma * math.sin(h));
  }

  factory Oklab.deArgb(int argb) {
    final r = _paraLinear((argb >> 16) & 0xFF);
    final g = _paraLinear((argb >> 8) & 0xFF);
    final b = _paraLinear(argb & 0xFF);
    final l = _raizCubica(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    final m = _raizCubica(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    final s = _raizCubica(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return Oklab(
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    );
  }

  final double l;
  final double a;
  final double b;

  double get croma => math.sqrt(a * a + b * b);

  /// Matiz em graus, de 0 a 360.
  double get matiz {
    final h = math.atan2(b, a) * 180 / math.pi;
    return h < 0 ? h + 360 : h;
  }

  Oklab comL(double novoL) => Oklab(novoL, a, b);

  Oklab comCroma(double novoCroma) {
    final c = croma;
    if (c < 1e-9) return Oklab(l, 0, 0);
    final k = novoCroma / c;
    return Oklab(l, a * k, b * k);
  }

  /// Mistura reta em Oklab: [t] = 0 devolve esta cor, 1 devolve [outra].
  Oklab mistura(Oklab outra, double t) => Oklab(l + (outra.l - l) * t, a + (outra.a - a) * t, b + (outra.b - b) * t);

  List<double> _rgbLinear() {
    final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
    final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
    final s_ = l - 0.0894841775 * a - 1.2914855480 * b;
    final l3 = l_ * l_ * l_, m3 = m_ * m_ * m_, s3 = s_ * s_ * s_;
    return [
      4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3,
      -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3,
      -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3,
    ];
  }

  bool get _cabeNoSrgb {
    const folga = 0.0005;
    for (final v in _rgbLinear()) {
      if (v < -folga || v > 1 + folga) return false;
    }
    return true;
  }

  /// A mesma cor, com o croma reduzido só o necessário para caber no sRGB.
  /// Luminosidade e matiz não mudam (cortar canal a canal mudaria o matiz).
  Oklab noSrgb() {
    final lSeguro = l.clamp(0.0, 1.0);
    final base = Oklab(lSeguro, a, b);
    if (base._cabeNoSrgb) return base;
    var baixo = 0.0, alto = base.croma;
    for (var i = 0; i < 18; i++) {
      final meio = (baixo + alto) / 2;
      if (base.comCroma(meio)._cabeNoSrgb) {
        baixo = meio;
      } else {
        alto = meio;
      }
    }
    return base.comCroma(baixo);
  }

  /// ARGB opaco. Fora do sRGB, reduz o croma antes de converter.
  int paraArgb() {
    final rgb = noSrgb()._rgbLinear();
    int canal(double v) => (_deLinear(v.clamp(0.0, 1.0)) * 255).round().clamp(0, 255);
    return 0xFF000000 | (canal(rgb[0]) << 16) | (canal(rgb[1]) << 8) | canal(rgb[2]);
  }
}

/// Luminância relativa do WCAG 2 (0 a 1).
double luminanciaRelativa(int argb) =>
    0.2126 * _paraLinear((argb >> 16) & 0xFF) +
    0.7152 * _paraLinear((argb >> 8) & 0xFF) +
    0.0722 * _paraLinear(argb & 0xFF);

/// Razão de contraste do WCAG 2 entre duas cores opacas (1 a 21).
double contraste(int a, int b) {
  final la = luminanciaRelativa(a), lb = luminanciaRelativa(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Paradas de um degradê entre duas cores, interpoladas em Oklab.
/// O meio não acinzenta nem muda de matiz, como acontece na mistura em sRGB.
List<int> degradeOklab(int de, int para, {int paradas = 7}) {
  assert(paradas >= 2);
  final inicio = Oklab.deArgb(de), fim = Oklab.deArgb(para);
  return [
    for (var i = 0; i < paradas; i++)
      if (i == 0) de else if (i == paradas - 1) para else inicio.mistura(fim, i / (paradas - 1)).paraArgb(),
  ];
}
