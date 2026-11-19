import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import 'package:heisuca/connection/connection.dart';
import 'package:heisuca/desktop/platform/desktop_metadata_cache.dart';
import 'package:heisuca/desktop/platform/desktop_connection_vault.dart';
import 'package:heisuca/services/plex_api_cache.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/services/jellyfin_client.dart';
import 'package:heisuca/mpv/models.dart';
import 'package:heisuca/mpv/player/player.dart';
import 'package:heisuca/mpv/video.dart';
import 'package:heisuca/desktop/desktop_app.dart';
import 'package:heisuca/desktop/desktop_playback_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bootstrap desktop real inicializa caches dos dois backends no Windows', (tester) async {
    final dir = await Directory.systemTemp.createTemp('heisuca-native-cache-');
    final database = await initializeDesktopMetadataCaches(supportDirectory: dir);
    try {
      await PlexApiCache.instance.put(ServerId('plex-fixture'), '/fixture', {'proof': 'plex'});
      await JellyfinApiCache.instance.put(ServerId('jellyfin-fixture'), '/fixture', {'proof': 'jellyfin'});
      expect((await PlexApiCache.instance.get(ServerId('plex-fixture'), '/fixture'))?['proof'], 'plex');
      expect((await JellyfinApiCache.instance.get(ServerId('jellyfin-fixture'), '/fixture'))?['proof'], 'jellyfin');
    } finally {
      await database.close();
      await dir.delete(recursive: true);
    }
  });

  testWidgets('Cliente Jellyfin real consulta biblioteca local com identidade Heisuca', (tester) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? header;
    server.listen((request) async {
      header = request.headers.value('Authorization');
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"Items":[],"TotalRecordCount":0}');
      await request.response.close();
    });
    final baseUrl = 'http://127.0.0.1:${server.port}';
    final connection = JellyfinConnection(
      id: 'fixture/user', baseUrl: baseUrl, baseUrls: [baseUrl],
      serverName: 'Fixture', serverMachineId: 'fixture', userId: 'user',
      userName: 'Fixture', accessToken: 'canario-publico-fixture',
      deviceId: 'fixture-desktop', createdAt: DateTime.utc(2026),
    );
    JellyfinClient? client;
    try {
      client = await JellyfinClient.create(connection, clientName: 'Heisuca Windows');
      expect(await client.fetchLibraries().timeout(const Duration(seconds: 5)), isEmpty);
      expect(header, contains('Client="Heisuca%20Windows"'));
    } finally {
      client?.close();
      await server.close(force: true);
    }
  });

  testWidgets('DPAPI nativo protege e recupera sessão no usuário Windows', (tester) async {
    expect(Platform.isWindows, isTrue);
    const channel = MethodChannel('heisuca/desktop_vault');
    final plain = Uint8List.fromList(utf8.encode('canario-publico-sem-credenciais'));
    final cipher = await channel.invokeMethod<Uint8List>('protect', plain);
    expect(cipher, isNotNull);
    expect(cipher, isNot(equals(plain)));
    final restored = await channel.invokeMethod<Uint8List>('unprotect', cipher!);
    expect(restored, orderedEquals(plain));
    final corrupt = Uint8List.fromList(cipher)..[0] ^= 0xff;
    await expectLater(channel.invokeMethod<Uint8List>('unprotect', corrupt),
        throwsA(isA<PlatformException>()));
  });

  testWidgets('Cofre Windows restaura JSON em nova instância com DPAPI real', (tester) async {
    final dir=await Directory.systemTemp.createTemp('heisuca-native-vault-fixture_');
    try {
      final first=PlatformWindowsVault(getDirectory:()async=>dir);
      await first.write([{'canario':'heisuca-fixture-sem-conta-real'}]);
      final second=PlatformWindowsVault(getDirectory:()async=>dir);
      expect(await second.read(),[{'canario':'heisuca-fixture-sem-conta-real'}]);
    } finally { await dir.delete(recursive:true); }
  });

  testWidgets(
    'Reprodução nativa desktop Windows - backend libmpv real e pipeline DComp',
    (WidgetTester tester) async {
      // Guard estrito de plataforma: falha explícita se o CI tentar rodar em SO não-Windows
      if (!Platform.isWindows) {
        fail(
          'Erro de configuração de CI: o teste de integração desktop_native_playback_test '
          'deve ser executado exclusivamente em ambiente Windows (-d windows).',
        );
      }

      // Resolução do fixture com caracteres Unicode no caminho
      final fixturePath = p.join(
        Directory.current.path,
        'test',
        'desktop',
        'fixtures',
        'ação teste.mkv',
      );
      final fixtureFile = File(fixturePath);

      if (!fixtureFile.existsSync()) {
        fail('Arquivo de fixture não encontrado no caminho especificado: $fixturePath');
      }

      // Instanciação real do backend Windows via Player() factory (sem mocks)
      final player = Player();
      final controller = DesktopPlaybackController(playerFactory: () => player);

      try {
        // Árvore com fundo transparente para composição direta (DirectComposition)
        await tester.pumpWidget(DesktopApp(controller: controller));

        // Abertura com inicialização preguiçosa (lazy open); sem print de URI/tokens
        // Runner has no physical sound device. Decode audio through mpv's
        // null output; this verifies track switching, never speaker output.
        await player.setProperty('ao', 'null');
        await player.setProperty('hwdec', 'no');
        await player.setProperty('d3d11-warp', 'yes');
        await controller.open(fixtureFile.path);

        // 1. Aguarda primeiro quadro renderizado e avanço do relógio >= 1s
        final pollStopwatch = Stopwatch()..start();
        var frameRenderedAndClockAdvanced = false;
        while (pollStopwatch.elapsed < const Duration(seconds: 30)) {
          await tester.pump(const Duration(milliseconds: 100));
          if (player.state.hasRenderedFrame && player.state.position >= const Duration(seconds: 1)) {
            frameRenderedAndClockAdvanced = true;
            break;
          }
        }

        if (!frameRenderedAndClockAdvanced) {
          fail(
            'Falha de inicialização no backend nativo: hasRenderedFrame=${player.state.hasRenderedFrame}, '
            'position=${player.state.position}. Esperado hasRenderedFrame=true e position>=1s em até 30s.',
          );
        }

        expect(controller.hasMedia, isTrue, reason: 'O shell deve reconhecer a mídia pronta.');
        expect(find.byType(Video), findsOneWidget, reason: 'A superfície de vídeo deve estar montada no shell.');

        // 2. Aguarda e valida enumeração de 2 faixas de áudio e 2 faixas de legenda
        var tracksDiscovered = false;
        pollStopwatch.reset();
        while (pollStopwatch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 100));
          if (player.state.tracks.audio.length == 2 && player.state.tracks.subtitle.length == 2) {
            tracksDiscovered = true;
            break;
          }
        }

        if (!tracksDiscovered) {
          fail(
            'Contagem de faixas incorreta: audio=${player.state.tracks.audio.length} (esperado 2), '
            'subtitle=${player.state.tracks.subtitle.length} (esperado 2).',
          );
        }

        final audioTracks = player.state.tracks.audio;
        final subtitleTracks = player.state.tracks.subtitle;

        expect(
          audioTracks.any((t) => (t.language ?? '').toLowerCase().contains('por')),
          isTrue,
          reason: 'Faixa de áudio em português não encontrada.',
        );
        expect(
          audioTracks.any((t) => (t.language ?? '').toLowerCase().contains('eng')),
          isTrue,
          reason: 'Faixa de áudio em inglês não encontrada.',
        );

        final ptSubTrack = subtitleTracks.firstWhere(
          (t) => (t.language ?? '').toLowerCase().contains('por'),
          orElse: () => fail('Faixa de legenda em português não encontrada no fixture.'),
        );

        // 3. Seleciona legenda em português e aguarda reflexão de estado e leitura de sub-text
        await player.selectSubtitleTrack(ptSubTrack);

        var subtitleSelected = false;
        pollStopwatch.reset();
        while (pollStopwatch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 100));
          if (player.state.track.subtitle?.id == ptSubTrack.id) {
            subtitleSelected = true;
            break;
          }
        }

        if (!subtitleSelected) {
          fail(
            'Seleção de legenda não refletiu em player.state.track.subtitle: '
            'atual=${player.state.track.subtitle?.id}, esperado=${ptSubTrack.id}.',
          );
        }

        // Valida que o mpv expõe o texto da cue ativa (cue 0.5-7s, tempo atual >= 1s)
        var cueTextFound = false;
        pollStopwatch.reset();
        while (pollStopwatch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 100));
          final subText = await player.getProperty('sub-text');
          if (subText != null && subText.contains('Heisuca')) {
            cueTextFound = true;
            break;
          }
        }

        if (!cueTextFound) {
          final subText = await player.getProperty('sub-text');
          fail('Propriedade sub-text nativa do mpv não conteve "Heisuca" durante o cue ativo: "$subText".');
        }

        // 4. Troca áudio para o segundo ID e confirma aid nativo no backend
        final secondAudio = audioTracks[1];
        await player.selectAudioTrack(secondAudio);

        var audioSwitched = false;
        pollStopwatch.reset();
        while (pollStopwatch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 100));
          final nativeAid = await player.getProperty('aid');
          if (player.state.track.audio?.id == secondAudio.id && nativeAid == secondAudio.id) {
            audioSwitched = true;
            break;
          }
        }

        if (!audioSwitched) {
          final nativeAid = await player.getProperty('aid');
          fail(
            'Troca de áudio não confirmada: player.state.track.audio=${player.state.track.audio?.id}, '
            'mpv aid="$nativeAid", esperado="${secondAudio.id}".',
          );
        }

        // 5. Desliga legenda e confirma sid = "no"
        await player.selectSubtitleTrack(SubtitleTrack.off);

        var subtitleDisabled = false;
        pollStopwatch.reset();
        while (pollStopwatch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 100));
          final nativeSid = await player.getProperty('sid');
          if (player.state.track.subtitle?.id == SubtitleTrack.off.id && nativeSid == 'no') {
            subtitleDisabled = true;
            break;
          }
        }

        if (!subtitleDisabled) {
          final nativeSid = await player.getProperty('sid');
          fail(
            'Desativação de legendas não confirmada no backend: '
            'track.subtitle=${player.state.track.subtitle?.id}, mpv sid="$nativeSid" (esperado "no").',
          );
        }

        // Playback speed must reach libmpv, not only change a UI label.
        await controller.setRate(1.25);
        expect(double.tryParse(await player.getProperty('speed') ?? ''), closeTo(1.25, 0.001));
        await controller.setRate(1.0);

        // 6. Pausar, seek para 5s, retomar e verificar avanço contínuo do relógio
        await player.pause();
        pollStopwatch.reset();
        var paused = false;
        while (pollStopwatch.elapsed < const Duration(seconds: 10)) {
          await tester.pump(const Duration(milliseconds: 100));
          if (!player.state.playing) {
            paused = true;
            break;
          }
        }

        if (!paused) {
          fail('Player não confirmou pausa dentro do tempo limite.');
        }

        await player.seek(const Duration(seconds: 5));
        pollStopwatch.reset();
        var seekLanded = false;
        while (pollStopwatch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 100));
          if (player.state.position >= const Duration(seconds: 4, milliseconds: 800)) {
            seekLanded = true;
            break;
          }
        }

        if (!seekLanded) {
          fail('Seek para 5s não refletido: posição atual=${player.state.position}.');
        }

        final posAfterSeek = player.state.position;
        await player.play();

        pollStopwatch.reset();
        var clockAdvanced = false;
        while (pollStopwatch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 100));
          if (player.state.playing && player.state.position >= posAfterSeek + const Duration(milliseconds: 500)) {
            clockAdvanced = true;
            break;
          }
        }

        if (!clockAdvanced) {
          fail(
            'Relógio não avançou após retomar reprodução: playing=${player.state.playing}, '
            'posição=${player.state.position}, anterior=$posAfterSeek.',
          );
        }
      } finally {
        // Desmonta Video widget da árvore antes de descartar o player para evitar que callbacks
        // addPostFrameCallback de layout tentem chamar setVideoRect após o dispose
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        controller.dispose();
        await player.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
