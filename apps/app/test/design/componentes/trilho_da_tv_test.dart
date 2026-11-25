import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/navegacao_tv/trilho_da_tv.dart';

import 'apoio.dart';

/// Trilho com quatro destinos e dois extras; guarda o que foi tocado e quantas vezes fechou.
class _Trilho {
  final tocados = <String>[];
  var fechou = 0;

  ItemDoTrilhoTv _item(String chave) =>
      ItemDoTrilhoTv(chave: chave, rotulo: chave, icone: Icons.circle, aoTocar: () => tocados.add(chave));

  Widget widget({String? selecionado = 'Filmes', String? focoInicial, bool comExtras = true}) => SizedBox(
    width: 960,
    height: 540,
    child: Align(
      alignment: Alignment.centerLeft,
      child: TrilhoDaTv(
        destinos: [
          for (final c in ['Início', 'Filmes', 'Séries', 'Buscar']) _item(c),
        ],
        extras: comExtras
            ? [
                for (final c in ['Trocar perfil', 'Ajustes']) _item(c),
              ]
            : const [],
        selecionado: selecionado,
        focoInicial: focoInicial,
        aoFechar: () => fechou++,
      ),
    ),
  );
}

/// Texto do item que tem o foco agora.
String? _focado() {
  final contexto = FocusManager.instance.primaryFocus?.context;
  if (contexto == null) return null;
  String? achado;
  void procurar(Element e) {
    if (achado != null) return;
    final w = e.widget;
    if (w is Text && w.data != null) {
      achado = w.data;
      return;
    }
    e.visitChildren(procurar);
  }

  (contexto as Element).visitChildren(procurar);
  return achado;
}

Future<void> _montar(WidgetTester tester, Widget filho, {TemaHeisuca tema = TemaHeisuca.shikkoku}) async {
  tester.view.physicalSize = const Size(960, 540);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(naTela(filho, tema: tema));
  await tester.pumpAndSettle();
}

void main() {
  group('TrilhoDaTv', () {
    test('na TV o claro vira o escuro equivalente; o kids mantém o acento', () {
      expect(TrilhoDaTv.escuroDaTv(TemaHeisuca.hisui), same(TemaHeisuca.shikkoku));
      expect(TrilhoDaTv.escuroDaTv(TemaHeisuca.ichigo), same(TemaHeisuca.ichigoNoite));
      expect(TrilhoDaTv.escuroDaTv(TemaHeisuca.sorairo), same(TemaHeisuca.sorairoNoite));
      for (final escuro in [
        TemaHeisuca.shikkoku,
        TemaHeisuca.sumi,
        TemaHeisuca.ichigoNoite,
        TemaHeisuca.sorairoNoite,
      ]) {
        expect(TrilhoDaTv.escuroDaTv(escuro), same(escuro));
      }
    });

    for (final tema in [...TemaHeisuca.todos, ...TemaHeisuca.doKids]) {
      testWidgets('monta no tema ${tema.nome} (${tema.brilho.name}) com texto do tema escuro', (tester) async {
        await _montar(tester, _Trilho().widget(), tema: tema);
        expect(tester.takeException(), isNull);
        final escuro = TrilhoDaTv.escuroDaTv(tema);
        // Item sem foco e fora do selecionado usa o texto secundário do escuro, nunca o do claro.
        final texto = tester.widget<Text>(find.text('Séries'));
        expect(texto.style?.color, escuro.texto2);
      });
    }

    testWidgets('cada item tem área de toque de 48 ou mais', (tester) async {
      await _montar(tester, _Trilho().widget());
      for (final rotulo in ['Início', 'Filmes', 'Séries', 'Buscar', 'Trocar perfil', 'Ajustes']) {
        final tamanho = tester.getSize(find.bySemanticsLabel(rotulo));
        expect(tamanho.height, greaterThanOrEqualTo(48), reason: rotulo);
        expect(tamanho.width, greaterThanOrEqualTo(48), reason: rotulo);
      }
    });

    testWidgets('abre com foco no selecionado; o focoInicial vence', (tester) async {
      await _montar(tester, _Trilho().widget());
      expect(_focado(), 'Filmes');
      // O foco inicial vale ao abrir: cada caso monta um trilho novo.
      await tester.pumpWidget(const SizedBox());
      await _montar(tester, _Trilho().widget(focoInicial: 'Ajustes'));
      expect(_focado(), 'Ajustes');
      await tester.pumpWidget(const SizedBox());
      await _montar(tester, _Trilho().widget(selecionado: null));
      expect(_focado(), 'Início');
    });

    testWidgets('↑ e ↓ andam pelos dois grupos, param nas pontas e não vazam', (tester) async {
      final t = _Trilho();
      final vazadas = <LogicalKeyboardKey>[];
      await _montar(
        tester,
        Focus(
          onKeyEvent: (_, e) {
            vazadas.add(e.logicalKey);
            return KeyEventResult.handled;
          },
          child: t.widget(selecionado: 'Início'),
        ),
      );
      expect(_focado(), 'Início');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_focado(), 'Início', reason: 'para na ponta de cima');
      for (final esperado in ['Filmes', 'Séries', 'Buscar', 'Trocar perfil', 'Ajustes', 'Ajustes']) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(_focado(), esperado);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(_focado(), 'Ajustes', reason: '← não sai do trilho');
      expect(vazadas, isEmpty);
      expect(t.fechou, 0);
      expect(t.tocados, isEmpty);
    });

    for (final tecla in [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.escape, LogicalKeyboardKey.goBack]) {
      testWidgets('${tecla.debugName} fecha uma vez, sem vazar', (tester) async {
        final t = _Trilho();
        final vazadas = <LogicalKeyboardKey>[];
        await _montar(
          tester,
          Focus(
            onKeyEvent: (_, e) {
              vazadas.add(e.logicalKey);
              return KeyEventResult.handled;
            },
            child: t.widget(),
          ),
        );
        // O Voltar do controle não tem tecla física no teclado de teste: vai pela do Esc, como no player.
        await tester.sendKeyEvent(tecla, physicalKey: PhysicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(t.fechou, 1);
        expect(vazadas, isEmpty);
      });
    }

    for (final tecla in [LogicalKeyboardKey.select, LogicalKeyboardKey.enter, LogicalKeyboardKey.gameButtonA]) {
      testWidgets('${tecla.debugName} escolhe o item com foco uma vez', (tester) async {
        final t = _Trilho();
        await _montar(tester, t.widget());
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(tecla);
        await tester.pumpAndSettle();
        expect(t.tocados, ['Séries']);
        expect(t.fechou, 0);
      });
    }

    testWidgets('toque escolhe o item', (tester) async {
      final t = _Trilho();
      await _montar(tester, t.widget());
      await tester.tap(find.text('Trocar perfil'));
      await tester.pumpAndSettle();
      expect(t.tocados, ['Trocar perfil']);
    });

    testWidgets('leitor de tela: cada item é um botão com o rótulo; o destino atual é anunciado como selecionado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, _Trilho().widget());
      expect(
        tester.getSemantics(find.bySemanticsLabel('Séries')),
        containsSemantics(label: 'Séries', isButton: true, hasTapAction: true, isEnabled: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Filmes')),
        // O Toque anuncia o item em que a pessoa está como "selecionado" (como uma aba), com a ação de tocar.
        containsSemantics(label: 'Filmes', isSelected: true, hasTapAction: true, isEnabled: true),
      );
      semantica.dispose();
    });

    testWidgets('letra a 200 % não estoura e o item com foco fica na tela', (tester) async {
      final t = _Trilho();
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        naTela(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
              child: t.widget(selecionado: 'Início'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      expect(_focado(), 'Ajustes');
      final caixa = tester.getRect(find.bySemanticsLabel('Ajustes'));
      expect(caixa.bottom, lessThanOrEqualTo(540), reason: 'rolou até o item com foco');
      expect(caixa.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('o item com foco cresce; com "remover animações", só a cor marca o foco', (tester) async {
      double escalaDoFocado() {
        final escalas = tester.widgetList<AnimatedScale>(
          find.ancestor(of: find.bySemanticsLabel('Filmes'), matching: find.byType(AnimatedScale)),
        );
        return escalas.first.scale;
      }

      await _montar(tester, _Trilho().widget());
      expect(escalaDoFocado(), greaterThan(1));
      await tester.pumpWidget(naTela(_Trilho().widget(), semAnimacao: true));
      await tester.pumpAndSettle();
      expect(escalaDoFocado(), 1);
    });
  });
}
