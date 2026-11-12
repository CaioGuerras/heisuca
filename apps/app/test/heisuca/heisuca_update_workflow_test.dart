import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// O atualizador próprio só entra na versão do site e no Heisuca Teste (canal de teste, com código).
/// A da Play nunca recebe o endereço do feed.
void main() {
  final linhas = File('../../.github/workflows/heisuca-android.yml').readAsLinesSync();
  final builds = linhas.where((l) => l.contains('flutter build ')).toList();

  test('só os builds direct recebem a configuração do feed', () {
    final direct = builds.where((l) => l.contains('--flavor direct')).toList();
    expect(direct, hasLength(2));
    for (final linha in direct) {
      expect(linha, contains('"\${feed_args[@]}"'));
    }
    for (final linha in builds.where((l) => !l.contains('--flavor direct'))) {
      expect(linha, isNot(contains('feed_args')));
      expect(linha, isNot(contains('HEISUCA_UPDATE')));
    }
    expect(builds.where((l) => l.contains('--flavor play')), hasLength(1));
  });

  test('o feed é https, do nosso site, e só nos ramos de produção e do Heisuca Teste', () {
    // Pelo índice: as duas linhas são iguais, e procurar pelo texto acharia sempre a primeira.
    final feed = [
      for (var i = 0; i < linhas.length; i++)
        if (linhas[i].contains('HEISUCA_UPDATE_FEED_URL=')) i,
    ];
    expect(feed, hasLength(2));
    for (final i in feed) {
      expect(linhas[i], contains('--dart-define=HEISUCA_UPDATE_FEED_URL=https://heisuca.docaio.com.br/pacotes/ '));
      expect(linhas[i], contains('--dart-define=HEISUCA_UPDATE_APK_HOSTS=heisuca.docaio.com.br)'));
      expect(
        linhas[i - 1].trim(),
        r'if [[ "$GITHUB_REF_NAME" == claude/producao-* || "$GITHUB_REF_NAME" == claude/heisuca-* ]]; then',
      );
    }
  });
}
