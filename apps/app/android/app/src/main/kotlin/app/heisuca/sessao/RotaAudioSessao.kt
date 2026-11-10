package app.heisuca.sessao

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import androidx.core.content.ContextCompat

/** A saída de áudio que desaparece não deve transferir o som ao alto-falante. */
internal class RotaAudioSessao(
  private val contexto: Context,
  private val estado: () -> EstadoSessao,
  private val enviar: (String) -> Unit,
) {
  private var registrado = false
  private val receiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      val atual = estado()
      if (intent.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY &&
        (atual.tocando || atual.estado == "buffering") && "pause" in atual.comandos) enviar("pause")
    }
  }
  fun registrar() {
    if (registrado) return
    ContextCompat.registerReceiver(contexto, receiver, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY),
      ContextCompat.RECEIVER_NOT_EXPORTED)
    registrado = true
  }
  fun fechar() {
    if (!registrado) return
    contexto.unregisterReceiver(receiver)
    registrado = false
  }
}
