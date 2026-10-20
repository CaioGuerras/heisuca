// Refino 2b (auditoria Google, item "teclado/controle nos cartões"): o cartão da Início recebe foco,
// mostra o contorno e abre com Enter.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/cgflix/home/cgflix_cards.dart';

void main() {
  testWidgets('cartão abre com Enter e mostra o contorno de foco', (tester) async {
    var abriu = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: cgflixAppTheme(),
        home: Scaffold(
          body: Center(
            child: CgflixPressable(
              semanticLabel: 'Duna',
              onTap: () => abriu++,
              child: const SizedBox(width: 120, height: 180, child: Text('Duna')),
            ),
          ),
        ),
      ),
    );
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final caixa = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(CgflixPressable), matching: find.byType(DecoratedBox)).first,
    );
    expect((caixa.decoration as BoxDecoration).border, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(abriu, 1);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });
}
