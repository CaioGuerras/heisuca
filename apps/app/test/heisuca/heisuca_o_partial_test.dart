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
  for (final backend in [MediaBackend.jellyfin, MediaBackend.plex]) {
    testWidgets('aviso só na primeira abertura Jellyfin: $backend', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final servers = testMultiServer(clients: [_NewsClient(backend)]);
      servers.manager.setNavigationSource(Object(), 'news');
      Widget app() => ChangeNotifierProvider<MultiServerProvider>.value(
        value: servers.provider,
        child: MaterialApp(
          home: const HeisucaNewsNotice(child: Scaffold(body: Text('Sessão'))),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(
        find.text('Veja o que mudou no Heisuca.'),
        backend == MediaBackend.jellyfin ? findsOneWidget : findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Veja o que mudou no Heisuca.'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
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
    await tester.pumpAndSettle();
    expect(find.text('Novidades'), findsOneWidget);
    expect(find.text('2.0.33 — O que mudou'), findsOneWidget);
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
  ServerId get serverId => ServerId('news');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
