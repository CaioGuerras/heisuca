/// Tira de um pôster a cor que tinge a tela, sem depender do Flutter.
library;

import 'dart:typed_data';

import 'package:material_color_utilities/material_color_utilities.dart';

import 'blurhash.dart';
import 'oklab.dart';

/// Abaixo deste croma (Oklab) a cor conta como cinza e não disputa.
const double _cromaDeCinza = 0.02;

/// Deste croma para cima a cor pesa só pela área que ocupa.
const double _cromaCheio = 0.10;

/// Cores a até esta distância de matiz contam como a mesma família.
const double _familiaGraus = 25;

/// Fatia do pôster (já pesada pelo croma) em que a cor começa a tingir e
/// em que tinge por inteiro. Entre as duas, a semente vai da média à cor.
const double _areaComeca = 0.04, _areaCheia = 0.14;

/// A cor que representa [pixels] (ARGB opacos).
///
/// Vence a família de cor que ocupa mais área, não a cor mais viva: uma
/// mancha vermelha num pôster de céu azul não pinta a tela de vermelho.
/// Pôster cinza, ou com a cor só num canto, fica na média da imagem, que
/// mantém o tom frio ou quente dela.
Future<int> extrairSemente(List<int> pixels) async {
  if (pixels.isEmpty) return 0xFF808080;
  final quantizado = await QuantizerCelebi().quantize(pixels, 16);
  return escolherSemente(quantizado.colorToCount);
}

/// Escolhe a semente entre os grupos de cor de um pôster ([contagem]: ARGB → pontos).
int escolherSemente(Map<int, int> contagem) {
  var total = 0;
  var lMedia = 0.0, aMedia = 0.0, bMedia = 0.0;
  final grupos = <({Oklab cor, double matiz, double peso})>[];
  contagem.forEach((argb, pontos) {
    final cor = Oklab.deArgb(argb);
    total += pontos;
    lMedia += cor.l * pontos;
    aMedia += cor.a * pontos;
    bMedia += cor.b * pontos;
    final croma = cor.croma;
    if (croma < _cromaDeCinza) return;
    grupos.add((cor: cor, matiz: cor.matiz, peso: pontos * _degrau(_cromaDeCinza, _cromaCheio, croma)));
  });
  if (total == 0) return 0xFF808080;
  final media = Oklab(lMedia / total, aMedia / total, bMedia / total);
  if (grupos.isEmpty) return media.paraArgb();

  // Para cada grupo, soma a família dele; vence a maior soma.
  var melhorPeso = 0.0;
  var melhor = media;
  for (final centro in grupos) {
    var peso = 0.0, l = 0.0, a = 0.0, b = 0.0;
    for (final g in grupos) {
      if (_distanciaDeMatiz(centro.matiz, g.matiz) > _familiaGraus) continue;
      peso += g.peso;
      l += g.cor.l * g.peso;
      a += g.cor.a * g.peso;
      b += g.cor.b * g.peso;
    }
    if (peso > melhorPeso) {
      melhorPeso = peso;
      melhor = Oklab(l / peso, a / peso, b / peso);
    }
  }
  final presenca = _degrau(_areaComeca, _areaCheia, melhorPeso / total);
  return media.mistura(melhor, presenca).paraArgb();
}

double _distanciaDeMatiz(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

/// Degrau suave de 0 a 1 entre [de] e [ate].
double _degrau(double de, double ate, double x) {
  final t = ((x - de) / (ate - de)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Média de [pixels] em Oklab.
int corMedia(List<int> pixels) {
  if (pixels.isEmpty) return 0xFF808080;
  var l = 0.0, a = 0.0, b = 0.0;
  for (final p in pixels) {
    final cor = Oklab.deArgb(p);
    l += cor.l;
    a += cor.a;
    b += cor.b;
  }
  final n = pixels.length;
  return Oklab(l / n, a / n, b / n).paraArgb();
}

/// A semente de um BlurHash, ou `null` quando o texto não é um BlurHash.
Future<int?> sementeDoBlurHash(String hash) async {
  final Uint32List? pixels = decodificarBlurHash(hash);
  if (pixels == null) return null;
  return extrairSemente(pixels);
}

/// Calcula várias sementes de uma vez; feito para rodar fora da thread da tela.
/// Hash inválido fica de fora do resultado.
Future<Map<String, int>> sementesEmLote(List<String> hashes) async {
  final saida = <String, int>{};
  for (final hash in hashes) {
    final semente = await sementeDoBlurHash(hash);
    if (semente != null) saida[hash] = semente;
  }
  return saida;
}
