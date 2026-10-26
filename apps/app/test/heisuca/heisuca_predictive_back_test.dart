import '../test_helpers/predictive_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_palette.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_title_sheet.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/services/device_performance.dart';

class _Routes extends NavigatorObserver {
  Route<dynamic>? last;
  @override void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) { last = route; }
}
void main() {
  tearDown(DevicePerformance.debugReset);
  for (final reduction in ['normal', 'aparelho', 'sistema']) {
    final reduced = reduction != 'normal';
    for (final edge in [0, 1]) {
      testWidgets('ficha real: voltar pela borda $edge, cancelar/confirmar, movimento $reduction', (tester) async {
        tester.view.physicalSize = const Size(412, 914);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final routes = _Routes();
        DevicePerformance.debugReset(autoReduced: reduction == 'aparelho');
        final theme = cgflixAppTheme(CgflixThemeVariant.isis);
        expect(theme.pageTransitionsTheme.builders[TargetPlatform.android], isA<PredictiveBackPageTransitionsBuilder>());
        final item = MediaItem.jellyfin(id: 'fixture', kind: MediaKind.movie, title: 'Filme de teste');
        await tester.pumpWidget(MaterialApp(theme: theme, navigatorObservers: [routes],
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 32, bottom: 24), disableAnimations: reduction == 'sistema'), child: child!),
          home: Scaffold(body: Builder(builder: (context) => Center(child: TextButton(
            onPressed: () => HeisucaTitleSheet.show(context, item), child: const Text('Abrir')))))));
        await tester.tap(find.text('Abrir')); await tester.pumpAndSettle();
        expect(routes.last, isA<MaterialPageRoute<void>>());
        expect(tester.getRect(find.byTooltip('Voltar')).top, greaterThanOrEqualTo(32));
        final initial = tester.getCenter(find.byType(HeisucaTitleSheet));
        await sendPredictiveBack(tester, 'startBackGesture', edge: edge);
        await sendPredictiveBack(tester, 'updateBackGestureProgress', edge: edge, progress: .35);
        await tester.pumpAndSettle();
        final moved = tester.getCenter(find.byType(HeisucaTitleSheet));
        if (reduced) { expect(moved, initial); }
        else if (edge == 0) { expect(moved.dx, greaterThan(initial.dx)); }
        else { expect(moved.dx, lessThan(initial.dx)); }
        await sendPredictiveBack(tester, 'cancelBackGesture', edge: edge);
        await tester.pumpAndSettle();
        expect(find.byType(HeisucaTitleSheet), findsOneWidget);
        expect(tester.getCenter(find.byType(HeisucaTitleSheet)), initial);
        await sendPredictiveBack(tester, 'startBackGesture', edge: edge);
        await sendPredictiveBack(tester, 'updateBackGestureProgress', edge: edge, progress: .65);
        await sendPredictiveBack(tester, 'commitBackGesture', edge: edge);
        await tester.pumpAndSettle();
        expect(find.byType(HeisucaTitleSheet), findsNothing);
        expect(find.text('Abrir'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, variant: TargetPlatformVariant.only(TargetPlatform.android));
    }
  }
}
