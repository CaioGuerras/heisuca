import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/services/media_controls_manager.dart';
import 'package:heisuca/services/sessao_media.dart';

import '../test_helpers/media_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const metodos = MethodChannel('app.heisuca.sessao/metodos');
  const eventos = MethodChannel('app.heisuca.sessao/eventos');
  final chamadas = <MethodCall>[];

  setUp(() {
    chamadas.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      eventos,
      (_) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(metodos, (
      chamada,
    ) async {
      chamadas.add(chamada);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(metodos, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(eventos, null);
  });

  test('estado chega à sessão Media3 pelo canal novo, em milissegundos', () async {
    final controles = MediaControlsManager();
    addTearDown(controles.dispose);
    await controles.updatePlaybackState(
      isPlaying: true,
      position: const Duration(milliseconds: 12345),
      speed: 1.25,
      force: true,
    );
    expect(chamadas, hasLength(1));
    expect(chamadas.single.method, 'setPlaybackState');
    expect(chamadas.single.arguments, {'state': 'playing', 'position': 12345, 'speed': 1.25});
  });

  test('novo proprietário impede limpar e publicar pelo proprietário anterior', () async {
    final anterior = MediaControlsManager();
    addTearDown(anterior.dispose);
    final atual = MediaControlsManager();
    addTearDown(atual.dispose);
    await atual.updateMetadata(
      metadata: testMediaItem(id: 'novo', title: 'Título atual'),
    );
    chamadas.clear();
    await anterior.clear();
    await anterior.updateMetadata(
      metadata: testMediaItem(id: 'antigo', title: 'Título antigo'),
    );
    await anterior.updatePlaybackState(isPlaying: false, position: Duration.zero, speed: 1, force: true);
    await anterior.setBackgroundMode(false);
    expect(chamadas, isEmpty);
    await atual.updatePlaybackState(isPlaying: true, position: const Duration(seconds: 3), speed: 1, force: true);
    expect(chamadas.single.method, 'setPlaybackState');
  });

  test('comando do sistema chega somente ao proprietário atual sem duplicação', () async {
    final anterior = MediaControlsManager();
    addTearDown(anterior.dispose);
    final recebidosAntes = <MediaControlEvent>[];
    final recebidosAgora = <MediaControlEvent>[];
    final assinaturaAntes = anterior.controlEvents.listen(recebidosAntes.add);
    final atual = MediaControlsManager();
    addTearDown(atual.dispose);
    final assinaturaAtual = atual.controlEvents.listen(recebidosAgora.add);
    await pumpEventQueue();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      eventos.name,
      const StandardMethodCodec().encodeSuccessEnvelope({'type': 'pause'}),
      (_) {},
    );
    await pumpEventQueue();
    expect(recebidosAntes, isEmpty);
    expect(recebidosAgora, hasLength(1));
    expect(recebidosAgora.single, isA<PauseEvent>());
    await assinaturaAntes.cancel();
    await assinaturaAtual.cancel();
  });

  test('duração e identificação chegam sem bitmap pela ponte', () async {
    final controles = MediaControlsManager();
    addTearDown(controles.dispose);
    await controles.updateMetadata(
      metadata: testMediaItem(id: 'video-2', title: 'Segundo título'),
      duration: const Duration(milliseconds: 90345),
    );
    final mapa = chamadas.single.arguments as Map;
    expect(mapa['duration'], 90345);
    expect(mapa['mediaId'], 'video-2');
    expect(mapa['isVideo'], isTrue);
    expect(mapa.containsKey('artwork'), isFalse);
  });

  test('eventos de busca e salto conservam milissegundos e próximo', () {
    expect(
      (MediaControlEvent.fromMap({'type': 'seek', 'position': 12345}) as SeekEvent).position,
      const Duration(milliseconds: 12345),
    );
    expect(
      (MediaControlEvent.fromMap({'type': 'skipForward', 'interval': 10000}) as SkipForwardEvent).interval,
      const Duration(seconds: 10),
    );
    expect(MediaControlEvent.fromMap({'type': 'nextTrack'}), isA<NextTrackEvent>());
    expect(MediaControlEvent.fromMap({'type': 'previousTrack'}), isA<PreviousTrackEvent>());
  });

  test('retomar proprietário anterior reenvia comandos depois de a sessão ser limpa', () async {
    final anterior = MediaControlsManager();
    addTearDown(anterior.dispose);
    await anterior.setControlsEnabled(canPlayPause: true, canSeek: true);
    final atual = MediaControlsManager();
    await atual.clear();
    atual.dispose();
    chamadas.clear();
    await anterior.setControlsEnabled(canPlayPause: true, canSeek: true);
    expect(chamadas.map((c) => c.method), ['enableControls', 'disableControls']);
    expect(chamadas.first.arguments, ['play', 'pause', 'seek']);
  });

  test('carregando, fim e erro não são reduzidos a pausa', () async {
    final controles = MediaControlsManager();
    addTearDown(controles.dispose);
    for (final estado in [PlaybackState.buffering, PlaybackState.ended, PlaybackState.error]) {
      await controles.updateDetailedPlaybackState(
        state: estado,
        position: const Duration(seconds: 9),
        speed: 1,
        force: true,
      );
    }
    expect(chamadas.map((c) => (c.arguments as Map)['state']), ['buffering', 'ended', 'error']);
  });
  test('itens com o mesmo id em servidores distintos não compartilham identidade', () async {
    final controles = MediaControlsManager();
    addTearDown(controles.dispose);
    final primeiro = testMediaItem(id: 'igual', serverId: 'origem-a', title: 'Filme A');
    final segundo = testMediaItem(id: 'igual', serverId: 'origem-b', title: 'Filme B');
    await controles.updateMetadata(metadata: primeiro);
    await controles.updateMetadata(metadata: segundo);
    final ids = chamadas.where((c) => c.method == 'setMetadata').map((c) => (c.arguments as Map)['mediaId']);
    expect(ids, [primeiro.globalKey, segundo.globalKey]);
    expect(ids.toSet(), hasLength(2));
  });

}
