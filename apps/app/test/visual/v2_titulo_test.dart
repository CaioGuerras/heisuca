// Tela Título da V2 com dados de exemplo, nos três temas.
//   HEISUCA_SNAPSHOT=1 flutter test test/visual/v2_titulo_test.dart --update-goldens
// Serve para comparar lado a lado com a referência. Sem fotos (não há rede no teste): a arte é um degradê da cor do
// pôster (BlurHash de verdade, do acervo de teste).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/titulo/modelo.dart';
import 'package:heisuca/features/titulo/tela_titulo.dart';

import 'heisuca_snapshot.dart';

void main() {
  final hashes = [
    for (final item in (jsonDecode(File('test/fixtures/cor_poster/blurhash_200.json').readAsStringSync()) as List))
      (item as Map<String, dynamic>)['primary'] as String,
  ];

  for (final tema in TemaHeisuca.todos) {
    testWidgets('tela Título: ${tema.nome}', (tester) async {
      await heisucaLoadFonts();
      heisucaPhoneView(tester);
      final cores = CorPosterCache();
      final hash = hashes[2];
      await tester.runAsync(() => cores.aquecer([hash]));
      final paleta = cores.ler(hash, TemasCorPoster.de(tema.nome))!;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: tema.paraMaterial(),
          home: Scaffold(
            body: TelaTitulo(
              cores: cores,
              aoAbrirMenu: () {},
              pagina: PaginaDoTitulo(
                chave: 'd',
                titulo: 'Deadwood',
                hash: hash,
                nota: '7,1',
                anos: '2004 – 2006',
                generos: 'Faroeste, Crime, Drama',
                classificacao: '16',
                detalhes: const ['3 temporadas', '1h 2min', '1080p'],
                sinopse:
                    'O ex-homem da lei Seth Bullock chega ao acampamento de Deadwood para abrir uma loja de '
                    'ferragens. O dono do saloon, Al Swearengen, desconfia dos recém-chegados. Wild Bill Hickok e '
                    'Calamity Jane também chegam à cidade.',
                rotuloDeAssistir: 'Continuar T1:E3',
                progresso: 0.4,
                arte: (context, tamanho) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(paleta.semente), Color(paleta.superficie2)],
                    ),
                  ),
                  child: SizedBox.fromSize(size: tamanho),
                ),
                aoAssistir: () {},
                naLista: true,
                aoAlternarLista: () {},
                aoAlternarVisto: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/v2_titulo_${tema.nome}.png'));
    }, skip: !heisucaSnapshotEnabled);
  }
}
