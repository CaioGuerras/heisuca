/// Publicação assíncrona da prontidão do PiP, separada do ciclo de vida da tela.
class AutoPipReadiness {
  int _revision = 0;

  void cancel() => _revision++;

  Future<void> update({
    required bool Function() ready,
    required Future<(int?, int?)> Function() dimensions,
    required Future<void> Function(bool, int?, int?) publish,
  }) async {
    final revision = ++_revision;
    if (!ready()) {
      await publish(false, null, null);
      return;
    }
    final size = await dimensions();
    // Dimensões chegam por canais nativos e podem voltar depois de outra escolha,
    // pausa, troca de player ou desmontagem. Só a decisão atual pode publicar.
    if (revision != _revision || !ready()) return;
    await publish(true, size.$1, size.$2);
  }
}
