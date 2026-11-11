// Vitrine da Fundação da V2: barra flutuante, cartões e botões numa tela "Início" simulada.
//   HEISUCA_SNAPSHOT=1 flutter test test/visual/v2_fundacao_test.dart --update-goldens
// Serve para comparar lado a lado com a referência; sem fotos (não há rede no teste): o cartão aparece na cor do pôster.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/barra_flutuante.dart';
import 'package:heisuca/design/componentes/botao.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/design/cor_poster/paleta_poster.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';
import 'package:heisuca/design/forma.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/design/tipo.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'heisuca_snapshot.dart';

// Sementes de pôsteres (cores de exemplo só para a vitrine).
const _sementes = [0xFF2E6F8E, 0xFF8E3B2E, 0xFF4E7A3A, 0xFF7A5BA8, 0xFFB8862B, 0xFF3A4E7A];

class _Vitrine extends StatelessWidget {
  const _Vitrine({required this.tema, required this.papel});
  final TemaHeisuca tema;
  final PapelDoTema papel;

  Color _cor(int semente) => Color(PaletaPoster.de(semente: semente, tema: papel).superficie2);

  Widget _fileira(String titulo, List<Widget> itens, double altura) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Forma.espaco4, Forma.espaco6, Forma.espaco4, Forma.espaco3),
        child: Row(
          children: [
            Expanded(child: Text(titulo, style: Tipo.subtitulo(tema))),
            Text('Ver tudo', style: Tipo.pequeno(tema).copyWith(color: tema.texto2)),
          ],
        ),
      ),
      SizedBox(
        height: altura,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
          itemCount: itens.length,
          separatorBuilder: (_, _) => const SizedBox(width: Forma.espaco3),
          itemBuilder: (_, i) => itens[i],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final paleta = PaletaPoster.de(semente: _sementes[0], tema: papel);
    return Scaffold(
      backgroundColor: Color(paleta.fundoFim),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [for (final c in paleta.degrade()) Color(c)],
          ),
        ),
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(top: 44, bottom: 120),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
                  child: Row(
                    children: [
                      Expanded(child: Text('Início', style: Tipo.titulo(tema))),
                      BotaoDeIcone(icone: Symbols.search_rounded, rotulo: 'Buscar', sobreArte: true, aoTocar: () {}),
                      const SizedBox(width: Forma.espaco2),
                      BotaoDeIcone(icone: Symbols.person_rounded, rotulo: 'Perfil', sobreArte: true, aoTocar: () {}),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Forma.espaco4, Forma.espaco6, Forma.espaco4, 0),
                  child: Row(
                    children: [
                      Botao(rotulo: 'Assistir', icone: Symbols.play_arrow_rounded, aoTocar: () {}),
                      const SizedBox(width: Forma.espaco3),
                      Botao(rotulo: 'Lista', icone: Symbols.add_rounded, tipo: TipoDeBotao.secundario, aoTocar: () {}),
                      const SizedBox(width: Forma.espaco2),
                      Botao(rotulo: 'Mais', tipo: TipoDeBotao.discreto, aoTocar: () {}),
                    ],
                  ),
                ),
                _fileira('Continuar', [
                  Cartao(
                    titulo: 'One Piece',
                    subtitulo: 'T23:E2 · Nami no Corre!',
                    largura: 220,
                    formato: FormatoDoCartao.paisagem,
                    corDoPoster: _cor(_sementes[1]),
                    progresso: 0.66,
                    tempo: '26:44 / 40:39',
                    aoTocar: () {},
                  ),
                  Cartao(
                    titulo: 'Deadwood',
                    subtitulo: 'T1:E4 · Aqui jaz um homem',
                    largura: 220,
                    formato: FormatoDoCartao.paisagem,
                    corDoPoster: _cor(_sementes[2]),
                    progresso: 0.2,
                    tempo: '10:41 / 55:10',
                    aoTocar: () {},
                  ),
                ], 184),
                _fileira('Animes', [
                  for (final (i, t) in const [
                    'InuYasha',
                    'Gintama',
                    'Frieren e a Jornada para o Além',
                    'Naruto',
                  ].indexed)
                    Cartao(
                      titulo: t,
                      subtitulo: '2000 – 2004',
                      largura: 118,
                      corDoPoster: _cor(_sementes[i + 2]),
                      nota: '8,${i + 2}',
                      aoTocar: () {},
                    ),
                ], 232),
                _fileira('Filmes', [
                  for (final (i, t) in const ['Akira', 'Paprika', 'Perfect Blue', 'Your Name'].indexed)
                    Cartao(
                      titulo: t,
                      subtitulo: '19${88 + i}',
                      largura: 118,
                      corDoPoster: _cor(_sementes[(i + 4) % 6]),
                      aoTocar: () {},
                    ),
                ], 232),
              ],
            ),
            Positioned(
              left: Forma.espaco4,
              right: Forma.espaco4,
              bottom: 24,
              child: Center(
                child: BarraFlutuante(
                  desfoque: false, // o desfoque não sai na captura do teste
                  indice: 0,
                  aoMudar: (_) {},
                  destinos: const [
                    DestinoDaBarra(icone: Symbols.home_rounded, rotulo: 'Início'),
                    DestinoDaBarra(icone: Symbols.explore_rounded, rotulo: 'Explorar'),
                    DestinoDaBarra(icone: Symbols.bookmark_rounded, rotulo: 'Minha lista'),
                    DestinoDaBarra(icone: Symbols.download_rounded, rotulo: 'Baixados'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  final temas = {
    'shikkoku': (TemaHeisuca.shikkoku, TemasCorPoster.shikkoku),
    'hisui': (TemaHeisuca.hisui, TemasCorPoster.hisui),
    'sumi': (TemaHeisuca.sumi, TemasCorPoster.sumi),
  };
  for (final MapEntry(key: nome, value: (tema, papel)) in temas.entries) {
    testWidgets('vitrine da Fundação: $nome', (tester) async {
      await heisucaLoadFonts();
      heisucaPhoneView(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: tema.paraMaterial(),
          home: _Vitrine(tema: tema, papel: papel),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/v2_fundacao_$nome.png'));
    }, skip: !heisucaSnapshotEnabled);
  }
}
