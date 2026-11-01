import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/utils/platform_detector.dart';

import '../test_helpers/prefs.dart';

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

  group('HeisucaLoginScreen T1 TV native text input focus bridge', () {
    testWidgets('foco no campo de usuário em TV chama setNativeTextInputFocused(true) e false ao desfocar', (tester) async {
      resetSharedPreferencesForTest();
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.tvUseNativeKeyboard, true);

      TvDetectionService.debugReset();
      await TvDetectionService.getInstance(forceTv: true);
      TvDetectionService.setForceTVSync(true);

      const channel = MethodChannel('app.heisuca/text_input');
      final sentStates = <bool>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'setNativeTextInputFocused') {
          sentStates.add(call.arguments as bool);
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      });

      await tester.pumpWidget(_montar(const HeisucaLoginScreen()));
      await tester.pump();

      final userField = find.byKey(const ValueKey('heisuca-login-user'));
      expect(userField, findsOneWidget);

      await tester.tap(userField);
      await tester.pump();
      await tester.pump();

      expect(sentStates, [true]);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump();

      expect(sentStates, [true, false]);
    });
  });
}
