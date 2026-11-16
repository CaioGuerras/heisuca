// Prova real da composição Flutter sobre as superfícies nativas, sem trocar o motor.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/mpv/mpv.dart' as mpv;
import 'package:heisuca/mpv/player/platform/player_android.dart';
import 'package:heisuca/services/jellyfin_auth_header.dart';
import 'package:heisuca/services/media_control_router.dart';
import 'package:heisuca/services/media_controls_manager.dart';
import 'package:heisuca/services/pip_service.dart';

import 'support/bancada_clock.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configureBancadaFrames(binding);
  registrarProvasSessaoHud(binding);
}

/// Registrado também no target já executado pelo workflow, depois do percurso antigo.
void registrarProvasSessaoHud(IntegrationTestWidgetsFlutterBinding binding) {
  final relatorio = <String, dynamic>{'concluido': false, 'motores': <String, dynamic>{}};
  var sequencia = 0;
  for (final exo in [false, true]) {
    final motor = exo ? 'exoplayer' : 'mpv';
    testWidgets('sessão única, botões PiP e HUD na superfície $motor', (tester) async {
      final suporte = await getApplicationSupportDirectory();
      final config = jsonDecode(await File('${suporte.path}/heisuca-bancada-config.json').readAsString()) as Map;
      final sessao = jsonDecode(await File('${suporte.path}/heisuca-bancada-session.json').readAsString()) as Map;
      final player = mpv.Player(useExoPlayer: exo);
      final controles = MediaControlsManager();
      final modo = ValueNotifier<String>('sem-faixas');
      final prova = <String, dynamic>{'tempos': <String, dynamic>{}};
      var proximos = 0;
      final titulo = 'Vídeo de amostra';
      final item = MediaItem(
        id: config['item'] as String,
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        title: titulo,
      );
      final assinaturas = <StreamSubscription<dynamic>>[];
      Future<void> publicar() => controles.updatePlaybackState(
        isPlaying: player.state.playing,
        position: player.currentPosition,
        speed: player.state.rate,
        force: true,
      );
      final roteador = MediaControlRouter(
        canControlPlayback: () => !player.disposed,
        canNavigateMediaItems: () => !player.disposed,
        onPlay: () => unawaited(player.play()),
        onPause: () => unawaited(player.pause()),
        onTogglePlayPause: () => unawaited(player.playOrPause()),
        onSeek: (posicao) => unawaited(player.seek(posicao)),
        onNext: () {
          proximos++;
          unawaited(player.seek(const Duration(seconds: 2)));
        },
        onPrevious: () => unawaited(player.seek(Duration.zero)),
        onStop: () => unawaited(player.stop()),
        onSkipForward: (intervalo) =>
            unawaited(player.seek(player.currentPosition + (intervalo ?? const Duration(seconds: 10)))),
        onSkipBackward: (intervalo) =>
            unawaited(player.seek(player.currentPosition - (intervalo ?? const Duration(seconds: 10)))),
        onSetSpeed: (velocidade) => unawaited(player.setRate(velocidade)),
      );
      assinaturas.add(controles.controlEvents.listen(roteador.route));
      assinaturas.add(player.streams.position.listen((_) => unawaited(publicar())));
      assinaturas.add(player.streams.playing.listen((_) => unawaited(publicar())));
      addTearDown(() async {
        await PipService.setAutoPipReady(ready: false);
        for (final assinatura in assinaturas) {
          await assinatura.cancel();
        }
        await controles.clear();
        controles.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await player.dispose();
        modo.dispose();
      });
      Future<void> esperar(bool Function() condicao, String etapa, {int segundos = 45}) async {
        final limite = DateTime.now().add(Duration(seconds: segundos));
        while (!condicao()) {
          if (DateTime.now().isAfter(limite)) throw StateError('Prova não confirmada: $motor/$etapa.');
          await waitBancada(binding, const Duration(milliseconds: 100));
        }
      }

      Future<Map<String, dynamic>> host(String nome, String acao, [Map<String, Object?> argumentos = const {}]) async {
        final seq = ++sequencia;
        final temporario = File('${suporte.path}/heisuca-sessao-event.tmp');
        await temporario.writeAsString(
          jsonEncode({'seq': seq, 'nome': '$motor-$nome', 'acao': acao, ...argumentos}),
          flush: true,
        );
        await temporario.rename('${suporte.path}/heisuca-sessao-event.json');
        Map<String, dynamic>? resposta;
        final limite = DateTime.now().add(const Duration(seconds: 45));
        while (resposta == null) {
          final arquivo = File('${suporte.path}/heisuca-sessao-ack.json');
          if (await arquivo.exists()) {
            final atual = jsonDecode(await arquivo.readAsString()) as Map<String, dynamic>;
            if (atual['seq'] == seq && atual['ok'] == true) resposta = atual;
          }
          if (DateTime.now().isAfter(limite)) throw StateError('Host não confirmou: $motor/$nome.');
          await waitBancada(binding, const Duration(milliseconds: 100));
        }
        return resposta;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: _SuperficieHud(player: player, modo: modo),
        ),
      );
      final uri = Uri.parse(
        '${(config['server'] as String).replaceFirst(RegExp(r'/$'), '')}/Videos/${config['item']}/stream',
      ).replace(queryParameters: {'static': 'true'});
      await player.open(
        mpv.Media(
          uri.toString(),
          headers: {
            'Authorization': buildJellyfinAuthHeader(
              clientName: 'Heisuca',
              deviceName: 'Android',
              deviceId: sessao['device'] as String,
              clientVersion: '1',
              accessToken: sessao['token'] as String,
            ),
          },
        ),
      );
      await esperar(
        () => player.state.hasRenderedFrame && player.currentPosition > const Duration(seconds: 2),
        'primeiro quadro',
      );
      expect(player.playerType, motor);
      if (player is PlayerAndroid) {
        expect(player.usingMpvFallback, isFalse, reason: 'Fallback não prova o motor ExoPlayer.');
      }
      await controles.updateMetadata(metadata: item, duration: player.state.duration);
      await controles.setControlsEnabled(
        canPlayPause: true,
        canGoNext: true,
        canGoPrevious: true,
        canSeek: true,
        canStop: true,
        canSkip: true,
        canSetSpeed: true,
      );
      await controles.setBackgroundMode(true);
      await publicar();
      await host('sessao-tocando', 'sessao', {'titulo': titulo, 'estado': 3, 'proximo': true});
      prova['sessaoUnica'] = true;
      await host('comando-pausa', 'pause');
      await esperar(() => !player.state.playing, 'pausa pelo sistema');
      await publicar();
      await host('sessao-pausada', 'sessao', {'titulo': titulo, 'estado': 2, 'proximo': true});
      prova['pausaSistema'] = true;
      await host('comando-tocar', 'play');
      await esperar(() => player.state.playing, 'tocar pelo sistema');
      // O mesmo quadro pausado permite comparar os pixels das três versões do HUD.
      await player.seek(const Duration(seconds: 20));
      await esperar(() => player.currentPosition >= const Duration(seconds: 19), 'quadro de comparação');
      await player.pause();
      await esperar(() => !player.state.playing, 'congelar quadro');
      await waitBancada(binding, const Duration(milliseconds: 500));
      for (final faixa in ['sem-faixas', 'desfoque', 'degrade']) {
        modo.value = faixa;
        await waitBancada(binding, const Duration(milliseconds: 500));
        await host('hud-$faixa', 'captura');
      }
      await player.play();
      for (final faixa in ['sem-faixas', 'desfoque', 'degrade']) {
        modo.value = faixa;
        await waitBancada(binding, const Duration(milliseconds: 300));
        final quadros = <ui.FrameTiming>[];
        void receber(List<ui.FrameTiming> valores) => quadros.addAll(valores);
        SchedulerBinding.instance.addTimingsCallback(receber);
        await waitBancada(binding, const Duration(seconds: 3));
        SchedulerBinding.instance.removeTimingsCallback(receber);
        expect(quadros.length, greaterThanOrEqualTo(30), reason: 'Amostra FrameTiming insuficiente.');
        Map<String, double> resumir(Iterable<Duration> valores) {
          final numeros = valores.map((d) => d.inMicroseconds / 1000).toList()..sort();
          final n = numeros.length;
          return {
            'mediana': n.isOdd ? numeros[n ~/ 2] : (numeros[n ~/ 2 - 1] + numeros[n ~/ 2]) / 2,
            'pior': numeros.last,
          };
        }

        (prova['tempos'] as Map)[faixa] = {
          'quadros': quadros.length,
          'build_ms': resumir(quadros.map((f) => f.buildDuration)),
          'raster_ms': resumir(quadros.map((f) => f.rasterDuration)),
          'total_ms': resumir(quadros.map((f) => f.totalSpan)),
        };
      }
      modo.value = 'sem-faixas';
      final maximo = await const MethodChannel('app.heisuca/pip').invokeMethod<int>('getMaxNumPictureInPictureActions');
      expect(maximo, greaterThanOrEqualTo(3));
      prova['pipMaxAcoes'] = maximo;
      await PipService.setAutoPipReady(ready: true, width: 1920, height: 1080);
      final entrada = await PipService.enter(width: 1920, height: 1080);
      expect(entrada.$1, isTrue, reason: 'Entrada PiP recusada: ${entrada.$2}');
      await esperar(() => PipService().isPipActive.value, 'PiP ativo');
      await host('pip-pausa', 'pip-botao', {'rotulo': 'Pausar'});
      await esperar(() => !player.state.playing, 'botão Pausar PiP');
      prova['pipPausa'] = true;
      await host('pip-tocar', 'pip-botao', {'rotulo': 'Tocar'});
      await esperar(() => player.state.playing, 'botão Tocar PiP');
      prova['pipToca'] = true;
      final antesVoltar = player.currentPosition;
      await host('pip-voltar', 'pip-botao', {'rotulo': 'Voltar 10 segundos'});
      await esperar(() => player.currentPosition < antesVoltar - const Duration(seconds: 6), 'botão voltar 10s');
      prova['pipVolta10'] = true;
      final antesAvancar = player.currentPosition;
      await host('pip-avancar', 'pip-botao', {'rotulo': 'Avançar 10 segundos'});
      await esperar(() => player.currentPosition > antesAvancar + const Duration(seconds: 7), 'botão avançar 10s');
      prova['pipAvanca10'] = true;
      if (maximo! >= 4) {
        await host('pip-proximo', 'pip-botao', {'rotulo': 'Próximo'});
        await esperar(() => proximos == 1, 'botão Próximo');
        prova['pipProximo'] = true;
      } else {
        prova['pipProximo'] = 'não exibido: limite de ações do Android';
      }
      await host('pip-restaurar', 'restaurar');
      await esperar(() => !PipService().isPipActive.value, 'sair do PiP');
      for (final assinatura in assinaturas) {
        await assinatura.cancel();
      }
      assinaturas.clear();
      await player.stop();
      await controles.clear();
      await host('encerrada', 'encerrada');
      prova['sessaoEncerrada'] = true;
      (relatorio['motores'] as Map)[motor] = prova;
      relatorio['concluido'] = exo;
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['sessaoHud'] = relatorio;
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}

class _SuperficieHud extends StatefulWidget {
  const _SuperficieHud({required this.player, required this.modo});
  final mpv.Player player;
  final ValueListenable<String> modo;
  @override
  State<_SuperficieHud> createState() => _SuperficieHudState();
}

class _SuperficieHudState extends State<_SuperficieHud> with SingleTickerProviderStateMixin {
  late final Ticker ticker;
  var quadro = 0;
  @override
  void initState() {
    super.initState();
    ticker = createTicker((_) {
      if (mounted) setState(() => quadro++);
    })..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Stack(
      fit: StackFit.expand,
      children: [
        mpv.Video(player: widget.player),
        // Igual nos três modos: garante frames Flutter durante vídeo em superfície separada.
        Positioned(
          right: 8,
          top: 8,
          child: Text('$quadro', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        ValueListenableBuilder<String>(
          valueListenable: widget.modo,
          builder: (_, modo, _) {
            if (modo == 'sem-faixas') return const SizedBox.shrink();
            final texto = Center(
              child: Text(
                modo == 'desfoque' ? 'Faixa com desfoque' : 'Faixa com degradê',
                style: const TextStyle(color: Colors.white, fontSize: 28),
              ),
            );
            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: modo == 'desfoque'
                    ? ClipRect(
                        child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16), child: texto),
                      )
                    : DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0xCC000000)],
                          ),
                        ),
                        child: texto,
                      ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
