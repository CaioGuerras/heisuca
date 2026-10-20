// Refino 2b: voltar preditivo ligado (Android 13+). O gesto de voltar arrasta a página junto com o
// dedo (encolhe e arredonda) e só fecha ao soltar; desistir devolve a página ao lugar.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';

Future<void> _mandar(WidgetTester tester, MethodCall call) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(call),
    (_) {},
  );
  await tester.pump();
}

Future<void> _abrirSubtela(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: cgflixAppTheme().copyWith(platform: TargetPlatform.android),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('subtela')))),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  expect(find.text('subtela'), findsOneWidget);
}

const _inicio = MethodCall('startBackGesture', {
  'touchOffset': [5.0, 300.0],
  'progress': 0.0,
  'swipeEdge': 0,
});

MethodCall _progresso(double p) =>
    MethodCall('updateBackGestureProgress', {'x': 100.0, 'y': 300.0, 'progress': p, 'swipeEdge': 0});

void main() {
  testWidgets('o gesto arrasta a subtela com o dedo e fecha ao soltar', (tester) async {
    await _abrirSubtela(tester);
    await _mandar(tester, _inicio);
    await _mandar(tester, _progresso(0.5));
    // Durante o gesto a página encolhe (efeito do voltar preditivo) e a de baixo aparece.
    final escala = tester.widget<ScaleTransition>(
      find.ancestor(of: find.text('subtela'), matching: find.byType(ScaleTransition)).first,
    );
    expect(escala.scale.value, closeTo(0.95, 0.02));
    expect(find.text('abrir'), findsOneWidget);

    await _mandar(tester, const MethodCall('commitBackGesture'));
    await tester.pumpAndSettle();
    expect(find.text('subtela'), findsNothing);
  });

  testWidgets('desistir do gesto devolve a subtela', (tester) async {
    await _abrirSubtela(tester);
    await _mandar(tester, _inicio);
    await _mandar(tester, _progresso(0.3));
    await _mandar(tester, const MethodCall('cancelBackGesture'));
    await tester.pumpAndSettle();
    expect(find.text('subtela'), findsOneWidget);
    expect(find.text('abrir'), findsNothing);
  });

  test('manifesto liga o voltar preditivo (android:enableOnBackInvokedCallback)', () {
    final manifesto = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifesto, contains('android:enableOnBackInvokedCallback="true"'));
  });
}
