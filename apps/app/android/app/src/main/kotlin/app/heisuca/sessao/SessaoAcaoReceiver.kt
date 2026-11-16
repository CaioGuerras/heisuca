package app.heisuca.sessao

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.media3.common.util.UnstableApi

/** Intent explícito e imutável dos botões da janela flutuante. */
@UnstableApi
class SessaoAcaoReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action == "app.heisuca.sessao.PIP") intent.getStringExtra("acao")?.let(SessaoBridge::dispatch)
  }
}
