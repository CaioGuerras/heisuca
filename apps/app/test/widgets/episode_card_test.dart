import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_part.dart';
import 'package:heisuca/media/media_stream.dart';
import 'package:heisuca/media/media_version.dart';
import 'package:heisuca/providers/download_provider.dart';
import 'package:heisuca/services/download_manager_service.dart';
import 'package:heisuca/services/download_storage_service.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';
import 'package:heisuca/services/plex_api_cache.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/theme/mono_theme.dart';
import 'package:heisuca/utils/platform_detector.dart';
import 'package:heisuca/widgets/collapsible_text.dart';
import 'package:heisuca/widgets/episode_card.dart';
import 'package:heisuca/widgets/media_progress_bar.dart';
import 'package:provider/provider.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(false);
    LocaleSettings.setLocaleSync(AppLocale.en);
    await SettingsService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('overflowing summary stays in card semantics without an Expand label', (tester) async {
    final semantics = tester.ensureSemantics();
    const summary =
        'The expedition follows a careful team through an unfamiliar landscape while each discovery changes their plans.';
    final episode = testMediaItem(
      id: 'semantic_episode',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'A Difficult Crossing',
      index: 3,
      summary: summary,
      durationMs: 42 * 60 * 1000,
    );

    await _pumpEpisodeCard(tester, episode);

    final summaryText = tester.widget<Text>(
      find.descendant(of: find.byType(CollapsibleText), matching: find.byType(Text)).first,
    );
    expect(summaryText.textSpan, isNotNull);
    expect(summaryText.textSpan!.toPlainText(), isNot(summary));

    final semanticNodes = <SemanticsNode>[];
    void collectSemantics(SemanticsNode node) {
      semanticNodes.add(node);
      node.visitChildren((child) {
        collectSemantics(child);
        return true;
      });
    }

    collectSemantics(tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!);
    final cardSemantics = semanticNodes.singleWhere((node) => node.label.contains('A Difficult Crossing'));
    expect(cardSemantics.label, contains('The expedition follows a careful team'));
    expect(cardSemantics.label, isNot(contains('Expand')));
    expect(cardSemantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('shows file size alongside media quality labels', (tester) async {
    final episode = testMediaItem(
      id: 'sized_episode',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'A Large Episode',
      index: 4,
      durationMs: 52 * 60 * 1000,
      mediaVersions: const [
        MediaVersion(
          id: 'source',
          videoResolution: '1080',
          parts: [
            MediaPart(
              id: 'part-1',
              sizeBytes: 1536 * 1024 * 1024,
              streams: [
                MediaStream(id: 'audio', kind: MediaStreamKind.audio, codec: 'eac3', channels: 6, selected: true),
              ],
            ),
          ],
        ),
      ],
    );

    await _pumpEpisodeCard(tester, episode);

    final metadataWrap = find.ancestor(of: find.text('1.50 GB'), matching: find.byType(Wrap));
    expect(metadataWrap, findsOneWidget);
    expect(find.descendant(of: metadataWrap, matching: find.text('EAC3 5.1')), findsOneWidget);
  });

  testWidgets('downloaded episode shows the resume progress bar', (tester) async {
    final episode = testMediaItem(
      id: 'resumable_episode',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Halfway There',
      index: 5,
      durationMs: 40 * 60 * 1000,
      viewOffsetMs: 20 * 60 * 1000,
    );

    await _pumpEpisodeCard(tester, episode);

    expect(find.byType(MediaProgressBar), findsOneWidget);
  });
}

Future<void> _pumpEpisodeCard(WidgetTester tester, MediaItem episode) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  JellyfinApiCache.initialize(db);
  final downloadManager = DownloadManagerService(
    database: db,
    storageService: DownloadStorageService.instance,
    clientResolver: (serverId, {clientScopeId}) => null,
  );
  downloadManager.recoveryFuture = Future<void>.value();
  final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
  await downloadProvider.ensureInitialized();
  addTearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<DownloadProvider>.value(
        value: downloadProvider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: EpisodeCard(episode: episode, isOffline: true, onTap: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
