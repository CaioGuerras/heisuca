import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/navigation_transitions.dart';

void main() {
  testWidgets('rota de sessão: transparente, sem violar a asserção do MaterialPageRoute, com transição do tema',
      (tester) async {
    final route = fadeRoute<void>(const Text('sessão'));
    expect(route, isA<PageRoute<void>>());
    expect(route, isA<MaterialRouteTransitionMixin<void>>());
    expect((route as PageRoute<void>).opaque, isFalse);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey: navigator, home: const Text('início')));
    navigator.currentState!.pushReplacement(route);
    await tester.pumpAndSettle();
    expect(find.text('sessão'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
