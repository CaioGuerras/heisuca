// Tela de entrada (login) no celular, nos três temas, para revisão visual.
//   HEISUCA_SNAPSHOT=1 flutter test test/visual/entrada_test.dart --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/utils/platform_detector.dart';

import '../test_helpers/prefs.dart';
import 'heisuca_snapshot.dart';

void main() {
  for (final (nome, variante) in [
    ('shikkoku', CgflixThemeVariant.isis),
    ('hisui', CgflixThemeVariant.heitor),
    ('sumi', CgflixThemeVariant.sumi),
  ]) {
    testWidgets('Entrada: $nome', (tester) async {
      resetSharedPreferencesForTest();
      TvDetectionService.debugReset();
      TvDetectionService.setForceTVSync(false);
      await heisucaLoadFonts();
      heisucaPhoneView(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: cgflixAppTheme(variante),
          home: const HeisucaLoginScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/entrada_$nome.png'));
    }, skip: !heisucaSnapshotEnabled);
  }
}
