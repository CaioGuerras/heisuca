// Etapa 1E (D): a dedicatória fica somente no Sobre (com os dois corações); sai o interruptor
// "Mostrar dedicatória" do Avançado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_about.dart';
import 'package:plezy/cgflix/cgflix_advanced.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../test_helpers/prefs.dart';

void main() {
  // Refino 2: o Avançado ganhou chaves de Pular abertura (precisam das preferências).
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  testWidgets('Sobre mostra a dedicatória com o coração roxo e o verde', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CgflixDedication())));
    expect(find.text(cgflixDedicationText), findsOneWidget);
    expect(find.descendant(of: find.byType(CgflixDedicationHearts), matching: find.byType(AppIcon)), findsNWidgets(2));
  });

  testWidgets('Avançado não tem mais "Mostrar dedicatória"', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: cgflixAppTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(child: Column(children: [CgflixAdvancedFeatures(), CgflixAdvancedPlayback()])),
        ),
      ),
    );
    expect(find.text('Mostrar dedicatória'), findsNothing);
    expect(find.text(cgflixDedicationText), findsNothing);
  });
}
