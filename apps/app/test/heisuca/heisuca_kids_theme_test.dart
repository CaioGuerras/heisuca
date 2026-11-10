import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids_flow.dart';

void main() {
  testWidgets('F2: app em Shikkoku -> abrir o fluxo -> fundo do passo 1 é o do Shikkoku', (tester) async {
    final shikkokuTheme = cgflixAppTheme(CgflixThemeVariant.isis);
    final shikkokuPalette = CgflixPalette.isis;

    await tester.pumpWidget(MaterialApp(
      theme: shikkokuTheme,
      home: const HeisucaKidsSetupScreen(),
    ));
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, shikkokuPalette.background);
  });
}
