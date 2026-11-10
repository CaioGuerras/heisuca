import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_home_screen.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/utils/platform_detector.dart';

void main() {
  setUp(() => TvDetectionService.debugSetTvOverride(true));
  tearDown(() => TvDetectionService.debugSetTvOverride(null));
  final items = [
    MediaItem(
      id: 'a',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: 'Um título muito longo que precisa terminar com reticências',
      summary: 'Sinopse do primeiro filme',
      year: 2026,
      contentRating: '12',
      durationMs: 5400000,
    ),
    MediaItem(id: 'b', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Segundo filme', year: 2025),
    MediaItem(id: 'c', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Terceiro filme'),
  ];
  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeisucaTvMediaRow(title: 'Filmes', items: items, onItemTap: (_) {}),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> focus(WidgetTester tester, int index) async {
    final target = find.byType(FocusableActionDetector).at(index);
    final child = find.descendant(of: target, matching: find.byType(GestureDetector)).first;
    Focus.of(tester.element(child)).requestFocus();
    await tester.pump();
  }

  testWidgets('foco troca só painel após debounce; sem sinopse mantém altura', (tester) async {
    await mount(tester);
    final panel = find.byKey(const ValueKey('tv-row-info'));
    expect(panel, findsOneWidget);
    final height = tester.getSize(panel).height;
    await focus(tester, 0);
    await tester.pump(const Duration(milliseconds: 130));
    expect(find.descendant(of: panel, matching: find.text('Sinopse do primeiro filme')), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text('2026 · 12 · 1 h 30')), findsOneWidget);
    final thirdCard = tester.element(find.byWidgetPredicate((w) => w.runtimeType.toString() == '_TvPosterCard').at(2));
    final rebuilt = <String>[];
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (builtOnce && (identical(element, thirdCard) || element.widget is HeisucaTvMediaRow)) {
        rebuilt.add(element.widget.runtimeType.toString());
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    await focus(tester, 1);
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Sinopse do primeiro filme'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.descendant(of: panel, matching: find.text('Segundo filme')), findsOneWidget);
    expect(find.text('Sinopse do primeiro filme'), findsNothing);
    expect(tester.getSize(panel).height, height);
    expect(rebuilt.where((name) => name == '_TvPosterCard'), isEmpty);
    expect(rebuilt.where((name) => name == 'HeisucaTvMediaRow'), isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('título fica sob pôster em uma linha com reticências', (tester) async {
    await mount(tester);
    final label = find.byKey(const ValueKey('tv-poster-title-a'));
    expect(label, findsOneWidget);
    final text = tester.widget<Text>(label);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.style!.fontSize, greaterThanOrEqualTo(22));
  });
}
