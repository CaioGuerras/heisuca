import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/design/componentes/pilula_de_escolha.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/forma.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/explorar/modelo.dart';
import 'package:heisuca/features/explorar/tela_explorar.dart';
import 'package:heisuca/features/inicio/aviso.dart';

import '../../design/componentes/apoio.dart';

const _bibliotecas = [
  BibliotecaDoExplorar(chave: 'f', titulo: 'Filmes'),
  BibliotecaDoExplorar(chave: 's', titulo: 'Séries'),
];
const _generos = [GeneroDoExplorar(chave: 'acao', nome: 'Ação'), GeneroDoExplorar(chave: 'drama', nome: 'Drama')];

List<ItemDoExplorar> _itens(int quantos, {VoidCallback? aoTocar, VoidCallback? aoSegurar}) => [
  for (var i = 0; i < quantos; i++)
    ItemDoExplorar(
      chave: 'k$i',
      titulo: 'Título $i',
      anos: '${2000 + i}',
      nota: i == 0 ? '8,6' : null,
      visto: i == 1,
      aoTocar: aoTocar,
      aoSegurar: aoSegurar,
    ),
];

void _tela(WidgetTester tester, Size tamanho) {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('colunas: nunca menos de 3 no celular, mais em tela larga, no máximo 9', () {
    expect(TelaExplorar.colunasPara(328), 3);
    expect(TelaExplorar.colunasPara(380), 3);
    expect(TelaExplorar.colunasPara(600), 4);
    expect(TelaExplorar.colunasPara(1000), 6);
    expect(TelaExplorar.colunasPara(4000), 9);
  });

  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: bibliotecas, ordem, filtros, gêneros e a grade em 3 colunas', (tester) async {
      _tela(tester, const Size(400, 900));
      await tester.pumpWidget(
        naTela(
          tema: tema,
          TelaExplorar(
            bibliotecas: _bibliotecas,
            bibliotecaAtual: 'f',
            generos: _generos,
            generoAtual: 'drama',
            soNaoVistos: false,
            aoAbrirFavoritos: () {},
            aoBuscar: () {},
            itens: _itens(7),
            cores: CorPosterCache(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final texto in ['Filmes', 'Séries', 'Favoritos', 'Título A–Z', 'Não vistos', 'Ação', 'Drama']) {
        expect(find.widgetWithText(PilulaDeEscolha, texto), findsOneWidget, reason: texto);
      }
      bool? marcada(String texto) =>
          tester.widget<PilulaDeEscolha>(find.widgetWithText(PilulaDeEscolha, texto)).selecionado;
      expect(marcada('Filmes'), isTrue);
      expect(marcada('Séries'), isFalse);
      expect(marcada('Favoritos'), isNull, reason: 'leva a outra tela: não é uma escolha');
      expect(marcada('Drama'), isTrue);
      expect(marcada('Não vistos'), isFalse);

      expect(find.byType(Cartao), findsNWidgets(7));
      final primeiro = tester.getRect(find.byKey(const ValueKey('k0')));
      final terceiro = tester.getRect(find.byKey(const ValueKey('k2')));
      final quarto = tester.getRect(find.byKey(const ValueKey('k3')));
      expect(primeiro.left, Forma.espaco4);
      expect(terceiro.right, moreOrLessEquals(400 - Forma.espaco4, epsilon: 0.01));
      expect(terceiro.top, primeiro.top);
      expect(quarto.left, primeiro.left);
      expect(quarto.top, greaterThan(primeiro.bottom));
      expect(find.bySemanticsLabel('Título 0, 2000, 8,6'), findsOneWidget);
      expect(find.bySemanticsLabel('Título 1, 2001, visto'), findsOneWidget);
      expect(find.bySemanticsLabel('Buscar'), findsOneWidget);
      expect(find.bySemanticsLabel('Ordenar, agora por Título A–Z'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tela larga ganha colunas; letra grande não estoura a grade', (tester) async {
    _tela(tester, const Size(1000, 800));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: naTela(
          TelaExplorar(bibliotecas: _bibliotecas, bibliotecaAtual: 'f', itens: _itens(12), cores: CorPosterCache()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final topo = tester.getRect(find.byKey(const ValueKey('k0'))).top;
    expect(tester.getRect(find.byKey(const ValueKey('k5'))).top, topo, reason: '6 colunas em 968 de largura');
    expect(tester.getRect(find.byKey(const ValueKey('k6'))).top, greaterThan(topo));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar avisa: biblioteca, gênero (o marcado desmarca), não vistos, cartão e toque longo', (tester) async {
    _tela(tester, const Size(400, 900));
    final avisos = <String>[];
    await tester.pumpWidget(
      naTela(
        TelaExplorar(
          bibliotecas: _bibliotecas,
          bibliotecaAtual: 'f',
          aoEscolherBiblioteca: (chave) => avisos.add('biblioteca $chave'),
          aoAbrirFavoritos: () => avisos.add('favoritos'),
          generos: _generos,
          generoAtual: 'drama',
          aoEscolherGenero: (chave) => avisos.add('gênero $chave'),
          soNaoVistos: false,
          aoMudarSoNaoVistos: (ligado) => avisos.add('não vistos $ligado'),
          aoBuscar: () => avisos.add('buscar'),
          itens: _itens(3, aoTocar: () => avisos.add('abrir'), aoSegurar: () => avisos.add('menu')),
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filmes'));
    await tester.tap(find.text('Séries'));
    await tester.tap(find.text('Favoritos'));
    await tester.tap(find.text('Ação'));
    await tester.tap(find.text('Drama'));
    await tester.tap(find.text('Não vistos'));
    await tester.tap(find.bySemanticsLabel('Buscar'));
    await tester.tap(find.byKey(const ValueKey('k0')));
    await tester.longPress(find.byKey(const ValueKey('k2')));
    await tester.pumpAndSettle();
    expect(avisos, [
      'biblioteca s',
      'favoritos',
      'gênero acao',
      'gênero null',
      'não vistos true',
      'buscar',
      'abrir',
      'menu',
    ], reason: 'a biblioteca já aberta não avisa de novo');
  });

  for (final semAnimacao in [false, true]) {
    testWidgets('a ordem abre uma folha e devolve a escolha (remover animações: $semAnimacao)', (tester) async {
      _tela(tester, const Size(400, 900));
      OrdemDoExplorar? escolhida;
      await tester.pumpWidget(
        naTela(
          semAnimacao: semAnimacao,
          TelaExplorar(
            bibliotecas: _bibliotecas,
            bibliotecaAtual: 'f',
            ordem: OrdemDoExplorar.recentes,
            aoOrdenar: (ordem) => escolhida = ordem,
            itens: _itens(3),
            cores: CorPosterCache(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PilulaDeEscolha, 'Adicionados recentemente'));
      await tester.pumpAndSettle();
      for (final ordem in OrdemDoExplorar.values) {
        final linha = find.bySemanticsLabel(ordem.rotulo);
        expect(linha, findsOneWidget, reason: ordem.rotulo);
        expect(tester.getSize(linha).height, greaterThanOrEqualTo(Forma.toqueMinimo));
      }
      await tester.tap(find.bySemanticsLabel('Nota'));
      await tester.pumpAndSettle();
      expect(escolhida, OrdemDoExplorar.nota);
      expect(find.bySemanticsLabel('Lançamento'), findsNothing, reason: 'a folha fechou');

      // A mesma ordem de novo não avisa ninguém.
      escolhida = null;
      await tester.tap(find.widgetWithText(PilulaDeEscolha, 'Adicionados recentemente'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Adicionados recentemente').last);
      await tester.pumpAndSettle();
      expect(escolhida, isNull);
    });
  }

  testWidgets('teclado: Tab chega às pílulas e Enter escolhe', (tester) async {
    _tela(tester, const Size(400, 900));
    String? aberta;
    await tester.pumpWidget(
      naTela(
        TelaExplorar(
          bibliotecas: _bibliotecas,
          bibliotecaAtual: 'f',
          aoEscolherBiblioteca: (chave) => aberta = chave,
          itens: _itens(3),
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 8 && aberta == null; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }
    expect(aberta, 's');
  });

  testWidgets('carregando guarda o lugar dos cartões sem nada para o leitor de tela', (tester) async {
    _tela(tester, const Size(400, 900));
    await tester.pumpWidget(
      naTela(
        TelaExplorar(
          bibliotecas: _bibliotecas,
          bibliotecaAtual: 'f',
          itens: const [],
          carregando: true,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Cartao), findsWidgets);
    expect(find.byType(Aviso), findsNothing);
    expect(
      find.ancestor(of: find.byType(Cartao).first, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
      reason: 'cartão de espera não fala',
    );
  });

  testWidgets('carregando mais: uma linha de espera depois dos títulos', (tester) async {
    _tela(tester, const Size(400, 900));
    await tester.pumpWidget(
      naTela(
        TelaExplorar(
          bibliotecas: _bibliotecas,
          bibliotecaAtual: 'f',
          itens: _itens(3),
          carregandoMais: true,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Cartao), findsNWidgets(6));
  });

  testWidgets('sem título: com filtro oferece limpar; sem filtro diz que a biblioteca está vazia', (tester) async {
    _tela(tester, const Size(400, 900));
    final avisos = <String>[];
    Widget tela({String? genero, bool naoVistos = false}) => naTela(
      TelaExplorar(
        bibliotecas: _bibliotecas,
        bibliotecaAtual: 'f',
        generos: _generos,
        generoAtual: genero,
        aoEscolherGenero: (chave) => avisos.add('gênero $chave'),
        soNaoVistos: naoVistos,
        aoMudarSoNaoVistos: (ligado) => avisos.add('não vistos $ligado'),
        itens: const [],
        cores: CorPosterCache(),
      ),
    );
    await tester.pumpWidget(tela(genero: 'drama', naoVistos: true));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum título com estes filtros'), findsOneWidget);
    await tester.tap(find.text('Limpar filtros'));
    expect(avisos, ['gênero null', 'não vistos false']);

    await tester.pumpWidget(tela());
    await tester.pumpAndSettle();
    expect(find.text('Esta biblioteca ainda está vazia'), findsOneWidget);
    expect(find.text('Limpar filtros'), findsNothing);
  });

  testWidgets('aviso ocupa o lugar da grade; sem "não vistos" e sem gêneros as faixas somem', (tester) async {
    _tela(tester, const Size(400, 900));
    await tester.pumpWidget(
      naTela(
        TelaExplorar(
          bibliotecas: _bibliotecas,
          bibliotecaAtual: 'f',
          itens: const [],
          aviso: const Aviso(icone: Icons.cloud_off, titulo: 'Não foi possível carregar os títulos'),
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar os títulos'), findsOneWidget);
    expect(find.byType(Cartao), findsNothing);
    expect(find.text('Não vistos'), findsNothing);
    expect(find.text('Favoritos'), findsNothing);
    expect(find.text('Esta biblioteca ainda está vazia'), findsNothing);
  });

  testWidgets('página seguinte que falha: o fim da grade oferece tentar de novo', (tester) async {
    _tela(tester, const Size(400, 900));
    var tentativas = 0;
    Widget tela({VoidCallback? aoTentarMais, Widget? aviso, int itens = 3}) => naTela(
      TelaExplorar(
        bibliotecas: _bibliotecas,
        bibliotecaAtual: 'f',
        itens: _itens(itens),
        aoTentarMais: aoTentarMais,
        aviso: aviso,
        cores: CorPosterCache(),
      ),
    );

    await tester.pumpWidget(tela());
    await tester.pump();
    expect(find.text('Tentar de novo'), findsNothing, reason: 'sem falha não há o que tentar');

    await tester.pumpWidget(tela(aoTentarMais: () => tentativas++));
    await tester.pump();
    expect(find.text('Não foi possível carregar mais títulos.'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    expect(tentativas, 1);

    await tester.pumpWidget(tela(aoTentarMais: () => tentativas++, itens: 0));
    await tester.pump();
    expect(find.text('Tentar de novo'), findsNothing, reason: 'sem título na tela quem fala é o aviso');
  });

  testWidgets('grade que cabe inteira na tela pede a próxima página sem esperar a rolagem', (tester) async {
    _tela(tester, const Size(400, 900));
    var pedidos = 0;
    await tester.pumpWidget(
      naTela(
        TelaExplorar(
          bibliotecas: _bibliotecas,
          bibliotecaAtual: 'f',
          itens: _itens(3),
          aoChegarPertoDoFim: () => pedidos++,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(pedidos, greaterThan(0));
  });

  testWidgets('perto do fim da rolagem pede a próxima página', (tester) async {
    _tela(tester, const Size(400, 900));
    var pedidos = 0;
    await tester.pumpWidget(
      naTela(
        TelaExplorar(
          bibliotecas: _bibliotecas,
          bibliotecaAtual: 'f',
          itens: _itens(60),
          aoChegarPertoDoFim: () => pedidos++,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(pedidos, 0, reason: 'longe do fim ninguém pede nada');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pumpAndSettle();
    expect(pedidos, greaterThan(0));
  });

  testWidgets('puxar a grade para baixo chama o atualizar', (tester) async {
    _tela(tester, const Size(400, 900));
    var pedidos = 0;
    await tester.pumpWidget(
      naTela(
        TelaExplorar(
          bibliotecas: _bibliotecas,
          bibliotecaAtual: 'f',
          itens: _itens(60),
          aoAtualizar: () async => pedidos++,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(pedidos, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o fundo segue a cor do primeiro pôster', (tester) async {
    _tela(tester, const Size(400, 900));
    final hashes = [
      for (final item in (jsonDecode(File('test/fixtures/cor_poster/blurhash_200.json').readAsStringSync()) as List))
        (item as Map<String, dynamic>)['primary'] as String,
    ];
    final cores = CorPosterCache();
    await tester.pumpWidget(
      naTela(
        TelaExplorar(
          bibliotecas: _bibliotecas,
          bibliotecaAtual: 'f',
          itens: [ItemDoExplorar(chave: 'a', titulo: 'A', hash: hashes.first)],
          cores: cores,
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('a')), findsOneWidget);
  });
}
