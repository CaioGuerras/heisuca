import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_version.dart';

void main() {
  test('Sobre mostra "Versão 1.6.2" abaixo do nome', () {
    expect(cgflixVersionLabel('1.6.2'), 'Versão 1.6.2');
    expect(cgflixVersionLabel(''), '');
  });

  test('pubspec: versão válida com versionCode', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([0-9.]+)\+(\d+)\s*$', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(match!.group(1), matches(RegExp(r'^\d+\.\d+\.\d+$')));
    expect(int.parse(match.group(2)!), greaterThan(0)); // a versão muda a cada entrega; o formato não
  });
}
