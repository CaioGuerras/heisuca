import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/widgets/video_controls/mobile_video_controls.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import '../test_helpers/watch_together_fakes.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('player em paisagem envia seek pelo callback real e acomoda o dock', (tester) async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final player = FakeSyncPlayer(position: const Duration(seconds: 20), hasRenderedFrame: true);
    final watch = WatchTogetherProvider();
    addTearDown(player.dispose);
    addTearDown(watch.dispose);
    final seeks = <Duration>[];
    final completed = <Duration>[];
    await tester.pumpWidget(ChangeNotifierProvider.value(value: watch, child: MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android, extensions: const [testMonoTokens]),
      home: Scaffold(body: MobileVideoControls(player: player, metadata: testMediaItem(id: 'real-flow'),
        chapters: const [], chaptersLoaded: true, seekTimeSmall: 10,
        trackChapterControls: const SizedBox(width: 1000, height: 64, child: Text('Áudio · Legendas · Ajustes')),
        onSeek: (_) {}, onSeekEnd: (_) => fail('deve usar o coordenador de seek'),
        onSeekRequested: (position) async { seeks.add(position); }, onSeekCompleted: completed.add,
        onPlayPause: () {},
      )))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Symbols.replay_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.forward_10));
    await tester.pump();
    expect(seeks, [const Duration(seconds: 10), const Duration(seconds: 30)]);
    expect(completed, seeks);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
