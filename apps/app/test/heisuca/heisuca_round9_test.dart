import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/heisuca/heisuca_media_category.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/you/cgflix_favorites_screen.dart';
import 'package:heisuca/cgflix/home/cgflix_cards.dart';
import 'package:heisuca/heisuca/heisuca_security.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/utils/platform_detector.dart';
import 'package:heisuca/screens/profile/pin_entry_dialog.dart';
import 'package:heisuca/i18n/strings.g.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('categorias distinguem anime sem tratar toda animação como anime', () {
    expect(heisucaMediaCategory(MediaItem.jellyfin(id: 'a', kind: MediaKind.show, libraryTitle: 'Animes Legendados')), HeisucaMediaCategory.anime);
    expect(heisucaMediaCategory(MediaItem.jellyfin(id: 'b', kind: MediaKind.movie, genres: ['Animação'])), HeisucaMediaCategory.movies);
    expect(heisucaMediaCategory(MediaItem.jellyfin(id: 'c', kind: MediaKind.show, genres: ['Anime'])), HeisucaMediaCategory.anime);
    expect(heisucaMediaCategory(MediaItem.jellyfin(id: 'd', kind: MediaKind.show, libraryTitle: 'Séries')), HeisucaMediaCategory.shows);
  });
  for (final size in [const Size(412, 960), const Size(960, 412), const Size(600, 960)]) {
    testWidgets('layout de aparelho por menor dimensão $size', (tester) async {
      tester.view.physicalSize = size; tester.view.devicePixelRatio = 1; addTearDown(tester.view.reset);
      bool? phone;
      await tester.pumpWidget(MaterialApp(theme: ThemeData(platform: TargetPlatform.android), home: Builder(builder: (ctx) {
        phone = PlatformDetector.isPhone(ctx); return const SizedBox();
      })));
      expect(phone, size.shortestSide < 600);
    });
  }
  testWidgets('cancelar biometria mantém bloqueado; sucesso libera e segundo plano bloqueia', (tester) async {
    resetSharedPreferencesForTest();
    final security = HeisucaSecurity.instance;
    await security.load(); await security.setAppLock(true);
    var allow = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(HeisucaSecurity.channel, (call) async {
      if (call.method == 'authenticate') return allow;
      return true;
    });
    addTearDown(() async { await security.setAppLock(false); tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(HeisucaSecurity.channel, null); });
    await tester.pumpWidget(const MaterialApp(home: HeisucaAppLock(child: Text('Acervo privado'))));
    await tester.pumpAndSettle();
    expect(find.text('Acervo privado'), findsNothing);
    expect(find.text('Heisuca bloqueado'), findsOneWidget);
    allow = true;
    await tester.tap(find.text('Desbloquear')); await tester.pumpAndSettle();
    expect(find.text('Acervo privado'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    // Android suspende frames em paused; confira a proteção no primeiro frame do retorno.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Acervo privado'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('campo invisível do PIN não herda borda colorida do tema', (tester) async {
    await tester.pumpWidget(TranslationProvider(child: MaterialApp(theme: ThemeData(platform: TargetPlatform.android,
      inputDecorationTheme: const InputDecorationTheme(focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)))),
      home: const Scaffold(body: PinEntryDialog(userName: 'Responsável')))));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.focusedBorder, InputBorder.none);
    expect(field.decoration!.enabledBorder, InputBorder.none);
    expect(tester.takeException(), isNull);
  });
  testWidgets('favoritos filtram filmes, séries e animes sem misturar categorias', (tester) async {
    final items = [
      MediaItem.jellyfin(id: 'film', kind: MediaKind.movie, title: 'Filme'),
      MediaItem.jellyfin(id: 'show', kind: MediaKind.show, title: 'Série', libraryTitle: 'Séries'),
      MediaItem.jellyfin(id: 'anime', kind: MediaKind.show, title: 'Anime', libraryTitle: 'Animes'),
    ];
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(CgflixThemeVariant.isis),
      home: CgflixFavoritesScreen(source: CgflixFavoritesSource(load: () async => items))));
    await tester.pumpAndSettle();
    expect(find.byType(CgflixPosterCard), findsNWidgets(3));
    for (final category in [('Filmes', 'film'), ('Séries', 'show'), ('Animes', 'anime')]) {
      await tester.tap(find.text(category.$1)); await tester.pumpAndSettle();
      expect(find.byType(CgflixPosterCard), findsOneWidget);
      expect(tester.widget<CgflixPosterCard>(find.byType(CgflixPosterCard)).item.id, category.$2);
    }
    expect(tester.takeException(), isNull);
  });

}
