import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/features/inicio/modelo.dart';
import 'package:heisuca/features/inicio/tela_inicio.dart';
import 'package:heisuca/heisuca/heisuca_design_system.dart';

/// O destaque troca só pelo dedo: um arrasto leva à página vizinha e para lá.
///
/// Montado como no app: dentro da tela Início (fundo tingido, que anima o tema a cada troca de página) e com a
/// rolagem global do Heisuca. Era nessa combinação que o destaque varria todas as páginas sem parar.
void main() {
  Future<PageController> montar(WidgetTester tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);
    final titulos = [
      for (var i = 0; i < 8; i++) TituloEmDestaque(chave: 'k$i', titulo: 'Título $i', aoAssistir: () {}),
    ];
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const HeisucaScrollBehavior(),
        home: Scaffold(
          body: TelaInicio(destaques: titulos, fileiras: const []),
        ),
      ),
    );
    return tester.widget<PageView>(find.byType(PageView)).controller!;
  }

  Future<void> esperar(WidgetTester tester, Duration tempo) async {
    for (var passado = Duration.zero; passado < tempo; passado += const Duration(milliseconds: 8)) {
      await tester.pump(const Duration(milliseconds: 8));
    }
  }

  for (final velocidade in [300.0, 1500.0, 4000.0, 9000.0]) {
    testWidgets('um arrasto a $velocidade px/s leva à página vizinha e o destaque para', (tester) async {
      final paginas = await montar(tester);

      await tester.fling(find.byType(PageView), const Offset(-150, 0), velocidade);
      await esperar(tester, const Duration(seconds: 3));

      expect(paginas.page, 1);
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nada mais se move');
      expect(find.text('Título 1'), findsOneWidget);

      // E continua parado.
      await esperar(tester, const Duration(seconds: 3));
      expect(paginas.page, 1);
    });
  }

  testWidgets('arrastar de volta retorna à primeira página e para', (tester) async {
    final paginas = await montar(tester);
    await tester.fling(find.byType(PageView), const Offset(-150, 0), 1500);
    await esperar(tester, const Duration(seconds: 3));

    await tester.fling(find.byType(PageView), const Offset(150, 0), 1500);
    await esperar(tester, const Duration(seconds: 3));

    expect(paginas.page, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('na última página, arrastar para a frente não sai dela', (tester) async {
    final paginas = await montar(tester);
    paginas.jumpToPage(7);
    await tester.pump();

    await tester.fling(find.byType(PageView), const Offset(-150, 0), 4000);
    await esperar(tester, const Duration(seconds: 3));

    expect(paginas.page, 7);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
