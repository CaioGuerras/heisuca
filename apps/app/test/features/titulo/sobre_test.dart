import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/pilula_de_escolha.dart';
import 'package:heisuca/design/componentes/toque.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/titulo/elenco.dart';
import 'package:heisuca/features/titulo/generos.dart';
import 'package:heisuca/features/titulo/info_da_midia.dart';
import 'package:heisuca/features/titulo/modelo.dart';

import '../../design/componentes/apoio.dart';

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

const _video = GrupoDeInfo(
  titulo: 'Vídeo',
  linhas: [('Resolução', '1920x1080'), ('Codec', 'h264'), ('Faixa dinâmica', 'SDR')],
);
const _audio = GrupoDeInfo(titulo: 'Áudio', linhas: [('Idioma', 'Português'), ('Canais', '5.1')]);

void main() {
  group('Elenco', () {
    for (final tema in TemaHeisuca.todos) {
      testWidgets('${tema.nome}: nome forte, personagem discreto e a inicial no lugar da foto que falta', (
        tester,
      ) async {
        _celular(tester);
        await tester.pumpWidget(
          _naLargura(
            tema: tema,
            Elenco(
              pessoas: [
                PessoaDoTitulo(
                  chave: 'a',
                  nome: 'Ian McShane',
                  papel: 'Al Swearengen',
                  foto: (context, tamanho) => SizedBox.fromSize(key: const Key('foto'), size: tamanho),
                ),
                const PessoaDoTitulo(chave: 'b', nome: 'Molly Parker'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(find.text('Elenco')).style!.color, tema.texto);
        expect(tester.widget<Text>(find.text('Ian McShane')).style!.color, tema.texto);
        expect(tester.widget<Text>(find.text('Al Swearengen')).style!.color, tema.texto2);
        expect(tester.getSize(find.byKey(const Key('foto'))), const Size.square(Elenco.largura));
        expect(find.text('M'), findsOneWidget, reason: 'sem foto, a inicial');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sem ninguém, a seção some', (tester) async {
      await tester.pumpWidget(_naLargura(const Elenco(pessoas: [])));
      expect(find.text('Elenco'), findsNothing);
      expect(tester.getSize(find.byType(Elenco)).height, 0);
    });

    testWidgets('toque, teclado e leitor de tela: cada pessoa é um botão com nome e personagem', (tester) async {
      _celular(tester);
      final alca = tester.ensureSemantics();
      final abertos = <String>[];
      await tester.pumpWidget(
        _naLargura(
          Elenco(
            pessoas: [
              for (final nome in ['Ana', 'Bia'])
                PessoaDoTitulo(chave: nome, nome: nome, papel: 'Ela mesma', aoTocar: () => abertos.add(nome)),
            ],
          ),
        ),
      );
      final ana = find.bySemanticsLabel('Ana, Ela mesma');
      expect(tester.getSemantics(ana).flagsCollection.isButton, isTrue);
      expect(tester.getSize(find.byType(Toque).first).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(find.byKey(const ValueKey('pessoa-Bia')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(abertos, ['Bia', 'Ana']);
      alca.dispose();
    });

    testWidgets('muita gente, nome comprido e letra em 200%: a fileira rola e nada estoura', (tester) async {
      _celular(tester, const Size(320, 700));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        _naLargura(
          semAnimacao: true,
          Elenco(
            pessoas: [
              for (var n = 0; n < 12; n++)
                PessoaDoTitulo(chave: '$n', nome: 'Maria Antonieta das Neves $n', papel: 'A vizinha do andar de cima'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const ValueKey('pessoa-0'))).dx, lessThan(0));
    });
  });

  group('Generos', () {
    for (final tema in TemaHeisuca.todos) {
      testWidgets('${tema.nome}: uma pílula por gênero, e o toque leva ao gênero', (tester) async {
        _celular(tester);
        final abertos = <String>[];
        await tester.pumpWidget(
          _naLargura(
            tema: tema,
            Generos(
              generos: [
                for (final nome in ['Faroeste', 'Crime', 'Drama'])
                  GeneroDoTitulo(nome: nome, aoTocar: () => abertos.add(nome)),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PilulaDeEscolha), findsNWidgets(3));
        expect(tester.widget<Text>(find.text('Crime')).style!.color, tema.texto2);
        await tester.tap(find.text('Crime'));
        await tester.pumpAndSettle();
        expect(abertos, ['Crime']);
      });
    }

    testWidgets('sem gênero, a seção some; muitos gêneros em letra de 200% quebram de linha', (tester) async {
      _celular(tester, const Size(320, 700));
      await tester.pumpWidget(_naLargura(const Generos(generos: [])));
      expect(find.text('Gêneros'), findsNothing);

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        _naLargura(
          const Generos(
            generos: [
              GeneroDoTitulo(nome: 'Ficção científica'),
              GeneroDoTitulo(nome: 'Documentário'),
              GeneroDoTitulo(nome: 'Animação'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('Animação')).dy,
        greaterThan(tester.getTopLeft(find.text('Ficção científica')).dy),
      );
    });
  });

  group('InfoDaMidia', () {
    for (final tema in TemaHeisuca.todos) {
      testWidgets('${tema.nome}: um cartão por grupo, da mesma altura, na superfície do tema', (tester) async {
        _celular(tester);
        await tester.pumpWidget(_naLargura(tema: tema, const InfoDaMidia(grupos: [_video, _audio])));
        await tester.pumpAndSettle();
        final cartoes = find.descendant(of: find.byType(InfoDaMidia), matching: find.byType(DecoratedBox));
        expect(cartoes, findsNWidgets(2));
        expect((tester.widget<DecoratedBox>(cartoes.first).decoration as ShapeDecoration).color, tema.superficie);
        expect(tester.getSize(cartoes.first), tester.getSize(cartoes.last));
        expect(tester.getSize(cartoes.first).width, InfoDaMidia.larguraDoCartao);
        expect(find.textContaining('Resolução: 1920x1080', findRichText: true), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('grupo sem linha não aparece; sem grupo, a seção some', (tester) async {
      await tester.pumpWidget(
        _naLargura(
          const InfoDaMidia(
            grupos: [
              _video,
              GrupoDeInfo(titulo: 'Legenda', linhas: []),
            ],
          ),
        ),
      );
      expect(find.text('Vídeo'), findsOneWidget);
      expect(find.text('Legenda'), findsNothing);

      await tester.pumpWidget(
        _naLargura(
          const InfoDaMidia(
            grupos: [GrupoDeInfo(titulo: 'Legenda', linhas: [])],
          ),
        ),
      );
      expect(find.text('Sobre a mídia'), findsNothing);
    });

    testWidgets('leitor de tela lê o nome do grupo como título e cada linha inteira; letra em 200% não estoura', (
      tester,
    ) async {
      _celular(tester, const Size(320, 700));
      final alca = tester.ensureSemantics();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_naLargura(semAnimacao: true, const InfoDaMidia(grupos: [_video, _audio])));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSemantics(find.bySemanticsLabel('Vídeo')).flagsCollection.isHeader, isTrue);
      expect(find.bySemanticsLabel('Codec: h264'), findsOneWidget);
      alca.dispose();
    });
  });
}
