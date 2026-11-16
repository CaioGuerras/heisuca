package app.heisuca.sessao

/** Retrato do transporte ativo; nenhuma decisão depende do motor de vídeo. */
data class EstadoSessao(
  val mediaId: String = "",
  val titulo: String = "",
  val subtitulo: String = "",
  val album: String? = null,
  val artworkUrl: String? = null,
  val duracaoMs: Long = 0,
  val posicaoMs: Long = 0,
  val velocidade: Float = 1f,
  val estado: String = "stopped",
  val comandos: Set<String> = emptySet(),
  val isVideo: Boolean = true,
) {
  val tocando: Boolean get() = estado == "playing"
  val temItem: Boolean get() = titulo.isNotBlank()
}
