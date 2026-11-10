package app.heisuca

import android.graphics.Rect
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class HeisucaPipParamsTest {
  @Test fun origemSegueImagemSemBarrasPretas() {
    assertEquals(Rect(0, 218, 1000, 781), pipImageRect(Rect(0, 0, 1000, 1000), 16, 9))
    assertEquals(Rect(250, 100, 750, 1100), pipImageRect(Rect(0, 100, 1000, 1100), 1, 2))
  }
  @Test fun entradaAutomaticaNaoUsaResizeContinuo() {
    val params = heisucaPipParams(1920, 1080, Rect(0, 0, 1920, 1080), true)
    assertEquals(Rect(0, 0, 1920, 1080), params.sourceRectHint)
    assertTrue(params.isAutoEnterEnabled)
    assertFalse(params.isSeamlessResizeEnabled)
  }
  @Test fun tamanhoDesconhecidoNaoCriaOrigemInvalida() {
    val params = heisucaPipParams(0, 0, Rect(), false)
    assertEquals(16f / 9, params.aspectRatio!!.toFloat(), .001f)
    assertFalse(params.isAutoEnterEnabled)
  }
}
