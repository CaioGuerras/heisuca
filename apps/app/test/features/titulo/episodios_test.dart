import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/titulo/episodios.dart';
import 'package:heisuca/features/titulo/modelo.dart';

import '../../design/componentes/apoio.dart';

List<EpisodioDoTitulo> _lista(int quantos, {int atual = 0, void Function(int)? aoTocar}) => [
  for (var n = 1; n <= quantos; n++)
    EpisodioDoTitulo(
      chave: 'e$n',
      numero: n,
      nome: 'Capítulo $n',
      duracao: '58 min',
      progresso: n < atual ? 1 : null,
      atual: n == atual,
      aoTocar: aoTocar == null ? null : () => aoTocar(n),
    ),
];

Widget _naLargura(Widget filho, {TemaHeisuca tema = TemaHeisuca.shikkoku, bool semAnimacao = false}) => naTela(
  tema: tema,
  semAnimacao: semAnimacao,
  SizedBox(width: double.infinity, child: filho),
);

void _celular(WidgetTester tester, [Size tamanho = const Size(390, 844)]) {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: nome da temporada, episódios numerados e o atual em destaque', (tester) async {
      _celular(tester);
      await tester.pumpWidget(
        _naLargura(
          tema: tema,
          Episodios(
            temporadas: [TemporadaDoTitulo(chave: 't1', nome: 'Temporada 1', episodios: _lista(3, atual: 2))],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('Temporada 1')).style!.color, tema.texto);
      expect(find.text('1. Capítulo 1'), findsOneWidget);
      final cartoes = tester.widgetList<Cartao>(find.byType(Cartao)).toList();
      expect(cartoes.every((cartao) => cartao.formato == FormatoDoCartao.paisagem), isTrue);
      expect([for (final cartao in cartoes) cartao.emDestaque], [false, true, false]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('uma temporada só: o nome não é seletor; sem episódios e sem temporadas, nada estoura', (tester) async {
    _celular(tester);
    await tester.pumpWidget(
      _naLargura(
        Episodios(
          temporadas: [TemporadaDoTitulo(chave: 't1', nome: 'Temporada 1', episodios: _lista(2))],
          aoVerTudo: (_) {},
        ),
      ),
    );
    expect(find.byTooltip('Temporada 1, trocar de temporada'), findsNothing);
    expect(find.bySemanticsLabel('Temporada 1, trocar de temporada'), findsNothing);
    expect(find.text('Ver tudo'), findsOneWidget);

    await tester.pumpWidget(
      _naLargura(
        Episodios(
          temporadas: const [TemporadaDoTitulo(chave: 't1', nome: 'Temporada 1', episodios: [])],
          aoVerTudo: (_) {},
        ),
      ),
    );
    expect(find.text('Esta temporada ainda não tem episódios.'), findsOneWidget);
    expect(find.text('Ver tudo'), findsNothing);

    await tester.pumpWidget(_naLargura(const Episodios(temporadas: [])));
    expect(find.byType(Cartao), findsNothing);
    expect(tester.getSize(find.byType(Episodios)).height, 0);
  });

  testWidgets('enquanto os episódios carregam, cartões vazios guardam o lugar e o leitor de tela não os lê', (
    tester,
  ) async {
    _celular(tester);
    final alca = tester.ensureSemantics();
    await tester.pumpWidget(
      _naLargura(
        const Episodios(
          temporadas: [TemporadaDoTitulo(chave: 't1', nome: 'Temporada 1')],
        ),
      ),
    );
    // A lista só monta os que aparecem: na largura de um celular, dois.
    expect(find.byType(Cartao), findsAtLeastNWidgets(2));
    expect(tester.widgetList<Cartao>(find.byType(Cartao)).every((cartao) => cartao.aoTocar == null), isTrue);
    // Cada cartão vazio fica fora da árvore do leitor de tela, e nenhum vira botão.
    for (final cartao in find.byType(Cartao).evaluate()) {
      expect(find.ancestor(of: find.byWidget(cartao.widget), matching: find.byType(ExcludeSemantics)), findsWidgets);
    }
    expect(find.bySemanticsLabel(RegExp('Epis[oó]dio [0-9]')), findsNothing);
    expect(tester.takeException(), isNull);
    alca.dispose();
  });

  testWidgets('trocar de temporada: a folha lista todas, marca a atual e a escolha troca os episódios', (tester) async {
    _celular(tester);
    final alca = tester.ensureSemantics();
    final abertas = <int>[];
    await tester.pumpWidget(
      _naLargura(
        Episodios(
          inicial: 1,
          aoMudarTemporada: abertas.add,
          temporadas: [
            TemporadaDoTitulo(chave: 't1', nome: 'Temporada 1', episodios: _lista(2)),
            TemporadaDoTitulo(
              chave: 't2',
              nome: 'Temporada 2',
              episodios: const [EpisodioDoTitulo(chave: 'x', numero: 1, nome: 'O retorno')],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1. O retorno'), findsOneWidget);

    final seletor = find.bySemanticsLabel('Temporada 2, trocar de temporada');
    expect(tester.getSize(seletor).height, greaterThanOrEqualTo(48));
    await tester.tap(seletor);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Temporada 2').last).flagsCollection.isSelected.toBoolOrNull(),
      isTrue,
    );
    final opcao = find.bySemanticsLabel('Temporada 1');
    expect(tester.getSize(opcao).height, greaterThanOrEqualTo(48));
    await tester.tap(opcao);
    await tester.pumpAndSettle();

    expect(abertas, [0]);
    expect(find.text('1. Capítulo 1'), findsOneWidget);
    expect(find.text('1. O retorno'), findsNothing);
    alca.dispose();
  });

  testWidgets('tocar no episódio abre o episódio, e "Ver tudo" diz de qual temporada', (tester) async {
    _celular(tester);
    final tocados = <int>[];
    final verTudo = <int>[];
    await tester.pumpWidget(
      _naLargura(
        Episodios(
          temporadas: [
            TemporadaDoTitulo(
              chave: 't1',
              nome: 'Temporada 1',
              episodios: _lista(3, aoTocar: tocados.add),
            ),
          ],
          aoVerTudo: verTudo.add,
        ),
      ),
    );
    await tester.tap(find.text('1. Capítulo 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver tudo'));
    await tester.pumpAndSettle();
    expect(tocados, [1]);
    expect(verTudo, [0]);
  });

  testWidgets('mais de dez episódios: as faixas aparecem, têm 48 de toque e levam a fileira até o primeiro da faixa', (
    tester,
  ) async {
    _celular(tester);
    final alca = tester.ensureSemantics();
    await tester.pumpWidget(
      _naLargura(
        semAnimacao: true,
        Episodios(
          temporadas: [TemporadaDoTitulo(chave: 't1', nome: 'Temporada 1', episodios: _lista(24))],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1-10'), findsOneWidget);
    expect(find.text('11-20'), findsOneWidget);
    expect(find.text('21-24'), findsOneWidget);
    bool? escolhida(String rotulo) =>
        tester.getSemantics(find.bySemanticsLabel(rotulo)).flagsCollection.isSelected.toBoolOrNull();
    expect(escolhida('Episódios 1 a 10'), isTrue);
    expect(tester.getSize(find.bySemanticsLabel('Episódios 11 a 20')).shortestSide, greaterThanOrEqualTo(48));
    expect(find.text('11. Capítulo 11'), findsNothing);

    await tester.tap(find.text('11-20'));
    await tester.pumpAndSettle();
    expect(find.text('11. Capítulo 11'), findsOneWidget);
    expect(tester.getTopLeft(find.text('11. Capítulo 11')).dx, closeTo(16, 1));
    expect(escolhida('Episódios 11 a 20'), isTrue);
    expect(escolhida('Episódios 1 a 10'), isFalse);

    // Rolar com o dedo também move a faixa marcada.
    await tester.drag(find.text('11. Capítulo 11'), const Offset(-6000, 0));
    await tester.pumpAndSettle();
    expect(escolhida('Episódios 21 a 24'), isTrue);
    alca.dispose();
  });

  testWidgets('até dez episódios não há faixas; a fileira abre no episódio atual', (tester) async {
    _celular(tester);
    await tester.pumpWidget(
      _naLargura(
        Episodios(
          temporadas: [TemporadaDoTitulo(chave: 't1', nome: 'Temporada 1', episodios: _lista(10, atual: 7))],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1-10'), findsNothing);
    expect(find.text('7. Capítulo 7'), findsOneWidget);
    expect(tester.getTopLeft(find.text('7. Capítulo 7')).dx, closeTo(16, 1));
    expect(find.text('1. Capítulo 1'), findsNothing);
  });

  testWidgets('letra em 200% e "remover animações": monta sem estourar nos três temas', (tester) async {
    _celular(tester, const Size(320, 700));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final tema in TemaHeisuca.todos) {
      await tester.pumpWidget(
        _naLargura(
          tema: tema,
          semAnimacao: true,
          Episodios(
            temporadas: [
              TemporadaDoTitulo(chave: 't1', nome: 'Temporada 1: A longa travessia', episodios: _lista(24, atual: 12)),
              const TemporadaDoTitulo(chave: 't2', nome: 'Temporada 2'),
            ],
            aoVerTudo: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tema.nome);
    }
  });
}
