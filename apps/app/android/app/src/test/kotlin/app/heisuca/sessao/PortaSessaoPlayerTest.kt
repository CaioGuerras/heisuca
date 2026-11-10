package app.heisuca.sessao

import android.os.Looper
import androidx.media3.common.Player
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class PortaSessaoPlayerTest {
  private fun porta() = PortaSessaoPlayer(Looper.getMainLooper()) { _, _ -> }

  @Test fun estadoDoMotorEMetadadosChegamAoAndroid() {
    val porta = porta()
    porta.atualizar(EstadoSessao(titulo = "Filme", subtitulo = "2026", duracaoMs = 120000,
      posicaoMs = 12000, velocidade = 1.5f, estado = "playing", comandos = setOf("play", "pause", "seek", "stop")))
    assertEquals(Player.STATE_READY, porta.playbackState)
    assertTrue(porta.isPlaying)
    assertEquals(12000L, porta.currentPosition)
    assertEquals(120000L, porta.duration)
    assertEquals("Filme", porta.mediaMetadata.title)
    assertEquals(1.5f, porta.playbackParameters.speed)
    porta.atualizar(porta.estado.copy(estado = "paused"))
    assertFalse(porta.isPlaying)
    assertEquals(Player.STATE_READY, porta.playbackState)
    porta.atualizar(porta.estado.copy(estado = "buffering"))
    assertEquals(Player.STATE_BUFFERING, porta.playbackState)
    assertTrue(porta.isLoading)
    porta.atualizar(porta.estado.copy(estado = "ended"))
    assertEquals(Player.STATE_ENDED, porta.playbackState)
    porta.atualizar(porta.estado.copy(estado = "error"))
    assertEquals(Player.STATE_IDLE, porta.playbackState)
    assertNotNull(porta.playerError)
  }

  @Test fun trocaDeItemNaoConservaPosicaoOuComandosAntigos() {
    val porta = porta()
    porta.atualizar(EstadoSessao(titulo = "Primeiro", estado = "playing", comandos = setOf("next", "seek")))
    assertTrue(porta.isCommandAvailable(Player.COMMAND_SEEK_TO_NEXT))
    porta.atualizar(EstadoSessao(titulo = "Segundo", subtitulo = "Outro", posicaoMs = 5000, estado = "paused"))
    assertEquals("Segundo", porta.mediaMetadata.title)
    assertEquals(5000L, porta.currentPosition)
    assertFalse(porta.isCommandAvailable(Player.COMMAND_SEEK_TO_NEXT))
    assertFalse(porta.isCommandAvailable(Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM))
  }

  @Test fun comandosDoSistemaRetornamPelaPortaUnica() {
    val eventos = mutableListOf<Pair<String, Map<String, Any>>>()
    val porta = PortaSessaoPlayer(Looper.getMainLooper()) { acao, args -> eventos.add(acao to args) }
    porta.atualizar(EstadoSessao(titulo = "Item", estado = "paused", duracaoMs = 120000,
      comandos = setOf("play", "pause", "seek", "skipForward", "skipBackward", "next", "previous", "stop", "changeSpeed")))
    porta.play(); porta.pause(); porta.seekTo(5000); porta.seekForward(); porta.seekBack();
    porta.seekToNextMediaItem(); porta.seekToPreviousMediaItem(); porta.setPlaybackSpeed(1.25f); porta.stop()
    assertEquals(listOf("play", "pause", "seek", "skipForward", "skipBackward", "nextTrack", "previousTrack", "setSpeed", "stop"), eventos.map { it.first })
    assertEquals(5000L, eventos[2].second["position"])
    assertEquals(10000L, porta.seekForwardIncrement)
    assertEquals(10000L, porta.seekBackIncrement)
  }
}
