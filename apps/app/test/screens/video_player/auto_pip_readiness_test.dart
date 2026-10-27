import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/screens/video_player/auto_pip_readiness.dart';

void main() {
  test('dimensão antiga não religa PiP depois de escolher só som', () async {
    final controller = AutoPipReadiness();
    final dimensions = Completer<(int?, int?)>();
    var allowed = true;
    final sent = <bool>[];
    Future<void> publish(bool ready, int? width, int? height) async => sent.add(ready);
    final pending = controller.update(ready: () => allowed, dimensions: () => dimensions.future, publish: publish);
    allowed = false;
    await controller.update(ready: () => allowed, dimensions: () async => (16, 9), publish: publish);
    dimensions.complete((1920, 1080));
    await pending;
    expect(sent, [false]);
  });
  test('uma consulta mais nova é a única que publica dimensões', () async {
    final controller = AutoPipReadiness();
    final old = Completer<(int?, int?)>();
    final sent = <(bool, int?, int?)>[];
    Future<void> publish(bool ready, int? width, int? height) async => sent.add((ready, width, height));
    final pending = controller.update(ready: () => true, dimensions: () => old.future, publish: publish);
    await controller.update(ready: () => true, dimensions: () async => (1920, 1080), publish: publish);
    old.complete((640, 480));
    await pending;
    expect(sent, [(true, 1920, 1080)]);
  });

  test('reconfere a condição mesmo sem uma segunda consulta', () async {
    final controller = AutoPipReadiness();
    final size = Completer<(int?, int?)>();
    var alive = true;
    final sent = <bool>[];
    final pending = controller.update(ready: () => alive, dimensions: () => size.future,
        publish: (ready, _, _) async => sent.add(ready));
    alive = false;
    size.complete((16, 9));
    await pending;
    expect(sent, isEmpty);
  });

  test('cancelar o dono invalida uma leitura pendente', () async {
    final controller = AutoPipReadiness();
    final size = Completer<(int?, int?)>();
    final sent = <bool>[];
    final pending = controller.update(ready: () => true, dimensions: () => size.future,
        publish: (ready, _, _) async => sent.add(ready));
    controller.cancel();
    size.complete((16, 9));
    await pending;
    expect(sent, isEmpty);
  });

  test('desliga imediatamente sem consultar dimensões', () async {
    final sent = <bool>[];
    await AutoPipReadiness().update(ready: () => false,
        dimensions: () async => throw StateError('não deve consultar'),
        publish: (ready, _, _) async => sent.add(ready));
    expect(sent, [false]);
  });

}
