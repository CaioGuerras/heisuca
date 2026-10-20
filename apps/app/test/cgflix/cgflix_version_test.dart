import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_version.dart';

void main() {
  test('Sobre mostra "Versão 1.6.2" abaixo do nome', () {
    expect(cgflixVersionLabel('1.6.2'), 'Versão 1.6.2');
    expect(cgflixVersionLabel(''), '');
  });

  test('pubspec: versão 1.6.2 (login sem senha, 16/10) com versionCode 811 (a 1.6.1 usou o 810)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([0-9.]+)\+(\d+)\s*$', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(match!.group(1), '1.6.2');
    expect(int.parse(match.group(2)!), 811); // instala por cima da 1.6.1 (810)
  });
}
