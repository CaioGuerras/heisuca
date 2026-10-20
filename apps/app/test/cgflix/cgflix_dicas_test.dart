// Refino 2: dicas do CGFLIX. A do player aparece uma vez, some com um toque ou sozinha, não volta,
// e o Sobre › Dicas do CGFLIX faz ela aparecer de novo. As folhas abrem pelo "?".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_dicas.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

Widget _app(Widget home, {bool reduzirMovimento = false}) => MaterialApp(
  theme: cgflixAppTheme(CgflixThemeVariant.isis),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduzirMovimento),
      child: home,
    ),
  ),
);

Widget _player() => const Scaffold(
  backgroundColor: Colors.black,
  body: Stack(children: [Positioned.fill(child: CgflixDicaPlayer())]),
);

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('todas as dicas têm título, resumo de uma linha e 2 a 4 frases', () {
    for (final dica in CgflixDica.values) {
      expect(dica.titulo, isNotEmpty);
      expect(dica.resumo.length, lessThan(90), reason: dica.name);
      final frases = RegExp(r'[.!?](\s|$)').allMatches(dica.texto).length;
      expect(frases, inInclusiveRange(2, 4), reason: '${dica.name}: $frases frases');
      // Sem jargão na frente do usuário.
      for (final jargao in ['bitrate', 'codec', 'transcodifica', 'buffer', 'mpv', 'passthrough']) {
        expect(dica.texto.toLowerCase(), isNot(contains(jargao)), reason: dica.name);
      }
    }
  });

  testWidgets('dica do player: aparece na primeira vez e some com um toque', (tester) async {
    await tester.pumpWidget(_app(_player()));
    expect(find.byKey(const ValueKey('cgflix-dica-player')), findsOneWidget);
    expect(find.text(cgflixDicaPlayerTexto), findsOneWidget);
    // Já conta como vista (se o app fechar no meio, não volta).
    expect(SettingsService.instance.read(cgflixDicaPlayerVistaPref), isTrue);

    await tester.tap(find.byKey(const ValueKey('cgflix-dica-player')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cgflix-dica-player')), findsNothing);
  });

  testWidgets('dica do player: some sozinha e não volta no próximo vídeo', (tester) async {
    await tester.pumpWidget(_app(_player()));
    expect(find.byKey(const ValueKey('cgflix-dica-player')), findsOneWidget);
    await tester.pump(cgflixDicaPlayerDuracao);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cgflix-dica-player')), findsNothing);

    // "Próximo vídeo": o player monta de novo.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(_player()));
    expect(find.byKey(const ValueKey('cgflix-dica-player')), findsNothing);
  });

  testWidgets('dica do player: com "remover animações" fecha sem esmaecer', (tester) async {
    await tester.pumpWidget(_app(_player(), reduzirMovimento: true));
    expect(find.byType(AnimatedOpacity), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cgflix-dica-player')));
    await tester.pump();
    expect(find.byKey(const ValueKey('cgflix-dica-player')), findsNothing);
  });

  testWidgets('Sobre › Dicas do CGFLIX: lista todas e reabre a dica do player', (tester) async {
    await SettingsService.instance.write(cgflixDicaPlayerVistaPref, true);
    tester.view.physicalSize = const Size(412, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const Scaffold(body: CgflixDicasAboutTile())));
    await tester.tap(find.text('Dicas do CGFLIX'));
    await tester.pumpAndSettle();
    for (final dica in CgflixDica.values) {
      expect(find.text(dica.titulo), findsOneWidget, reason: dica.name);
    }

    await tester.tap(find.byKey(const ValueKey('cgflix-dicas-rever-player')));
    await tester.pumpAndSettle();
    expect(find.text('Pronto. A dica aparece no próximo vídeo.'), findsOneWidget);
    expect(SettingsService.instance.read(cgflixDicaPlayerVistaPref), isFalse);

    // E aparece de novo no player.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(_player()));
    expect(find.byKey(const ValueKey('cgflix-dica-player')), findsOneWidget);
  });

  testWidgets('o "?" abre a folha com o texto e "Entendi" fecha', (tester) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: CgflixComDica(
            dica: CgflixDica.pularAbertura,
            child: const ListTile(title: Text('Pular abertura')),
          ),
        ),
      ),
    );
    final botao = find.byKey(const ValueKey('cgflix-dica-botao-pularAbertura'));
    expect(tester.getSize(botao).height, greaterThanOrEqualTo(48));
    expect(find.byTooltip('Saiba mais: Pular abertura e créditos'), findsOneWidget);

    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(find.text(CgflixDica.pularAbertura.texto), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.text(CgflixDica.pularAbertura.texto), findsNothing);
  });

  testWidgets('folha da dica usa a superfície do tema Heitor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.heitor),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () => showCgflixDica(context, CgflixDica.gestos), child: const Text('abrir')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, CgflixPalette.heitor.surface);
  });
}
