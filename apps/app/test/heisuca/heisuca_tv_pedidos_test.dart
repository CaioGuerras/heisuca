import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/requests/cgflix_requests_ui.dart';
import 'package:heisuca/cgflix/requests/cgflix_seerr.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_canvas.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_pecas.dart';
import 'package:heisuca/utils/platform_detector.dart';

import '../design/componentes/apoio.dart';

class _Pedidos implements CgflixRequestsBackend {
  final pedidos = <(int, List<int>?)>[];
  @override
  Future<List<CgflixRequestable>> search(String query) async => const [
    CgflixRequestable(tmdbId: 1, isMovie: true, title: 'O filme distante'),
    CgflixRequestable(tmdbId: 2, isMovie: false, title: 'A série distante'),
  ];
  @override
  Future<List<CgflixSeasonChoice>> seasons(int tmdbId) async => const [
    CgflixSeasonChoice(number: 1, name: 'Temporada 1', lockedLabel: 'Já temos'),
    CgflixSeasonChoice(number: 2, name: 'Temporada 2'),
    CgflixSeasonChoice(number: 3, name: 'Temporada 3'),
  ];
  @override
  Future<void> request(CgflixRequestable item, {List<int>? seasons}) async => pedidos.add((item.tmdbId, seasons));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Pedidos pedidos;
  setUp(() {
    TvDetectionService.debugSetTvOverride(true);
    pedidos = _Pedidos();
    CgflixRequests.debugOverride = pedidos;
  });
  tearDown(() {
    TvDetectionService.debugSetTvOverride(null);
    CgflixRequests.debugOverride = null;
  });
  for (final letra in [1.0, 2.0]) {
    testWidgets('Pedir na TV usa peças V2; OK pede filme e escolhe temporadas, letra $letra', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        naTela(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
              child: const HeisucaTvCanvas(
                child: SingleChildScrollView(child: CgflixRequestSection(query: 'distante')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final filme = find.byKey(const ValueKey('cgflix-pedir-filme-1'));
      final acaoFilme = find.descendant(of: filme, matching: find.byType(BotaoTv));
      expect(acaoFilme, findsOneWidget, reason: 'pedido precisa da mesma peça e foco da TV');
      final detector = tester.widget<FocusableActionDetector>(
        find.descendant(of: acaoFilme, matching: find.byType(FocusableActionDetector)),
      );
      // A navegação é por foco real; usar o próprio nó do detector, sem toque no botão.
      Focus.of(
        tester.element(find.descendant(of: acaoFilme, matching: find.byType(GestureDetector)).first),
      ).requestFocus();
      expect(detector, isNotNull);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(pedidos.pedidos, [(1, null)]);
      final serie = find.byKey(const ValueKey('cgflix-pedir-serie-2'));
      final acaoSerie = find.descendant(of: serie, matching: find.byType(BotaoTv));
      await tester.ensureVisible(acaoSerie);
      Focus.of(
        tester.element(find.descendant(of: acaoSerie, matching: find.byType(GestureDetector)).first),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('Temporada 2'), findsOneWidget);
      final temporada = find.widgetWithText(BotaoTv, 'Temporada 2');
      Focus.of(
        tester.element(find.descendant(of: temporada, matching: find.byType(GestureDetector)).first),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      final confirmar = find.widgetWithText(BotaoTv, 'Pedir 1 temporada');
      await tester.ensureVisible(confirmar);
      Focus.of(
        tester.element(find.descendant(of: confirmar, matching: find.byType(GestureDetector)).first),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(pedidos.pedidos, hasLength(2));
      expect(pedidos.pedidos.last.$1, 2);
      expect(pedidos.pedidos.last.$2, [3]);
      expect(tester.takeException(), isNull);
    });
  }
}
