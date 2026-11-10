package app.heisuca.sessao

import android.content.Context

/** Só apresentação e posição; nenhuma URL de mídia, credencial ou instrução de reprodução. */
internal object UltimoItemSessao {
  fun salvar(context: Context, estado: EstadoSessao) {
    if (!estado.temItem) return
    context.getSharedPreferences("sessao-ultimo-item", Context.MODE_PRIVATE).edit()
      .putString("id", estado.mediaId).putString("titulo", estado.titulo)
      .putString("subtitulo", estado.subtitulo).putString("album", estado.album)
      .putString("arte", estado.artworkUrl?.takeIf { it.startsWith("file:") })
      .putLong("posicao", estado.posicaoMs).putLong("duracao", estado.duracaoMs)
      .putBoolean("video", estado.isVideo).apply()
  }
  fun ler(context: Context): EstadoSessao? {
    val prefs = context.getSharedPreferences("sessao-ultimo-item", Context.MODE_PRIVATE)
    val titulo = prefs.getString("titulo", null)?.takeIf { it.isNotBlank() } ?: return null
    return EstadoSessao(mediaId = prefs.getString("id", "") ?: "", titulo = titulo,
      subtitulo = prefs.getString("subtitulo", "") ?: "", album = prefs.getString("album", null),
      artworkUrl = prefs.getString("arte", null), posicaoMs = prefs.getLong("posicao", 0),
      duracaoMs = prefs.getLong("duracao", 0), isVideo = prefs.getBoolean("video", true), estado = "paused")
  }
}
