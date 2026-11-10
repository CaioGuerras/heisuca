import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/cor_poster/blurhash.dart';
import 'package:heisuca/design/cor_poster/oklab.dart';
import 'package:heisuca/design/cor_poster/paleta_poster.dart';
import 'package:heisuca/design/cor_poster/semente.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';

String _hex(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

Map<String, int> _papeis(PaletaPoster p) => {
  'fundoTopo': p.fundoTopo,
  'halo': p.halo,
  'superficie': p.superficie,
  'superficie2': p.superficie2,
};

void main() {
  final amostra = (jsonDecode(File('test/fixtures/cor_poster/blurhash_200.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  test('a amostra tem 200 pôsteres reais', () {
    expect(amostra, hasLength(200));
  });

  // Meta do plano: contraste AA em 200 pôsteres reais, nos 3 temas.
  // Um par reprovado derruba o build.
  test('os 200 pôsteres passam no contraste AA nos 3 temas (capa e fundo)', () async {
    final reprovados = <String>[];
    final folha = <Map<String, dynamic>>[];
    var pares = 0;
    for (var i = 0; i < amostra.length; i++) {
      for (final origem in const ['primary', 'backdrop']) {
        final hash = amostra[i][origem] as String?;
        if (hash == null) continue;
        final semente = await sementeDoBlurHash(hash);
        expect(semente, isNotNull, reason: 'BlurHash $i/$origem inválido');
        final linha = <String, dynamic>{'i': i, 'origem': origem, 'hash': hash, 'semente': _hex(semente!)};
        for (final tema in TemasCorPoster.todos) {
          final paleta = PaletaPoster.de(semente: semente, tema: tema);
          final papeis = _papeis(paleta);
          for (final MapEntry(key: papel, value: fundo) in papeis.entries) {
            for (final (nome, tinta, minimo) in [
              ('texto', tema.texto, contrasteMinimoTexto),
              ('texto2', tema.texto2, contrasteMinimoTexto),
              ('acento', tema.acento, contrasteMinimoAcento),
            ]) {
              pares++;
              final c = contraste(tinta, fundo);
              if (c < minimo) {
                reprovados.add('$i/$origem ${tema.nome} $nome sobre $papel ${_hex(fundo)}: ${c.toStringAsFixed(2)}');
              }
            }
          }
          expect(paleta.fundoFim, tema.fundo, reason: 'o degradê termina no papel');
          expect(paleta.degrade().last, tema.fundo);
          linha[tema.nome] = {
            for (final e in papeis.entries) e.key: _hex(e.value),
            'degrade': [for (final c in paleta.degrade()) _hex(c)],
            'alcanceHalo': paleta.alcanceHalo,
          };
        }
        folha.add(linha);
      }
    }
    final destino = Platform.environment['COR_POSTER_FOLHA'];
    if (destino != null && destino.isNotEmpty) {
      File(destino).writeAsStringSync(
        jsonEncode({
          'temas': {
            for (final t in TemasCorPoster.todos)
              t.nome: {
                'fundo': _hex(t.fundo),
                'texto': _hex(t.texto),
                'texto2': _hex(t.texto2),
                'acento': _hex(t.acento),
              },
          },
          'itens': folha,
        }),
      );
    }
    expect(pares, greaterThan(200 * 3 * 4 * 3), reason: 'todos os pares foram conferidos');
    expect(reprovados, isEmpty, reason: reprovados.take(20).join('\n'));
  });

  test('o fundo no topo fica na faixa de luminosidade de cada tema', () async {
    final foraDaFaixa = <String>[];
    var corrigidos = 0, total = 0;
    for (var i = 0; i < amostra.length; i++) {
      final semente = (await sementeDoBlurHash(amostra[i]['primary'] as String))!;
      for (final tema in TemasCorPoster.todos) {
        final l = Oklab.deArgb(PaletaPoster.de(semente: semente, tema: tema).fundoTopo).l;
        total++;
        final (minimo, maximo) = switch (tema.tinta) {
          TintaDoTema.escura => (0.20, 0.24),
          TintaDoTema.pastel => (0.95, 1.0),
          TintaDoTema.oled => (0.0, 0.14),
        };
        // Meio ponto de folga para o arredondamento em 8 bits.
        if (l < minimo - 0.005 || l > maximo + 0.005) {
          foraDaFaixa.add('$i ${tema.nome} L=${l.toStringAsFixed(3)}');
          corrigidos++;
        }
      }
    }
    expect(foraDaFaixa, isEmpty, reason: '$corrigidos de $total fora da faixa:\n${foraDaFaixa.take(20).join('\n')}');
  });

  test('a tela tingida muda com o pôster (não é uma cor fixa)', () async {
    for (final tema in TemasCorPoster.todos) {
      // Cerca de um quarto do acervo é pôster cinza ou de muitas cores sem
      // dominante: esses ficam no tom do papel, de propósito.
      final neutro = PaletaPoster.neutra(tema).fundoTopo;
      final topos = <int>{};
      var tingidos = 0;
      for (final item in amostra) {
        final semente = (await sementeDoBlurHash(item['primary'] as String))!;
        final topo = PaletaPoster.de(semente: semente, tema: tema).fundoTopo;
        topos.add(topo);
        if (topo != neutro) tingidos++;
      }
      expect(topos.length, greaterThan(80), reason: '${tema.nome}: ${topos.length} fundos diferentes em 200');
      expect(tingidos, greaterThan(140), reason: '${tema.nome}: $tingidos pôsteres tingidos em 200');
    }
  });

  group('faixa mostarda', () {
    test('o croma cai pela metade entre 70° e 115°, com borda suave', () {
      expect(fatorMostarda(70), closeTo(0.5, 1e-9));
      expect(fatorMostarda(92), closeTo(0.5, 1e-9));
      expect(fatorMostarda(115), closeTo(0.5, 1e-9));
      expect(fatorMostarda(40), 1);
      expect(fatorMostarda(140), 1);
      expect(fatorMostarda(64), inExclusiveRange(0.5, 1.0));
      expect(fatorMostarda(121), inExclusiveRange(0.5, 1.0));
    });

    // A comparação é com o verde: em pastel, o sRGB quase não tem azul
    // (croma máximo perto de 0,04), e o teste mediria o gamut, não a regra.
    test('pôster mostarda tinge menos que um verde de mesmo croma', () {
      final mostarda = Oklab.deLch(0.7, 0.08, 95).paraArgb();
      final verde = Oklab.deLch(0.7, 0.08, 150).paraArgb();
      for (final tema in TemasCorPoster.todos) {
        final cMostarda = Oklab.deArgb(PaletaPoster.de(semente: mostarda, tema: tema).halo).croma;
        final cVerde = Oklab.deArgb(PaletaPoster.de(semente: verde, tema: tema).halo).croma;
        expect(cMostarda, lessThan(cVerde * 0.75), reason: tema.nome);
      }
    });
  });

  group('casos de borda', () {
    test('pôster cinza fica no tom do papel do tema', () {
      for (final tema in TemasCorPoster.todos) {
        final paleta = PaletaPoster.de(semente: 0xFF808080, tema: tema);
        final topo = Oklab.deArgb(paleta.fundoTopo), papel = Oklab.deArgb(tema.fundo);
        expect(topo.croma, closeTo(papel.croma, 0.012), reason: tema.nome);
        expect(leituraGarantida(paleta.fundoTopo, tema), isTrue);
      }
    });

    test('cores extremas ainda dão leitura', () {
      const extremos = [0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFFFFFF00, 0xFFFF00FF, 0xFF00FFFF, 0xFFFFFFFF, 0xFF000000];
      for (final cor in extremos) {
        for (final tema in TemasCorPoster.todos) {
          final paleta = PaletaPoster.de(semente: cor, tema: tema);
          for (final e in _papeis(paleta).entries) {
            expect(leituraGarantida(e.value, tema), isTrue, reason: '${_hex(cor)} ${tema.nome} ${e.key}');
          }
        }
      }
    });

    test('a superfície se distingue do fundo', () {
      for (final tema in TemasCorPoster.todos) {
        final paleta = PaletaPoster.de(semente: 0xFF3366CC, tema: tema);
        final topo = Oklab.deArgb(paleta.fundoTopo).l, sup = Oklab.deArgb(paleta.superficie).l;
        expect((sup - topo).abs(), greaterThan(0.02), reason: tema.nome);
      }
    });

    test('imagem de uma cor só devolve essa cor como semente', () async {
      final pixels = List<int>.filled(64, 0xFF2F6FB5);
      final semente = await extrairSemente(pixels);
      expect(Oklab.deArgb(semente).matiz, closeTo(Oklab.deArgb(0xFF2F6FB5).matiz, 6));
    });

    test('imagem cinza usa a média, não o azul padrão do Material', () async {
      final pixels = [for (var i = 0; i < 64; i++) 0xFF000000 | (0x010101 * (96 + i))];
      final semente = await extrairSemente(pixels);
      expect(Oklab.deArgb(semente).croma, lessThan(0.01));
    });

    test('a cor que ocupa o pôster vence a cor viva que ocupa um canto', () async {
      // 75% azul-acinzentado claro, 25% vermelho vivo: a tela segue o azul.
      const azul = 0xFF9DB4D6, vermelho = 0xFFD2190B;
      final pixels = [for (var i = 0; i < 576; i++) i < 432 ? azul : vermelho];
      final semente = Oklab.deArgb(await extrairSemente(pixels));
      expect(_distanciaDeMatiz(semente.matiz, Oklab.deArgb(azul).matiz), lessThan(20));
    });

    test('pôster quase todo branco com uma mancha de cor fica perto do neutro', () async {
      // 96% branco, 4% vermelho escuro: a mancha não pinta a tela.
      final pixels = [for (var i = 0; i < 576; i++) i < 553 ? 0xFFF4F4F4 : 0xFF4B0400];
      final semente = Oklab.deArgb(await extrairSemente(pixels));
      expect(semente.croma, lessThan(0.03));
    });

    test('duas cores vivas: vence a de maior área', () async {
      const verde = 0xFF1E9E55, laranja = 0xFFE07A10;
      final pixels = [for (var i = 0; i < 576; i++) i < 380 ? verde : laranja];
      final semente = Oklab.deArgb(await extrairSemente(pixels));
      expect(_distanciaDeMatiz(semente.matiz, Oklab.deArgb(verde).matiz), lessThan(20));
    });

    test('BlurHash decodificado dá 576 pontos', () {
      final pixels = decodificarBlurHash(amostra.first['primary'] as String);
      expect(pixels, hasLength(24 * 24));
    });
  });
}

double _distanciaDeMatiz(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}
