import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/services/playback_coordinator.dart';

void main() {
  test('bloqueio do atualizador inclui música carregada e não usa registro ocioso como reprodução', () async {
    final coordenador = PlaybackCoordinator.instance;
    var carregada = false;
    Future<void> parar() async {}
    Future<void> anterior() async {}
    coordenador.registerMusicSession(stopAndDispose: anterior, emUso: () => true);
    coordenador.registerMusicSession(stopAndDispose: parar, emUso: () => carregada);
    try {
      expect(coordenador.temReproducao, isFalse);
      carregada = true;
      expect(coordenador.temReproducao, isTrue);
      coordenador.unregisterMusicSession(anterior);
      expect(coordenador.temReproducao, isTrue);
    } finally {
      coordenador.unregisterMusicSession(parar);
    }
    expect(coordenador.temReproducao, isFalse);
  });
}
