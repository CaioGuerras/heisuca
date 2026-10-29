import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/player/heisuca_player_hud.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/widgets/overlay_sheet.dart';
import 'package:heisuca/widgets/video_controls/mobile_video_controls.dart';
import 'package:heisuca/widgets/video_controls/widgets/timeline_slider.dart';
import 'package:heisuca/widgets/video_controls/models/track_controls_state.dart';
import 'package:heisuca/watch_together/providers/watch_together_provider.dart';
import '../test_helpers/player_hud_fixture.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../visual/heisuca_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({List<String> calls, List<double> rates})> pumpHud(
    WidgetTester tester, {
    bool snapshot = false,
    EdgeInsets gestures = EdgeInsets.zero,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    // O idioma é biblioteca adiada: carrega fora do relógio falso do teste.
    await tester.runAsync(() async { await LocaleSettings.setLocale(AppLocale.pt); await initializeDateFormatting('pt'); });
    // Edge 60 Pro em paisagem: 2712×1220 px ≈ 986×444 dp.
    tester.view.physicalSize = const Size(986 * 2, 444 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final player = HeisucaHudPlayer();
    final watch = WatchTogetherProvider();
    addTearDown(player.dispose);
    addTearDown(watch.dispose);
    final calls = <String>[];
    final rates = <double>[];
    final state = TrackControlsState(
      boxFitMode: 0,
      subtitlesVisible: true,
      onCycleBoxFitMode: () => calls.add('proporção'),
      onTogglePIPMode: () => calls.add('janelinha'),
      onToggleRotationLock: () => calls.add('rotação'),
      onToggleScreenLock: () => calls.add('travar'),
      onRateRequested: (r) async => rates.add(r),
    );
    await tester.pumpWidget(ChangeNotifierProvider.value(value: watch, child: MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          systemGestureInsets: gestures,
          viewPadding: viewPadding,
          padding: viewPadding,
        ),
        child: child!,
      ),
      theme: cgflixAppTheme(CgflixThemeVariant.isis).copyWith(platform: TargetPlatform.android),
      home: Scaffold(backgroundColor: const Color(0xff2a3550), body: OverlaySheetHost(child: MobileVideoControls(
        player: player, heisucaTrackState: state,
        metadata: testMediaItem(id: 'ep', title: 'Shaula / Herói'),
        chapters: const [], chaptersLoaded: true, seekTimeSmall: 10,
        trackChapterControls: const Text('RÉGUA ANTIGA'),
        onSeek: (_) {}, onSeekEnd: (_) {}, onSeekRequested: (_) async {}, onPlayPause: () {},
        onNext: () => calls.add('próximo'),
      ))))));
    await tester.pump();
    return (calls: calls, rates: rates);
  }

  testWidgets('HUD mantém a régua e os botões fora da área de gesto do sistema', (tester) async {
    await pumpHud(tester, gestures: const EdgeInsets.only(left: 24, right: 28, bottom: 24));
    final timeline = tester.getRect(find.byType(TimelineSlider));
    expect(timeline.left, greaterThanOrEqualTo(24));
    expect(timeline.right, lessThanOrEqualTo(986 - 28));
    expect(tester.getRect(find.text('Ajustes')).bottom, lessThanOrEqualTo(444 - 24));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('HUD: ações reais, ajustes à direita e sem botão Próximo', (tester) async {
    final r = await pumpHud(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('RÉGUA ANTIGA'), findsNothing, reason: 'a régua apertada saiu do celular');
    expect(find.textContaining('Japonês 5.1'), findsOneWidget, reason: 'idioma e canais, como no 07A');
    expect(find.textContaining('Português (ASS)'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    // Caio, 24/10: Próximo saiu do HUD; cartão de fim e avanço automático permanecem no player.
    expect(find.text('Próximo'), findsNothing);
    expect(find.byIcon(Symbols.replay_10_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.forward_10_rounded), findsOneWidget);
    await tester.tap(find.text('Original'));
    await tester.tap(find.byIcon(Symbols.picture_in_picture_alt_rounded));
    await tester.tap(find.byIcon(Symbols.lock_rounded));
    expect(r.calls, ['proporção', 'janelinha', 'travar']);
    await tester.tap(find.textContaining('1,0x'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1,5x').last);
    await tester.pumpAndSettle();
    expect(r.rates, [1.5]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('captura visual do HUD (HEISUCA_SNAPSHOT=1)', skip: !heisucaSnapshotEnabled, (tester) async {
    await heisucaLoadFonts();
    await pumpHud(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../visual/out/player_hud.png'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('F7: player em paisagem com furo/entalhe assimétrico aplica margem horizontal simétrica', (tester) async {
    await pumpHud(tester, viewPadding: const EdgeInsets.only(left: 48, right: 0));
    final timeline = tester.getRect(find.byType(TimelineSlider));
    final leftMargin = timeline.left;
    final rightMargin = 986 - timeline.right;
    expect(leftMargin, equals(rightMargin));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('F7: botões redondos do topo têm centro do ícone igual ao centro do botão (tolerância 1 px)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: cgflixAppTheme(CgflixThemeVariant.isis),
      home: Scaffold(
        body: Center(
          child: HeisucaPlayerPill(
            icon: Symbols.picture_in_picture_alt_rounded,
            semanticLabel: 'Janelinha',
            onTap: () {},
          ),
        ),
      ),
    ));
    final buttonRect = tester.getRect(find.byType(HeisucaPlayerPill));
    final iconRect = tester.getRect(find.byIcon(Symbols.picture_in_picture_alt_rounded));
    expect((buttonRect.center.dx - iconRect.center.dx).abs(), lessThanOrEqualTo(1.0));
    expect((buttonRect.center.dy - iconRect.center.dy).abs(), lessThanOrEqualTo(1.0));
  });
}
