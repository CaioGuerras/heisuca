import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/requests/cgflix_secure_store.dart';
import 'package:heisuca/heisuca/heisuca_profile_screen.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_menu.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/providers/theme_provider.dart';
import 'package:heisuca/screens/updates/update_screen.dart';
import 'package:heisuca/screens/updates/update_settings_screen.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/services/playback_diagnostics.dart';
import 'package:heisuca/services/updates/apk_installer.dart';
import 'package:heisuca/services/updates/update_controller.dart';
import 'package:heisuca/services/updates/update_feed_client.dart';
import 'package:heisuca/utils/log_redaction_manager.dart';
import 'package:heisuca/utils/platform_detector.dart';
import '../test_helpers/prefs.dart';

/// Conta os pedidos de cancelamento que a tela faz ao controlador.
class _ControladorQueConta extends UpdateController {
  _ControladorQueConta(UpdateController base)
    : super(
        config: base.config,
        feed: base.feed,
        instalador: base.instalador,
        settings: base.settings,
        segredos: base.segredos,
        emReproducao: base.emReproducao,
        cache: base.cache,
      );
  int cancelamentos = 0;
  bool _fechando = false;
  @override
  void cancelar() {
    if (!_fechando) cancelamentos++;
    super.cancelar();
  }

  @override
  void dispose() {
    // O próprio dispose cancela; o que interessa é o que a tela pede.
    _fechando = true;
    super.dispose();
  }
}

void main() {
  const nativo = MethodChannel('app.heisuca/updates');
  late UpdateController c;
  late SettingsService settings;
  late CgflixMemorySecureStore segredos;
  late Directory pasta;
  late int consultas;
  late bool reproduzindo;
  late Completer<void> validado;
  late List<String> acoes;
  final bytes = List<int>.generate(128, (i) => i);
  setUp(() async {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetTvOverride(true);
    settings = await SettingsService.getInstance();
    segredos = CgflixMemorySecureStore();
    pasta = await Directory.systemTemp.createTemp('heisuca-update-ui-');
    consultas = 0;
    reproduzindo = false;
    validado = Completer<void>();
    acoes = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(nativo, (call) async {
      acoes.add(call.method);
      return switch (call.method) {
        'estado' => {'habilitado': true, 'build': 2041, 'versao': '2.0.34', 'espacoLivre': 999999999},
        'escolherAbi' => 'universal',
        'validar' => () {
          if (!validado.isCompleted) validado.complete();
          return true;
        }(),
        'instalar' => 'permissao',
        _ => null,
      };
    });
    final config = ConfiguracaoAtualizacao(feed: 'https://feed.example/');
    final feed = UpdateFeedClient(
      config,
      cliente: MockClient((r) async {
        if (!r.url.path.endsWith('.json')) return http.Response.bytes(bytes, 200);
        consultas++;
        return http.Response(
          jsonEncode({
            'canal': 'estavel',
            'build': 2042,
            'versao': '2.0.35',
            'notas': 'Melhorias no app.',
            'assinatura_sha256': 'b' * 64,
            'apks': [
              {
                'abi': 'universal',
                'url': 'https://feed.example/app.apk',
                'bytes': bytes.length,
                'sha256': sha256.convert(bytes).toString(),
              },
            ],
          }),
          200,
        );
      }),
    );
    c = UpdateController(
      config: config,
      feed: feed,
      instalador: ApkInstaller(diagnosticos: PlaybackDiagnosticStore(directory: () async => pasta)),
      settings: settings,
      segredos: segredos,
      emReproducao: () => reproduzindo,
      cache: () async => pasta,
    );
  });
  tearDown(() {
    c.dispose();
    TvDetectionService.debugSetTvOverride(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(nativo, null);
  });
  Future<void> mostrar(WidgetTester tester, Widget tela, {double escala = 1}) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = escala;
    addTearDown(tester.view.reset);
    await tester.runAsync(c.iniciar);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: c,
        child: MaterialApp(theme: cgflixDarkTheme(), home: tela),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  }

  Future<void> acionar(WidgetTester tester, Future<void> Function() evento, bool Function() concluido) async {
    await tester.runAsync(() async {
      final sinal = Completer<void>();
      void observar() {
        if (concluido() && !sinal.isCompleted) sinal.complete();
      }

      c.addListener(observar);
      try {
        await evento();
        observar();
        await sinal.future.timeout(const Duration(seconds: 3));
      } finally {
        c.removeListener(observar);
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('menu da TV só mostra Atualizações depois de existir versão maior', (tester) async {
    await mostrar(tester, HeisucaTvMenu(onSelectDestination: (_) {}));
    expect(find.text('Atualizações'), findsNothing);
    await tester.runAsync(() => c.verificar(manual: true));
    await tester.pumpAndSettle();
    expect(find.text('Atualizações'), findsOneWidget);
  });
  testWidgets('título permanece visível ao focar as ações em TV 1080p', (tester) async {
    await tester.runAsync(() => c.verificar(manual: true));
    await mostrar(tester, const UpdateScreen(), escala: 2);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'atualizador-acao');
    expect(tester.getTopLeft(find.text('Atualizações')).dy, greaterThanOrEqualTo(0));
  });
  testWidgets('direcional percorre ações, baixa e trata permissão sem instalar sozinho', (tester) async {
    await tester.runAsync(() => c.verificar(manual: true));
    await mostrar(tester, const UpdateScreen());
    expect(find.textContaining('2.0.35'), findsWidgets);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'atualizador-acao');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'atualizador-voltar');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await acionar(tester, () => tester.sendKeyEvent(LogicalKeyboardKey.select), () => c.pronto);
    expect(find.text('Instalar'), findsOneWidget);
    expect(acoes.where((a) => a == 'instalar'), isEmpty);
    await acionar(
      tester,
      () => tester.sendKeyEvent(LogicalKeyboardKey.select),
      () => c.mensagem?.startsWith('Permita') == true,
    );
    expect(find.textContaining('Permita a instalação'), findsOneWidget);
    expect(acoes.where((a) => a == 'instalar'), hasLength(1));
    expect(find.textContaining('abra o app de novo'), findsOneWidget);
  });
  testWidgets('sair da tela de Atualizações não cancela o download em andamento', (tester) async {
    final espia = _ControladorQueConta(c);
    addTearDown(espia.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: cgflixDarkTheme(),
        home: UpdateScreen(controlador: espia),
      ),
    );
    await tester.pump();

    // O usuário sai da tela.
    await tester.pumpWidget(const SizedBox.shrink());

    expect(espia.cancelamentos, 0);
  });

  testWidgets('abertura e botão manual não consultam durante reprodução', (tester) async {
    reproduzindo = true;
    await tester.runAsync(c.aoAbrir);
    await mostrar(tester, const UpdateSettingsScreen());
    await acionar(tester, () => tester.tap(find.text('Verificar agora')), () => c.mensagem?.startsWith('Pare') == true);
    expect(consultas, 0);
    expect(find.textContaining('Pare a reprodução'), findsOneWidget);
  });
  testWidgets('beta persiste e código fica no cofre, nunca nas preferências exportáveis', (tester) async {
    await mostrar(tester, const UpdateSettingsScreen());
    await acionar(tester, () => tester.tap(find.textContaining('Receber versões beta')), () => c.beta);
    expect(c.beta, true);
    const codigo = 'codigo-sintetico-sem-credencial-123';
    await tester.runAsync(() => c.definirCodigo(codigo));
    await tester.pumpAndSettle();
    expect(c.codigo, codigo);
    expect(segredos.values.values, contains(codigo));
    expect(settings.prefs.getString('heisuca_update_test_code_v1'), isNull);
    expect(LogRedactionManager.redact(codigo), isNot(codigo));
    expect(find.textContaining('Canal: Teste'), findsOneWidget);
  });
  testWidgets('uma verificação ao abrir, limite diário também no botão manual', (tester) async {
    await tester.runAsync(() async {
      await c.aoAbrir();
      await c.aoAbrir();
      await c.verificar(manual: true);
    });
    expect(consultas, 1);
    await mostrar(tester, const UpdateSettingsScreen());
    expect(find.textContaining('Já verificamos hoje'), findsOneWidget);
  });
  testWidgets('salvar código zera o limite; no canal de teste o manual sempre consulta', (tester) async {
    await tester.runAsync(() async {
      await c.aoAbrir();
      await c.definirCodigo('codigo-sintetico-sem-credencial-123');
      await c.verificar(manual: true);
      await c.verificar(manual: true);
      await c.verificar();
    });
    expect(consultas, 3);
    expect(c.mensagem, isNot(contains('Já verificamos hoje')));
  });

  group('celular', () {
    Future<void> perfil(WidgetTester tester, UpdateController controlador, {double letra = 1}) async {
      TvDetectionService.debugSetTvOverride(false);
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final tema = ThemeProvider();
      addTearDown(tema.dispose);
      await tester.runAsync(controlador.iniciar);
      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeProvider>.value(value: tema),
              ChangeNotifierProvider<UpdateController>.value(value: controlador),
            ],
            child: MaterialApp(
              theme: cgflixDarkTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
                child: child!,
              ),
              home: const HeisucaProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    }

    Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
      await tester.scrollUntilVisible(alvo, 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle(); // o salto até o item só aparece no quadro seguinte
    }

    testWidgets('a tela Você tem a entrada Atualizações e ela abre a tela certa', (tester) async {
      await perfil(tester, c);
      await rolarAte(tester, find.text('Atualizações'));
      expect(find.text('Buscar versão nova e escolher o canal'), findsOneWidget);
      await tester.tap(find.text('Atualizações'));
      await tester.pumpAndSettle();
      expect(find.byType(UpdateSettingsScreen), findsOneWidget);
      expect(find.text('Verificar agora'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('com versão maior no ar, a entrada avisa antes de abrir', (tester) async {
      await tester.runAsync(() async {
        await c.iniciar();
        await c.verificar(manual: true);
      });
      expect(c.oferta, isNotNull);
      await perfil(tester, c);
      await rolarAte(tester, find.text('Atualizações'));
      expect(find.text('Versão nova disponível'), findsOneWidget);
    });

    testWidgets('na versão da loja a entrada não aparece', (tester) async {
      final loja = UpdateController(
        config: ConfiguracaoAtualizacao(feed: 'https://feed.example/', distribuicao: 'play'),
        feed: c.feed,
        instalador: c.instalador,
        settings: settings,
        segredos: segredos,
        emReproducao: () => false,
      );
      addTearDown(loja.dispose);
      await perfil(tester, loja);
      await rolarAte(tester, find.text('Sair da conta'));
      expect(find.text('Sobre o Heisuca'), findsOneWidget);
      expect(find.text('Atualizações'), findsNothing);
    });

    testWidgets('tela estreita com letra em 200%: entrada e tela de atualizações não estouram', (tester) async {
      await perfil(tester, c, letra: 2);
      await rolarAte(tester, find.text('Atualizações'));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Atualizações'));
      await tester.pumpAndSettle();
      expect(find.byType(UpdateSettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      final lista = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.text('Voltar'), 200, scrollable: lista);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
