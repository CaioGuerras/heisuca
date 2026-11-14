import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/design/componentes/pilula_de_escolha.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/busca/modelo.dart';
import 'package:heisuca/features/busca/tela_busca.dart';

import '../../design/componentes/apoio.dart';

void _tela(WidgetTester tester, [Size tamanho = const Size(400, 1600)]) {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _filme = TituloDaBusca(chave: 'f1', titulo: 'Duna', tipo: TipoDoResultado.filme, anos: '2021', nota: '8,0');
const _serie = TituloDaBusca(
  chave: 's1',
  titulo: 'Dark',
  tipo: TipoDoResultado.serie,
  anos: '2017 - 2020',
  origem: '2 fontes',
);
const _pessoa = PessoaDaBusca(chave: 'p1', nome: 'Zendaya');

/// Monta a tela com campo e foco descartados no fim do teste.
Widget _busca({
  TemaHeisuca tema = TemaHeisuca.shikkoku,
  TextEditingController? campo,
  VoidCallback? aoVoltar,
  List<String> recentes = const [],
  ValueChanged<String>? aoEscolherRecente,
  ValueChanged<String>? aoTirarRecente,
  VoidCallback? aoLimparRecentes,
  List<TituloDaBusca> titulos = const [],
  List<PessoaDaBusca> pessoas = const [],
  bool buscando = false,
  bool buscou = false,
  Widget? aviso,
  Widget? pedir,
}) => naTela(
  tema: tema,
  TelaBusca(
    campo: campo ?? TextEditingController(),
    foco: FocusNode(),
    focoInicial: false,
    aoVoltar: aoVoltar,
    recentes: recentes,
    aoEscolherRecente: aoEscolherRecente,
    aoTirarRecente: aoTirarRecente,
    aoLimparRecentes: aoLimparRecentes,
    titulos: titulos,
    pessoas: pessoas,
    buscando: buscando,
    buscou: buscou,
    aviso: aviso,
    pedir: pedir,
    cores: CorPosterCache(),
  ),
);

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: resultados com pílulas, pessoas e cartões, sem exceção', (tester) async {
      _tela(tester);
      await tester.pumpWidget(
        _busca(tema: tema, titulos: const [_filme, _serie], pessoas: const [_pessoa], buscou: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PilulaDeEscolha), findsNWidgets(4));
      expect(find.text('Zendaya'), findsOneWidget);
      expect(find.byType(Cartao), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('antes de buscar: recentes tocam, saem e se limpam', (tester) async {
    _tela(tester);
    final escolhidos = <String>[];
    final tirados = <String>[];
    var limpou = false;
    await tester.pumpWidget(
      _busca(
        recentes: const ['naruto', 'duna'],
        aoEscolherRecente: escolhidos.add,
        aoTirarRecente: tirados.add,
        aoLimparRecentes: () => limpou = true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buscas recentes'), findsOneWidget);
    await tester.tap(find.text('naruto'));
    await tester.tap(find.bySemanticsLabel('Tirar "duna" do histórico'));
    await tester.tap(find.text('Limpar'));
    expect(escolhidos, ['naruto']);
    expect(tirados, ['duna']);
    expect(limpou, isTrue);
  });

  testWidgets('depois de buscar, o histórico sai', (tester) async {
    _tela(tester);
    await tester.pumpWidget(_busca(recentes: const ['naruto'], titulos: const [_filme], buscou: true));
    await tester.pumpAndSettle();
    expect(find.text('Buscas recentes'), findsNothing);
    expect(find.text('naruto'), findsNothing);
  });

  testWidgets('subtítulo junta ano e origem', (tester) async {
    _tela(tester);
    await tester.pumpWidget(_busca(titulos: const [_serie], buscou: true));
    await tester.pumpAndSettle();
    expect(find.text('2017 - 2020 · 2 fontes'), findsOneWidget);
  });

  testWidgets('um tipo só: sem pílulas', (tester) async {
    _tela(tester);
    await tester.pumpWidget(
      _busca(
        titulos: const [
          _filme,
          TituloDaBusca(chave: 'f2', titulo: 'Alien', tipo: TipoDoResultado.filme),
        ],
        buscou: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PilulaDeEscolha), findsNothing);
    expect(find.byType(Cartao), findsNWidgets(2));
  });

  testWidgets('pílulas filtram: Filmes, Séries e Pessoas', (tester) async {
    _tela(tester);
    await tester.pumpWidget(_busca(titulos: const [_filme, _serie], pessoas: const [_pessoa], buscou: true));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(PilulaDeEscolha, 'Filmes'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PilulaDeEscolha, 'Filmes'));
    await tester.pumpAndSettle();
    expect(find.text('Duna'), findsOneWidget);
    expect(find.text('Dark'), findsNothing);
    expect(find.text('Zendaya'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(PilulaDeEscolha, 'Séries'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PilulaDeEscolha, 'Séries'));
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Duna'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(PilulaDeEscolha, 'Pessoas'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PilulaDeEscolha, 'Pessoas'));
    await tester.pumpAndSettle();
    expect(find.text('Zendaya'), findsOneWidget);
    expect(find.byType(Cartao), findsNothing);
  });

  testWidgets('resultado novo sem o tipo escolhido: volta a Todos', (tester) async {
    _tela(tester);
    await tester.pumpWidget(_busca(titulos: const [_filme, _serie], buscou: true));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(PilulaDeEscolha, 'Séries'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PilulaDeEscolha, 'Séries'));
    await tester.pumpAndSettle();

    const outroFilme = TituloDaBusca(chave: 'f3', titulo: 'Alien', tipo: TipoDoResultado.filme);
    await tester.pumpWidget(_busca(titulos: const [outroFilme], pessoas: const [_pessoa], buscou: true));
    await tester.pumpAndSettle();
    expect(find.text('Alien'), findsOneWidget);
    expect(find.text('Zendaya'), findsOneWidget);
  });

  testWidgets('tocar e segurar o cartão; tocar a pessoa', (tester) async {
    _tela(tester);
    final eventos = <String>[];
    await tester.pumpWidget(
      _busca(
        titulos: [
          TituloDaBusca(
            chave: 'f1',
            titulo: 'Duna',
            aoTocar: () => eventos.add('tocou'),
            aoSegurar: () => eventos.add('segurou'),
          ),
        ],
        pessoas: [PessoaDaBusca(chave: 'p', nome: 'Zendaya', aoTocar: () => eventos.add('pessoa'))],
        buscou: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duna'));
    await tester.longPress(find.text('Duna'));
    await tester.tap(find.text('Zendaya'));
    await tester.pumpAndSettle();
    expect(eventos, ['tocou', 'segurou', 'pessoa']);
  });

  testWidgets('aviso no lugar dos resultados, com o "Pedir" embaixo', (tester) async {
    _tela(tester);
    await tester.pumpWidget(
      _busca(buscou: true, aviso: const Text('Nada encontrado'), pedir: const Text('Pedir este título')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nada encontrado'), findsOneWidget);
    expect(find.text('Pedir este título'), findsOneWidget);
    expect(find.byType(Cartao), findsNothing);
  });

  testWidgets('"Pedir" só depois de buscar', (tester) async {
    _tela(tester);
    await tester.pumpWidget(_busca(pedir: const Text('Pedir este título')));
    await tester.pumpAndSettle();
    expect(find.text('Pedir este título'), findsNothing);
  });

  testWidgets('buscando sem resultado: cartões de espera', (tester) async {
    _tela(tester);
    await tester.pumpWidget(_busca(buscando: true, buscou: true));
    await tester.pump();
    expect(find.byType(Cartao), findsNWidgets(TelaBusca.cartoesCarregando));
  });

  testWidgets('o × limpa o campo e só aparece com texto; voltar chama quem abriu', (tester) async {
    _tela(tester);
    final campo = TextEditingController();
    addTearDown(campo.dispose);
    var voltou = false;
    await tester.pumpWidget(_busca(campo: campo, aoVoltar: () => voltou = true));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Limpar a busca'), findsNothing);

    await tester.enterText(find.byType(TextField), 'duna');
    await tester.pump();
    expect(find.bySemanticsLabel('Limpar a busca'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Limpar a busca'));
    await tester.pump();
    expect(campo.text, isEmpty);

    await tester.tap(find.bySemanticsLabel('Voltar'));
    expect(voltou, isTrue);
  });

  testWidgets('enviar pelo teclado entrega o texto', (tester) async {
    _tela(tester);
    final enviados = <String>[];
    await tester.pumpWidget(
      naTela(
        TelaBusca(
          campo: TextEditingController(),
          foco: FocusNode(),
          focoInicial: false,
          aoEnviar: enviados.add,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'dark');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(enviados, ['dark']);
  });

  testWidgets('alvos de toque de 48', (tester) async {
    _tela(tester);
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(
      _busca(
        aoVoltar: () {},
        recentes: const ['naruto'],
        aoEscolherRecente: (_) {},
        aoTirarRecente: (_) {},
        aoLimparRecentes: () {},
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantica.dispose();
  });

  testWidgets('letra 200%: recentes e resultados sem estouro', (tester) async {
    _tela(tester, const Size(360, 1600));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _busca(aoVoltar: () {}, titulos: const [_filme, _serie], pessoas: const [_pessoa], buscou: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _busca(recentes: const ['um título bem comprido para a linha do histórico'], aoTirarRecente: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
