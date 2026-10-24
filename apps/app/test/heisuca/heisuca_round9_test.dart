import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/heisuca/heisuca_media_category.dart';
import 'package:plezy/heisuca/heisuca_security.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/screens/profile/pin_entry_dialog.dart';
import 'package:plezy/i18n/strings.g.dart';
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
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused); await tester.pump();
    expect(find.text('Acervo privado'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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
}
