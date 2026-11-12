import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/botao.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/cor_poster/paleta_poster.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/titulo/cabeca.dart';
import 'package:heisuca/features/titulo/modelo.dart';
import 'package:heisuca/features/titulo/tela_titulo.dart';

import '../../design/componentes/apoio.dart';

const _sonda = Key('sonda');

/// Uma "seção" que só mostra a superfície que o tema entrega a quem está dentro da tela.
class _Sonda extends StatelessWidget {
  const _Sonda();
  @override
  Widget build(BuildContext context) => SizedBox(
    key: _sonda,
    height: 40,
    child: ColoredBox(color: TemaHeisuca.de(context).superficie),
  );
}

Color _superficieNaTela(WidgetTester tester) =>
    tester.widget<ColoredBox>(find.descendant(of: find.byKey(_sonda), matching: find.byType(ColoredBox))).color;

const _sinopse =
    'O ex-homem da lei Seth Bullock chega ao acampamento de Deadwood para abrir uma loja de ferragens. '
    'O dono do saloon, Al Swearengen, desconfia dos recém-chegados. Wild Bill Hickok e Calamity Jane também '
    'chegam à cidade, e a notícia do ouro nas colinas traz mais gente a cada dia que passa.';

PaginaDoTitulo _cheia({
  VoidCallback? aoAssistir,
  VoidCallback? aoAlternarLista,
  VoidCallback? aoAlternarVisto,
  bool naLista = false,
  bool visto = false,
  String? hash,
}) => PaginaDoTitulo(
  chave: 'd',
  titulo: 'Deadwood',
  nota: '7,1',
  anos: '2004 – 2006',
  generos: 'Faroeste, Crime, Drama',
  classificacao: '16',
  detalhes: const ['3 temporadas', '1h 2min', '1080p'],
  sinopse: _sinopse,
  rotuloDeAssistir: 'Continuar T1:E3',
  progresso: 0.4,
  hash: hash,
  arte: (context, tamanho) => SizedBox.fromSize(
    size: tamanho,
    child: const ColoredBox(color: Colors.grey),
  ),
  aoAssistir: aoAssistir ?? () {},
  naLista: naLista,
  aoAlternarLista: aoAlternarLista ?? () {},
  visto: visto,
  aoAlternarVisto: aoAlternarVisto ?? () {},
);

void main() {
  final hashes = [
    for (final item in (jsonDecode(File('test/fixtures/cor_poster/blurhash_200.json').readAsStringSync()) as List))
      (item as Map<String, dynamic>)['primary'] as String,
  ];

  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: cabeça completa, seções embaixo e a superfície neutra sem cor de pôster', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        naTela(
          tema: tema,
          TelaTitulo(pagina: _cheia(), secoes: const [_Sonda()], aoAbrirMenu: () {}, cores: CorPosterCache()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deadwood'), findsOneWidget);
      expect(find.text('7,1'), findsOneWidget);
      expect(find.text('3 temporadas · 1h 2min · 1080p'), findsOneWidget);
      expect(find.text('Continuar T1:E3'), findsOneWidget);
      expect(find.byTooltip('Minha lista'), findsOneWidget);
      expect(find.byTooltip('Já vi'), findsOneWidget);
      expect(find.byTooltip('Voltar').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Mais opções').hitTestable(), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(_sonda)).dy,
        greaterThan(tester.getBottomLeft(find.byType(CabecaDoTitulo)).dy - 0.5),
        reason: 'a primeira seção começa depois da cabeça',
      );
      expect(_superficieNaTela(tester), Color(PaletaPoster.neutra(TemasCorPoster.de(tema.nome)).superficie));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a cor do pôster tinge as superfícies das seções', (tester) async {
    final cores = CorPosterCache();
    final hash = hashes[2];
    await tester.pumpWidget(
      naTela(
        TelaTitulo(
          pagina: _cheia(hash: hash),
          secoes: const [_Sonda()],
          cores: cores,
        ),
      ),
    );
    final neutra = Color(PaletaPoster.neutra(TemasCorPoster.shikkoku).superficie);
    // A conta roda em outra thread: o relógio de verdade anda um pouco e a tela recebe o aviso no quadro seguinte.
    for (var volta = 0; volta < 200 && cores.ler(hash, TemasCorPoster.shikkoku) == null; volta++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    final paleta = cores.ler(hash, TemasCorPoster.shikkoku);
    expect(paleta, isNotNull);
    expect(_superficieNaTela(tester), Color(paleta!.superficie));
    expect(_superficieNaTela(tester), isNot(neutra));
  });

  testWidgets('dado ausente não aparece: só o nome e o botão de voltar', (tester) async {
    await tester.pumpWidget(
      naTela(
        TelaTitulo(
          pagina: const PaginaDoTitulo(chave: 'a', titulo: 'Akira'),
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Akira'), findsOneWidget);
    expect(find.byType(Botao), findsNothing);
    expect(find.byTooltip('Minha lista'), findsNothing);
    expect(find.byTooltip('Já vi'), findsNothing);
    expect(find.byTooltip('Mais opções'), findsNothing);
    expect(find.textContaining('·'), findsNothing);
    expect(find.textContaining('「'), findsNothing);
    expect(find.byTooltip('Voltar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assistir, minha lista e já vi chamam cada um a sua ação; os botões têm 48 de toque', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final toques = <String>[];
    await tester.pumpWidget(
      naTela(
        TelaTitulo(
          pagina: _cheia(
            aoAssistir: () => toques.add('assistir'),
            aoAlternarLista: () => toques.add('lista'),
            aoAlternarVisto: () => toques.add('visto'),
            naLista: true,
          ),
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Botao));
    await tester.tap(find.byTooltip('Minha lista'));
    await tester.tap(find.byTooltip('Já vi'));
    await tester.pumpAndSettle();
    expect(toques, ['assistir', 'lista', 'visto']);

    expect(tester.getSize(find.byType(Botao)).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(find.byType(Botao)).width, greaterThan(300), reason: 'o botão ocupa a largura da tela');
    for (final dica in ['Minha lista', 'Já vi', 'Voltar']) {
      expect(tester.getSize(find.byTooltip(dica)).shortestSide, greaterThanOrEqualTo(48), reason: dica);
    }
    Icon icone(String dica) =>
        tester.widget<Icon>(find.descendant(of: find.byTooltip(dica), matching: find.byType(Icon)));
    expect(icone('Minha lista').fill, 1, reason: 'na lista, o coração fica cheio');
    expect(icone('Já vi').fill, 0);
  });

  testWidgets('o leitor de tela lê o nome como cabeçalho e o estado de "Minha lista"', (tester) async {
    final alca = tester.ensureSemantics();
    await tester.pumpWidget(naTela(TelaTitulo(pagina: _cheia(naLista: true), cores: CorPosterCache())));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.bySemanticsLabel('Deadwood')).flagsCollection.isHeader, isTrue);
    expect(tester.getSemantics(find.bySemanticsLabel('Minha lista')).flagsCollection.isSelected.toBoolOrNull(), isTrue);
    expect(tester.getSemantics(find.bySemanticsLabel('Já vi')).flagsCollection.isSelected.toBoolOrNull(), isFalse);
    expect(find.bySemanticsLabel('40% assistido'), findsOneWidget);
    alca.dispose();
  });

  testWidgets('a sinopse abre e fecha com o toque', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(naTela(TelaTitulo(pagina: _cheia(), cores: CorPosterCache())));
    await tester.pumpAndSettle();
    final sinopse = find.textContaining('「Deadwood」', findRichText: true);
    final fechada = tester.getSize(sinopse).height;
    await tester.tap(sinopse);
    await tester.pumpAndSettle();
    expect(tester.getSize(sinopse).height, greaterThan(fechada));
    await tester.tap(sinopse);
    await tester.pumpAndSettle();
    expect(tester.getSize(sinopse).height, fechada);
  });

  testWidgets('"Voltar" sai da tela quando ninguém diz o que fazer, e chama a ação quando recebe uma', (tester) async {
    await tester.pumpWidget(
      naTela(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: TelaTitulo(
                    pagina: const PaginaDoTitulo(chave: 'a', titulo: 'Akira'),
                    cores: CorPosterCache(),
                  ),
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaTitulo), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaTitulo), findsNothing);

    var voltas = 0;
    await tester.pumpWidget(
      naTela(
        TelaTitulo(
          pagina: const PaginaDoTitulo(chave: 'a', titulo: 'Akira'),
          aoVoltar: () => voltas++,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar'));
    expect(voltas, 1);
  });

  testWidgets('a arte ocupa 60% da altura da tela, dentro dos limites', (tester) async {
    Future<double> alturaEm(Size tela) async {
      tester.view.physicalSize = tela;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(naTela(TelaTitulo(pagina: _cheia(), cores: CorPosterCache())));
      await tester.pumpAndSettle();
      return tester.widget<CabecaDoTitulo>(find.byType(CabecaDoTitulo)).alturaDaArte;
    }

    addTearDown(tester.view.reset);
    expect(await alturaEm(const Size(400, 900)), closeTo(900 * TelaTitulo.fracaoDaArte, 0.01));
    expect(await alturaEm(const Size(400, 400)), TelaTitulo.arteMinima);
    expect(await alturaEm(const Size(400, 1400)), TelaTitulo.arteMaxima);
  });

  testWidgets('letra em 200% e "remover animações": a tela monta sem estourar nos três temas', (tester) async {
    for (final tema in TemaHeisuca.todos) {
      await tester.pumpWidget(
        MaterialApp(
          theme: tema.paraMaterial(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
              padding: EdgeInsets.only(top: 32, bottom: 24),
            ),
            child: Scaffold(
              body: TelaTitulo(pagina: _cheia(), secoes: const [_Sonda()], aoAbrirMenu: () {}, cores: CorPosterCache()),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: tema.nome);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: tema.nome);
    }
  });

  group('barra do topo', () {
    const alto = SizedBox(height: 1600);

    Future<void> montar(WidgetTester tester, Widget tela, {bool semAnimacao = false}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(naTela(tela, semAnimacao: semAnimacao));
      await tester.pumpAndSettle();
    }

    int barrasAVista(WidgetTester tester) => find.byKey(TelaTitulo.chaveDaBarra).evaluate().length;

    /// A barra ocupa o lugar inteiro dela: de ponta a ponta, do alto da tela até o fim da faixa, sem fresta.
    void esperaABarraInteira(WidgetTester tester) {
      final barra = find.byKey(TelaTitulo.chaveDaBarra);
      final cima = MediaQuery.paddingOf(tester.element(barra)).top;
      expect(tester.getRect(barra), Rect.fromLTWH(0, 0, 390, cima + TelaTitulo.alturaDaBarra));
    }

    testWidgets('no começo a barra não aparece nem recebe toque; o botão grande é o único "assistir"', (tester) async {
      var plays = 0;
      await montar(
        tester,
        TelaTitulo(
          pagina: _cheia(aoAssistir: () => plays++),
          secoes: const [alto],
          cores: CorPosterCache(),
        ),
      );
      expect(barrasAVista(tester), 0);
      expect(find.byTooltip('Continuar T1:E3').hitTestable(), findsNothing);
      await tester.tap(find.text('Continuar T1:E3'));
      await tester.pumpAndSettle();
      expect(plays, 1);
    });

    testWidgets('quando o botão de assistir sai de vista, a barra entra com o nome e um assistir de 48', (
      tester,
    ) async {
      var plays = 0;
      var menus = 0;
      var voltas = 0;
      await montar(
        tester,
        TelaTitulo(
          pagina: _cheia(aoAssistir: () => plays++),
          secoes: const [alto],
          aoVoltar: () => voltas++,
          aoAbrirMenu: () => menus++,
          cores: CorPosterCache(),
        ),
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(barrasAVista(tester), 1);
      esperaABarraInteira(tester);

      final pequeno = find.byTooltip('Continuar T1:E3').hitTestable();
      expect(pequeno, findsOneWidget);
      expect(tester.getSize(pequeno).shortestSide, greaterThanOrEqualTo(48));
      // O nome fica entre o voltar e o assistir, sem passar por baixo de nenhum botão.
      final nome = tester.getRect(find.text('Deadwood').hitTestable());
      expect(nome.left, greaterThanOrEqualTo(tester.getRect(find.byTooltip('Voltar')).right));
      expect(nome.right, lessThanOrEqualTo(tester.getRect(pequeno).left));
      expect(tester.getRect(pequeno).right, lessThanOrEqualTo(tester.getRect(find.byTooltip('Mais opções')).left));

      await tester.tap(pequeno);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      expect((plays, voltas, menus), (1, 1, 1));

      // De volta ao começo, a barra sai.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
      await tester.pumpAndSettle();
      expect(barrasAVista(tester), 0);
      expect(find.byTooltip('Continuar T1:E3').hitTestable(), findsNothing);
    });

    testWidgets('sem botão de assistir, a barra entra só com o nome depois que a arte passou', (tester) async {
      await montar(
        tester,
        TelaTitulo(
          pagina: PaginaDoTitulo(chave: 'd', titulo: 'Deadwood'),
          secoes: const [alto],
          cores: CorPosterCache(),
        ),
      );
      expect(barrasAVista(tester), 0);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(barrasAVista(tester), 1);
      esperaABarraInteira(tester);
      expect(find.byTooltip('Assistir'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('com o leitor de tela, o assistir da barra só existe enquanto ela está à vista', (tester) async {
      final alca = tester.ensureSemantics();
      await montar(tester, TelaTitulo(pagina: _cheia(), secoes: const [alto], cores: CorPosterCache()));
      expect(find.bySemanticsLabel('Continuar T1:E3'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Continuar T1:E3').hitTestable(), findsOneWidget);
      alca.dispose();
    });

    testWidgets('a arte fica para trás e some ao rolar; com "remover animações" ela rola junto', (tester) async {
      Finder daArte(Type tipo) => find.descendant(of: find.byType(CabecaDoTitulo), matching: find.byType(tipo));

      await montar(tester, TelaTitulo(pagina: _cheia(), secoes: const [alto], cores: CorPosterCache()));
      expect(tester.widget<Opacity>(daArte(Opacity).first).opacity, 1);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pump();
      final rolado = tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
      expect(rolado, greaterThan(0));
      final altura = tester.widget<CabecaDoTitulo>(find.byType(CabecaDoTitulo)).alturaDaArte;
      expect(tester.widget<Opacity>(daArte(Opacity).first).opacity, closeTo(1 - rolado / altura, 0.001));
      final desvio = tester.widget<Transform>(daArte(Transform).first).transform.getTranslation().y;
      expect(desvio, closeTo(rolado * CabecaDoTitulo.atrasoDaArte, 0.001));

      await montar(
        tester,
        TelaTitulo(key: UniqueKey(), pagina: _cheia(), secoes: const [alto], cores: CorPosterCache()),
        semAnimacao: true,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pump();
      expect(daArte(Opacity), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('controle de rolagem de fora continua valendo e a barra o acompanha', (tester) async {
      final controle = ScrollController();
      addTearDown(controle.dispose);
      await montar(
        tester,
        TelaTitulo(pagina: _cheia(), secoes: const [alto], controle: controle, cores: CorPosterCache()),
      );
      controle.jumpTo(900);
      await tester.pumpAndSettle();
      expect(barrasAVista(tester), 1);
    });
  });
}
