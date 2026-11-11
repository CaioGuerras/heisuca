import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';

void main() {
  final hashes = [
    for (final item in (jsonDecode(File('test/fixtures/cor_poster/blurhash_200.json').readAsStringSync()) as List))
      (item as Map<String, dynamic>)['primary'] as String,
  ];

  test('antes de aquecer não há cor; depois, a paleta sai na hora', () async {
    final cache = CorPosterCache();
    expect(cache.ler(hashes[0], TemasCorPoster.hisui), isNull);
    var avisos = 0;
    cache.addListener(() => avisos++);
    await cache.aquecer(hashes.take(12));
    expect(avisos, 1, reason: 'um aviso por lote, não um por pôster');
    for (final hash in hashes.take(12)) {
      for (final tema in TemasCorPoster.todos) {
        expect(cache.ler(hash, tema), isNotNull);
      }
    }
  });

  test('a paleta de um pôster num tema é montada uma vez e reaproveitada', () async {
    final cache = CorPosterCache();
    await cache.aquecer([hashes[0]]);
    final primeira = cache.ler(hashes[0], TemasCorPoster.shikkoku);
    expect(identical(cache.ler(hashes[0], TemasCorPoster.shikkoku), primeira), isTrue);
    expect(identical(cache.ler(hashes[0], TemasCorPoster.hisui), primeira), isFalse);
  });

  test('dois pedidos do mesmo pôster calculam uma vez e os dois esperam', () async {
    final cache = CorPosterCache();
    var avisos = 0;
    cache.addListener(() => avisos++);
    final a = cache.paleta(hashes[3], TemasCorPoster.sumi);
    final b = cache.paleta(hashes[3], TemasCorPoster.shikkoku);
    expect(await a, isNotNull);
    expect(await b, isNotNull);
    expect(avisos, 1);
  });

  test('hash inválido não quebra nem é tentado de novo', () async {
    final cache = CorPosterCache();
    var avisos = 0;
    cache.addListener(() => avisos++);
    expect(await cache.paleta('isto não é um blurhash', TemasCorPoster.hisui), isNull);
    expect(await cache.paleta('isto não é um blurhash', TemasCorPoster.hisui), isNull);
    expect(await cache.paleta(null, TemasCorPoster.hisui), isNull);
    expect(avisos, 0);
  });

  test('o cache esquece o pôster usado há mais tempo', () async {
    final cache = CorPosterCache(capacidade: 4);
    await cache.aquecer(hashes.take(4));
    expect(cache.ler(hashes[0], TemasCorPoster.hisui), isNotNull); // 0 passa a ser o mais recente
    await cache.aquecer([hashes[4]]);
    expect(cache.guardadas, 4);
    expect(cache.ler(hashes[1], TemasCorPoster.hisui), isNull);
    expect(cache.ler(hashes[0], TemasCorPoster.hisui), isNotNull);
  });
}
