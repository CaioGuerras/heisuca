import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/cabecalho_de_fileira.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/inicio/fileira.dart';
import 'package:heisuca/features/inicio/modelo.dart';

import '../../design/componentes/apoio.dart';

List<ItemDaFileira> _itens(int quantos, {VoidCallback? aoTocar}) => [
  for (var i = 0; i < quantos; i++) ItemDaFileira(chave: 'item-$i', titulo: 'Título $i', aoTocar: aoTocar),
];

Widget _naLargura(Widget filho) => SizedBox(width: 412, child: filho);

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: cabeçalho e cartões da fileira', (tester) async {
      await tester.pumpWidget(
        naTela(
          tema: tema,
          _naLargura(
            Fileira(
              cores: CorPosterCache(),
              dados: FileiraDoInicio(chave: 'filmes', titulo: 'Chegaram em Filmes', itens: _itens(3)),
            ),
          ),
        ),
      );
      expect(find.text('Chegaram em Filmes'), findsOneWidget);
      expect(find.byType(Cartao), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('fileira vazia não aparece, nem o cabeçalho', (tester) async {
    await tester.pumpWidget(
      naTela(
        _naLargura(
          Fileira(
            cores: CorPosterCache(),
            dados: const FileiraDoInicio(chave: 'vazia', titulo: 'Em breve', itens: []),
          ),
        ),
      ),
    );
    expect(find.byType(CabecalhoDeFileira), findsNothing);
    expect(tester.getSize(find.byType(Fileira)).height, 0);
  });

  testWidgets('numerada: mostra a posição e para no décimo', (tester) async {
    final leitor = tester.ensureSemantics();
    await tester.pumpWidget(
      naTela(
        _naLargura(
          Fileira(
            cores: CorPosterCache(),
            dados: FileiraDoInicio(chave: 'alta', titulo: 'Em alta no Brasil', numerada: true, itens: _itens(14)),
          ),
        ),
      ),
    );
    expect(find.text('1'), findsOneWidget);
    expect(find.bySemanticsLabel('1º lugar'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(-6000, 0));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);
    expect(find.text('11'), findsNothing);
    expect(find.text('Título 9'), findsOneWidget);
    expect(find.text('Título 10'), findsNothing);
    leitor.dispose();
  });

  testWidgets('tocar e segurar no cartão chamam as ações do item', (tester) async {
    final chamadas = <String>[];
    await tester.pumpWidget(
      naTela(
        _naLargura(
          Fileira(
            cores: CorPosterCache(),
            dados: FileiraDoInicio(
              chave: 'continuar',
              titulo: 'Continuar',
              formato: FormatoDoCartao.paisagem,
              itens: [
                ItemDaFileira(
                  chave: 'ep',
                  titulo: 'A Série',
                  subtitulo: 'T1:E2 · O começo',
                  progresso: 0.4,
                  tempo: 'restam 12 min',
                  aoTocar: () => chamadas.add('tocar'),
                  aoSegurar: () => chamadas.add('segurar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('T1:E2 · O começo'), findsOneWidget);
    expect(find.text('restam 12 min'), findsOneWidget);
    await tester.tap(find.byType(Cartao));
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(Cartao));
    await tester.pumpAndSettle();
    expect(chamadas, ['tocar', 'segurar']);
  });

  testWidgets('"Ver tudo" só aparece com ação e chama a ação', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      naTela(
        _naLargura(
          Fileira(
            cores: CorPosterCache(),
            dados: FileiraDoInicio(chave: 'animes', titulo: 'Animes', itens: _itens(2), aoVerTudo: () => toques++),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ver tudo'));
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('a arte recebe o tamanho do quadro do cartão', (tester) async {
    Size? pedido;
    await tester.pumpWidget(
      naTela(
        _naLargura(
          Fileira(
            cores: CorPosterCache(),
            dados: FileiraDoInicio(
              chave: 'filmes',
              titulo: 'Filmes',
              itens: [
                ItemDaFileira(
                  chave: 'a',
                  titulo: 'A Viagem',
                  arte: (context, tamanho) {
                    pedido = tamanho;
                    return const SizedBox.expand(key: Key('arte'));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('arte')), findsOneWidget);
    expect(pedido, isNotNull);
    expect(pedido!.height / pedido!.width, closeTo(1.5, 0.02));
  });

  testWidgets('pôster no menor tamanho (tela de 360) com letra em 200% não estoura', (tester) async {
    await tester.pumpWidget(
      naTela(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 780), textScaler: TextScaler.linear(2)),
          child: _naLargura(
            Fileira(
              cores: CorPosterCache(),
              dados: FileiraDoInicio(
                chave: 'series',
                titulo: 'Séries',
                itens: [
                  for (var i = 0; i < 6; i++)
                    ItemDaFileira(
                      chave: '$i',
                      titulo: 'Um título comprido de série $i',
                      subtitulo: '2024',
                      nota: '8,1',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(Cartao).first).width, 88);
    expect(tester.getSize(find.byType(Cartao).first).height, greaterThanOrEqualTo(48));
  });

  testWidgets('letra grande não estoura a fileira', (tester) async {
    await tester.pumpWidget(
      naTela(
        MediaQuery(
          data: const MediaQueryData(size: Size(412, 914), textScaler: TextScaler.linear(2)),
          child: _naLargura(
            Fileira(
              cores: CorPosterCache(),
              dados: FileiraDoInicio(
                chave: 'continuar',
                titulo: 'Continuar',
                formato: FormatoDoCartao.paisagem,
                itens: [
                  for (var i = 0; i < 3; i++)
                    ItemDaFileira(
                      chave: '$i',
                      titulo: 'Um título comprido de série $i',
                      subtitulo: 'T1:E$i · Episódio de nome longo',
                      progresso: 0.5,
                      tempo: 'restam 1 h 12 min',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('enquanto carrega, guarda o lugar sem falar nada ao leitor de tela', (tester) async {
    final leitor = tester.ensureSemantics();
    await tester.pumpWidget(naTela(_naLargura(const FileiraCarregando(formato: FormatoDoCartao.paisagem))));
    expect(find.byType(Text), findsNothing);
    expect(tester.getSize(find.byType(FileiraCarregando)).height, greaterThan(100));
    expect(tester.getSemantics(find.byType(FileiraCarregando)).label, isEmpty);
    leitor.dispose();
  });
}
