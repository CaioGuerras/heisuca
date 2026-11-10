package app.heisuca.sessao

import android.content.Intent
import android.media.AudioManager
import android.os.Looper
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class RotaAudioSessaoTest {
  @Test fun retiradaDoFonePausaSomenteOTransporteAtivoAutorizado() {
    val contexto = RuntimeEnvironment.getApplication()
    var estado = EstadoSessao(titulo = "Item", estado = "playing", comandos = setOf("pause"))
    val acoes = mutableListOf<String>()
    val rota = RotaAudioSessao(contexto, { estado }, acoes::add)
    rota.registrar()
    fun retirar() { contexto.sendBroadcast(Intent(AudioManager.ACTION_AUDIO_BECOMING_NOISY)); shadowOf(Looper.getMainLooper()).idle() }
    retirar()
    assertEquals(listOf("pause"), acoes)
    estado = estado.copy(estado = "paused")
    retirar()
    assertEquals(1, acoes.size)
    estado = estado.copy(estado = "buffering")
    retirar()
    assertEquals(listOf("pause", "pause"), acoes)
    estado = estado.copy(comandos = emptySet())
    retirar()
    assertEquals(2, acoes.size)
    rota.fechar(); rota.fechar()
    estado = estado.copy(estado = "playing", comandos = setOf("pause"))
    retirar()
    assertEquals(2, acoes.size)
  }
}
