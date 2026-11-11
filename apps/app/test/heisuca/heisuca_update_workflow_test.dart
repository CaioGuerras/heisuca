import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// O atualizador próprio só entra na versão do site. A da Play nunca recebe o endereço do feed.
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

  test('o feed é https, do nosso site, e só no ramo de produção', () {
    final feed = linhas.where((l) => l.contains('HEISUCA_UPDATE_FEED_URL=')).toList();
    expect(feed, hasLength(2));
    for (final linha in feed) {
      expect(linha, contains('--dart-define=HEISUCA_UPDATE_FEED_URL=https://heisuca.docaio.com.br/pacotes/ '));
      expect(linha, contains('--dart-define=HEISUCA_UPDATE_APK_HOSTS=heisuca.docaio.com.br)'));
      expect(linhas[linhas.indexOf(linha) - 1], contains('== claude/producao-*'));
    }
  });
}
