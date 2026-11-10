/// Contagem da sessão do player. Toque/tecla real reinicia; eventos de vídeo não.
class HeisucaEpisodeAttention {
  int completed = 0;
  void interact() => completed = 0;
  bool finish({required int limit}) {
    if (limit <= 0) {
      completed = 0;
      return false;
    }
    return ++completed >= limit;
  }
}
