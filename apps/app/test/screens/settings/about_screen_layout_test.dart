import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heisuca/cgflix/apoio/cgflix_apoio_screen.dart';
import 'package:heisuca/cgflix/cgflix_about.dart';
import 'package:heisuca/cgflix/cgflix_dicas.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_logo.dart';
import 'package:heisuca/heisuca/heisuca_news.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/screens/settings/about_screen.dart';
import 'package:heisuca/screens/settings/licenses_screen.dart';
import 'package:heisuca/widgets/app_icon.dart';

import '../../test_helpers/multi_server_fixtures.dart';

const _selo = '🤖 Feito em parceria com IA: Claude, Codex e Gemini.';
const _codigo = 'O Heisuca é software livre: qualquer pessoa pode ver, estudar e melhorar o código.';
const _canalUrl = MethodChannel('plugins.flutter.io/url_launcher');

Future<void> _sobre(
  WidgetTester tester,
  CgflixThemeVariant tema, {
  Size tamanho = const Size(400, 2400),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fontes = testMultiServer(clients: [_FonteNoticias()]);
  fontes.manager.setNavigationSource(Object(), 'news');
  await tester.pumpWidget(
    ChangeNotifierProvider<MultiServerProvider>.value(
      value: fontes.provider,
      child: TranslationProvider(
        child: MaterialApp(
          theme: cgflixAppTheme(tema),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala)),
            child: child!,
          ),
          home: const AboutScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.pt);
    PackageInfo.setMockInitialValues(
      appName: 'Heisuca',
      packageName: 'app.heisuca.player.teste.home',
      version: '2.0.34',
      buildNumber: '38',
      buildSignature: '',
    );
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final tema in [CgflixThemeVariant.isis, CgflixThemeVariant.heitor]) {
    testWidgets('Sobre $tema: ordem única, textos aprovados, selo e dedicatória', (tester) async {
      await _sobre(tester, tema);
      final ordem = [
        find.byType(HeisucaLogo),
        find.text('Nada entre você e o filme.'),
        find.text('Versão 2.0.34'),
        find.byType(CgflixDicasAboutTile),
        find.byType(HeisucaNewsEntry),
        find.byType(HeisucaOpenSourceCard),
        find.text('Agradecimentos'),
        find.byType(HeisucaTributeCards),
        find.text(t.about.openSourceLicenses),
        find.byType(CgflixApoioAboutLine),
        find.byType(HeisucaAiSeal),
        find.byType(CgflixDedication),
      ];
      double anterior = -1;
      for (final alvo in ordem) {
        expect(alvo, findsOneWidget);
        final topo = tester.getTopLeft(alvo).dy;
        expect(topo, greaterThan(anterior), reason: '$alvo está fora da ordem');
        anterior = topo;
      }
      expect(find.text('Licença GPL-3.0'), findsOneWidget);
      expect(find.text(_codigo), findsOneWidget);
      expect(find.text('Por sempre apoiar a fazer essas coisas rsrs.'), findsOneWidget);
      expect(
        find.text('Por até rir às vezes mas sempre me encorajar a evoluir, mesmo que cheio de HnR no site.'),
        findsOneWidget,
      );
      expect(find.text('all.dev.br'), findsOneWidget);
      expect(find.text('locadora.cc'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is AppIcon && w.icon == Symbols.handshake), findsOneWidget);
      expect(find.text(_selo), findsOneWidget);
      expect(find.text('Feito com amor, para Isis e Heitor'), findsOneWidget);
      expect(find.text('Para a família, que sempre se reuniu diante da tela.'), findsNothing);
      expect(
        tester.widget<Text>(find.text(cgflixDedicationText)).style?.color,
        cgflixAppTheme(tema).extension<CgflixPalette>()!.textMuted,
      );
      expect(tester.getSize(find.byType(CgflixApoioAboutLine)).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sobre $tema: celular estreito e fonte ampliada sem overflow', (tester) async {
      await _sobre(tester, tema, tamanho: const Size(320, 640), escala: 1.6);
      await tester.scrollUntilVisible(find.byType(CgflixDedication), 300, maxScrolls: 30);
      expect(find.byType(CgflixDedication), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Sobre: botões abrem GitHub, all.dev.br e locadora.cc nos destinos aprovados', (tester) async {
    final abertos = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_canalUrl, (call) async {
      if (call.method == 'launch') abertos.add((call.arguments as Map)['url'] as String);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_canalUrl, null));
    await _sobre(tester, CgflixThemeVariant.isis);
    for (final texto in ['Ver o código no GitHub', 'all.dev.br', 'locadora.cc']) {
      final botao = find.widgetWithText(TextButton, texto);
      expect(botao, findsOneWidget);
      expect(tester.getSize(botao).height, greaterThanOrEqualTo(48));
      await tester.tap(botao);
      await tester.pumpAndSettle();
    }
    expect(abertos, ['https://github.com/CaioGuerras/heisuca', 'https://all.dev.br/', 'https://locadora.cc/']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sobre: licenças identificam o Plezy GPL-3.0 como base do app', (tester) async {
    await _sobre(tester, CgflixThemeVariant.isis);
    await tester.tap(find.text(t.about.openSourceLicenses));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(find.byType(LicensesScreen), findsOneWidget);
    final aviso = find.text('Heisuca (GPL-3.0); base: Plezy (GPL-3.0)');
    await tester.scrollUntilVisible(aviso, 500, maxScrolls: 80);
    expect(aviso, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FonteNoticias implements MediaServerClient {
  @override
  void close() {}
  @override
  MediaBackend get backend => MediaBackend.jellyfin;
  @override
  String get serverName => 'Servidor de teste';
  @override
  ServerId get serverId => ServerId('news');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
