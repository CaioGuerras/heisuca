import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Regra do fork e decisão do Caio (21/10): player neutro, nenhum servidor embutido ou pré-preenchido.
/// O relay de comandos próprio foi autorizado por Caio em 24/10; não é fonte de mídia.
/// A conexão rápida chegou a usar escondido o endereço do CGSERVER com o campo vazio (corrigido em 23/10).
void main() {
  test('nenhum servidor de mídia embutido; somente relay próprio autorizado', () {
    final offenders = <String>[];
    var authorizedRelays = 0;
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].replaceFirst(RegExp(r'(?<!:)//.*'), '');
        // Caio, 24/10: exceção exata para o relay de comandos de 2.0.12; nenhum login/servidor de mídia.
        if (file.path == 'lib/cgflix/cgflix_defaults.dart' &&
            code.trim() == "const String cgflixWatchTogetherRelay = 'https://heisuca.docaio.com.br/junto';") {
          authorizedRelays++;
          continue;
        }
        if (code.contains('docaio.com.br')) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
    expect(authorizedRelays, 1);
  });
}
