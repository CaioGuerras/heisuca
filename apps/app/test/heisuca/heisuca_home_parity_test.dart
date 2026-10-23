import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/cgflix/cgflix_palette.dart';
import 'package:plezy/heisuca/heisuca_home_chrome.dart';
import 'package:plezy/heisuca/heisuca_home_style.dart';
import 'package:plezy/heisuca/heisuca_upcoming.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';

void main() {
  test('máscara dissolve a arte antes do fim, mantendo o fundo único da página', () {
    expect(heisucaHeroMask.stops, [0, 0.52, 0.74, 0.94]);
    expect(heisucaHeroMask.colors.last.a, 0);
    expect(heisucaHeroHeight(914), closeTo(589.53, 0.01));
  });

  test('paleta não inventa uma cor a partir do nome; BlurHash inválido é tolerado', () {
    final first = MediaItem.jellyfin(id: 'a', kind: MediaKind.movie, title: 'Um título');
    final other = MediaItem.jellyfin(id: 'b', kind: MediaKind.movie, title: 'Outro título');
    expect(heisucaPageColor(first, isLight: false), heisucaPageColor(other, isLight: false));
    expect(heisucaBaseColor('inválido!'), isNull);
    expect(heisucaBaseColor('000000'), const Color(0xFF000000));
    final backdrop = MediaItem.jellyfin(id: 'c', kind: MediaKind.movie, raw: {
      'ImageBlurHashes': {'Backdrop': {'tag': 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'}}});
    expect(heisucaArtworkHash(backdrop), 'LEHV6nWB2yk8pyo0adR*.7kCMdnj');
    expect(heisucaBaseColor(heisucaArtworkHash(backdrop)), isNotNull);
    final dark = heisucaPageColor(backdrop, isLight: false);
    final light = heisucaPageColor(backdrop, isLight: true);
    expect(dark.computeLuminance(), lessThan(0.05));
    expect(light.computeLuminance(), greaterThan(0.4));
  });

  test('Em breve usa o mapa real, deduplica séries e preserva jf/tmdb', () {
    final items = heisucaParseUpcoming({'s': {'7': {'nome': 'Uma série', 'jf': 'jf7', 'tmdb': 77}}}, {'Items': [
      {'SeriesName': 'Nome do episódio', 'PremiereDate': '2026-10-24T12:00:00Z',
        'ProviderIds': {'SonarrSeriesId': '7', 'SonarrPoster': '/HomeScreen/CachedImage/7', 'EpisodeInfo': 'S01E02 - Segundo'}},
      {'ProviderIds': {'SonarrSeriesId': '7'}},
      {'Name': 'Sem correspondência', 'ProviderIds': {'SonarrSeriesId': '8'}},
    ]}, isMovie: false);
    expect(items, hasLength(1));
    expect(items.single.title, 'Uma série');
    expect(items.single.subtitle, '24/10 · S01E02');
    expect(items.single.jellyfinId, 'jf7');
    expect(items.single.tmdbId, 77);
    expect(items.single.imagePath, '/HomeScreen/CachedImage/7');
    expect(heisucaParseUpcoming(null, null, isMovie: true), isEmpty);
  });

  test('calendário não aceita um pôster remoto arbitrário nem inventa disponibilidade', () {
    final items = heisucaParseUpcoming({'m': {'1': {'jf': null, 'tmdb': 15}}}, {'Items': [
      {'Name': 'Novo filme', 'ProviderIds': {'RadarrMovieId': '1', 'RadarrPoster': 'https://outro.test/imagem.jpg'}},
    ]}, isMovie: true);
    expect(items.single.jellyfinId, isNull);
    expect(items.single.imagePath, isNull);
    expect(items.single.isMovie, isTrue);
  });

  testWidgets('logo sobe com o conteúdo, encaixa sem barra e preserva busca', (tester) async {
    tester.view.physicalSize = const Size(412, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final anchor = GlobalKey();
    var searches = 0;
    var docked = false;
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(CgflixThemeVariant.isis), home: Scaffold(body: Stack(children: [
      ListView(controller: controller, padding: EdgeInsets.zero, children: [
        const SizedBox(height: 420), SizedBox(key: anchor, height: 56), const SizedBox(height: 1200),
      ]),
      Positioned.fill(child: HeisucaHomeChrome(scrollController: controller, logoAnchor: anchor,
        pageColor: const Color(0xFF232138), item: MediaItem.jellyfin(id: 'movie', kind: MediaKind.movie, title: 'Título real'),
        onSearch: () => searches++, onHome: () {}, onDockedChanged: (value) => docked = value)),
    ]))));
    await tester.pumpAndSettle();
    final logo = find.byKey(const ValueKey('heisuca-docking-logo'));
    final initial = tester.getRect(logo);
    expect(initial.center.dy, closeTo(448, 1));
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byKey(const ValueKey('heisuca-top-veil')), findsNothing);
    controller.jumpTo(500);
    await tester.pumpAndSettle();
    final after = tester.getRect(logo);
    expect(after.center.dy, closeTo(30, 1));
    expect(after.width, lessThan(initial.width));
    expect(docked, isTrue);
    expect(find.byKey(const ValueKey('heisuca-top-veil')), findsOneWidget);
    expect(find.text('Título real'), findsOneWidget);
    await tester.tap(find.byTooltip('Buscar'));
    expect(searches, 1);
  });
}
