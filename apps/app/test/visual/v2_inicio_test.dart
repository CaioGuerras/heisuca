// Tela Início da V2 com dados de exemplo, nos três temas.
//   HEISUCA_SNAPSHOT=1 flutter test test/visual/v2_inicio_test.dart --update-goldens
// Serve para comparar lado a lado com a referência. Sem fotos (não há rede no teste): a arte do destaque é um degradê
// da cor do pôster e cada cartão aparece na cor do próprio pôster (BlurHash de verdade, do acervo de teste).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_palette.dart';
import 'package:heisuca/design/componentes/barra_flutuante.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/design/componentes/pilula_de_perfil.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/casca/casca.dart';
import 'package:heisuca/features/inicio/fileira.dart';
import 'package:heisuca/features/inicio/modelo.dart';
import 'package:heisuca/features/inicio/tela_inicio.dart';
import 'package:heisuca/features/tema_da_v2.dart';

import 'package:material_symbols_icons/symbols.dart';

import 'heisuca_snapshot.dart';

void main() {
  final hashes = [
    for (final item in (jsonDecode(File('test/fixtures/cor_poster/blurhash_200.json').readAsStringSync()) as List))
      (item as Map<String, dynamic>)['primary'] as String,
  ];

  for (final tema in TemaHeisuca.todos) {
    testWidgets('tela Início: ${tema.nome}', (tester) async {
      await heisucaLoadFonts();
      heisucaPhoneView(tester);
      final cores = CorPosterCache();
      await tester.runAsync(() => cores.aquecer(hashes.take(40)));
      final papel = TemasCorPoster.de(tema.nome);

      FazArte arteDe(String hash) => (context, tamanho) {
        final paleta = cores.ler(hash, papel)!;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(paleta.semente), Color(paleta.superficie2)],
            ),
          ),
          child: SizedBox.fromSize(size: tamanho),
        );
      };

      var proximo = 3;
      ItemDaFileira item(String titulo, {String? subtitulo, String? nota, double? progresso, String? tempo}) {
        final hash = hashes[proximo++];
        return ItemDaFileira(
          chave: 'i$proximo',
          titulo: titulo,
          subtitulo: subtitulo,
          hash: hash,
          nota: nota,
          progresso: progresso,
          tempo: tempo,
          aoTocar: () {},
        );
      }

      final destaques = [
        TituloEmDestaque(
          chave: 'd0',
          titulo: 'Frieren e a Jornada para o Além',
          nota: '8,9',
          anos: '2023',
          generos: 'Animação, Aventura, Drama',
          classificacao: '12',
          sinopse:
              'Depois da vitória sobre o Rei Demônio, a maga elfa Frieren refaz o caminho dos antigos companheiros.',
          hash: hashes[0],
          arte: arteDe(hashes[0]),
          aoAbrir: () {},
          aoAssistir: () {},
        ),
        TituloEmDestaque(chave: 'd1', titulo: 'Akira', anos: '1988', hash: hashes[1], arte: arteDe(hashes[1])),
        TituloEmDestaque(
          chave: 'd2',
          titulo: 'Deadwood',
          anos: '2004 – 2006',
          hash: hashes[2],
          arte: arteDe(hashes[2]),
        ),
      ];

      final fileiras = [
        FileiraDoInicio(
          chave: 'continuar',
          titulo: 'Continuar assistindo',
          formato: FormatoDoCartao.paisagem,
          itens: [
            item('One Piece', subtitulo: 'T23:E2 · Nami no Corre!', progresso: 0.66, tempo: '26:44 / 40:39'),
            item('Deadwood', subtitulo: 'T1:E4 · Aqui jaz um homem', progresso: 0.2, tempo: '10:41 / 55:10'),
          ],
        ),
        FileiraDoInicio(
          chave: 'animes',
          titulo: 'Animes',
          aoVerTudo: () {},
          itens: [
            item('InuYasha', subtitulo: '2000 – 2004', nota: '8,2'),
            item('Gintama', subtitulo: '2006 – 2018', nota: '8,7'),
            item('Frieren e a Jornada para o Além', subtitulo: '2023', nota: '8,9'),
            item('Naruto', subtitulo: '2002 – 2007', nota: '8,4'),
          ],
        ),
        FileiraDoInicio(
          chave: 'alta',
          titulo: 'Em alta',
          numerada: true,
          itens: [item('Akira'), item('Paprika'), item('Perfect Blue'), item('Your Name')],
        ),
        FileiraDoInicio(
          chave: 'filmes',
          titulo: 'Filmes',
          aoVerTudo: () {},
          itens: [
            item('A Viagem de Chihiro', subtitulo: '2001'),
            item('Meu Amigo Totoro', subtitulo: '1988'),
            item('O Castelo Animado', subtitulo: '2004'),
            item('Princesa Mononoke', subtitulo: '1997'),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          // A casca lê o tema escolhido no app (a paleta); a tela, o tema da V2.
          theme: temaDaV2(
            ThemeData(
              extensions: [
                switch (tema.nome) {
                  'hisui' => CgflixPalette.heitor,
                  'sumi' => CgflixPalette.sumi,
                  _ => CgflixPalette.isis,
                },
              ],
            ),
            tema,
          ),
          home: Casca(
            indice: 0,
            aoMudar: (_) {},
            desfoque: false,
            destinos: const [
              DestinoDaBarra(icone: Symbols.home_rounded, rotulo: 'Início'),
              DestinoDaBarra(icone: Symbols.explore_rounded, rotulo: 'Explorar'),
              DestinoDaBarra(icone: Symbols.bookmark_rounded, rotulo: 'Minha lista'),
              DestinoDaBarra(icone: Symbols.download_rounded, rotulo: 'Baixados'),
            ],
            corpo: TelaInicio(
              destaques: destaques,
              fileiras: [for (final fileira in fileiras) Fileira(dados: fileira, cores: cores)],
              aoBuscar: () {},
              perfil: PilulaDePerfil(nome: 'Caio', aoTocar: () {}, sobreArte: true),
              cores: cores,
              folgaInferior: Casca.reserva,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/v2_inicio_${tema.nome}.png'));
    }, skip: !heisucaSnapshotEnabled);
  }
}
