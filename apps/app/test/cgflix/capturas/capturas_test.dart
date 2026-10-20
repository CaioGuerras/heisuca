// Capturas do refino 2 (item F): telas reais do app, com a fonte Inter e os Material Symbols
// Rounded de verdade, nos dois temas (Isis e Heitor), num celular de 412 × 914 dp.
//
// Só roda quando pedido (não pesa no `flutter test` comum):
//   CGFLIX_CAPTURAS=docs/prints/refino2/depois flutter test test/cgflix/capturas/capturas_test.dart
// O "antes" do menu do título usa a ordem do Plezy (sem `cgflixArrangeTitleMenu`).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/cgflix/cgflix_config_itens.dart';
import 'package:plezy/cgflix/cgflix_dicas.dart';
import 'package:plezy/cgflix/cgflix_menus.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/cgflix/cgflix_user_menu.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/playback_settings_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/app_menu.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/cgflix/you/cgflix_favorites_screen.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';

final _destino = Platform.environment['CGFLIX_CAPTURAS'];
const _celular = Size(412, 914);
const _deitado = Size(914, 412);

Future<void> _carregarFontes() async {
  Future<void> carregar(String familia, List<String> arquivos) async {
    final loader = FontLoader(familia);
    for (final arquivo in arquivos) {
      loader.addFont(Future.value(ByteData.sublistView(File(arquivo).readAsBytesSync())));
    }
    await loader.load();
  }

  await carregar('Inter', [
    for (final peso in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/Inter-$peso.ttf',
  ]);
  // Os ícones vêm do pacote material_symbols_icons (mesmo arquivo do app).
  final pacote = File('.dart_tool/package_config.json').readAsStringSync();
  final raiz = RegExp(r'"rootUri":\s*"([^"]*material_symbols_icons[^"]*)"').firstMatch(pacote)!.group(1)!;
  final dir = Uri.parse(raiz).isAbsolute ? Uri.parse(raiz).toFilePath() : '.dart_tool/$raiz';
  await carregar('packages/material_symbols_icons/MaterialSymbolsRounded', [
    '$dir/lib/fonts/MaterialSymbolsRounded.ttf',
  ]);
}

Future<void> _salvar(WidgetTester tester, String nome) async {
  final destino = _destino!;
  await tester.runAsync(() async {
    final image = await captureImage(tester.element(find.byKey(const ValueKey('cgflix-captura'))));
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final arquivo = File('$destino/$nome.png')..createSync(recursive: true);
    arquivo.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<ThemeProvider> _montar(
  WidgetTester tester,
  CgflixThemeVariant? variante,
  Widget home, {
  Size tela = _celular,
  List<SingleChildWidget> providers = const [],
}) async {
  tester.view.physicalSize = tela * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final theme = ThemeProvider();
  addTearDown(theme.dispose);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('cgflix-captura'),
      child: TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ...providers,
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            // Player: sempre escuro (Isis), como no app.
            theme: cgflixAppTheme(variante ?? CgflixThemeVariant.isis).copyWith(platform: TargetPlatform.android),
            home: home,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  return theme;
}

/// Menu do título de um filme no Continuar assistindo (quem não administra o servidor).
List<AppMenuItem<String>> _menuDoTitulo() => [
  AppMenuItem(value: 'play_from_beginning', icon: Symbols.replay_rounded, label: t.mediaMenu.playFromBeginning),
  AppMenuItem(value: 'play_trailer', icon: Symbols.theaters_rounded, label: t.tooltips.playTrailer),
  AppMenuItem(value: 'watch', icon: Symbols.check_circle_outline_rounded, label: t.mediaMenu.markAsWatched),
  AppMenuItem(
    value: 'remove_from_continue_watching',
    icon: Symbols.close_rounded,
    label: t.mediaMenu.removeFromContinueWatching,
  ),
  AppMenuItem(value: 'details', icon: Symbols.info_rounded, label: t.mediaMenu.viewDetails),
  AppMenuItem(value: 'rate', icon: Symbols.star_rounded, label: t.mediaMenu.rate),
  AppMenuItem(value: 'fileinfo', icon: Symbols.description_rounded, label: t.mediaMenu.fileInfo),
  AppMenuItem(value: 'download', icon: Symbols.download_rounded, label: t.downloads.downloadNow),
  AppMenuItem(value: 'toggle_watchlist', icon: Symbols.bookmark_add_rounded, label: t.explore.addToWatchlist),
];

class _Player implements Player {
  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state => const PlayerState(
    playing: true,
    position: Duration(minutes: 12, seconds: 31),
    duration: Duration(minutes: 47),
    seekable: true,
    tracks: Tracks(
      audio: [AudioTrack(id: '1', title: 'Português', language: 'por')],
      subtitle: [SubtitleTrack(id: '2', title: 'Português', language: 'por')],
    ),
    track: TrackSelection(
      audio: AudioTrack(id: '1', title: 'Português', language: 'por'),
      subtitle: SubtitleTrack(id: '2', title: 'Português', language: 'por'),
    ),
  );

  @override
  PlayerStreams get streams => const PlayerStreams(
    playheadJump: Stream<Duration?>.empty(),
    playing: Stream<bool>.empty(),
    completed: Stream<bool>.empty(),
    buffering: Stream<bool>.empty(),
    position: Stream<Duration>.empty(),
    duration: Stream<Duration>.empty(),
    seekable: Stream<bool>.empty(),
    buffer: Stream<Duration>.empty(),
    volume: Stream<double>.empty(),
    rate: Stream<double>.empty(),
    tracks: Stream<Tracks>.empty(),
    track: Stream<TrackSelection>.empty(),
    log: Stream<PlayerLog>.empty(),
    error: Stream<PlayerError>.empty(),
    audioDevice: Stream<AudioDevice>.empty(),
    audioDevices: Stream<List<AudioDevice>>.empty(),
    bufferRanges: Stream<List<BufferRange>>.empty(),
    playbackRestart: Stream<void>.empty(),
    backendSwitched: Stream<void>.empty(),
  );

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {}

  @override
  Future<bool> isHdrOutputSupported() async => false;

  @override
  bool get supportsSecondarySubtitles => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final pular = _destino == null ? 'defina CGFLIX_CAPTURAS=<pasta> para gerar as capturas' : null;

  setUpAll(() async {
    if (_destino == null) return;
    await _carregarFontes();
    await initializeDateFormatting('pt');
    await LocaleSettings.setLocale(AppLocale.pt); // carrega o português (biblioteca adiada)
    cgflixSettingsDebugInline = false;
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    if (_destino != null) LocaleSettings.setLocaleSync(AppLocale.pt);
    cgflixUserMenuDebugOnline = true;
    CgflixFavoritesSource.debugOverride = CgflixFavoritesSource(load: () async => const []);
  });

  tearDown(() {
    cgflixUserMenuDebugOnline = null;
    CgflixFavoritesSource.debugOverride = null;
  });

  for (final variante in CgflixThemeVariant.values) {
    final tema = variante.name;

    testWidgets('$tema: menu do usuário', skip: pular != null, (tester) async {
      await _montar(
        tester,
        variante,
        Builder(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black54,
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: context.cgflix.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: const Padding(padding: EdgeInsets.only(top: 24), child: CgflixUserMenuSheet()),
              ),
            ),
          ),
        ),
      );
      await _salvar(tester, '$tema-01-menu-usuario');
    });

    testWidgets('$tema: Reprodução (Configurações › Ao assistir)', skip: pular != null, (tester) async {
      await _montar(tester, variante, const PlaybackSettingsScreen());
      await _salvar(tester, '$tema-02-reproducao');
    });

    testWidgets('$tema: menu do título (antes × depois)', skip: pular != null, (tester) async {
      for (final (nome, entradas) in [
        ('antes', <AppMenuEntry<String>>[..._menuDoTitulo()]),
        ('depois', cgflixArrangeTitleMenu(_menuDoTitulo())),
      ]) {
        await _montar(
          tester,
          variante,
          Builder(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black54,
              body: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: context.cgflix.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AppMenuSheet<String>(title: 'Ainda Estou Aqui', entries: entradas),
                ),
              ),
            ),
          ),
        );
        await _salvar(tester, '$tema-03-menu-titulo-$nome');
      }
    });

    testWidgets('$tema: Dicas do CGFLIX e folha de uma dica', skip: pular != null, (tester) async {
      await _montar(tester, variante, const CgflixDicasScreen());
      await _salvar(tester, '$tema-04-dicas');
      await tester.tap(find.text(CgflixDica.pularAbertura.titulo));
      await tester.pumpAndSettle();
      await _salvar(tester, '$tema-05-dica-pular-abertura');
    });
  }

  group('player (sempre escuro)', () {
    late PlayerChromeController chrome;
    late PlayerToastController toast;
    late VideoVolumeController volume;
    late PlaybackStateProvider playbackState;
    late WatchTogetherProvider watchTogether;
    late AppDatabase database;
    final player = _Player();
    final primeiroQuadro = ValueNotifier<bool>(true);

    setUp(() async {
      TvDetectionService.debugSetAppleTVOverride(false);
      PlatformDetector.debugSetIsDesktopOSOverride(false);
      database = AppDatabase.forTesting(NativeDatabase.memory());
      chrome = PlayerChromeController();
      toast = PlayerToastController();
      volume = VideoVolumeController(player: player, settings: SettingsService.instance, initialVolume: 100);
      playbackState = PlaybackStateProvider();
      watchTogether = WatchTogetherProvider();
    });

    tearDown(() async {
      TvDetectionService.debugSetAppleTVOverride(null);
      PlatformDetector.debugSetIsDesktopOSOverride(null);
      volume.dispose();
      playbackState.dispose();
      watchTogether.dispose();
      chrome.dispose();
      toast.dispose();
      await database.close();
    });

    Future<void> montarPlayer(WidgetTester tester) => _montar(
      tester,
      null,
      Scaffold(
        backgroundColor: const Color(0xFF1B2A3A),
        body: OverlaySheetHost(
          child: PlexVideoControls(
            player: player,
            hasFirstFrame: primeiroQuadro,
            volumeController: volume,
            metadata: testMediaItem(id: 'cgflix-captura', title: 'Cidade Invisível'),
            toastController: toast,
            chromeController: chrome,
            canNavigateMediaItems: false,
          ),
        ),
      ),
      tela: _deitado,
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
        ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
      ],
    );

    testWidgets('dica única e controles', skip: pular != null, (tester) async {
      await montarPlayer(tester);
      await _salvar(tester, 'player-01-dica-unica');

      await tester.tap(find.byKey(const ValueKey('cgflix-dica-player')));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _salvar(tester, 'player-02-controles');

      await tester.tap(find.byTooltip(t.videoControls.settingsButton).first);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _salvar(tester, 'player-03-ajustes-do-video');
    });

    testWidgets('áudio e legendas', skip: pular != null, (tester) async {
      await SettingsService.instance.write(cgflixDicaPlayerVistaPref, true);
      await montarPlayer(tester);
      chrome.show();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byTooltip(t.videoControls.tracksButton).first);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _salvar(tester, 'player-04-audio-e-legendas');
    });
  });
}
