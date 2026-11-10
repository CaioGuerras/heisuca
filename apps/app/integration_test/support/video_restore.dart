import 'dart:async';

/// A captura seguinte exige um restart nativo NOVO, além do retorno da ação.
/// A assinatura antecede a ação: um evento síncrono não pode se perder.
Future<void> restoreVideoForBancada({
  required Stream<void> restarts,
  required Future<void> Function() restore,
  Duration timeout = const Duration(seconds: 45),
}) async {
  final frame = Completer<void>();
  void fail(Object error, [StackTrace? trace]) {
    if (!frame.isCompleted) frame.completeError(error, trace);
  }
  final subscription = restarts.listen((_) {
    if (!frame.isCompleted) frame.complete();
  }, onError: fail, onDone: () => fail(StateError('O motor encerrou sem confirmar novo quadro.')));
  final deadline = Timer(timeout, () => fail(TimeoutException('O motor não confirmou novo quadro após restaurar o vídeo.', timeout)));
  try {
    await Future.wait<void>([Future<void>.sync(restore), frame.future], eagerError: true);
  } finally {
    deadline.cancel();
    await subscription.cancel();
  }
}
