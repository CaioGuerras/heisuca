import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/requests/cgflix_secure_store.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_settings_screen.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/screens/updates/update_settings_screen.dart';
import 'package:heisuca/services/playback_diagnostics.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/services/updates/apk_installer.dart';
import 'package:heisuca/services/updates/update_controller.dart';
import 'package:heisuca/services/updates/update_feed_client.dart';
import 'package:heisuca/utils/platform_detector.dart';

import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';

/// Ajustes da TV (Rosiel, Android TV, 2.0.45): na 1ª entrada as linhas ficavam coladas, a linha focada ia
/// de borda a borda e o 1º item aparecia cortado; "Atualizações" saía cortada no pé da tela.
///
/// Causa: a linha focada crescia 6 % sobre a largura inteira (passava da margem e da tela) e a borda de
/// foco engrossava de 1 para 3, o que mudava a altura da linha e empurrava as outras. Só a linha com foco
/// quebrava: ao voltar para a aba sem foco em linha nenhuma, tudo parecia normal; ao escolher uma opção,
/// o foco voltava a uma linha e quebrava de novo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const nativo = MethodChannel('app.heisuca/updates');
  // Google TV 1080p: 960×540 dp, densidade 2. Margem segura de 5 %: 48 dp nas laterais, 27 dp em cima e embaixo.
  const tela = Size(960, 540);
  final areaSegura = Rect.fromLTRB(48, 27, tela.width - 48, tela.height - 27);

  late HeisucaP3Fixture fixture;
  late UpdateController atualizacoes;
  late Directory pasta;

  setUp(() async {
    resetSharedPreferencesForTest();
    await LocaleSettings.setLocale(AppLocale.pt);
    TvDetectionService.debugSetTvOverride(true);
    fixture = HeisucaP3Fixture();
    await fixture.initialize(settings.ThemeMode.dark);
    pasta = await Directory.systemTemp.createTemp('heisuca-tv-ajustes-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(nativo, (call) async {
      return switch (call.method) {
        'estado' => {'habilitado': true, 'build': 3032, 'versao': '2.0.47', 'espacoLivre': 999999999},
        _ => null,
      };
    });
    final config = ConfiguracaoAtualizacao(feed: 'https://feed.example/');
    atualizacoes = UpdateController(
      config: config,
      feed: UpdateFeedClient(config),
      instalador: ApkInstaller(diagnosticos: PlaybackDiagnosticStore(directory: () async => pasta)),
      settings: settings.SettingsService.instanceOrNull!,
      segredos: CgflixMemorySecureStore(),
      emReproducao: () => true, // sem consulta à rede no teste
      cache: () async => pasta,
    );
  });

  tearDown(() {
    atualizacoes.dispose();
    TvDetectionService.debugSetTvOverride(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(nativo, null);
  });

  Future<void> montar(WidgetTester tester, Widget tela0, {double letra = 1}) async {
    tester.view.physicalSize = tela * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      fixture.wrap(
        ChangeNotifierProvider<UpdateController>.value(
          value: atualizacoes,
          child: MaterialApp(
            theme: cgflixDarkTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
              child: child!,
            ),
            home: tela0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  }

  const itens = [
    'Perfil',
    'Tema',
    'Áudio padrão',
    'Legenda padrão',
    'Tamanho da legenda',
    'Ainda está aí?',
    'Desempenho na tela',
    'Atualizações',
    'Sobre',
    'Sair',
  ];

  /// Retângulo desenhado (com a escala do foco) dos itens que estão na tela.
  Map<String, Rect> visiveis(WidgetTester tester) => {
    for (final nome in itens)
      if (find.text(nome).evaluate().isNotEmpty) nome: tester.getRect(find.byKey(ValueKey('tv-ajuste-$nome'))),
  };

  String? nomeComFoco() {
    final contexto = FocusManager.instance.primaryFocus?.context;
    if (contexto == null) return null;
    for (final nome in itens) {
      if (find.descendant(of: find.byWidget(contexto.widget), matching: find.text(nome)).evaluate().isNotEmpty) {
        return nome;
      }
    }
    return null;
  }

  void dentroDaAreaSegura(WidgetTester tester, String quando) {
    final lista = tester.getRect(find.byType(Scrollable).first);
    for (final MapEntry(key: nome, value: linha) in visiveis(tester).entries) {
      // Linha cortada pela borda da lista (o pé de uma linha que ainda vai entrar) não conta; a com foco, sim.
      final inteira = lista.contains(linha.topLeft) && lista.contains(linha.bottomRight - const Offset(0.01, 0.01));
      if (!inteira && nomeComFoco() != nome) continue;
      expect(linha.left, greaterThanOrEqualTo(areaSegura.left), reason: '$quando: "$nome" encosta na esquerda $linha');
      expect(linha.right, lessThanOrEqualTo(areaSegura.right), reason: '$quando: "$nome" encosta na direita $linha');
      expect(inteira, isTrue, reason: '$quando: "$nome" com foco aparece cortado ($linha, lista $lista)');
      expect(linha.top, greaterThanOrEqualTo(areaSegura.top), reason: '$quando: "$nome" acima da margem $linha');
      expect(linha.bottom, lessThanOrEqualTo(areaSegura.bottom), reason: '$quando: "$nome" abaixo da margem $linha');
    }
  }

  testWidgets('Ajustes da TV: o foco não muda o espaçamento nem leva linha para fora da margem segura', (tester) async {
    await montar(tester, const HeisucaTvSettingsScreen());

    // 1ª entrada: o foco já está no 1º item, e ele cabe inteiro.
    expect(nomeComFoco(), 'Perfil');
    dentroDaAreaSegura(tester, '1ª entrada');

    // A distância entre duas linhas sem foco não depende de onde está o foco (Tema e Legenda padrão
    // cercam Áudio padrão): antes, a borda de foco mais grossa empurrava as linhas de baixo.
    double vao() => tester.getRect(find.text('Legenda padrão')).top - tester.getRect(find.text('Tema')).top;
    final vaoComFocoNoPerfil = vao();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(nomeComFoco(), 'Áudio padrão');
    expect(vao(), vaoComFocoNoPerfil, reason: 'a linha com foco mudou o espaçamento das outras');
    dentroDaAreaSegura(tester, 'foco em Áudio padrão');

    // Escolher uma opção (Áudio padrão) não muda nada no desenho.
    final antes = visiveis(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(visiveis(tester), antes, reason: 'escolher uma opção mexeu no espaçamento');

    // Descendo até o fim, cada item com foco aparece inteiro, dentro da margem segura (Atualizações inclusive).
    final vistos = <String>{};
    for (var i = 0; i < itens.length; i++) {
      final nome = nomeComFoco();
      if (nome != null) vistos.add(nome);
      dentroDaAreaSegura(tester, 'foco em $nome');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(vistos, containsAll(['Atualizações', 'Sobre', 'Sair']));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ajustes da TV com letra em 200%: nenhum texto cortado e nada fora da margem segura', (tester) async {
    await montar(tester, const HeisucaTvSettingsScreen(), letra: 2);
    expect(tester.takeException(), isNull, reason: 'estouro de layout');
    for (var i = 0; i < itens.length; i++) {
      final nome = nomeComFoco()!;
      dentroDaAreaSegura(tester, '200 %, foco em $nome');
      final linha = tester.getRect(find.byKey(ValueKey('tv-ajuste-$nome')));
      for (final texto in tester.widgetList<Text>(
        find.descendant(of: find.byKey(ValueKey('tv-ajuste-$nome')), matching: find.byType(Text)),
      )) {
        final caixa = tester.getRect(find.byWidget(texto));
        expect(
          linha.contains(caixa.topLeft) && linha.contains(caixa.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
          reason: '"${texto.data}" sai da linha "$nome"',
        );
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Atualizações na TV: título, botões e lista dentro da margem segura, numa coluna central', (
    tester,
  ) async {
    await tester.runAsync(atualizacoes.iniciar);
    await montar(tester, UpdateSettingsScreen(controlador: atualizacoes));
    final titulo = tester.getRect(find.text('Atualizações'));
    expect(areaSegura.contains(titulo.topLeft), isTrue, reason: 'título fora da margem segura: $titulo');
    final lista = tester.getRect(find.byType(Scrollable).first);
    expect(lista.left, greaterThanOrEqualTo(areaSegura.left), reason: 'lista encosta na esquerda: $lista');
    expect(lista.right, lessThanOrEqualTo(areaSegura.right), reason: 'lista encosta na direita: $lista');
    expect(lista.bottom, lessThanOrEqualTo(areaSegura.bottom), reason: 'lista passa da margem de baixo: $lista');
    expect(lista.width, lessThanOrEqualTo(900), reason: 'coluna larga demais para a TV: $lista');

    // Descendo pelo controle remoto até o Voltar, cada botão com foco aparece inteiro.
    for (var i = 0; i < 4; i++) {
      final foco = FocusManager.instance.primaryFocus!.context!.findRenderObject()! as RenderBox;
      final caixa = foco.localToGlobal(Offset.zero) & foco.size;
      expect(
        lista.contains(caixa.topLeft) && lista.contains(caixa.bottomRight - const Offset(0.01, 0.01)),
        isTrue,
        reason: 'item com foco cortado: $caixa (lista $lista)',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
