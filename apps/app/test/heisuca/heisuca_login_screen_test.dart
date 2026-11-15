import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/utils/platform_detector.dart';

import '../test_helpers/prefs.dart';

Widget _montar(Widget child) => MaterialApp(theme: cgflixAppTheme(CgflixThemeVariant.isis), home: child);

void main() {
  _testesFontesEAviso();
  tearDown(() {
    TvDetectionService.debugReset();
    TvDetectionService.setForceTVSync(false);
  });

  group('HeisucaLoginScreen F1 QuickConnect TV vs Celular', () {
    // V2 (PLANO §4, Entrada): Quick Connect no ícone também no celular, para entrar sem digitar a senha.
    testWidgets('login em celular exibe o botão de Conexão Rápida (QR)', (tester) async {
      TvDetectionService.debugReset();
      TvDetectionService.setForceTVSync(false);

      await tester.pumpWidget(_montar(const HeisucaLoginScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
      expect(find.byTooltip('Conexão Rápida'), findsOneWidget);
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
    testWidgets('foco no campo de usuário em TV chama setNativeTextInputFocused(true) e false ao desfocar', (
      tester,
    ) async {
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

  testWidgets('servidor, usuário e senha avisam o preenchimento automático do Android, dentro de um grupo só', (
    tester,
  ) async {
    TvDetectionService.debugReset();
    TvDetectionService.setForceTVSync(false);
    await tester.pumpWidget(_montar(const HeisucaLoginScreen()));
    await tester.pump();

    List<String>? dicas(String chave) => tester
        .widget<TextField>(find.descendant(of: find.byKey(ValueKey(chave)), matching: find.byType(TextField)))
        .autofillHints
        ?.toList();
    expect(dicas('heisuca-login-server'), [AutofillHints.url]);
    expect(dicas('heisuca-login-user'), [AutofillHints.username]);
    expect(dicas('heisuca-login-password'), [AutofillHints.password]);
    for (final chave in ['heisuca-login-server', 'heisuca-login-user', 'heisuca-login-password']) {
      expect(find.ancestor(of: find.byKey(ValueKey(chave)), matching: find.byType(AutofillGroup)), findsOneWidget);
    }
    expect(find.byType(AutofillGroup), findsOneWidget, reason: 'os três campos dividem o mesmo grupo');
  });

  testWidgets('sair da tela sem entrar não oferece guardar a senha: só o login aceito oferece', (tester) async {
    TvDetectionService.debugReset();
    TvDetectionService.setForceTVSync(false);
    await tester.pumpWidget(_montar(const HeisucaLoginScreen()));
    await tester.pump();

    expect(tester.widget<AutofillGroup>(find.byType(AutofillGroup)).onDisposeAction, AutofillContextAction.cancel);
  });
}

void _testesFontesEAviso() {
  group('HeisucaLoginScreen folha de fontes e aviso', () {
    testWidgets('folha mostra as 3 marcas em SVG e sem o ícone genérico', (tester) async {
      await tester.pumpWidget(_montar(const HeisucaLoginScreen()));
      await tester.pump();
      await tester.tap(find.text('Outros servidores e pastas locais'));
      await tester.pumpAndSettle();

      expect(find.text('Adicionar Fontes e Servidores'), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.byType(SvgPicture)), findsNWidgets(3));
      expect(find.byIcon(Icons.dns_rounded), findsNothing);
      expect(find.byIcon(Icons.movie_filter_rounded), findsNothing);
    });

    testWidgets('aviso da conexão rápida some ao digitar o endereço', (tester) async {
      await tester.pumpWidget(_montar(const HeisucaLoginScreen()));
      await tester.pump();
      await tester.tap(find.byTooltip('Conexão Rápida'));
      await tester.pump();
      const aviso = 'Digite o endereço do servidor para usar a conexão rápida.';
      expect(find.text(aviso), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('heisuca-login-server')), 'https://meu.servidor.com');
      await tester.pump();
      expect(find.text(aviso), findsNothing);
    });
  });
}
