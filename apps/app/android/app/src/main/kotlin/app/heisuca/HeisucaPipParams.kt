package app.heisuca

import android.app.PictureInPictureParams
import android.graphics.Rect
import android.os.Build
import android.util.Rational
import androidx.annotation.RequiresApi
import kotlin.math.roundToInt

/** Origem é a imagem contida na janela, sem levar as barras pretas para a animação. */
internal fun pipImageRect(bounds: Rect, width: Int, height: Int): Rect {
  if (bounds.isEmpty || width <= 0 || height <= 0) return Rect(bounds)
  val scale = minOf(bounds.width().toDouble() / width, bounds.height().toDouble() / height)
  val w = (width * scale).roundToInt().coerceAtLeast(1)
  val h = (height * scale).roundToInt().coerceAtLeast(1)
  val left = bounds.left + (bounds.width() - w) / 2
  val top = bounds.top + (bounds.height() - h) / 2
  return Rect(left, top, left + w, top + h)
}

@RequiresApi(Build.VERSION_CODES.O)
internal fun heisucaPipParams(width: Int, height: Int, source: Rect,
    autoEnterEnabled: Boolean?): PictureInPictureParams {
  val aspect = if (width <= 0 || height <= 0) 16.0 / 9 else width.toDouble() / height
  val ratio = when {
    aspect < 1.0 / 2.39 -> Rational(100, 239)
    aspect > 2.39 -> Rational(239, 100)
    width <= 0 || height <= 0 -> Rational(16, 9)
    else -> Rational(width, height)
  }
  val builder = PictureInPictureParams.Builder().setAspectRatio(ratio)
  if (!source.isEmpty) builder.setSourceRectHint(pipImageRect(source, width, height))
  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
    // O vídeo e a camada libass são superfícies distintas; o resize contínuo causa artefatos.
    builder.setSeamlessResizeEnabled(false)
    if (autoEnterEnabled != null) builder.setAutoEnterEnabled(autoEnterEnabled)
  }
  return builder.build()
}
