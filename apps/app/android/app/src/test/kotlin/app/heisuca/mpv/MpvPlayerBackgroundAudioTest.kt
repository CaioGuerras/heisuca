package app.heisuca.mpv

import android.app.Activity
import android.os.Looper
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.util.concurrent.ConcurrentLinkedQueue

@RunWith(RobolectricTestRunner::class)
class MpvPlayerBackgroundAudioTest {
  @Test fun superficieRealAposPlaceholderComVidAtivoExecutaSeek() {
    val operations = ConcurrentLinkedQueue<String>()
    val core = MpvPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get(),
      audioOnly = false,
      propertyWriter = { key, value -> operations.add("$key=$value"); Unit },
      commandRunner = { args -> operations.add(args.joinToString(" ")); null })
    core.propertyReaderOverride = { "7" }
    try {
      runBlocking {
        core.handleRealSurfaceAttachedAfterPlaceholder("teste")
      }
      assertTrue("deve executar seek 0 relative exact ao anexar superfície real com vid ativo",
        operations.contains("seek 0 relative exact"))
    } finally { core.dispose() }
  }

  @Test fun superficieRealAposPlaceholderComVidDesligadoNaoExecutaSeek() {
    val operations = ConcurrentLinkedQueue<String>()
    val core = MpvPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get(),
      audioOnly = false,
      propertyWriter = { key, value -> operations.add("$key=$value"); Unit },
      commandRunner = { args -> operations.add(args.joinToString(" ")); null })
    core.propertyReaderOverride = { "no" }
    try {
      runBlocking {
        core.handleRealSurfaceAttachedAfterPlaceholder("teste")
      }
      assertFalse("não deve executar seek se vid for no",
        operations.contains("seek 0 relative exact"))
    } finally { core.dispose() }
  }

  @Test fun reativarVideoRessincronizaNoPontoAtualSemTrocarFaixa() {
    val operations = ConcurrentLinkedQueue<String>()
    val core = MpvPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get(),
      audioOnly = false,
      propertyWriter = { key, value -> operations.add("$key=$value"); Unit },
      commandRunner = { args -> operations.add(args.joinToString(" ")); null })
    core.propertyReaderOverride = { "7" }
    try {
      assertTrue(change(core, true).isSuccess)
      assertTrue(change(core, false).isSuccess)
      assertTrue(change(core, false).isSuccess) // Idempotente: não repete o seek.
      assertEquals(listOf("vid=no", "vid=7", "seek 0 relative exact"), operations.toList())
    } finally { core.dispose() }
  }

  @Test fun somDesligaVideoERestauraExatamenteAFaixaAnterior() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get(),
      audioOnly = false, propertyWriter = { name, value -> writes.add(name to value); Unit },
      commandRunner = { null })
    core.propertyReaderOverride = { "7" }
    try {
      change(core, true)
      change(core, true) // Repetir hidden/paused não perde a seleção anterior.
      change(core, false)
      change(core, false)
      assertEquals(listOf("vid" to "no", "vid" to "7"), writes.toList())
    } finally { core.dispose() }
  }

  @Test fun falhaNaRessincronizacaoNaoConfirmaRestauro() {
    val core = MpvPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get(),
      audioOnly = false, propertyWriter = { _, _ -> Unit },
      commandRunner = { error("seek rejeitado") })
    core.propertyReaderOverride = { "7" }
    try {
      assertTrue(change(core, true).isSuccess)
      assertTrue(change(core, false).isFailure)
      val state = MpvPlayerCore::class.java.getDeclaredField("backgroundVideoTrack").apply { isAccessible = true }
      assertEquals("7", state.get(core))
    } finally { core.dispose() }
  }

  @Test fun videoJaDesligadoNaoBuscaAoVoltar() {
    val commands = ConcurrentLinkedQueue<String>()
    val core = MpvPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get(),
      audioOnly = false, propertyWriter = { _, _ -> Unit },
      commandRunner = { args -> commands.add(args.joinToString(" ")); null })
    core.propertyReaderOverride = { "no" }
    try {
      assertTrue(change(core, true).isSuccess)
      assertTrue(change(core, false).isSuccess)
      assertTrue(commands.isEmpty())
    } finally { core.dispose() }
  }

  @Test fun falhaAoDesligarVideoNaoConfirmaAudioEmSegundoPlano() {
    val core = MpvPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get(),
      audioOnly = false, propertyWriter = { _, _ -> error("rejeitado") })
    core.propertyReaderOverride = { "1" }
    try {
      assertTrue(change(core, true).isFailure)
      val state = MpvPlayerCore::class.java.getDeclaredField("backgroundVideoTrack").apply { isAccessible = true }
      assertNull(state.get(core))
    } finally { core.dispose() }
  }

  @Test fun faixaDesconhecidaNaoEInventada() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get(),
      audioOnly = false, propertyWriter = { name, value -> writes.add(name to value); Unit })
    core.propertyReaderOverride = { null }
    try {
      assertTrue(change(core, true).isFailure)
      assertTrue(writes.isEmpty())
    } finally { core.dispose() }
  }

  private fun change(core: MpvPlayerCore, enabled: Boolean): Result<Unit> {
    var result: Result<Unit>? = null
    core.setBackgroundAudio(enabled) { result = it }
    val deadline = System.nanoTime() + 3_000_000_000L
    while (result == null && System.nanoTime() < deadline) {
      shadowOf(Looper.getMainLooper()).idle()
      Thread.sleep(5)
    }
    assertNotNull("núcleo não respondeu", result)
    return result!!
  }
}
