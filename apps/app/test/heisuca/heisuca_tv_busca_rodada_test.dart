import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/features/busca/modelo.dart';
import 'package:heisuca/features/busca/tela_busca_tv.dart';
import 'package:heisuca/features/explorar/modelo.dart';
import 'package:heisuca/features/explorar/tela_explorar_tv.dart';
import 'package:heisuca/features/titulo/menu_do_titulo_tv.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/platform_detector.dart';
import 'package:heisuca/widgets/tv_virtual_keyboard.dart';

import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';
import '../visual/heisuca_snapshot.dart';

void main() {
  final capturas = Platform.environment['HEISUCA_TV_CAPTURAS'];
  late HeisucaP3Fixture fixture;
  setUp(() async {
    resetSharedPreferencesForTest();
    await LocaleSettings.setLocale(AppLocale.pt);
    TvDetectionService.debugSetTvOverride(true);
    fixture = HeisucaP3Fixture();
    await fixture.initialize(settings.ThemeMode.dark);
  });
  tearDown(() => TvDetectionService.debugSetTvOverride(null));

  Future<void> montar(WidgetTester tester, Widget child, double letra) async {
    if (capturas != null) await heisucaLoadFonts();
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      fixture.wrap(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
            child: child!,
          ),
          home: child,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  for (final letra in [1.0, 2.0]) {
    testWidgets('Busca compõe um campo, teclado e resultados lado a lado, letra $letra', (tester) async {
      final campo = TextEditingController();
      final foco = FocusNode();
      addTearDown(campo.dispose);
      addTearDown(foco.dispose);
      await montar(
        tester,
        TelaBuscaTv(
          campo: campo,
          foco: foco,
          buscou: true,
          titulos: const [TituloDaBusca(chave: 'a', titulo: 'Duna')],
        ),
        letra,
      );
      foco.requestFocus();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Buscar filmes, séries e pessoas'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('a'), findsOneWidget, reason: 'teclado integrado continua visível junto dos resultados');
      final tecla = tester.getRect(find.text('a'));
      final resultado = tester.getRect(find.byKey(const ValueKey('busca-tv-a')));
      expect(tecla.right, lessThan(resultado.left));
      expect(tecla.top, lessThan(540 - 27));
      if (capturas != null) {
        Directory(capturas).createSync(recursive: true);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(Uri.file('$capturas/busca_${(letra * 100).round()}.png')),
        );
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(campo.text, 'b');
      expect(tester.takeException(), isNull);
    });

    for (final biblioteca in [false, true]) {
      testWidgets(
        '${biblioteca ? 'Biblioteca' : 'Busca'}: segurar OK abre menu uma vez sem abrir título, letra $letra',
        (tester) async {
          var abriu = 0;
          var menu = 0;
          final campo = TextEditingController();
          final foco = FocusNode();
          final primeiro = FocusNode();
          addTearDown(campo.dispose);
          addTearDown(foco.dispose);
          addTearDown(primeiro.dispose);
          await montar(
            tester,
            biblioteca
                ? TelaExplorarTv(
                    bibliotecas: const [],
                    primeiroCartao: primeiro,
                    itens: [
                      ItemDoExplorar(chave: 'a', titulo: 'Duna', aoTocar: () => abriu++, aoSegurar: () => menu++),
                    ],
                  )
                : TelaBuscaTv(
                    campo: campo,
                    foco: foco,
                    primeiroResultado: primeiro,
                    buscou: true,
                    titulos: [
                      TituloDaBusca(chave: 'a', titulo: 'Duna', aoTocar: () => abriu++, aoSegurar: () => menu++),
                    ],
                  ),
            letra,
          );
          primeiro.requestFocus();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
          await tester.pump(const Duration(milliseconds: 600));
          await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
          await tester.pump();
          expect(menu, 1);
          expect(abriu, 0);
          await tester.sendKeyEvent(LogicalKeyboardKey.select);
          await tester.pump();
          expect(abriu, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Teclado sobreposto do login expõe a tecla focada à acessibilidade', (tester) async {
    final semantica = tester.ensureSemantics();
    final campo = TextEditingController();
    addTearDown(campo.dispose);
    late BuildContext contexto;
    await montar(
      tester,
      Builder(
        builder: (context) {
          contexto = context;
          return const Scaffold();
        },
      ),
      2,
    );
    showTvVirtualKeyboard(context: contexto, controller: campo);
    await tester.pumpAndSettle();
    final um = find.bySemanticsLabel('1');
    expect(um, findsOneWidget);
    expect(tester.getSemantics(um).flagsCollection.isFocused, ui.Tristate.isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.bySemanticsLabel('2')).flagsCollection.isFocused, ui.Tristate.isTrue);
    expect(tester.getSemantics(um).flagsCollection.isFocused, ui.Tristate.isFalse);
    semantica.dispose();
  });

  testWidgets('Repetições do OK que abriu o menu não acionam Assistir na nova rota', (tester) async {
    final campo = TextEditingController();
    final foco = FocusNode();
    final primeiro = FocusNode();
    addTearDown(campo.dispose);
    addTearDown(foco.dispose);
    addTearDown(primeiro.dispose);
    var assistiu = 0;
    await montar(
      tester,
      Builder(
        builder: (context) => TelaBuscaTv(
          campo: campo,
          foco: foco,
          primeiroResultado: primeiro,
          buscou: true,
          titulos: [
            TituloDaBusca(
              chave: 'a',
              titulo: 'Duna',
              aoSegurar: () => showDialog<void>(
                context: context,
                builder: (_) => MenuDoTituloTv(
                  titulo: 'Duna',
                  aoAssistir: () => assistiu++,
                  aoAbrir: () {},
                  aoMudarVisto: () {},
                  aoMudarLista: () {},
                  visto: false,
                  naLista: false,
                ),
              ),
            ),
          ],
        ),
      ),
      2,
    );
    primeiro.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(MenuDoTituloTv), findsOneWidget);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(assistiu, 0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(assistiu, 1);
  });

  testWidgets('Campo integrado recebe teclado físico e Enter envia sem abrir outro campo', (tester) async {
    final campo = TextEditingController();
    final foco = FocusNode();
    addTearDown(campo.dispose);
    addTearDown(foco.dispose);
    var envios = 0;
    await montar(tester, TelaBuscaTv(campo: campo, foco: foco, aoEnviar: () => envios++), 2);
    foco.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'á');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(campo.text, 'á');
    expect(envios, 1);
    expect(find.byType(Dialog), findsNothing);
  });
}
