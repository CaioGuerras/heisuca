import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../integration_test/support/video_capture_geometry.dart';

void main() {
  test('ponte textual lê subpropriedades sem inventar PAR ausente', () async {
    final read = <String>[];
    final params = await readVideoParamsForCapture((key) async {
      read.add(key);
      return {'video-params/w': '720', 'video-params/h': '480', 'video-params/par': '1.185185'}[key];
    });
    expect(params, {'w': 720, 'h': 480, 'par': 1.185185});
    expect(read, containsAll(['video-params/dw', 'video-params/dh', 'video-params/rotate']));
    await expectLater(readVideoParamsForCapture((_) async => 'indisponível'), throwsStateError);
  });
  Map<String, Object?> capture(Map<String, dynamic> params, {bool hidden = true, int mode = 0}) =>
      videoCaptureGeometry(window: const Size(1200, 540), surface: const Rect.fromLTWH(0, 0, 1200, 540),
        systemBars: const EdgeInsets.only(bottom: 24), videoParams: params,
        boxFitMode: mode, zoom: 1, hudHidden: hidden);

  test('captura usa tamanho de exibição, não o tamanho codificado anamórfico', () {
    final geometry = capture({'w': 720, 'h': 480, 'dw': 853, 'dh': 480});
    expect(geometry['hudOculto'], isTrue);
    expect(geometry['video'], {'largura': 853.0, 'altura': 480.0, 'modo': 'conter', 'zoom': 1.0});
    expect(geometry['barrasSistema'], {'topo': 0.0, 'base': 24.0, 'esquerda': 0.0, 'direita': 0.0});
  });
  test('PAR informado pelo motor resolve display sem supor pixel quadrado', () {
    expect((capture({'w': 720, 'h': 480, 'par': 32 / 27})['video'] as Map)['largura'], closeTo(853.3333, .001));
    expect(() => capture({'w': 720, 'h': 480}), throwsStateError);
  });
  test('rotação de 90 graus troca a largura e a altura de exibição', () {
    final video = capture({'dw': 1920, 'dh': 1080, 'rotate': 90})['video'] as Map;
    expect(video['largura'], 1080);
    expect(video['altura'], 1920);
  });
  test('sem HUD oculto não autoriza medir uma captura limpa', () {
    expect(() => capture({'dw': 1920, 'dh': 1080}, hidden: false), throwsStateError);
  });
  test('dimensões ou modo desconhecidos não produzem prova de vídeo', () {
    for (final params in [{'dw': 0, 'dh': 1080}, {'dw': double.nan, 'dh': 1080}, {'dw': 1920, 'dh': 1080, 'rotate': 13}]) {
      expect(() => capture(params), throwsStateError);
    }
    expect(() => capture({'dw': 1920, 'dh': 1080}, mode: 9), throwsStateError);
  });
}
