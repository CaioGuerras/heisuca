package app.heisuca.mpv

import org.junit.Assert.*
import org.junit.Test

/** Limites reais do cache mpv, não uma cópia da fórmula em Dart. */
class HeisucaBufferBudgetTest {
  private val mib = 1024L * 1024L

  @Test fun `automatico preserva politica e heap desconhecido nao inventa limite`() {
    assertNull(DemuxerBudget.forPreference(0, "extra_large"))
    for (heap in listOf(128, 256, 384, 512, 1024, 4096)) {
      assertEquals(DemuxerBudget.forHeapClassMB(heap), DemuxerBudget.forPreference(heap, "auto"))
    }
  }
  @Test fun `tamanho solicitado cresce sem ultrapassar teto seguro`() {
    for (heap in listOf(128, 256, 384, 512, 1024, 4096)) {
      val auto = DemuxerBudget.forPreference(heap, "auto")!!
      val large = DemuxerBudget.forPreference(heap, "large")!!
      val extra = DemuxerBudget.forPreference(heap, "extra_large")!!
      assertTrue(large.aheadBytes >= auto.aheadBytes)
      assertTrue(extra.aheadBytes >= large.aheadBytes)
      assertTrue(extra.totalBytes <= maxOf(auto.totalBytes, minOf(512 * mib, heap * mib / 2)))
      assertEquals(auto.backBytes, extra.backBytes)
    }
    assertTrue(DemuxerBudget.forPreference(1024, "large")!!.aheadBytes > DemuxerBudget.forPreference(1024, "auto")!!.aheadBytes)
  }
  @Test fun `preferencia maior nao reabre cache reduzido por memoria`() {
    val trimmed = DemuxerBudget(32 * mib, 0)
    val large = DemuxerBudget.forPreference(1024, "extra_large")!!
    assertEquals(trimmed, trimmed.narrowedTo(large))
    val next = trimmed.widenedToward(large)!!
    assertFalse(trimmed.canWiden(next, 4L * 1024 * mib, 128 * mib, true))
  }
}
