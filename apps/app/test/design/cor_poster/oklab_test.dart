import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/cor_poster/blurhash.dart';
import 'package:heisuca/design/cor_poster/oklab.dart';

void main() {
  group('Oklab', () {
    test('ida e volta devolve a mesma cor em todo o cubo sRGB', () {
      for (var r = 0; r <= 255; r += 15) {
        for (var g = 0; g <= 255; g += 15) {
          for (var b = 0; b <= 255; b += 15) {
            final argb = 0xFF000000 | (r << 16) | (g << 8) | b;
            expect(Oklab.deArgb(argb).paraArgb(), argb, reason: argb.toRadixString(16));
          }
        }
      }
    });

    test('valores de referência do Oklab', () {
      final branco = Oklab.deArgb(0xFFFFFFFF);
      expect(branco.l, closeTo(1, 1e-3));
      expect(branco.croma, closeTo(0, 1e-3));
      final vermelho = Oklab.deArgb(0xFFFF0000);
      expect(vermelho.l, closeTo(0.628, 2e-3));
      expect(vermelho.croma, closeTo(0.2577, 2e-3));
      expect(vermelho.matiz, closeTo(29.23, 0.2));
    });

    test('cor fora do sRGB perde croma, não luminosidade nem matiz', () {
      final fora = Oklab.deLch(0.6, 0.4, 150);
      final dentro = Oklab.deArgb(fora.paraArgb());
      expect(dentro.l, closeTo(0.6, 0.01));
      expect(dentro.matiz, closeTo(150, 1.5));
      expect(dentro.croma, lessThan(0.4));
    });

    test('contraste do WCAG', () {
      expect(contraste(0xFF000000, 0xFFFFFFFF), closeTo(21, 1e-9));
      expect(contraste(0xFF777777, 0xFFFFFFFF), closeTo(4.48, 0.01));
      expect(contraste(0xFF123456, 0xFF123456), 1);
    });

    test('degradê começa e termina exatamente nas cores pedidas', () {
      final paradas = degradeOklab(0xFFD9E6F2, 0xFFF8F6EF, paradas: 7);
      expect(paradas, hasLength(7));
      expect(paradas.first, 0xFFD9E6F2);
      expect(paradas.last, 0xFFF8F6EF);
      final ls = [for (final p in paradas) Oklab.deArgb(p).l];
      for (var i = 1; i < ls.length; i++) {
        expect(ls[i], greaterThanOrEqualTo(ls[i - 1] - 0.002), reason: 'luminosidade sobe sem degrau');
      }
    });
  });

  group('BlurHash', () {
    test('decodifica o exemplo oficial', () {
      final pixels = decodificarBlurHash('LEHV6nWB2yk8pyo0adR*.7kCMdnj', largura: 8, altura: 8);
      expect(pixels, isNotNull);
      expect(pixels, hasLength(64));
      expect(pixels!.every((p) => (p >> 24) & 0xFF == 0xFF), isTrue);
    });

    test('hash de uma cor só devolve essa cor', () {
      // 1×1 componente, cor média #808080 → "00" + 4 dígitos do DC.
      const digitos = r'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~';
      var dc = 0x336699;
      final texto = StringBuffer();
      final partes = <int>[];
      for (var i = 0; i < 4; i++) {
        partes.insert(0, dc % 83);
        dc ~/= 83;
      }
      for (final p in partes) {
        texto.write(digitos[p]);
      }
      final pixels = decodificarBlurHash('00$texto', largura: 4, altura: 4);
      expect(pixels, isNotNull);
      expect(pixels!.toSet(), {0xFF336699});
    });

    test('texto inválido devolve null', () {
      expect(decodificarBlurHash(''), isNull);
      expect(decodificarBlurHash('abc'), isNull);
      expect(decodificarBlurHash('LEHV6nWB2yk8pyo0adR*.7kCMdn'), isNull);
      expect(decodificarBlurHash('LEHV6nWB2yk8pyo0adR*.7kCMd"j'), isNull);
    });
  });
}
