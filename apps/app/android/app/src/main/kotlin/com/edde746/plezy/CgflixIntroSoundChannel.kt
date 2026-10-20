package com.edde746.plezy

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

/**
 * CGFLIX: toca o "tum" curto da abertura (res/raw/cgflix_intro.wav, gerado por
 * cgflix-brand/som/gerar_tum.py). Só toca com o aparelho no modo normal: no silencioso ou
 * no vibrar fica quieto. Responde `true` quando tocou.
 *
 * Etapa 1E: o `MediaPlayer.create` (lê e prepara o arquivo, síncrono) roda numa thread
 * própria, fora da thread de UI (pendência da auditoria 1D); a resposta volta na principal.
 */
internal object CgflixIntroSoundChannel {
  private const val TAG = "CgflixIntroSound"
  private const val CHANNEL = "br.com.docaio.cgflix/intro_sound"

  fun register(messenger: BinaryMessenger, context: Context) {
    val appContext = context.applicationContext
    MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "play" -> {
          val main = Handler(Looper.getMainLooper())
          thread(name = "cgflix-intro-sound") {
            val played = play(appContext)
            main.post { result.success(played) }
          }
        }
        else -> result.notImplemented()
      }
    }
  }

  private fun play(context: Context): Boolean {
    val audio = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
    if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL) return false
    return try {
      val player = MediaPlayer.create(
        context,
        R.raw.cgflix_intro,
        AudioAttributes.Builder()
          .setUsage(AudioAttributes.USAGE_MEDIA)
          .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
          .build(),
        audio.generateAudioSessionId()
      ) ?: return false
      player.setOnCompletionListener { it.release() }
      player.start()
      true
    } catch (e: Exception) {
      Log.w(TAG, "som da abertura falhou", e)
      false
    }
  }
}
