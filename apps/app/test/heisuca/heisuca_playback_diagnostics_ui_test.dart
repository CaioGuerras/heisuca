import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_settings_screen.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/mpv/mpv.dart';
import 'package:heisuca/mpv/player/player_stream_controllers.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/dialogs.dart';
import 'package:heisuca/utils/platform_detector.dart';
import 'package:heisuca/widgets/video_controls/widgets/performance_overlay/performance_overlay.dart';
import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';

class _OverlayPlayer with PlayerStreamControllersMixin implements Player {
  @override
  late final PlayerStreams streams = createStreams();
  @override
  bool get providesNativeStats => true;
  @override
  Future<String> runtimePlayerType() async => 'mpv';
  @override
  Future<Map<String, dynamic>> getStats() async => {
    'playerType': 'mpv',
    'video-codec': 'h264',
    'hwdec-current': 'mediacodec-copy',
    'video-params/w': '1440',
    'video-params/h': '1080',
    'frame-drop-count': '2',
  };
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.pt);
  });
  setUp(() async {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetTvOverride(true);
  });
  tearDown(() => TvDetectionService.debugSetTvOverride(null));
  Future<void> dialog(
    WidgetTester tester,
    UnplayableMediaCause cause, {
    String? alternative,
    ValueChanged<UnplayableMediaAction>? onResult,
  }) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: cgflixDarkTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final action = await showUnplayableMediaDialog(
                    context,
                    formatReason: 'H.264, 8 bits, 1440×1080',
                    cause: cause,
                    alternativeResolution: alternative,
                  );
                  onResult?.call(action);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('falta de formato usa texto próprio e permite tentar sem inventar alternativa', (tester) async {
    UnplayableMediaAction? result;
    await dialog(tester, UnplayableMediaCause.unsupportedFormat, onResult: (v) => result = v);
    expect(find.text('Formato sem suporte'), findsOneWidget);
    expect(find.textContaining('O vídeo está chegando devagar'), findsNothing);
    expect(find.textContaining('Tocar versão'), findsNothing);
    await tester.tap(find.text('Tentar assim mesmo'));
    await tester.pumpAndSettle();
    expect(result, UnplayableMediaAction.tryAnyway);
  });
  testWidgets('vigia descreve entrega/aparelho lento e oferece somente alternativa existente', (tester) async {
    UnplayableMediaAction? result;
    await dialog(tester, UnplayableMediaCause.slowDeliveryOrDevice, alternative: '2', onResult: (v) => result = v);
    expect(find.text('Reprodução lenta'), findsOneWidget);
    expect(find.textContaining('O vídeo está chegando devagar ou o aparelho está lento.'), findsOneWidget);
    expect(find.text('Formato sem suporte'), findsNothing);
    await tester.tap(find.textContaining('Tocar versão'));
    await tester.pumpAndSettle();
    expect(result, UnplayableMediaAction.playVersion);
  });
  testWidgets('Ajustes da TV liga e desliga a sobreposição persistida', (tester) async {
    final fixture = HeisucaP3Fixture();
    await tester.runAsync(() => fixture.initialize(settings.ThemeMode.dark));
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(fixture.dispose);
    });
    await tester.pumpWidget(fixture.wrap(MaterialApp(theme: cgflixDarkTheme(), home: const HeisucaTvSettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Desempenho na tela'), findsOneWidget);
    await tester.tap(find.text('Desempenho na tela'));
    await tester.pumpAndSettle();
    expect(settings.SettingsService.instanceOrNull!.read(settings.SettingsService.showPerformanceOverlay), true);
    await tester.tap(find.text('Desempenho na tela'));
    await tester.pumpAndSettle();
    expect(settings.SettingsService.instanceOrNull!.read(settings.SettingsService.showPerformanceOverlay), false);
  });
  testWidgets('sobreposição da TV usa corpo legível em azul, sem reduzir para 10px', (tester) async {
    final player = _OverlayPlayer();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await player.closeStreamControllers();
    });
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: cgflixDarkTheme(),
          home: Scaffold(body: PlayerPerformanceOverlay(player: player, active: true)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final motor = find.textContaining('Motor:');
    expect(motor, findsOneWidget);
    expect(tester.widget<Text>(motor).style!.fontSize, greaterThanOrEqualTo(22));
    expect(tester.takeException(), isNull);
  });
}
