import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/heisuca/heisuca_title_sheet.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_file_info.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/heisuca/heisuca_title_parts.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/jellyfin_mappers.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import '../test_helpers/prefs.dart';
import '../visual/heisuca_snapshot.dart';

// Formas reais do Jellyfin do CGSERVER (23/10/2026), com IDs encurtados. Os testes antigos usavam
// MediaItem sem SeriesName/SeriesId; com eles, displayTitle devolve o nome da série e o defeito aparece.
MediaItem _map(Map<String, dynamic> json) =>
    JellyfinMappers.mediaItem(json, serverId: ServerId('source'), absolutizer: null)!;

Map<String, dynamic> _series(String id, String name, {double? community, String? overview}) => {
  'Id': id, 'Name': name, 'Type': 'Series', 'CommunityRating': ?community, 'Overview': ?overview,
};
Map<String, dynamic> _season(String seriesId, String seriesName, int index) => {
  'Id': '$seriesId-s$index', 'Name': index == 0 ? 'Especiais' : 'Temporada $index', 'Type': 'Season',
  'IndexNumber': index, 'SeriesId': seriesId, 'SeriesName': seriesName, 'ParentId': seriesId,
};
Map<String, dynamic> _episode(String seriesId, String seriesName, int season, int index, String name,
    {int minutes = 24, String? overview}) => {
  'Id': '$seriesId-s${season}e$index', 'Name': name, 'Type': 'Episode', 'IndexNumber': index,
  'ParentIndexNumber': season, 'SeasonId': '$seriesId-s$season', 'SeriesId': seriesId, 'SeriesName': seriesName,
  'RunTimeTicks': minutes * 600000000, 'Overview': ?overview,
};

// Fonte de mídia no formato do Jellyfin para Re:ZERO T4:E19 (mesmas faixas do print do Caio, 23/10).
final _rezeroFile = parseJellyfinFileInfoFromJson({'MediaSources': [{
  'Id': 'src', 'Container': 'mkv', 'Bitrate': 8766000,
  'Path': '/home/caioguerras/data/media/anime/Re ZERO (2016)/Season 04/S04E19 - Shaula Hero.mkv',
  'MediaStreams': [
    {'Type': 'Video', 'Index': 0, 'Codec': 'h264', 'Width': 1920, 'Height': 1080, 'RealFrameRate': 23.976, 'BitDepth': 8, 'VideoRange': 'SDR'},
    {'Type': 'Audio', 'Index': 1, 'Codec': 'aac', 'Language': 'por', 'Channels': 2, 'IsDefault': true},
    {'Type': 'Audio', 'Index': 2, 'Codec': 'aac', 'Language': 'jpn', 'Channels': 2, 'IsDefault': false},
    {'Type': 'Subtitle', 'Index': 3, 'Codec': 'ass', 'Language': 'por', 'IsForced': true, 'IsDefault': true},
    {'Type': 'Subtitle', 'Index': 4, 'Codec': 'ass', 'Language': 'eng'},
  ],
}]})!;

class _Client extends MediaServerClient {
  /// Quando definido, segura a resposta do item até o teste completar (prova o paralelismo).
  Completer<void>? holdItem;
  final childRequests = <String>[];
  _Client({required this.series, required this.seasons, required this.episodesBySeason, this.onDeck, this.fileInfo});
  final MediaFileInfo? fileInfo;
  final MediaItem series;
  final List<MediaItem> seasons;
  final Map<String, List<MediaItem>> episodesBySeason;
  final MediaItem? onDeck;
  final itemRequests = <String>[];
  @override ServerCapabilities get capabilities => const ServerCapabilities(userFavorites: true);
  @override ServerId get serverId => ServerId('source');
  @override MediaBackend get backend => MediaBackend.jellyfin;
  @override Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id,
      {void Function(MediaItem)? onItemReady}) async {
    itemRequests.add(id);
    if (holdItem != null) await holdItem!.future;
    if (id == series.id) return (item: series, onDeckEpisode: onDeck);
    final all = episodesBySeason.values.expand((e) => e);
    return (item: all.where((e) => e.id == id).firstOrNull, onDeckEpisode: null);
  }
  @override Future<List<MediaItem>> fetchChildren(String id) async {
    childRequests.add(id);
    return id == series.id ? seasons : episodesBySeason[id] ?? const [];
  }
  @override String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) => '';
  @override Future<MediaFileInfo?> getFileInfo(MediaItem item) async => fileInfo;
  @override Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async => const [];
  @override dynamic noSuchMethod(Invocation invocation) => null;
}

Future<_Client> _open(WidgetTester tester, _Client client, MediaItem entry) async {
  tester.view.physicalSize = const Size(412, 914);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final servers = MultiServerProvider(manager, DataAggregationService(manager));
  addTearDown(servers.dispose);
  addTearDown(manager.dispose);
  await tester.pumpWidget(ChangeNotifierProvider.value(value: servers, child: MaterialApp(
    theme: cgflixAppTheme(CgflixThemeVariant.isis),
    home: Builder(builder: (ctx) => HeisucaTitleSheet(hostContext: ctx, item: entry)))));
  await tester.pumpAndSettle();
  return client;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.hideSpoilers, false);
  });

  group('rótulos com dados reais do Jellyfin', () {
    test('temporada usa o próprio nome, não o da série', () {
      final season = _map(_season('op', 'One Piece', 1));
      expect(season.displayTitle, 'One Piece', reason: 'armadilha: displayTitle é título de cabeçalho');
      expect(heisucaSeasonLabel(season), 'Temporada 1');
      expect(heisucaSeasonLabel(_map(_season('op', 'One Piece', 0))), 'Especiais');
    });
    test('temporada que só repete o nome da série vira "Temporada N"', () {
      final season = _map({..._season('op', 'One Piece', 3), 'Name': 'One Piece'});
      expect(heisucaSeasonLabel(season), 'Temporada 3');
    });
    test('episódio usa o próprio nome e cai em "Episódio N" quando repete a série', () {
      final ep = _map(_episode('op', 'One Piece', 1, 1, 'Eu sou Luffy! O homem que será o Rei dos Piratas!'));
      expect(ep.displayTitle, 'One Piece');
      expect(heisucaEpisodeLabel(ep), 'Eu sou Luffy! O homem que será o Rei dos Piratas!');
      expect(heisucaEpisodeLabel(_map(_episode('op', 'One Piece', 1, 2, 'One Piece'))), 'Episódio 2');
    });
    test('episódio e temporada apontam para a série', () {
      expect(heisucaSeriesIdFor(_map(_episode('rz', 'Re:Zero', 4, 19, 'Shaula / Herói'))), 'rz');
      expect(heisucaSeriesIdFor(_map(_season('rz', 'Re:Zero', 4))), 'rz');
      expect(heisucaSeriesIdFor(_map(_series('rz', 'Re:Zero'))), isNull);
    });
  });

  testWidgets('One Piece: seletor distingue Especiais e temporadas; cartões com nome do episódio', (tester) async {
    const name = 'One Piece';
    final series = _map(_series('op', name, community: 8.8));
    final seasons = [for (final i in [0, 1, 2]) _map(_season('op', name, i))];
    final client = _Client(series: series, seasons: seasons, episodesBySeason: {
      'op-s0': [_map(_episode('op', name, 0, 1, 'Especial do Luffy'))],
      'op-s1': [
        _map(_episode('op', name, 1, 1, 'Eu sou Luffy! O homem que será o Rei dos Piratas!', minutes: 65)),
        _map(_episode('op', name, 1, 2, 'O grande espadachim aparece! Caçador de Piratas, Roronoa Zoro', minutes: 56)),
      ],
      'op-s2': [_map(_episode('op', name, 2, 1, 'Episódio da temporada 2'))],
    });
    await _open(tester, client, series);

    expect(find.textContaining('2 temporadas'), findsOneWidget, reason: 'Especiais não contam como temporada');
    expect(find.textContaining('audience'), findsNothing, reason: 'fonte de nota crua não aparece');
    expect(find.textContaining('Eu sou Luffy!'), findsWidgets);
    expect(find.text('1. One Piece'), findsNothing);

    await tester.scrollUntilVisible(find.text('Temporada 1'), 180, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Temporada 1'));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    for (final label in ['Especiais', 'Temporada 1', 'Temporada 2']) {
      expect(find.descendant(of: sheet, matching: find.text(label)), findsOneWidget);
    }
    expect(find.descendant(of: sheet, matching: find.text(name)), findsNothing);

    await tester.tap(find.descendant(of: sheet, matching: find.text('Temporada 2')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Episódio da temporada 2'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Re:ZERO: episódio vindo da Home abre a série, temporada 4 e alvo T4:E19', (tester) async {
    const name = 'Re:Zero - Começando uma Vida em Outro Mundo';
    final series = _map(_series('rz', name, overview: 'Sinopse da série'));
    final entry = _map(_episode('rz', name, 4, 19, 'Shaula / Herói', minutes: 41,
        overview: 'Enquanto Emilia tenta passar pelo teste do topo, Subaru e os demais continuam lutando.'));
    final client = _Client(
      series: series,
      seasons: [for (final i in [1, 2, 3, 4]) _map(_season('rz', name, i))],
      episodesBySeason: {
        'rz-s1': [_map(_episode('rz', name, 1, 1, 'O fim do começo e o começo do fim'))],
        'rz-s4': [for (var i = 1; i <= 19; i++) i == 19 ? entry : _map(_episode('rz', name, 4, i, 'Capítulo $i'))],
      },
      onDeck: _map(_episode('rz', name, 1, 1, 'O fim do começo e o começo do fim')),
      fileInfo: _rezeroFile,
    );
    await _open(tester, client, entry);

    expect(client.itemRequests.first, 'rz', reason: 'a ficha busca a série, não o episódio');
    expect(find.textContaining('4 temporadas'), findsOneWidget);
    expect(find.textContaining('T4:E19'), findsWidgets, reason: 'o alvo é o episódio tocado, não o on-deck T1:E1');
    expect(find.textContaining('T1:E1'), findsNothing);
    expect(find.text('Assistir T4:E19'), findsWidgets, reason: 'episódio novo não iniciado não é "Continuar"');
    await tester.scrollUntilVisible(find.text('Temporada 4'), 180, scrollable: find.byType(Scrollable).first);
    expect(find.text('Temporada 4'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('19. Shaula / Herói'), 120, scrollable: find.byType(Scrollable).first);
    expect(find.text('19. Shaula / Herói'), findsOneWidget, reason: 'a faixa abre no episódio-alvo');
    // Com "ocultar spoilers" desligado (setUp), a sinopse é a do episódio-alvo com a marca do site.
    expect(find.textContaining('「$name·Temp. 4·EP 19」'), findsOneWidget);

    // Info mídia: cartões lado a lado com dados reais; o caminho do arquivo nunca aparece.
    await tester.scrollUntilVisible(find.text('Info mídia · T4:E19'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('1920 × 1080'), findsOneWidget);
    expect(find.text('Dolby Digital'), findsNothing);
    expect(find.text('Estéreo (2.0)'), findsWidgets);
    expect(find.text('Áudio 1'), findsOneWidget);
    expect(find.text('Legendas'), findsOneWidget);
    expect(find.textContaining('/home/caioguerras'), findsNothing);
    expect(find.textContaining('Caminho'), findsNothing);
    expect(find.textContaining('1080p', skipOffstage: false), findsWidgets, reason: 'linha técnica do topo usa a versão real');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sinopse longa: "mais" na própria linha, sem botão solto; abre e fecha', (tester) async {
    tester.view.physicalSize = const Size(412, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final long = List.filled(40, 'Subaru volta no tempo a cada morte e tenta salvar todos.').join(' ');
    const colors = HeisucaTitleColors(page: Colors.black, text: Colors.white, accent: Colors.purple, isLight: false);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: HeisucaSynopsis(text: long, colors: colors))));
    expect(find.byType(TextButton), findsNothing);
    expect(find.textContaining('… mais'), findsOneWidget);
    final rich = tester.widget<Text>(find.textContaining('… mais'));
    expect(rich.maxLines, 4);
    await tester.tapOnText(find.textRange.ofSubstring('mais'));
    await tester.pump();
    expect(find.textContaining('menos'), findsOneWidget);
    expect(find.textContaining(long), findsOneWidget);
  });

  testWidgets('captura visual da ficha (HEISUCA_SNAPSHOT=1)', skip: !heisucaSnapshotEnabled, (tester) async {
    await heisucaLoadFonts();
    const name = 'Re:Zero - Começando uma Vida em Outro Mundo';
    final series = _map({..._series('rz', name, community: 8.1, overview: 'Natsuki Subaru, um adolescente comum, conhece uma linda garota de cabelos prateados vinda de outro mundo. Subaru quer ficar ao lado dela, mas o fardo que ela carrega é maior do que Subaru pode imaginar. Eles enfrentam o feroz ataque de monstros, traições, violência irracional e, por fim, a morte.'),
      'ProductionYear': 2016, 'PremiereDate': '2016-04-04T00:00:00Z', 'Studios': [{'Name': 'TV Tokyo'}], 'OfficialRating': 'BR-16',
      'Genres': ['Animação', 'Mistério', 'Ação', 'Aventura', 'Ficção científica', 'Fantasia'],
      'People': [for (final (n, r) in [('Yusuke Kobayashi', 'Subaru Natsuki (voice)'), ('Rie Takahashi', 'Emilia (voice)'), ('Yumi Uchiyama', 'Puck (voice)'), ('Rie Murakawa', 'Ram (voice)')]) {'Name': n, 'Role': r, 'Type': 'Actor', 'Id': n}]});
    final entry = _map(_episode('rz', name, 4, 19, 'Shaula / Herói', minutes: 41,
        overview: 'Enquanto Emilia tenta passar pelo teste do topo, Subaru e os demais continuam lutando.'));
    final client = _Client(series: series, seasons: [for (final i in [1, 2, 3, 4]) _map({..._season('rz', name, i), 'ChildCount': i == 4 ? 19 : 25, 'ProductionYear': 2015 + i * 2})],
      episodesBySeason: {'rz-s4': [for (var i = 1; i <= 19; i++) i == 19 ? entry : _map(_episode('rz', name, 4, i, i == 18 ? 'Rem / Ram' : 'Capítulo $i', minutes: 24))]},
      fileInfo: _rezeroFile);
    heisucaPhoneView(tester, height: 2900);
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(servers.dispose);
    addTearDown(manager.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: servers, child: MaterialApp(
      debugShowCheckedModeBanner: false, theme: cgflixAppTheme(CgflixThemeVariant.isis),
      home: Builder(builder: (ctx) => HeisucaTitleSheet(hostContext: ctx, item: entry)))));
    await tester.pumpAndSettle();
    await expectLater(find.byType(HeisucaTitleSheet), matchesGoldenFile('../visual/out/ficha_rezero.png'));
    await tester.tap(find.text('Temporada 4'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../visual/out/ficha_rezero_temporadas.png'));
  });

  testWidgets('ficha pede temporadas e a temporada do episódio junto com o item (sem fila)', (tester) async {
    const name = 'Re:Zero - Começando uma Vida em Outro Mundo';
    final series = _map(_series('rz', name));
    final entry = _map(_episode('rz', name, 4, 19, 'Shaula / Herói'));
    final client = _Client(series: series, seasons: [for (final i in [1, 2, 3, 4]) _map(_season('rz', name, i))],
      episodesBySeason: {'rz-s4': [entry]})..holdItem = Completer<void>();
    tester.view.physicalSize = const Size(412, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(servers.dispose);
    addTearDown(manager.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: servers, child: MaterialApp(
      theme: cgflixAppTheme(CgflixThemeVariant.isis),
      home: Builder(builder: (ctx) => HeisucaTitleSheet(hostContext: ctx, item: entry)))));
    await tester.pump();
    expect(client.itemRequests, ['rz']);
    expect(client.childRequests, containsAll(['rz', 'rz-s4']), reason: 'pedidos já saíram com o item ainda pendente');
    client.holdItem!.complete();
    await tester.pumpAndSettle();
    expect(client.childRequests.where((id) => id == 'rz-s4').length, 1, reason: 'a temporada antecipada não é pedida de novo');
    expect(find.text('Temporada 4', skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
