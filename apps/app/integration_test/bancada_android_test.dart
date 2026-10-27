// Bancada real: sem falsos de rede, player, sessão ou serviços do app.
import 'dart:convert';
import 'dart:io';
import 'support/bancada_clock.dart';
import 'support/pip_overflow_policy.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:heisuca/services/pip_service.dart';
import 'package:heisuca/services/settings_service.dart';
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
  _BancadaBinding() { configureBancadaFrames(this); }

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
    final warnings = <Map<String, Object?>>[];
    var pipPhase = 'fora';
    binding.reportData = {'passos': steps, 'testeEncerrado': false, 'avisos': warnings, 'capturasNativas': <String, dynamic>{}};
    FlutterError.onError = (details) {
      final view = binding.platformDispatcher.views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      final warning = pipHudWarning(details, phase: pipPhase, width: size.width, height: size.height);
      if (warning != null) {
        warnings.add(warning);
        print('BANCADA_ATENCAO: ${jsonEncode(warning)}');
        return;
      }
      flutterErrorHandler?.call(details);
    };
    Future<void> Function(String)? captureTimeout;
    Future<void> until(bool Function() ready, String stage, {int seconds = 90}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (!ready()) {
        if (DateTime.now().isAfter(deadline)) {
          await captureTimeout?.call(stage);
          throw StateError('Tempo esgotado na etapa: $stage.');
        }
        await waitBancada(binding, const Duration(milliseconds: 200));
      }
      await waitBancada(binding, const Duration(milliseconds: 400));
    }

    var sequence = 0;
    Future<void> shot(String name, {bool back = false, String? action, bool decodedFrame = false}) async {
      await waitBancada(binding, const Duration(milliseconds: 400));
      final seq = ++sequence;
      final pending = File('${support.path}/heisuca-bancada-event.tmp');
      await pending.writeAsString(jsonEncode({'seq': seq, 'name': name, 'back': back, if (action != null) 'action': action,
        if (decodedFrame) 'decodedFrame': true}), flush: true);
      await pending.rename('${support.path}/heisuca-bancada-event.json');
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      final ack = File('${support.path}/heisuca-bancada-ack.json');
      while (true) {
        if (await ack.exists()) {
          final data = jsonDecode(await ack.readAsString()) as Map<String, dynamic>;
          if (data['seq'] == seq && data['ok'] == true) {
            if (name == '21-imagem-apos-audio' || name == '06-player') {
              final image = data['imagem'];
              expect(image, isA<Map>());
              expect((image as Map)['imagem'], 'sim', reason: 'A captura nativa precisa conter imagem.');
              (binding.reportData!['capturasNativas'] as Map)[name] = image;
            }
            break;
          }
        }
        if (DateTime.now().isAfter(deadline)) throw StateError('Captura não confirmada: $name.');
        await waitBancada(binding, const Duration(milliseconds: 200));
      }
      steps.add(name);
    }

    Finder field(String name) =>
        find.descendant(of: find.byKey(ValueKey('heisuca-login-$name')), matching: find.byType(TextField));
    await until(() => find.byType(HeisucaLoginScreen).evaluate().isNotEmpty, 'login');
    binding.captureAppSemantics = false;
    await waitBancada(binding, Duration.zero);
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
    await waitBancada(binding, const Duration(milliseconds: 500));
    await shot('02-inicio');
    // Captura falhas só após anonimizar o perfil; nunca captura o login preenchido.
    captureTimeout = (stage) async {
      final state = {
        'etapa': stage,
        'playerVisivel': find.byType(VideoPlayerScreen).evaluate().isNotEmpty,
        'playerNaArvore': find.byType(VideoPlayerScreen, skipOffstage: false).evaluate().isNotEmpty,
        'fichaVisivel': find.byType(HeisucaTitleSheet).evaluate().isNotEmpty,
        'fichaNaArvore': find.byType(HeisucaTitleSheet, skipOffstage: false).evaluate().isNotEmpty,
        'buscaVisivel': find.byType(SearchScreen).evaluate().isNotEmpty,
        'inicioVisivel': find.byType(HeisucaHomeScreen).evaluate().isNotEmpty,
        'pipAtivo': PipService().isPipActive.value,
        'cicloFlutter': binding.lifecycleState?.name,
        'servicoMidiaForeground': await PipService.isMediaPlaybackServiceActive(),
        if (find.byType(VideoPlayerScreen).evaluate().isNotEmpty) ...{
          'continuarOuvindo': tester.state<VideoPlayerScreenState>(find.byType(VideoPlayerScreen).first).debugContinueListeningEnabled,
          'audioForaDaTela': tester.state<VideoPlayerScreenState>(find.byType(VideoPlayerScreen).first).debugBackgroundAudioActive,
        },
      };
      binding.reportData!['diagnosticoRetorno'] = state;
      print('BANCADA_RETORNO: ${jsonEncode(state)}');
      await shot('12-falha-retorno');
    };
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
    final playControl = find.ancestor(of: find.text('Assistir'), matching: find.byType(InkWell)).hitTestable();
    await until(() {
      final controls = playControl.evaluate();
      return controls.isNotEmpty && (controls.first.widget as InkWell).onTap != null;
    }, 'botão Assistir habilitado e visível');
    await tester.tap(playControl.first);
    await until(() => find.byType(MobileVideoControls).evaluate().isNotEmpty, 'player nativo');
    final player = tester.widget<MobileVideoControls>(find.byType(MobileVideoControls).first).player;
    // Só na integração: detalhes de inicialização do VO; o APK de uso mantém seu nível de log.
    await player.setLogLevel('v');
    Future<Map<String, Object?>> videoProbe() async {
      final values = <String, Object?>{};
      for (final key in ['vid', 'pause', 'vo-configured', 'current-vo', 'hwdec-current',
        'video-params/w', 'video-params/h', 'video-dec-params/pixelformat', 'current-tracks/video/id',
        'avsync', 'decoder-frame-drop-count', 'frame-drop-count', 'video-out-params/w', 'video-out-params/h']) {
        try { values[key] = await player.getProperty(key); }
        catch (_) { values[key] = 'indisponível'; }
      }
      return values;
    }
    Future<bool> decodedFrame(Map<String, Object?> probe) async {
      final file = File('${support.path}/heisuca-bancada-video-frame.png');
      if (await file.exists()) await file.delete();
      try {
        await player.command(['screenshot-to-file', file.path, 'video']);
        final available = await file.exists();
        probe['capturaDecodificada'] = available ? 'disponível' : 'não produzida pelo motor';
        return available;
      } catch (error) {
        probe['capturaDecodificada'] = 'indisponível: ${error.runtimeType}';
        return false;
      }
    }
    await until(
      () =>
          player.state.hasRenderedFrame && player.state.playing && player.currentPosition >= const Duration(seconds: 1),
      'primeiro quadro real',
      seconds: 120,
    );
    final initialProbe = await videoProbe();
    binding.reportData!['imagemInicial'] = initialProbe;
    final initialDecoded = await decodedFrame(initialProbe);
    print('BANCADA_VIDEO_INICIAL: ${jsonEncode(initialProbe)}');
    await shot('05-player-inicio', decodedFrame: initialDecoded);
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
    // M: Home e controles usam eventos do Android. Só depois do perfil anônimo.
    final settings = SettingsService.instance;
    expect(settings.read(SettingsService.continueListening), isFalse);
    final outsideApp = <String, dynamic>{'padraoDesligado': true};
    binding.reportData!['foraDoApp'] = outsideApp;
    pipPhase = 'entrada';
    await shot('13-home-pip', action: 'home');
    await until(() => PipService().isPipActive.value, 'Home entra em PiP');
    pipPhase = 'ativo';
    var position = player.currentPosition;
    await until(() => player.currentPosition >= position + const Duration(seconds: 2), 'vídeo continua no PiP');
    outsideApp['pipPadrao'] = true;
    pipPhase = 'saída';
    await shot('14-voltar-do-pip', action: 'reopen');
    await until(() => !PipService().isPipActive.value && binding.lifecycleState == AppLifecycleState.resumed,
        'retorno do PiP');
    await until(() => binding.platformDispatcher.views.first.physicalSize.width /
      binding.platformDispatcher.views.first.devicePixelRatio > 320, 'janela expandida após PiP');
    pipPhase = 'fora';
    await settings.write(SettingsService.continueListening, true);
    final playerScreen = tester.state<VideoPlayerScreenState>(find.byType(VideoPlayerScreen));
    await until(() => playerScreen.debugContinueListeningEnabled, 'preferência de áudio aplicada');
    // O serviço inicia com a MediaSession tocando, enquanto o app ainda está visível.
    final foregroundDeadline = DateTime.now().add(const Duration(seconds: 20));
    while (!await PipService.isMediaPlaybackServiceActive()) {
      if (DateTime.now().isAfter(foregroundDeadline)) throw StateError('Serviço de mídia não iniciou.');
      await waitBancada(binding, const Duration(milliseconds: 200));
    }
    await shot('15-home-so-som', action: 'home');
    await until(() => playerScreen.debugBackgroundAudioActive && !PipService().isPipActive.value,
        'só som fora do app');
    position = player.currentPosition;
    await until(() => player.currentPosition >= position + const Duration(seconds: 3), 'áudio fora do app avança');
    expect(await player.getProperty('vid'), 'no');
    expect(await PipService.isMediaPlaybackServiceActive(), isTrue);
    outsideApp['audioComServico'] = true;
    await shot('16-pausar-na-sessao', action: 'media_pause');
    await until(() => !player.state.playing, 'pausa pela MediaSession');
    await shot('17-tocar-na-sessao', action: 'media_play');
    await until(() => player.state.playing, 'retoma pela MediaSession');
    outsideApp['controlesDaSessao'] = true;
    await shot('18-voltar-do-audio', action: 'reopen');
    await until(() => binding.lifecycleState == AppLifecycleState.resumed && !playerScreen.debugBackgroundAudioActive,
        'imagem restaurada depois do áudio');
    expect(await player.getProperty('vid'), isNot('no'));
    position = player.currentPosition;
    await until(() => player.currentPosition >= position + const Duration(seconds: 2), 'vídeo avança após restaurar a imagem');
    final restoredProbe = await videoProbe();
    binding.reportData!['imagemAposAudio'] = restoredProbe;
    final restoredDecoded = await decodedFrame(restoredProbe);
    print('BANCADA_VIDEO_APOS_AUDIO: ${jsonEncode(restoredProbe)}');
    await shot('21-imagem-apos-audio', decodedFrame: restoredDecoded);
    // Probe é diagnóstico anterior ao PNG; o ACK traz a prova da captura real.
    pipPhase = 'entrada';
    expect((await PipService.enter(width: 16, height: 9)).$1, isTrue);
    await until(() => PipService().isPipActive.value, 'PiP manual com áudio permitido');
    pipPhase = 'ativo';
    await shot('19-fechar-pip', action: 'pip_close');
    pipPhase = 'saída';
    await until(() => !PipService().isPipActive.value && playerScreen.debugBackgroundAudioActive,
        'fechar PiP mantém só o som');
    position = player.currentPosition;
    await until(() => player.currentPosition >= position + const Duration(seconds: 2), 'áudio após fechar PiP avança');
    expect(await PipService.isMediaPlaybackServiceActive(), isTrue);
    outsideApp['audioAposFecharPip'] = true;
    await shot('20-restaurar-imagem', action: 'reopen');
    await until(() => binding.lifecycleState == AppLifecycleState.resumed && !playerScreen.debugBackgroundAudioActive,
        'imagem restaurada antes do Back');
    await until(() => binding.platformDispatcher.views.first.physicalSize.width /
      binding.platformDispatcher.views.first.devicePixelRatio > 320, 'janela expandida antes do Back');
    pipPhase = 'fora';
    print('BANCADA_FORA_DO_APP: ${jsonEncode(outsideApp)}');

    // O retorno é uma tecla Back real enviada pelo adb pelo host.
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
    final beforeBackProbe = await videoProbe();
    binding.reportData!['imagemAntesDoBack'] = beforeBackProbe;
    await shot('06-player', back: true);
    // Não confundir uma amostra anterior à captura com os pixels do PNG confirmado.
    await until(
      () => find.byType(VideoPlayerScreen).evaluate().isEmpty && find.byType(HeisucaTitleSheet).evaluate().isNotEmpty,
      'voltar à ficha',
    );
    await shot('07-ficha-retorno', back: true);
    await until(() => find.byType(SearchScreen).evaluate().isNotEmpty, 'voltar à busca');
    for (var attempt = 0; attempt < 3 && find.byType(SearchScreen).evaluate().isNotEmpty; attempt++) {
      await shot('08-busca-retorno-$attempt', back: true);
      await waitBancada(binding, const Duration(milliseconds: 500));
    }
    await until(() => find.byType(HeisucaHomeScreen).evaluate().isNotEmpty, 'voltar à Início');
    await tester.tap(find.byKey(const ValueKey('heisuca-nav-1')));
    await waitBancada(binding, const Duration(seconds: 2));
    await shot('09-biblioteca');
    await tester.tap(find.byKey(const ValueKey('heisuca-nav-2')));
    await waitBancada(binding, const Duration(seconds: 2));
    await shot('10-baixados');
    await tester.tap(find.byKey(const ValueKey('heisuca-nav-3')));
    await until(() => find.byType(HeisucaProfileScreen).evaluate().isNotEmpty, 'Você');
    await shot('11-voce', back: true);
    await waitBancada(binding, const Duration(seconds: 1));
    binding.reportData!['testeEncerrado'] = true;
    await tester.pumpWidget(const SizedBox.shrink());
    binding.releaseAppSemantics();
    ErrorWidget.builder = errorWidgetBuilder;
    FlutterError.onError = flutterErrorHandler;
  }, timeout: const Timeout(Duration(minutes: 10)));
}
