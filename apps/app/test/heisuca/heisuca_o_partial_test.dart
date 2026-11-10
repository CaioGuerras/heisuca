import 'package:flutter/services.dart';
import 'package:heisuca/heisuca/heisuca_floating_island.dart';
import 'package:heisuca/heisuca/heisuca_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import '../test_helpers/multi_server_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_news.dart';
import 'package:heisuca/heisuca/services/heisuca_episode_attention.dart';
import 'package:heisuca/heisuca/services/heisuca_playback_delivery.dart';

void main() {
  testWidgets('Novidades pendente não intercepta Você', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final servers = testMultiServer(clients: [_NewsClient(MediaBackend.jellyfin)]);
    servers.manager.setNavigationSource(Object(), 'news');
    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>.value(
        value: servers.provider,
        child: MaterialApp(
          theme: cgflixAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Stack(
                children: [
                  HeisucaFloatingIsland(
                    currentIndex: 0,
                    onDestinationSelected: (index) {
                      if (index == 3)
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute<void>(builder: (_) => const HeisucaProfileScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('heisuca-nav-3')));
    await tester.pumpAndSettle();
    expect(find.byType(HeisucaProfileScreen), findsOneWidget);
    expect(find.byType(HeisucaNewsScreen), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });
  test('changelog empacotado não expõe notas internas', () async {
    final text = await rootBundle.loadString(heisucaNewsAsset);
    for (final internal in ['Caio', 'bancada', 'emulador', 'Em avaliação']) {
      expect(text.toLowerCase(), isNot(contains(internal.toLowerCase())));
    }
    expect(text, contains('base do Plezy 2.22.0'));
  });
  testWidgets('ponto permanece até abrir Novidades e some ao voltar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: cgflixAppTheme(),
        home: const Scaffold(body: HeisucaNewsEntry()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Novidades ainda não lidas')), findsOneWidget);
    await tester.runAsync(() => rootBundle.loadString(heisucaNewsAsset));
    await tester.tap(find.text('Novidades'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Novidades ainda não lidas')), findsNothing);
    expect((await SharedPreferences.getInstance()).getString('heisuca.news.read'), heisucaNewsVersion);
  });
  test('episódios: três conclusões, interação reinicia, zero desliga', () {
    final attention = HeisucaEpisodeAttention();
    expect(attention.finish(limit: 3), isFalse);
    expect(attention.finish(limit: 3), isFalse);
    attention.interact();
    expect(attention.finish(limit: 3), isFalse);
    expect(attention.finish(limit: 3), isFalse);
    expect(attention.finish(limit: 3), isTrue);
    expect(attention.finish(limit: 0), isFalse);
    expect(attention.completed, 0);
  });
  test('conversão usa motivos do servidor sem exibir URL ou credenciais', () {
    final delivery = HeisucaPlaybackDelivery.jellyfin(
      method: 'Transcode',
      transcodingUrl: '/video?api_key=SEGREDO&TranscodeReasons=AudioCodecNotSupported,SubtitleCodecNotSupported',
    );
    expect(delivery.reasons, hasLength(2));
    expect(delivery.explanation, contains('áudio'));
    expect(delivery.explanation, isNot(contains('SEGREDO')));
    expect(HeisucaPlaybackDelivery.jellyfin(method: 'Transcode').explanation, contains('não informou'));
    expect(
      HeisucaPlaybackDelivery.jellyfin(
        method: 'DirectPlay',
        transcodingUrl: '/?TranscodeReasons=AudioCodecNotSupported',
      ).reasons,
      isEmpty,
    );
  });
  testWidgets('Novidades usa texto editorial e cabe em tela pequena com texto ampliado', (tester) async {
    await tester.runAsync(() => rootBundle.loadString(heisucaNewsAsset));
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: cgflixAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: const HeisucaNewsScreen(),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Novidades'), findsOneWidget);
    expect(find.text('2.0.34 — O que mudou'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _NewsClient implements MediaServerClient {
  _NewsClient(this.backend);
  @override
  void close() {}
  @override
  final MediaBackend backend;
  @override
  String get serverName => 'Servidor';
  @override
  ServerId get serverId => ServerId('news');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
