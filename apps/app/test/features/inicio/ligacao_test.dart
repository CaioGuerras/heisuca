import 'package:flutter_test/flutter_test.dart';
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
}
