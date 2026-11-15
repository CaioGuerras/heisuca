// Tela Busca da V2 com dados de exemplo, nos três temas: antes de digitar (recentes) e com resultados.
//   HEISUCA_SNAPSHOT=1 flutter test test/visual/v2_busca_test.dart --update-goldens
// Serve para comparar lado a lado com a busca de hoje. Sem fotos (não há rede no teste): a arte é um degradê da cor
// do pôster (BlurHash de verdade, do acervo de teste).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/busca/modelo.dart';
import 'package:heisuca/features/busca/tela_busca.dart';
import 'package:heisuca/features/inicio/modelo.dart' show FazArte;

import 'heisuca_snapshot.dart';

void main() {
  final hashes = [
    for (final item in (jsonDecode(File('test/fixtures/cor_poster/blurhash_200.json').readAsStringSync()) as List))
      (item as Map<String, dynamic>)['primary'] as String,
  ];

  const nomes = [
    ('Duna', TipoDoResultado.filme, '2021', '8,0'),
    ('Duna: Parte Dois', TipoDoResultado.filme, '2024', '8,5'),
    ('Duna: A Profecia', TipoDoResultado.serie, '2024', '7,1'),
    ('Duna (1984)', TipoDoResultado.filme, '1984', '6,3'),
    ('Dunkirk', TipoDoResultado.filme, '2017', '7,8'),
    ('Dune Drifter', TipoDoResultado.filme, '2020', null),
  ];

  for (final tema in TemaHeisuca.todos) {
    testWidgets('tela Busca: ${tema.nome}', (tester) async {
      await heisucaLoadFonts();
      heisucaPhoneView(tester);
      final cores = CorPosterCache();
      final usados = [for (var i = 0; i < nomes.length; i++) hashes[i * 7 % hashes.length]];
      await tester.runAsync(() => cores.aquecer(usados));

      FazArte arte(String hash) {
        final paleta = cores.ler(hash, TemasCorPoster.de(tema.nome))!;
        return (context, tamanho) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(paleta.semente), Color(paleta.superficie2)],
            ),
          ),
          child: SizedBox.fromSize(size: tamanho),
        );
      }

      Widget tela({required bool buscou}) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: tema.paraMaterial(),
        home: Scaffold(
          body: TelaBusca(
            campo: TextEditingController(text: buscou ? 'duna' : ''),
            foco: FocusNode(),
            focoInicial: false,
            cores: cores,
            aoVoltar: () {},
            recentes: const ['Duna', 'Naruto', 'O Urso', 'Gintama'],
            aoEscolherRecente: (_) {},
            aoTirarRecente: (_) {},
            aoLimparRecentes: () {},
            buscou: buscou,
            titulos: [
              for (final (i, (nome, tipo, anos, nota)) in nomes.indexed)
                TituloDaBusca(
                  chave: 't$i',
                  titulo: nome,
                  tipo: tipo,
                  anos: anos,
                  nota: nota,
                  origem: i == 0 ? '2 fontes' : null,
                  visto: i == 3,
                  hash: usados[i],
                  arte: arte(usados[i]),
                  aoTocar: () {},
                ),
            ],
            pessoas: [
              PessoaDaBusca(chave: 'p1', nome: 'Denis Villeneuve', aoTocar: () {}),
              PessoaDaBusca(chave: 'p2', nome: 'Zendaya', aoTocar: () {}),
            ],
          ),
        ),
      );

      await tester.pumpWidget(tela(buscou: false));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/v2_busca_${tema.nome}_recentes.png'));

      await tester.pumpWidget(tela(buscou: true));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/v2_busca_${tema.nome}.png'));
    }, skip: !heisucaSnapshotEnabled);
  }
}
