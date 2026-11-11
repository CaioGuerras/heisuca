import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/paginacao.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/inicio/destaque.dart';
import 'package:heisuca/features/inicio/modelo.dart';

import '../../design/componentes/apoio.dart';

const _altura = 560.0;

Widget _destaque(List<TituloEmDestaque> titulos, {ValueChanged<int>? aoMudar}) =>
    Destaque(titulos: titulos, altura: _altura, aoMudar: aoMudar);

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: nota, anos, gêneros, classificação e sinopse do título', (tester) async {
      await tester.pumpWidget(
        naTela(
          tema: tema,
          _destaque(const [
            TituloEmDestaque(
              chave: 'a',
              titulo: 'A Viagem',
              nota: '8,6',
              anos: '2001',
              generos: 'Animação, Fantasia',
              classificacao: 'L',
              sinopse: 'Uma menina atravessa um mundo de espíritos.',
            ),
          ]),
        ),
      );
      expect(find.text('A Viagem'), findsOneWidget);
      expect(find.text('8,6'), findsOneWidget);
      expect(find.text('2001'), findsOneWidget);
      expect(find.text('Animação, Fantasia'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      expect(find.textContaining('Uma menina atravessa', findRichText: true), findsOneWidget);
      expect(tester.widget<Text>(find.text('A Viagem')).style!.color, tema.texto);
      expect(tester.getSize(find.byType(Destaque)).height, _altura);
    });
  }

  testWidgets('dado ausente não aparece: sem nota, sem sinopse, sem "Assistir" e sem pontos', (tester) async {
    await tester.pumpWidget(naTela(_destaque(const [TituloEmDestaque(chave: 'a', titulo: 'Só o título')])));
    expect(find.text('Só o título'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(find.text('·'), findsNothing);
    expect(find.text('Assistir'), findsNothing);
    expect(
      find.byType(RichText).evaluate().where((e) => (e.widget as RichText).text.toPlainText().contains('「')),
      isEmpty,
    );
    expect(tester.getSize(find.byType(Paginacao)), Size.zero);
  });

  testWidgets('lista vazia guarda o lugar, sem nada dentro', (tester) async {
    await tester.pumpWidget(naTela(_destaque(const [])));
    expect(tester.getSize(find.byType(Destaque)).height, _altura);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('a troca é só pelo dedo: parado, o destaque não avança', (tester) async {
    final trocas = <int>[];
    await tester.pumpWidget(
      naTela(
        _destaque(const [
          TituloEmDestaque(chave: 'a', titulo: 'Primeiro'),
          TituloEmDestaque(chave: 'b', titulo: 'Segundo'),
        ], aoMudar: trocas.add),
      ),
    );
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(trocas, isEmpty);
    expect(find.text('Primeiro'), findsOneWidget);
    expect(find.bySemanticsLabel('Destaque 1 de 2'), findsOneWidget);
  });

  testWidgets('arrastar troca o título e avisa quem usa', (tester) async {
    final trocas = <int>[];
    await tester.pumpWidget(
      naTela(
        _destaque(const [
          TituloEmDestaque(chave: 'a', titulo: 'Primeiro'),
          TituloEmDestaque(chave: 'b', titulo: 'Segundo'),
        ], aoMudar: trocas.add),
      ),
    );
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(trocas, [1]);
    expect(find.text('Segundo'), findsOneWidget);
    expect(find.bySemanticsLabel('Destaque 2 de 2'), findsOneWidget);
  });

  testWidgets('tocar abre o título, "Assistir" toca direto e segurar abre o menu', (tester) async {
    final chamadas = <String>[];
    await tester.pumpWidget(
      naTela(
        _destaque([
          TituloEmDestaque(
            chave: 'a',
            titulo: 'A Viagem',
            aoAbrir: () => chamadas.add('abrir'),
            aoAssistir: () => chamadas.add('assistir'),
            aoSegurar: () => chamadas.add('segurar'),
          ),
        ]),
      ),
    );
    final topo = tester.getTopLeft(find.byType(PageView)) + const Offset(120, 120);

    await tester.tapAt(topo);
    await tester.pumpAndSettle();
    expect(chamadas, ['abrir']);

    await tester.tap(find.text('Assistir'));
    await tester.pumpAndSettle();
    expect(chamadas, ['abrir', 'assistir']);

    await tester.longPressAt(topo);
    await tester.pumpAndSettle();
    expect(chamadas, ['abrir', 'assistir', 'segurar']);
  });

  testWidgets('"Assistir" tem área de toque de 48', (tester) async {
    await tester.pumpWidget(naTela(_destaque([TituloEmDestaque(chave: 'a', titulo: 'A Viagem', aoAssistir: () {})])));
    final botao = tester.getSize(
      find.ancestor(of: find.text('Assistir'), matching: find.bySemanticsLabel('Assistir A Viagem')).first,
    );
    expect(botao.height, greaterThanOrEqualTo(48));
    expect(botao.width, greaterThanOrEqualTo(48));
  });

  testWidgets('leitor de tela: o título inteiro numa frase e "Assistir" com o nome', (tester) async {
    final leitor = tester.ensureSemantics();
    await tester.pumpWidget(
      naTela(
        _destaque([
          TituloEmDestaque(
            chave: 'a',
            titulo: 'A Viagem',
            nota: '8,6',
            anos: '2001',
            generos: 'Animação, Fantasia',
            classificacao: 'L',
            aoAbrir: () {},
            aoAssistir: () {},
          ),
        ]),
      ),
    );
    expect(find.bySemanticsLabel('A Viagem, nota 8,6, 2001, Animação, Fantasia, classificação L'), findsOneWidget);
    expect(find.bySemanticsLabel('Assistir A Viagem'), findsOneWidget);
    leitor.dispose();
  });

  testWidgets('arte e logo vêm de quem usa; sem logo, o título escrito ocupa o lugar', (tester) async {
    await tester.pumpWidget(
      naTela(
        _destaque([
          TituloEmDestaque(
            chave: 'a',
            titulo: 'A Viagem',
            arte: (context, tamanho) => SizedBox.fromSize(key: const Key('arte'), size: tamanho),
            logo: (context, tamanho, semLogo) => KeyedSubtree(key: const Key('logo'), child: semLogo),
          ),
        ]),
      ),
    );
    expect(find.byKey(const Key('arte')), findsOneWidget);
    expect(find.byKey(const Key('logo')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('logo')), matching: find.text('A Viagem')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('arte'))).height, closeTo((_altura - 24) * Destaque.fracaoDaArte, 0.5));
  });

  testWidgets('letra grande e "remover animações" não estouram', (tester) async {
    await tester.pumpWidget(
      naTela(
        semAnimacao: true,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2), disableAnimations: true),
          child: SizedBox(
            width: 360,
            child: _destaque([
              TituloEmDestaque(
                chave: 'a',
                titulo: 'Um título bem comprido para caber em duas linhas',
                nota: '8,6',
                anos: '2019–2024',
                generos: 'Animação, Fantasia, Aventura',
                classificacao: '14',
                sinopse: 'Uma sinopse longa o bastante para passar de duas linhas na letra grande do sistema.',
                aoAssistir: () {},
              ),
              const TituloEmDestaque(chave: 'b', titulo: 'Segundo'),
            ]),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('se a lista encolhe, volta ao primeiro em vez de ficar numa página que não existe', (tester) async {
    Widget com(int quantos) =>
        naTela(_destaque([for (var i = 0; i < quantos; i++) TituloEmDestaque(chave: '$i', titulo: 'Título $i')]));
    await tester.pumpWidget(com(3));
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Título 2'), findsOneWidget);

    await tester.pumpWidget(com(1));
    await tester.pumpAndSettle();
    expect(find.text('Título 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
