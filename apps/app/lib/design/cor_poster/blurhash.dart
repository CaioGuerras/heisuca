/// Leitura de BlurHash para uma grade pequena de cores, sem depender do Flutter.
library;

import 'dart:math' as math;
import 'dart:typed_data';

const _base83 = r'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~';

int _decodifica83(String texto, int inicio, int fim) {
  var valor = 0;
  for (var i = inicio; i < fim; i++) {
    final digito = _base83.indexOf(texto[i]);
    if (digito < 0) return -1;
    valor = valor * 83 + digito;
  }
  return valor;
}

double _paraLinear(int v) {
  final x = v / 255.0;
  return x <= 0.04045 ? x / 12.92 : math.pow((x + 0.055) / 1.055, 2.4).toDouble();
}

int _paraSrgb(double v) {
  final x = v.clamp(0.0, 1.0);
  return ((x <= 0.0031308 ? x * 12.92 : 1.055 * math.pow(x, 1 / 2.4) - 0.055) * 255).round().clamp(0, 255);
}

double _ac(int valor, double maximo) {
  final v = (valor - 9) / 9;
  return v.sign * v * v * maximo;
}

/// Decodifica [hash] em [largura]×[altura] cores ARGB opacas, linha a linha.
/// Devolve `null` quando o texto não é um BlurHash válido.
Uint32List? decodificarBlurHash(String hash, {int largura = 24, int altura = 24}) {
  if (hash.length < 6) return null;
  final tamanho = _decodifica83(hash, 0, 1);
  if (tamanho < 0) return null;
  final nx = tamanho % 9 + 1, ny = tamanho ~/ 9 + 1;
  if (hash.length != 4 + 2 * nx * ny) return null;
  final quantizado = _decodifica83(hash, 1, 2);
  final dc = _decodifica83(hash, 2, 6);
  if (quantizado < 0 || dc < 0) return null;
  final maximo = (quantizado + 1) / 166;

  final fatores = Float64List(nx * ny * 3);
  fatores[0] = _paraLinear((dc >> 16) & 0xFF);
  fatores[1] = _paraLinear((dc >> 8) & 0xFF);
  fatores[2] = _paraLinear(dc & 0xFF);
  for (var k = 1; k < nx * ny; k++) {
    final valor = _decodifica83(hash, 4 + k * 2, 6 + k * 2);
    if (valor < 0) return null;
    fatores[k * 3] = _ac(valor ~/ 361, maximo);
    fatores[k * 3 + 1] = _ac((valor ~/ 19) % 19, maximo);
    fatores[k * 3 + 2] = _ac(valor % 19, maximo);
  }

  final cosX = Float64List(largura * nx), cosY = Float64List(altura * ny);
  for (var x = 0; x < largura; x++) {
    for (var i = 0; i < nx; i++) {
      cosX[x * nx + i] = math.cos(math.pi * x * i / largura);
    }
  }
  for (var y = 0; y < altura; y++) {
    for (var j = 0; j < ny; j++) {
      cosY[y * ny + j] = math.cos(math.pi * y * j / altura);
    }
  }

  final saida = Uint32List(largura * altura);
  for (var y = 0; y < altura; y++) {
    for (var x = 0; x < largura; x++) {
      var r = 0.0, g = 0.0, b = 0.0;
      for (var j = 0; j < ny; j++) {
        final cy = cosY[y * ny + j];
        for (var i = 0; i < nx; i++) {
          final base = cosX[x * nx + i] * cy;
          final k = (i + j * nx) * 3;
          r += fatores[k] * base;
          g += fatores[k + 1] * base;
          b += fatores[k + 2] * base;
        }
      }
      saida[y * largura + x] = 0xFF000000 | (_paraSrgb(r) << 16) | (_paraSrgb(g) << 8) | _paraSrgb(b);
    }
  }
  return saida;
}
