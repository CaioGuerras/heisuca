// Vitrine da loja: capturas para a ficha da Google Play com o servidor PÚBLICO de demonstração do Jellyfin.
// Sem segredos, sem conta nossa, sem nome de pessoa. As imagens são tiradas pelo host (adb screencap),
// como na Bancada, para incluir o quadro nativo do vídeo; o teste só pede e espera a confirmação.
//
// Protocolo (arquivos no diretório privado do app, lidos por scripts/vitrine_loja.py via run-as):
//   files/heisuca-vitrine-event.json  {seq, nome?, voltar?}  ->  files/heisuca-vitrine-ack.json {seq, ok}
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/barra_flutuante.dart';
import 'package:heisuca/design/componentes/botao.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/design/componentes/pilula_de_perfil.dart';
import 'package:heisuca/features/busca/ligacao.dart';
import 'package:heisuca/features/explorar/ligacao.dart';
import 'package:heisuca/features/inicio/ligacao.dart';
import 'package:heisuca/features/titulo/ligacao.dart';
import 'package:heisuca/features/voce/ligacao.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/heisuca/heisuca_settings_screen.dart';
import 'package:heisuca/main.dart' as app;
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/profiles/profile_registry.dart';
import 'package:heisuca/screens/video_player_screen.dart';
import 'package:heisuca/utils/pointer_scroll_axis.dart';
import 'package:heisuca/utils/semantics_tree_gate.dart';
import 'package:heisuca/widgets/video_controls/mobile_video_controls.dart';
import 'package:heisuca/widgets/video_controls/video_controls.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'support/bancada_clock.dart';

/// Credenciais públicas da documentação do Jellyfin (https://demo.jellyfin.org): usuário "demo", senha vazia.
const _servidorDemo = 'https://demo.jellyfin.org/stable';
const _usuarioDemo = 'demo';

/// Títulos de domínio aberto/Creative Commons do acervo de demonstração, em ordem de preferência.
const _buscas = ['Caminandes', 'Night of the Living Dead', 'Big Buck Bunny', 'Sintel', 'Pioneer One', 'Dracula'];

class _VitrineBinding extends IntegrationTestWidgetsFlutterBinding with PointerScrollAxisLock, SemanticsTreeGate {
  _VitrineBinding() {
    configureBancadaFrames(this);
  }

  // Mesmo cuidado da Bancada: o app abre em debug um handle de semântica que dura a sessão.
  bool captureAppSemantics = false;
  final List<SemanticsHandle> appSemanticsHandles = [];

  @override
  SemanticsHandle ensureSemantics() {
    final handle = super.ensureSemantics();
    if (captureAppSemantics) appSemanticsHandles.add(handle);
    return handle;
  }

  void releaseAppSemantics() {
    for (final handle in appSemanticsHandles) {
      handle.dispose();
    }
    appSemanticsHandles.clear();
  }
}

void main() {
  final binding = HeisucaWidgetsBinding.ensureInitialized(createBinding: _VitrineBinding.new) as _VitrineBinding;

  testWidgets('vitrine da loja com o servidor de demonstração', (tester) async {
    // Sem faixa de debug em nenhuma tela (o app já desliga; isto cobre rotas que não passem pelo MaterialApp dele).
    WidgetsApp.debugAllowBannerOverride = false;
    final errorWidgetBuilder = ErrorWidget.builder;
    final flutterErrorHandler = FlutterError.onError;
    addTearDown(() {
      ErrorWidget.builder = errorWidgetBuilder;
      FlutterError.onError = flutterErrorHandler;
    });
    final support = await getApplicationSupportDirectory();
    final passos = <String>[];
    binding.reportData = {'passos': passos, 'testeEncerrado': false};
    binding.captureAppSemantics = true;
    app.main();

    Future<void> espera(Duration d) => waitBancada(binding, d);

    Future<void> ate(bool Function() pronto, String etapa, {int segundos = 90}) async {
      final limite = DateTime.now().add(Duration(seconds: segundos));
      while (!pronto()) {
        if (DateTime.now().isAfter(limite)) throw StateError('Tempo esgotado na etapa: $etapa.');
        await espera(const Duration(milliseconds: 250));
      }
      await espera(const Duration(milliseconds: 400));
    }

    var seq = 0;
    // Pede ao host uma captura (nome) e/ou o botão Voltar do sistema (voltar) e espera a confirmação.
    Future<void> host({String? nome, bool voltar = false}) async {
      await espera(const Duration(milliseconds: 600));
      final atual = ++seq;
      final tmp = File('${support.path}/heisuca-vitrine-event.tmp');
      await tmp.writeAsString(jsonEncode({'seq': atual, 'nome': ?nome, if (voltar) 'voltar': true}), flush: true);
      await tmp.rename('${support.path}/heisuca-vitrine-event.json');
      final ack = File('${support.path}/heisuca-vitrine-ack.json');
      final limite = DateTime.now().add(const Duration(seconds: 60));
      while (true) {
        if (await ack.exists()) {
          try {
            final dados = jsonDecode(await ack.readAsString()) as Map<String, dynamic>;
            if (dados['seq'] == atual && dados['ok'] == true) break;
          } on FormatException {
            // Arquivo em escrita: lê de novo.
          }
        }
        if (DateTime.now().isAfter(limite)) throw StateError('Host não confirmou: ${nome ?? 'voltar'}.');
        await espera(const Duration(milliseconds: 200));
      }
      if (nome != null) passos.add(nome);
      if (voltar) await espera(const Duration(milliseconds: 900));
    }

    Future<void> captura(String nome) => host(nome: nome);

    Future<void> voltarAte(bool Function() pronto, String etapa) async {
      for (var i = 0; i < 5 && !pronto(); i++) {
        await host(voltar: true);
      }
      await ate(pronto, etapa, segundos: 20);
    }

    // Arte carregada = RawImage com ui.Image decodificada dentro da tela.
    int artes(Finder tela) => find
        .descendant(of: tela, matching: find.byWidgetPredicate((w) => w is RawImage && w.image != null))
        .evaluate()
        .length;

    Future<void> esperaArte(Finder tela, String etapa, {int minimo = 1, int segundos = 60}) async {
      final limite = DateTime.now().add(Duration(seconds: segundos));
      while (artes(tela) < minimo && DateTime.now().isBefore(limite)) {
        await espera(const Duration(milliseconds: 500));
      }
      // Sem arte suficiente a captura sai mesmo assim (melhor que nada); o log avisa.
      // ignore: avoid_print
      if (artes(tela) < minimo) print('VITRINE_AVISO: pouca arte em $etapa (${artes(tela)}/$minimo).');
      await espera(const Duration(seconds: 2)); // fade-in dos pôsteres
    }

    // ---- 08: folha "Adicionar Fontes e Servidores" (antes do login, nada digitado) ----
    await ate(() => find.byType(HeisucaLoginScreen).evaluate().isNotEmpty, 'login');
    binding.captureAppSemantics = false;
    await espera(const Duration(seconds: 2));
    final outros = find.text('Outros servidores e pastas locais');
    await ate(() => outros.evaluate().isNotEmpty, 'botão de outras fontes');
    await tester.ensureVisible(outros);
    await espera(const Duration(milliseconds: 300));
    await tester.tap(outros.hitTestable().first);
    final tituloFolha = find.text('Adicionar Fontes e Servidores');
    await ate(() => tituloFolha.evaluate().isNotEmpty && find.text('Servidor Emby').evaluate().isNotEmpty, 'folha');
    await espera(const Duration(seconds: 1));
    await captura('08-fontes');
    Navigator.of(tester.element(tituloFolha)).pop();
    await ate(() => tituloFolha.evaluate().isEmpty, 'fechar folha');

    // ---- login no servidor de demonstração ----
    Finder campo(String nome) =>
        find.descendant(of: find.byKey(ValueKey('heisuca-login-$nome')), matching: find.byType(TextField));
    await tester.enterText(campo('server'), _servidorDemo);
    await tester.enterText(campo('user'), _usuarioDemo);
    await tester.enterText(campo('password'), '');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.ensureVisible(find.text('Iniciar sessão'));
    await tester.tap(find.text('Iniciar sessão'));
    await ate(() => find.byType(LigacaoDoInicio).evaluate().isNotEmpty, 'Início', segundos: 120);

    // Perfil local com o nome do servidor de demonstração (só no aparelho; não altera o servidor).
    final contexto = tester.element(find.byType(LigacaoDoInicio).first);
    final perfis = contexto.read<ActiveProfileProvider>();
    final ativo = perfis.active;
    if (ativo != null && ativo.displayName != _usuarioDemo) {
      await contexto.read<ProfileRegistry>().upsert(ativo.copyWith(displayName: _usuarioDemo));
      await ate(() => perfis.active?.displayName == _usuarioDemo, 'perfil demo', segundos: 20);
    }

    // ---- 01: Início com pôsteres ----
    final inicio = find.byType(LigacaoDoInicio);
    await ate(() => find.descendant(of: inicio, matching: find.byType(Cartao)).evaluate().length >= 3, 'cartões');
    await esperaArte(inicio, 'Início', minimo: 6, segundos: 90);
    await captura('01-inicio');

    // ---- 04: Explorar com filtros ----
    Finder destino(String rotulo) => find.descendant(of: find.byType(BarraFlutuante), matching: find.text(rotulo));
    await tester.tap(destino('Explorar').first);
    await ate(() => find.byType(LigacaoDoExplorar).evaluate().isNotEmpty, 'Explorar');
    await ate(
      () => find.text('Ordem e filtros').evaluate().isNotEmpty || find.byType(Cartao).evaluate().isNotEmpty,
      'filtros do Explorar',
      segundos: 60,
    );
    await esperaArte(find.byType(LigacaoDoExplorar), 'Explorar', minimo: 3);
    await captura('04-explorar');

    // ---- 06: Você ----
    await ate(() => find.byType(PilulaDePerfil).hitTestable().evaluate().isNotEmpty, 'pílula do perfil');
    await tester.tap(find.byType(PilulaDePerfil).hitTestable().first);
    await ate(() => find.byType(LigacaoDaVoce).evaluate().isNotEmpty, 'Você');
    await espera(const Duration(seconds: 1));
    await captura('06-voce');

    // ---- 05: Configurações > Aparência e Tema ----
    final config = find.descendant(of: find.byType(LigacaoDaVoce), matching: find.text('Configurações'));
    await tester.ensureVisible(config.first);
    await espera(const Duration(milliseconds: 300));
    await tester.tap(config.hitTestable().first);
    await ate(
      () =>
          find.byType(HeisucaSettingsScreen).evaluate().isNotEmpty &&
          find.text('Aparência e Tema').evaluate().isNotEmpty,
      'Configurações',
    );
    // A loja não deve mostrar o nome técnico do aparelho de teste: rola até o título da seção.
    await Scrollable.ensureVisible(tester.element(find.text('Aparência e Tema').first), alignment: 0.0);
    await espera(const Duration(seconds: 1));
    await captura('05-aparencia');

    // Volta às abas pelo Voltar do sistema (como uma pessoa) e vai à Início.
    await voltarAte(
      () => find.byType(HeisucaSettingsScreen).evaluate().isEmpty && find.byType(LigacaoDaVoce).evaluate().isEmpty,
      'voltar às abas',
    );
    await ate(() => destino('Início').hitTestable().evaluate().isNotEmpty, 'barra com Início');
    await tester.tap(destino('Início').hitTestable().first);
    await ate(() => find.byType(LigacaoDoInicio).hitTestable().evaluate().isNotEmpty, 'Início de novo');

    // ---- 03: busca com resultados ----
    final buscar = find.byTooltip('Buscar').hitTestable();
    await ate(() => buscar.evaluate().isNotEmpty, 'botão Buscar');
    await tester.tap(buscar.first);
    await ate(() => find.byType(LigacaoDaBusca).evaluate().isNotEmpty, 'busca');
    final busca = find.byType(LigacaoDaBusca);
    Finder resultados(String termo) => find.descendant(
      of: busca,
      matching: find.byWidgetPredicate((w) => w is Cartao && w.titulo.toLowerCase().contains(termo.toLowerCase())),
    );
    String? termo;
    // O servidor de demonstração às vezes demora a responder (tempo esgotado na conexão):
    // repete a lista de termos algumas vezes antes de desistir.
    for (var rodada = 0; rodada < 3 && termo == null; rodada++) {
      for (final candidato in _buscas) {
        await tester.enterText(find.descendant(of: busca, matching: find.byType(TextField)).first, candidato);
        FocusManager.instance.primaryFocus?.unfocus();
        final limite = DateTime.now().add(const Duration(seconds: 25));
        while (resultados(candidato).evaluate().isEmpty && DateTime.now().isBefore(limite)) {
          await espera(const Duration(milliseconds: 400));
        }
        if (resultados(candidato).evaluate().isNotEmpty) {
          termo = candidato;
          break;
        }
      }
    }
    if (termo == null) throw StateError('Nenhum título do acervo de demonstração apareceu na busca.');
    await esperaArte(busca, 'busca', minimo: 1);
    await captura('03-busca');

    // ---- 02: ficha do filme ----
    final cartoes = resultados(termo).evaluate().map((e) => e.widget as Cartao).toList();
    final preferido = cartoes.firstWhere((c) => c.titulo.contains('Llama Drama'), orElse: () => cartoes.first);
    final alvo = find.descendant(of: busca, matching: find.byWidget(preferido));
    await tester.ensureVisible(alvo);
    await espera(const Duration(milliseconds: 300));
    await tester.tap(alvo.hitTestable().first);
    final assistir = find.byWidgetPredicate(
      (w) => w is Botao && (w.rotulo == 'Assistir' || w.rotulo.startsWith('Continuar')),
    );
    await ate(() => find.byType(LigacaoDoTitulo).evaluate().isNotEmpty && assistir.evaluate().isNotEmpty, 'ficha');
    await esperaArte(find.byType(LigacaoDoTitulo), 'ficha', minimo: 1);
    await captura('02-ficha');

    // ---- 07: player em paisagem com controles ----
    await ate(
      () => assistir.evaluate().isNotEmpty && (assistir.evaluate().first.widget as Botao).aoTocar != null,
      'Assistir habilitado',
    );
    final tocar = assistir.hitTestable();
    final limiteTocar = DateTime.now().add(const Duration(seconds: 30));
    while (tocar.evaluate().isEmpty) {
      await Scrollable.ensureVisible(tester.element(assistir.first), alignment: 0.5);
      await espera(const Duration(milliseconds: 250));
      if (DateTime.now().isAfter(limiteTocar)) throw StateError('Botão Assistir não ficou visível.');
    }
    await tester.tap(tocar.first);
    await ate(() => find.byType(MobileVideoControls).evaluate().isNotEmpty, 'player', segundos: 60);
    final player = tester.widget<MobileVideoControls>(find.byType(MobileVideoControls).first).player;
    await ate(
      () =>
          player.state.hasRenderedFrame && player.state.playing && player.currentPosition >= const Duration(seconds: 1),
      'primeiro quadro',
      segundos: 120,
    );
    final ui.FlutterView vista = binding.platformDispatcher.views.first;
    await ate(() => vista.physicalSize.width > vista.physicalSize.height, 'paisagem', segundos: 20);
    // Deixa o filme andar até uma cena com imagem (Caminandes abre com letreiro).
    final inicioVideo = player.currentPosition;
    await ate(() => player.currentPosition >= inicioVideo + const Duration(seconds: 12), 'cena', segundos: 60);
    final chrome = tester.widget<PlexVideoControls>(find.byType(PlexVideoControls)).chromeController;
    chrome.show(restartAutoHide: false);
    await ate(() => chrome.controlsPresented, 'controles visíveis', segundos: 15);
    await espera(const Duration(seconds: 1));
    if (!chrome.controlsPresented) chrome.show(restartAutoHide: false);
    await captura('07-player');
    await player.pause();

    binding.reportData!['testeEncerrado'] = true;
    // Encerra a árvore aqui: o player solta o mpv e a sessão no servidor de demonstração.
    expect(find.byType(VideoPlayerScreen), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await espera(const Duration(seconds: 1));
    binding.releaseAppSemantics();
    ErrorWidget.builder = errorWidgetBuilder;
    FlutterError.onError = flutterErrorHandler;
  }, timeout: const Timeout(Duration(minutes: 12)));
}
