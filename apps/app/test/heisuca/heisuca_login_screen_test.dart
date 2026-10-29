import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/utils/platform_detector.dart';

Widget _montar(Widget child) => MaterialApp(
  theme: cgflixAppTheme(CgflixThemeVariant.isis),
  home: child,
);

void main() {
  tearDown(() {
    TvDetectionService.debugReset();
    TvDetectionService.setForceTVSync(false);
  });

  group('HeisucaLoginScreen F1 QuickConnect TV vs Celular', () {
    testWidgets('login em celular não exibe o botão de Conexão Rápida (QR)', (tester) async {
      TvDetectionService.debugReset();
      TvDetectionService.setForceTVSync(false);

      await tester.pumpWidget(_montar(const HeisucaLoginScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.qr_code_2_rounded), findsNothing);
      expect(find.byTooltip('Conexão Rápida'), findsNothing);
    });

    testWidgets('login em TV exibe o botão de Conexão Rápida (QR)', (tester) async {
      TvDetectionService.debugReset();
      await TvDetectionService.getInstance(forceTv: true);
      TvDetectionService.setForceTVSync(true);

      await tester.pumpWidget(_montar(const HeisucaLoginScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
      expect(find.byTooltip('Conexão Rápida'), findsOneWidget);
    });
  });
}
