import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/cor_poster/paleta_poster.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/inicio/destaque.dart';
import 'package:heisuca/features/inicio/modelo.dart';
import 'package:heisuca/features/inicio/tela_inicio.dart';

import '../../design/componentes/apoio.dart';

const _sonda = Key('sonda');

/// Uma "fileira" que só mostra a superfície que o tema entrega a quem está dentro da tela.
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

const _viagem = TituloEmDestaque(chave: 'a', titulo: 'A Viagem', anos: '2001');

void main() {
  final hashes = [
    for (final item in (jsonDecode(File('test/fixtures/cor_poster/blurhash_200.json').readAsStringSync()) as List))
      (item as Map<String, dynamic>)['primary'] as String,
  ];

  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: destaque no topo, fileiras embaixo e a superfície neutra sem cor de pôster', (
      tester,
    ) async {
      await tester.pumpWidget(
        naTela(
          tema: tema,
          TelaInicio(destaques: const [_viagem], fileiras: const [_Sonda()], cores: CorPosterCache()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A Viagem'), findsOneWidget);
      expect(find.byKey(_sonda), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(_sonda)).dy,
        greaterThan(tester.getBottomLeft(find.byType(Destaque)).dy - 0.5),
        reason: 'a primeira fileira começa depois do destaque',
      );
      expect(_superficieNaTela(tester), Color(PaletaPoster.neutra(TemasCorPoster.de(tema.nome)).superficie));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a cor do pôster do destaque tinge as superfícies de quem está na tela', (tester) async {
    final cores = CorPosterCache();
    final hash = hashes[0];
    await tester.pumpWidget(
      naTela(
        TelaInicio(
          destaques: [TituloEmDestaque(chave: 'a', titulo: 'A Viagem', hash: hash)],
          fileiras: const [_Sonda()],
          cores: cores,
        ),
      ),
    );
    final neutra = Color(PaletaPoster.neutra(TemasCorPoster.shikkoku).superficie);
    expect(_superficieNaTela(tester), neutra, reason: 'antes de a cor chegar a tela usa a superfície neutra');

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
    expect(tester.widget<Text>(find.text('A Viagem')).style!.color, TemaHeisuca.shikkoku.texto);
  });

  testWidgets('o destaque ocupa 74% da altura da tela, dentro dos limites', (tester) async {
    Future<double> alturaEm(Size tela) async {
      tester.view.physicalSize = tela;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        naTela(TelaInicio(destaques: const [_viagem], fileiras: const [], cores: CorPosterCache())),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(Destaque)).height;
    }

    addTearDown(tester.view.reset);
    expect(await alturaEm(const Size(400, 900)), closeTo(900 * TelaInicio.fracaoDoDestaque, 0.01));
    expect(await alturaEm(const Size(400, 560)), TelaInicio.destaqueMinimo);
    expect(await alturaEm(const Size(400, 1400)), TelaInicio.destaqueMaximo);
  });

  testWidgets('enquanto os destaques carregam, o lugar deles fica guardado e as fileiras não sobem', (tester) async {
    await tester.pumpWidget(
      naTela(
        TelaInicio(
          destaques: const [],
          destaqueCarregando: true,
          noLugarDoDestaque: const Text('Não deu para carregar'),
          fileiras: const [_Sonda()],
          cores: CorPosterCache(),
        ),
      ),
    );
    expect(find.byType(Destaque), findsOneWidget);
    expect(find.text('Não deu para carregar'), findsNothing);
    expect(tester.getTopLeft(find.byKey(_sonda)).dy, greaterThanOrEqualTo(TelaInicio.destaqueMinimo));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem destaque para mostrar, o aviso ocupa o topo e as fileiras continuam', (tester) async {
    await tester.pumpWidget(
      naTela(
        TelaInicio(
          destaques: const [],
          noLugarDoDestaque: const Text('Não deu para carregar'),
          fileiras: const [_Sonda()],
          aoBuscar: () {},
          cores: CorPosterCache(),
        ),
      ),
    );
    expect(find.byType(Destaque), findsNothing);
    expect(find.text('Não deu para carregar'), findsOneWidget);
    expect(find.byKey(_sonda), findsOneWidget);
    // O aviso começa abaixo do botão de busca, que continua no canto.
    expect(
      tester.getTopLeft(find.text('Não deu para carregar')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.bySemanticsLabel('Buscar')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('o botão "Buscar" chama a busca, tem 48 de toque e some quando não há busca', (tester) async {
    final alca = tester.ensureSemantics();
    var buscas = 0;
    await tester.pumpWidget(
      naTela(
        TelaInicio(destaques: const [_viagem], fileiras: const [], aoBuscar: () => buscas++, cores: CorPosterCache()),
      ),
    );
    await tester.pumpAndSettle();
    final botao = find.bySemanticsLabel('Buscar');
    expect(botao, findsOneWidget);
    expect(tester.getSize(botao).shortestSide, greaterThanOrEqualTo(48));
    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(buscas, 1);

    await tester.pumpWidget(
      naTela(TelaInicio(destaques: const [_viagem], fileiras: const [], cores: CorPosterCache())),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Buscar'), findsNothing);
    alca.dispose();
  });

  testWidgets('puxar para atualizar só existe quando a tela recebe o que fazer, e chama uma vez', (tester) async {
    var pedidos = 0;
    await tester.pumpWidget(
      naTela(
        TelaInicio(
          destaques: const [_viagem],
          fileiras: const [_Sonda()],
          aoAtualizar: () async => pedidos++,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsOneWidget);
    await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1200);
    await tester.pumpAndSettle();
    expect(pedidos, 1);

    await tester.pumpWidget(
      naTela(TelaInicio(destaques: const [_viagem], fileiras: const [_Sonda()], cores: CorPosterCache())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('letra em 200% e "remover animações": a tela monta sem estourar nos três temas', (tester) async {
    for (final tema in TemaHeisuca.todos) {
      await tester.pumpWidget(
        MaterialApp(
          theme: tema.paraMaterial(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 760),
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
              padding: EdgeInsets.only(top: 32, bottom: 24),
            ),
            child: Scaffold(
              body: TelaInicio(
                destaques: const [
                  TituloEmDestaque(
                    chave: 'a',
                    titulo: 'A Viagem de Chihiro',
                    nota: '8,6',
                    anos: '2001',
                    generos: 'Animação, Fantasia, Família',
                    classificacao: 'L',
                    sinopse: 'Uma menina atravessa um mundo de espíritos para salvar os pais.',
                  ),
                ],
                fileiras: const [_Sonda()],
                aoBuscar: () {},
                cores: CorPosterCache(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: tema.nome);
    }
  });
}
