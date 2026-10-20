// Etapa 1D (paisagem): o destaque da Início desenha sem exceção nem overflow em pé, deitado e
// com fonte em 200%. Foi a exceção do destaque que pintava a Início de preto ao girar o celular.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_layout.dart';
import 'package:plezy/cgflix/home/cgflix_hero.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';

const _sizes = <String, Size>{
  'retrato 360': Size(360, 760),
  'retrato 412 (edge 70)': Size(412, 914),
  'paisagem 360': Size(760, 360),
  'paisagem 412 (edge 70)': Size(914, 412),
  'tablet deitado': Size(1280, 800),
};

void main() {
  final item = MediaItem.jellyfin(
    id: 'f',
    kind: MediaKind.movie,
    title: 'Um título bem comprido para testar a quebra de linha do destaque',
    genres: const ['Ação', 'Aventura', 'Fantasia'],
  );

  for (final entry in _sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('destaque: ${entry.key}, fonte ${(scale * 100).round()}%', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: entry.value, textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: ListView(
                  children: [
                    CgflixHero(items: [item], height: cgflixHeroHeight(entry.value), paused: true),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.text('Assistir'), findsOneWidget);
        expect(find.text('Detalhes'), findsOneWidget);
      });
    }
  }
}
