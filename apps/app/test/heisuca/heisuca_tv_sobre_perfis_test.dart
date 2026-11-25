import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_pecas.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/screens/profile/profile_switch_screen.dart';
import 'package:heisuca/screens/profile/pin_entry_dialog.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/profiles/profile.dart';
import 'package:heisuca/profiles/profile_connection.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/screens/settings/about_screen.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/platform_detector.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HeisucaP3Fixture fixture;

  setUp(() async {
    resetSharedPreferencesForTest();
    await LocaleSettings.setLocale(AppLocale.pt);
    TvDetectionService.debugSetTvOverride(true);
    PackageInfo.setMockInitialValues(
      appName: 'Heisuca',
      packageName: 'app.heisuca.player.teste.home',
      version: '2.0.47',
      buildNumber: '3032',
      buildSignature: '',
    );
    fixture = HeisucaP3Fixture();
    await fixture.initialize(settings.ThemeMode.dark);
    addTearDown(fixture.dispose);
  });
  tearDown(() => TvDetectionService.debugSetTvOverride(null));

  Future<void> montar(WidgetTester tester, Widget tela, double letra) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      fixture.wrap(
        MaterialApp(
          theme: cgflixLightTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
            child: child!,
          ),
          home: tela,
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  }

  for (final letra in [1.0, 2.0]) {
    testWidgets('Sobre da TV: grade igual, V2 escura e foco pelo D-pad, letra $letra', (tester) async {
      final semantica = tester.ensureSemantics();
      await montar(tester, const AboutScreen(), letra);
      expect(find.byType(BotaoTv), findsWidgets, reason: 'Sobre usa as peças da TV');
      expect(find.byType(InkWell), findsNothing);
      expect(tester.getSemantics(find.byType(BotaoTv).first), isSemantics(isFocused: true));
      final larguras = [
        for (final chave in ['dicas', 'codigo', 'rosiel', 'locadora'])
          tester.getSize(find.byKey(ValueKey('sobre-tv-$chave'))).width,
      ];
      expect(larguras.toSet(), hasLength(1), reason: 'Dicas/código/agradecimentos têm a mesma largura');
      expect(Theme.of(tester.element(find.text('Sobre'))).brightness, Brightness.dark);
      expect(tester.element(find.text('Sobre')).cgflix.isLight, isFalse);
      expect(tester.takeException(), isNull);
      final vistos = <String>{};
      for (var i = 0; i < 12; i++) {
        final contexto = FocusManager.instance.primaryFocus?.context;
        if (contexto != null) {
          final caixa = contexto.findRenderObject()! as RenderBox;
          final retangulo = Rect.fromPoints(
            caixa.localToGlobal(Offset.zero),
            caixa.localToGlobal(caixa.size.bottomRight(Offset.zero)),
          );
          expect(retangulo.top, greaterThanOrEqualTo(27));
          expect(retangulo.bottom, lessThanOrEqualTo(513));
          vistos.add(contexto.findAncestorWidgetOfExactType<BotaoTv>()?.rotulo ?? '');
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      expect(vistos.length, greaterThan(2), reason: 'o D-pad atravessa a grade e chega ao fim');
      await tester.scrollUntilVisible(find.text('Feito com amor, para Isis e Heitor'), 300);
      expect(find.text('🤖 Em parceria com IA: Claude, Codex e Gemini.'), findsOneWidget);
      expect(find.text('🤝 Rosiel Victor'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantica.dispose();
    });

    testWidgets('Perfil com PIN: estado legível sem selo recortado e formulário pelo D-pad, letra $letra', (
      tester,
    ) async {
      final perfis = _PerfisComPin();
      addTearDown(perfis.dispose);
      await montar(
        tester,
        ChangeNotifierProvider<ActiveProfileProvider>.value(value: perfis, child: const ProfileSwitchScreen()),
        letra,
      );
      expect(find.text('Protegido por PIN'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(CartaoTv), matching: find.byIcon(Symbols.lock_rounded)),
        findsNothing,
        reason: 'o cadeado no canto seria recortado pelo círculo; a legenda já informa o PIN',
      );
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ProfileTile:protegido');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.byType(PinEntryDialog), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'PinKeypad');
      expect(tester.takeException(), isNull);
      // 1 → 2 → 3 ↓ 6: um PIN incorreto retorna ao formulário sem liberar o gerenciamento.
      for (final tecla in [
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.select,
      ]) {
        await tester.sendKeyEvent(tecla);
        await tester.pumpAndSettle();
      }
      expect(find.text(t.profiles.incorrectPinTryAgain), findsOneWidget);
      expect(tester.getRect(find.text(t.profiles.incorrectPinTryAgain)).bottom, lessThanOrEqualTo(513));
      // A tecla de cancelar fica na 4ª linha, 1ª coluna; também é acessível só com o controle.
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      expect(tester.getRect(find.byIcon(Symbols.close_rounded)).bottom, lessThanOrEqualTo(513));
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.byType(PinEntryDialog), findsNothing);
      expect(find.byType(ProfileSwitchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Perfil ativo com PIN mantém os dois estados sem selo recortado, letra $letra', (tester) async {
      final perfis = _PerfisComPin(comAtivo: true);
      addTearDown(perfis.dispose);
      await montar(
        tester,
        ChangeNotifierProvider<ActiveProfileProvider>.value(value: perfis, child: const ProfileSwitchScreen()),
        letra,
      );
      expect(find.text(t.profiles.active), findsOneWidget);
      expect(find.text('Protegido por PIN'), findsOneWidget);
      expect(find.descendant(of: find.byType(CartaoTv), matching: find.byIcon(Symbols.lock_rounded)), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Trocar perfil da TV: cartões V2, sem onda e com foco legível, letra $letra', (tester) async {
      final semantica = tester.ensureSemantics();
      await montar(tester, const ProfileSwitchScreen(), letra);
      expect(find.byType(CartaoTv), findsOneWidget, reason: 'perfil usa o cartão da TV');
      expect(find.byType(BotaoTv), findsWidgets);
      expect(find.byType(InkWell), findsNothing);
      expect(Theme.of(tester.element(find.text('Trocar perfil'))).brightness, Brightness.dark);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ProfileTile:familia');
      expect(tester.getSemantics(find.bySemanticsLabel('Família, ${t.profiles.active}')), isSemantics(isFocused: true));
      expect(find.widgetWithText(BotaoTv, t.profiles.manage), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('ProfileTile:familia'));
      final contexto = FocusManager.instance.primaryFocus!.context!;
      final caixa = contexto.findRenderObject()! as RenderBox;
      final retangulo = Rect.fromPoints(
        caixa.localToGlobal(Offset.zero),
        caixa.localToGlobal(caixa.size.bottomRight(Offset.zero)),
      );
      expect(retangulo.top, greaterThanOrEqualTo(27));
      expect(retangulo.bottom, lessThanOrEqualTo(513));
      expect(tester.takeException(), isNull);
      semantica.dispose();
    });
  }

  testWidgets('Sobre da TV: OK nos links abre os destinos aprovados', (tester) async {
    const canalUrl = MethodChannel('plugins.flutter.io/url_launcher');
    final abertos = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canalUrl, (call) async {
      if (call.method == 'launch') abertos.add((call.arguments as Map)['url'] as String);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canalUrl, null));
    await montar(tester, const AboutScreen(), 2);
    for (final rotulo in ['Ver o código', 'all.dev.br', 'locadora.cc']) {
      Focus.of(tester.element(find.text(rotulo))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
    }
    expect(abertos, ['https://github.com/CaioGuerras/heisuca', 'https://all.dev.br/', 'https://locadora.cc/']);
    expect(tester.takeException(), isNull);
  });
}

class _PerfisComPin extends ChangeNotifier implements ActiveProfileProvider {
  _PerfisComPin({this.comAtivo = false});
  final bool comAtivo;
  final protegido = Profile.local(
    id: 'protegido',
    displayName: 'Perfil protegido',
    createdAt: DateTime.utc(2026),
    pinHash: computePinHash('1234'),
  );
  @override
  List<Profile> get profiles => [protegido];
  @override
  bool get isInitialized => true;
  @override
  Profile? get active => comAtivo ? protegido : null;
  @override
  String? get activeId => active?.id;
  @override
  String? avatarUrlFor(String profileId) => null;
  @override
  Map<String, List<ProfileConnection>> get connectionsByProfile => const {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
