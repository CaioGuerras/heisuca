import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/home/cgflix_cards.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';

void main() {
  testWidgets('Top 10, cartão largo com progresso e esqueleto desenham sem erro', (tester) async {
    final movie = MediaItem.jellyfin(id: 'm', kind: MediaKind.movie, title: 'Filme');
    final episode = MediaItem.jellyfin(
      id: 'e',
      kind: MediaKind.episode,
      title: 'Piloto',
      grandparentTitle: 'Série',
      parentIndex: 2,
      index: 5,
      viewOffsetMs: 30 * 60000,
      durationMs: 60 * 60000,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              CgflixRow(
                title: 'Em alta no Brasil',
                storageKey: 'teste',
                height: cgflixPosterHeight,
                itemCount: 10,
                itemBuilder: (context, i) => CgflixTop10Card(rank: i + 1, item: movie, client: null),
              ),
              CgflixWideCard(item: episode, client: null),
              const CgflixSkeletonRow(),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Em alta no Brasil'), findsOneWidget);
    expect(find.text('Série'), findsOneWidget);
    expect(find.text('T2:E5 · Piloto'), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progress.value, closeTo(0.5, 0.001));
    expect(tester.takeException(), isNull);
  });
}
