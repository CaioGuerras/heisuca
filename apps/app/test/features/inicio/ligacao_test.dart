import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_palette.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/inicio/ligacao.dart';

const _minuto = Duration.millisecondsPerMinute;

void main() {
  group('restam', () {
    test('minutos, arredondando para cima', () {
      expect(restam(40 * _minuto, 28 * _minuto), 'restam 12 min');
      expect(restam(40 * _minuto, 39 * _minuto + 30000), 'restam 1 min');
    });

    test('horas cheias e horas com minutos', () {
      expect(restam(150 * _minuto, 30 * _minuto), 'restam 2 h');
      expect(restam(125 * _minuto, 60 * _minuto), 'restam 1 h 5 min');
    });

    test('sem duração, sem ponto de parada ou já no fim, não diz nada', () {
      expect(restam(null, 10), isNull);
      expect(restam(0, 10), isNull);
      expect(restam(40 * _minuto, null), isNull);
      expect(restam(40 * _minuto, 0), isNull);
      expect(restam(40 * _minuto, 40 * _minuto), isNull);
      expect(restam(40 * _minuto, 41 * _minuto), isNull);
    });
  });

  group('progressoDe', () {
    test('fração vista, presa entre 0 e 1', () {
      expect(progressoDe(1000, 250), 0.25);
      expect(progressoDe(1000, 5000), 1);
    });

    test('sem duração ou sem ponto de parada, não há barra', () {
      expect(progressoDe(null, 250), isNull);
      expect(progressoDe(0, 250), isNull);
      expect(progressoDe(1000, null), isNull);
      expect(progressoDe(1000, 0), isNull);
    });
  });

  test('notaDe: uma casa, com vírgula; sem nota não aparece', () {
    expect(notaDe(8.64), '8,6');
    expect(notaDe(7), '7,0');
    expect(notaDe(null), isNull);
    expect(notaDe(0), isNull);
  });

  test('juntar: só o que existe, sem ponto sobrando', () {
    expect(juntar(['T2:E5', 'O retorno']), 'T2:E5 · O retorno');
    expect(juntar(['', 'O retorno']), 'O retorno');
    expect(juntar([null, '  ']), isNull);
  });

  group('temaDaPaleta', () {
    test('cada tema do app tem o seu par na V2', () {
      expect(temaDaPaleta(CgflixPalette.isis), TemaHeisuca.shikkoku);
      expect(temaDaPaleta(CgflixPalette.heitor), TemaHeisuca.hisui);
      expect(temaDaPaleta(CgflixPalette.sumi), TemaHeisuca.sumi);
    });

    test('o kids segue o brilho da paleta', () {
      for (final paleta in [
        CgflixPalette.ichigo,
        CgflixPalette.sorairo,
        CgflixPalette.ichigoNoite,
        CgflixPalette.sorairoNoite,
      ]) {
        expect(temaDaPaleta(paleta), paleta.isLight ? TemaHeisuca.hisui : TemaHeisuca.shikkoku);
      }
    });
  });

  test('temaDaV2 guarda as extensões que as telas atuais leem e troca só o tema da V2', () {
    final atual = ThemeData(extensions: const [CgflixPalette.isis, TemaHeisuca.shikkoku]);
    final novo = temaDaV2(atual, TemaHeisuca.hisui);
    expect(novo.extension<CgflixPalette>(), CgflixPalette.isis);
    expect(novo.extension<TemaHeisuca>(), TemaHeisuca.hisui);
    expect(novo.brightness, Brightness.light);
  });
}
