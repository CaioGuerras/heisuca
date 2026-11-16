package app.heisuca.sessao

import android.net.Uri
import android.os.Looper
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.SimpleBasePlayer
import androidx.media3.common.util.UnstableApi
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/** A sessão observa o motor; comandos do Android voltam ao dono do transporte no Dart. */
@UnstableApi
class PortaSessaoPlayer(
  looper: Looper,
  private val enviar: (String, Map<String, Any>) -> Unit,
) : SimpleBasePlayer(looper) {
  var estado: EstadoSessao = EstadoSessao()
    private set

  fun atualizar(novo: EstadoSessao) {
    verifyApplicationThread()
    estado = novo
    invalidateState()
  }

  override fun getState(): State {
    val e = estado
    val comandos = Player.Commands.Builder().addAll(
      Player.COMMAND_GET_CURRENT_MEDIA_ITEM, Player.COMMAND_GET_METADATA,
      Player.COMMAND_GET_TIMELINE, Player.COMMAND_GET_AUDIO_ATTRIBUTES,
      Player.COMMAND_SET_MEDIA_ITEM, Player.COMMAND_PREPARE,
    )
    if ("play" in e.comandos || "pause" in e.comandos) comandos.add(Player.COMMAND_PLAY_PAUSE)
    if ("seek" in e.comandos) comandos.add(Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM)
    if ("stop" in e.comandos) comandos.add(Player.COMMAND_STOP)
    if ("changeSpeed" in e.comandos) comandos.add(Player.COMMAND_SET_SPEED_AND_PITCH)
    if ("skipForward" in e.comandos) comandos.add(Player.COMMAND_SEEK_FORWARD)
    if ("skipBackward" in e.comandos) comandos.add(Player.COMMAND_SEEK_BACK)
    if ("next" in e.comandos) comandos.addAll(Player.COMMAND_SEEK_TO_NEXT, Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM)
    if ("previous" in e.comandos) comandos.addAll(Player.COMMAND_SEEK_TO_PREVIOUS, Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM)

    val lista = mutableListOf<MediaItemData>()
    if (e.temItem && "previous" in e.comandos) lista.add(MediaItemData.Builder("anterior:${e.mediaId}").build())
    val indice = lista.size
    if (e.temItem) lista.add(MediaItemData.Builder("atual:${e.mediaId}:${e.titulo}")
      .setMediaItem(item(e)).setIsSeekable("seek" in e.comandos)
      .setDurationUs(if (e.duracaoMs > 0) e.duracaoMs * 1000 else C.TIME_UNSET).build())
    if (e.temItem && "next" in e.comandos) lista.add(MediaItemData.Builder("proximo:${e.mediaId}").build())
    val fase = if (!e.temItem) Player.STATE_IDLE else when (e.estado) {
      "playing", "paused" -> Player.STATE_READY
      "buffering" -> Player.STATE_BUFFERING
      "ended" -> Player.STATE_ENDED
      else -> Player.STATE_IDLE
    }
    return State.Builder().setAvailableCommands(comandos.build())
      .setPlaylist(lista).setCurrentMediaItemIndex(if (lista.isEmpty()) C.INDEX_UNSET else indice)
      .setPlaybackState(fase).setPlayWhenReady(e.tocando || e.estado == "buffering", Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST)
      .setIsLoading(fase == Player.STATE_BUFFERING)
      .setPlayerError(if (e.estado == "error") PlaybackException("Não foi possível reproduzir.", null, PlaybackException.ERROR_CODE_UNSPECIFIED) else null)
      .setContentPositionMs(e.posicaoMs.coerceAtLeast(0))
      .setPlaybackParameters(PlaybackParameters(e.velocidade.coerceIn(.1f, 8f)))
      .setSeekBackIncrementMs(10000).setSeekForwardIncrementMs(10000).build()
  }

  override fun handleSetPlayWhenReady(playWhenReady: Boolean): ListenableFuture<*> {
    enviar(if (playWhenReady) "play" else "pause", emptyMap())
    return Futures.immediateVoidFuture()
  }
  override fun handlePrepare(): ListenableFuture<*> = Futures.immediateVoidFuture()
  override fun handleStop(): ListenableFuture<*> {
    enviar("stop", emptyMap())
    return Futures.immediateVoidFuture()
  }
  override fun handleSeek(mediaItemIndex: Int, positionMs: Long, seekCommand: Int): ListenableFuture<*> {
    val acao = when (seekCommand) {
      Player.COMMAND_SEEK_TO_NEXT, Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM -> "nextTrack"
      Player.COMMAND_SEEK_TO_PREVIOUS, Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM -> "previousTrack"
      Player.COMMAND_SEEK_FORWARD -> "skipForward"
      Player.COMMAND_SEEK_BACK -> "skipBackward"
      else -> "seek"
    }
    enviar(acao, when (acao) {
      "seek" -> mapOf("position" to positionMs.coerceAtLeast(0))
      "skipForward", "skipBackward" -> mapOf("interval" to 10000L)
      else -> emptyMap()
    })
    return Futures.immediateVoidFuture()
  }
  override fun handleSetPlaybackParameters(playbackParameters: PlaybackParameters): ListenableFuture<*> {
    enviar("setSpeed", mapOf("speed" to playbackParameters.speed.toDouble()))
    return Futures.immediateVoidFuture()
  }
  override fun handleSetMediaItems(mediaItems: List<MediaItem>, startIndex: Int, startPositionMs: Long): ListenableFuture<*> {
    if (mediaItems.size != 1 || mediaItems.first().mediaId != estado.mediaId) {
      return Futures.immediateFailedFuture<Any>(UnsupportedOperationException("Abra o conteúdo no app."))
    }
    if (startPositionMs != C.TIME_UNSET) enviar("seek", mapOf("position" to startPositionMs.coerceAtLeast(0)))
    return Futures.immediateVoidFuture()
  }

  companion object {
    fun item(e: EstadoSessao): MediaItem = MediaItem.Builder().setMediaId(e.mediaId)
      .setMediaMetadata(MediaMetadata.Builder().setTitle(e.titulo).setArtist(e.subtitulo)
        .setSubtitle(e.subtitulo).setAlbumTitle(e.album)
        .setArtworkUri(e.artworkUrl?.let(Uri::parse)).build()).build()
  }
}
