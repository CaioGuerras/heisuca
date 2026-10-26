// Bancada real: sem falsos de rede, player, sessão ou serviços do app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/main.dart' as app;
import 'package:heisuca/heisuca/heisuca_home_screen.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/heisuca/heisuca_profile_screen.dart';
import 'package:heisuca/heisuca/heisuca_title_sheet.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/profiles/profile_registry.dart';
import 'package:heisuca/screens/search_screen.dart';
import 'package:heisuca/screens/video_player_screen.dart';
import 'package:heisuca/services/jellyfin_client.dart';
import 'package:heisuca/utils/pointer_scroll_axis.dart';
import 'package:heisuca/utils/semantics_tree_gate.dart';
import 'package:heisuca/widgets/focusable_media_card.dart';
import 'package:heisuca/widgets/video_controls/mobile_video_controls.dart';

class _BancadaBinding extends IntegrationTestWidgetsFlutterBinding with PointerScrollAxisLock, SemanticsTreeGate {
  // Em debug o app abre um handle de semântica que dura a sessão (main.dart). Iniciado dentro do caso, ele
  // contaria como vazamento no fim do teste; a bancada guarda os handles abertos durante app.main() e os solta.
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

class _NativeBackProbe with WidgetsBindingObserver {
  @override
  Future<bool> didPopRoute() async {
    print('BANCADA_POP_NATIVO_RECEBIDO');
    return false; // Observa sem consumir nem alterar o caminho do app.
  }
}

void main() {
  final binding = HeisucaWidgetsBinding.ensureInitialized(createBinding: _BancadaBinding.new) as _BancadaBinding;
  late final Directory support;
  late final Map<String, dynamic> config;
  // O test_api recusa declarar casos depois de um await em main() ("Can't call test() once tests have begun
  // running", run 40235597511): o caso é declarado de forma síncrona e a leitura assíncrona fica no setUpAll.
  setUpAll(() async {
    support = await getApplicationSupportDirectory();
    config =
        jsonDecode(await File('${support.path}/heisuca-bancada-config.json').readAsString()) as Map<String, dynamic>;
  });
  testWidgets('abertura, login, acervo, vídeo nativo, abas e voltar', (tester) async {
    final server = config['server'] as String;
    final user = config['user'] as String;
    final itemId = config['item'] as String;
    final title = config['title'] as String;
    if ([server, user, itemId, title].any((value) => value.isEmpty) || user.toLowerCase().endsWith('-kids')) {
      throw StateError('Configuração privada da bancada indisponível.');
    }
    // Inicia dentro do caso: ao começar, o framework troca a árvore pela tela "Test starting..." e um app iniciado
    // antes some (run 40237449346: 90 s parado nela). O binding do runner não é recriado.
    // O app instala os próprios tratadores de erro (main.dart); o framework exige os originais de volta no fim.
    final errorWidgetBuilder = ErrorWidget.builder;
    final flutterErrorHandler = FlutterError.onError;
    addTearDown(() {
      ErrorWidget.builder = errorWidgetBuilder;
      FlutterError.onError = flutterErrorHandler;
    });
    final backProbe = _NativeBackProbe();
    binding.addObserver(backProbe);
    addTearDown(() => binding.removeObserver(backProbe));
    binding.captureAppSemantics = true;
    app.main();
    final steps = <String>[];
    binding.reportData = {'passos': steps, 'testeEncerrado': false};
    Future<void> Function()? captureTimeout;
    Future<void> until(bool Function() ready, String stage, {int seconds = 90}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (!ready()) {
        if (DateTime.now().isAfter(deadline)) {
          if (captureTimeout != null) await captureTimeout!();
          throw StateError('Tempo esgotado na etapa: $stage.');
        }
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    var sequence = 0;
    Future<void> shot(String name, {bool back = false}) async {
      await tester.pump(const Duration(milliseconds: 400));
      final seq = ++sequence;
      final pending = File('${support.path}/heisuca-bancada-event.tmp');
      await pending.writeAsString(jsonEncode({'seq': seq, 'name': name, 'back': back}), flush: true);
      await pending.rename('${support.path}/heisuca-bancada-event.json');
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      final ack = File('${support.path}/heisuca-bancada-ack.json');
      while (true) {
        if (await ack.exists()) {
          final data = jsonDecode(await ack.readAsString()) as Map<String, dynamic>;
          if (data['seq'] == seq && data['ok'] == true) break;
        }
        if (DateTime.now().isAfter(deadline)) throw StateError('Captura não confirmada: $name.');
        await tester.pump(const Duration(milliseconds: 200));
      }
      steps.add(name);
    }

    Finder field(String name) =>
        find.descendant(of: find.byKey(ValueKey('heisuca-login-$name')), matching: find.byType(TextField));
    await until(() => find.byType(HeisucaLoginScreen).evaluate().isNotEmpty, 'login');
    binding.captureAppSemantics = false;
    await tester.pump();
    // Host encerra o vídeo da abertura antes de entrar qualquer dado privado.
    await shot('01-login');
    await tester.enterText(field('server'), server);
    await tester.enterText(field('user'), user);
    await tester.enterText(field('password'), '');
    await tester.ensureVisible(find.text('Iniciar sessão'));
    await tester.tap(find.text('Iniciar sessão'));
    await until(() => find.byType(HeisucaHomeScreen).evaluate().isNotEmpty, 'Início');
    final context = tester.element(find.byType(HeisucaHomeScreen).first);
    final clients = context
        .read<MultiServerProvider>()
        .serverManager
        .navigationOnlineClients
        .values
        .whereType<JellyfinClient>();
    if (clients.length != 1) throw StateError('A bancada exige uma única fonte Jellyfin.');
    final connection = clients.single.connection;
    final directory = await getApplicationSupportDirectory();
    // Só no APK de teste, armazenamento privado; o host lê sem imprimir nem publicar.
    await File('${directory.path}/heisuca-bancada-session.json').writeAsString(
      jsonEncode({'token': connection.accessToken, 'user': connection.userId, 'device': connection.deviceId}),
      flush: true,
    );
    // Perfil local anônimo: não altera nome nem foto no servidor da pessoa.
    final profiles = context.read<ActiveProfileProvider>();
    final active = profiles.active!;
    final avatar = File('${directory.path}/heisuca-bancada-avatar.png');
    await avatar.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAGUlEQVR4nGO8I2fEQApgIkn1qIZRDUNKAwDJTwFMq+x9qAAAAABJRU5ErkJggg==',
      ),
    );
    await context.read<ProfileRegistry>().upsert(
      active.copyWith(displayName: 'Bancada Android', avatarThumbUrl: avatar.uri.toString()),
    );
    await until(
      () =>
          profiles.active?.displayName == 'Bancada Android' &&
          profiles.avatarUrlFor(active.id) == avatar.uri.toString(),
      'perfil local anônimo',
    );
    await precacheImage(FileImage(avatar), context);
    await tester.pump(const Duration(milliseconds: 500));
    await shot('02-inicio');
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search_rounded).first);
    await until(() => find.byType(SearchScreen).evaluate().isNotEmpty, 'busca');
    await tester.enterText(find.byType(TextField).first, title);
    FocusManager.instance.primaryFocus?.unfocus();
    final card = find.byWidgetPredicate(
      (w) => w is FocusableMediaCard && w.item is MediaItem && (w.item as MediaItem).id == itemId,
    );
    await until(() => card.evaluate().isNotEmpty, 'resultado da busca');
    await tester.ensureVisible(card.first);
    await shot('03-busca');
    await tester.tap(card.first);
    await until(
      () => find.byType(HeisucaTitleSheet).evaluate().isNotEmpty && find.text('Assistir').evaluate().isNotEmpty,
      'ficha',
    );
    await shot('04-ficha');
    // Sonda novamente imediatamente antes do play: não disputa uma sessão que começou depois do login.
    final http = HttpClient();
    try {
      final request = await http.getUrl(Uri.parse('${connection.baseUrl.replaceFirst(RegExp(r'/$'), '')}/Sessions'));
      request.headers.set('X-Emby-Token', connection.accessToken);
      final response = await request.close();
      if (response.statusCode != 200) throw StateError('Não foi possível conferir as sessões antes do vídeo.');
      final sessions = jsonDecode(await utf8.decoder.bind(response).join()) as List;
      if (sessions.any(
        (dynamic s) =>
            (s['UserId'] as String? ?? '').replaceAll('-', '').toLowerCase() ==
                connection.userId.replaceAll('-', '').toLowerCase() &&
            s['NowPlayingItem'] != null,
      )) {
        throw StateError('BANCADA_OCUPADA: a conta ficou ocupada antes do vídeo.');
      }
    } finally {
      http.close(force: true);
    }
    await tester.ensureVisible(find.text('Assistir').first);
    await tester.tap(find.text('Assistir').first);
    await until(() => find.byType(MobileVideoControls).evaluate().isNotEmpty, 'player nativo');
    final player = tester.widget<MobileVideoControls>(find.byType(MobileVideoControls).first).player;
    await until(
      () =>
          player.state.hasRenderedFrame && player.state.playing && player.currentPosition >= const Duration(seconds: 1),
      'primeiro quadro real',
      seconds: 120,
    );
    await shot('05-player-inicio');
    final start = player.currentPosition;
    await until(
      () => player.currentPosition >= start + const Duration(seconds: 3),
      'reprodução avançando',
      seconds: 30,
    );
    binding.reportData!['video'] = {
      'motor': await player.runtimePlayerType(),
      'quadroNativo': player.state.hasRenderedFrame,
      'segundosAvancados': (player.currentPosition - start).inMilliseconds / 1000,
    };
    // O retorno é uma tecla Back real enviada pelo adb pelo host.
    // Diagnóstico só após o perfil anônimo e o vídeo: nunca captura o login preenchido.
    captureTimeout = () async {
      final state = {
        'playerVisivel': find.byType(VideoPlayerScreen).evaluate().isNotEmpty,
        'playerNaArvore': find.byType(VideoPlayerScreen, skipOffstage: false).evaluate().isNotEmpty,
        'fichaVisivel': find.byType(HeisucaTitleSheet).evaluate().isNotEmpty,
        'fichaNaArvore': find.byType(HeisucaTitleSheet, skipOffstage: false).evaluate().isNotEmpty,
        'buscaVisivel': find.byType(SearchScreen).evaluate().isNotEmpty,
        'inicioVisivel': find.byType(HeisucaHomeScreen).evaluate().isNotEmpty,
      };
      binding.reportData!['diagnosticoRetorno'] = state;
      print('BANCADA_RETORNO: ${jsonEncode(state)}');
      await shot('12-falha-retorno');
    };
    final videoContext = tester.element(find.byType(VideoPlayerScreen).first);
    final videoRoute = ModalRoute.of(videoContext);
    final routeState = {
      'navigatorPodeVoltar': Navigator.of(videoContext).canPop(),
      'navigatorRaizPodeVoltar': Navigator.of(videoContext, rootNavigator: true).canPop(),
      'cicloFlutter': binding.lifecycleState?.name,
      'rotaAtual': videoRoute?.isCurrent,
      'rotaPrimeira': videoRoute?.isFirst,
      'disposicaoPop': videoRoute?.popDisposition.name,
    };
    binding.reportData!['rotasAntesDoBack'] = routeState;
    print('BANCADA_ROTAS_ANTES: ${jsonEncode(routeState)}');
    await shot('06-player', back: true);
    await until(
      () => find.byType(VideoPlayerScreen).evaluate().isEmpty && find.byType(HeisucaTitleSheet).evaluate().isNotEmpty,
      'voltar à ficha',
    );
    await shot('07-ficha-retorno', back: true);
    await until(() => find.byType(SearchScreen).evaluate().isNotEmpty, 'voltar à busca');
    for (var attempt = 0; attempt < 3 && find.byType(SearchScreen).evaluate().isNotEmpty; attempt++) {
      await shot('08-busca-retorno-$attempt', back: true);
      await tester.pump(const Duration(milliseconds: 500));
    }
    await until(() => find.byType(HeisucaHomeScreen).evaluate().isNotEmpty, 'voltar à Início');
    await tester.tap(find.byKey(const ValueKey('heisuca-nav-1')));
    await tester.pump(const Duration(seconds: 2));
    await shot('09-biblioteca');
    await tester.tap(find.byKey(const ValueKey('heisuca-nav-2')));
    await tester.pump(const Duration(seconds: 2));
    await shot('10-baixados');
    await tester.tap(find.byKey(const ValueKey('heisuca-nav-3')));
    await until(() => find.byType(HeisucaProfileScreen).evaluate().isNotEmpty, 'Você');
    await shot('11-voce', back: true);
    await tester.pump(const Duration(seconds: 1));
    binding.reportData!['testeEncerrado'] = true;
    await tester.pumpWidget(const SizedBox.shrink());
    binding.releaseAppSemantics();
    ErrorWidget.builder = errorWidgetBuilder;
    FlutterError.onError = flutterErrorHandler;
  }, timeout: const Timeout(Duration(minutes: 10)));
}
