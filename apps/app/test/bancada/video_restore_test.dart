import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../../integration_test/support/video_restore.dart';

void main() {
  test('comando aceito não libera captura antes de um quadro novo', () async {
    final events = StreamController<void>.broadcast(sync: true);
    addTearDown(events.close);
    final accepted = Completer<void>();
    var released = false;
    final ready = restoreVideoForBancada(restarts: events.stream,
      restore: () async => accepted.complete()).then((_) => released = true);
    await accepted.future;
    await Future<void>.delayed(Duration.zero);
    expect(released, isFalse);
    events.add(null);
    await ready;
    expect(released, isTrue);
    expect(events.hasListener, isFalse);
  });

  test('assina antes da ação para não perder restart síncrono', () async {
    final events = StreamController<void>.broadcast(sync: true);
    addTearDown(events.close);
    await restoreVideoForBancada(restarts: events.stream, restore: () async {
      expect(events.hasListener, isTrue);
      events.add(null);
    });
    expect(events.hasListener, isFalse);
  });

  test('falha da ação continua falha e cancela a assinatura', () async {
    final events = StreamController<void>.broadcast(sync: true);
    addTearDown(events.close);
    await expectLater(restoreVideoForBancada(restarts: events.stream,
      restore: () async => throw StateError('falha do comando')), throwsStateError);
    expect(events.hasListener, isFalse);
  });

  test('sem quadro novo expira em erro, nunca libera captura', () async {
    final events = StreamController<void>.broadcast(sync: true);
    addTearDown(events.close);
    await expectLater(restoreVideoForBancada(restarts: events.stream,
      restore: () async {}, timeout: Duration.zero), throwsA(isA<TimeoutException>()));
    expect(events.hasListener, isFalse);
  });

  test('motor encerrado sem quadro é erro', () async {
    final events = StreamController<void>.broadcast(sync: true);
    await expectLater(restoreVideoForBancada(restarts: events.stream,
      restore: events.close), throwsStateError);
    expect(events.hasListener, isFalse);
  });
}
