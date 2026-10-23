import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Regra do fork e decisão do Caio (21/10): player neutro, nenhum servidor embutido ou pré-preenchido.
/// A conexão rápida chegou a usar escondido o endereço do CGSERVER com o campo vazio (corrigido em 23/10).
void main() {
  test('nenhum endereço do CGSERVER embutido no código do app (fora de comentários)', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].replaceFirst(RegExp(r'(?<!:)//.*'), '');
        if (code.contains('docaio.com.br')) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
