package app.heisuca

import android.app.PictureInPictureParams
import android.app.PendingIntent
import android.app.RemoteAction
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import app.heisuca.sessao.SessaoAcaoReceiver
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

/** A ordem preserva transporte e saltos quando o sistema limita o número de ações. */
internal data class PipControle(val acao: String, val rotulo: String, val icone: Int)

internal fun pipControles(tocando: Boolean, ativo: Boolean, podePular: Boolean, proximo: Boolean): List<PipControle> {
  if (!ativo) return emptyList()
  return buildList {
    add(if (tocando) PipControle("pause", "Pausar", android.R.drawable.ic_media_pause)
        else PipControle("play", "Tocar", android.R.drawable.ic_media_play))
    if (podePular) {
      add(PipControle("skipBackward", "Voltar 10 segundos", android.R.drawable.ic_media_rew))
      add(PipControle("skipForward", "Avançar 10 segundos", android.R.drawable.ic_media_ff))
    }
    if (proximo) add(PipControle("nextTrack", "Próximo", android.R.drawable.ic_media_next))
  }
}

internal fun pipAutomatico(pronto: Boolean, tocando: Boolean, video: Boolean): Boolean = pronto && tocando && video

@RequiresApi(Build.VERSION_CODES.O)
internal fun pipAcoes(context: Context, controles: List<PipControle>): List<RemoteAction> = controles.map { controle ->
  val intent = Intent(context, SessaoAcaoReceiver::class.java)
    .setAction("app.heisuca.sessao.PIP")
    .putExtra("acao", controle.acao)
  val pendingIntent = PendingIntent.getBroadcast(context, controle.acao.hashCode(), intent,
    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
  RemoteAction(Icon.createWithResource(context, controle.icone), controle.rotulo, controle.rotulo, pendingIntent)
}

@RequiresApi(Build.VERSION_CODES.O)
internal fun heisucaPipParams(width: Int, height: Int, source: Rect,
    autoEnterEnabled: Boolean?, actions: List<RemoteAction> = emptyList()): PictureInPictureParams {
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
    builder.setActions(actions)
    if (autoEnterEnabled != null) builder.setAutoEnterEnabled(autoEnterEnabled)
  }
  return builder.build()
}
