import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Na V2 a cor tem uma fonte só: os tokens gerados em `lib/heisuca/theme/`.
/// Este teste falha se alguém escrever uma cor à mão em `lib/design/` ou em `lib/features/`.
void main() {
  // Máscara de opacidade e o "cinza sem cor" que a semente devolve para um pôster vazio.
  const permitidos = {'0xFF000000', '0xFF808080'};
  final hex = RegExp(r'0x[0-9A-Fa-f]{6,8}\b');
  final fabrica = RegExp(r'Color\.from(ARGB|RGBO)\(|\bColors\.(?!transparent\b)');

  List<String> achados(String texto, String caminho) {
    final lista = <String>[];
    final linhas = texto.split('\n');
    for (var i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      if (linha.trimLeft().startsWith('//')) continue;
      final temHex = hex
          .allMatches(linha)
          .any((m) => !permitidos.contains(m.group(0)!.toUpperCase().replaceFirst('0X', '0x')));
      if (temHex || fabrica.hasMatch(linha)) lista.add('$caminho:${i + 1}: ${linha.trim()}');
    }
    return lista;
  }

  test('o detector enxerga cor à mão (prova negativa)', () {
    expect(achados('final a = Color(0xFF276C4F);', 'x.dart'), hasLength(1));
    expect(achados('color: Colors.white,', 'x.dart'), hasLength(1));
    expect(achados('final b = Color.fromARGB(255, 1, 2, 3);', 'x.dart'), hasLength(1));
    expect(achados('color: Colors.transparent,', 'x.dart'), isEmpty);
    expect(achados('return 0xFF000000 | (r << 16);', 'x.dart'), isEmpty);
    expect(achados('// exemplo: Color(0xFF276C4F)', 'x.dart'), isEmpty);
  });

  test('nenhuma cor escrita à mão em lib/design nem em lib/features', () {
    final problemas = <String>[];
    var arquivos = 0;
    for (final pasta in ['lib/design', 'lib/features']) {
      final dir = Directory(pasta);
      if (!dir.existsSync()) continue;
      for (final arquivo in dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        arquivos++;
        problemas.addAll(achados(arquivo.readAsStringSync(), arquivo.path));
      }
    }
    expect(arquivos, greaterThan(5), reason: 'o teste tem de estar lendo os arquivos');
    expect(problemas, isEmpty, reason: problemas.join('\n'));
  });
}
