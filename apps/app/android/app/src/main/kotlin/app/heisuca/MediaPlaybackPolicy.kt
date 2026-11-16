package app.heisuca

import android.app.ActivityManager
import android.content.Context

/** Consulta só o serviço deste processo; um pedido de FGS não prova que ele iniciou. */
internal fun hasMediaPlaybackService(context: Context): Boolean = runCatching {
  @Suppress("DEPRECATION")
  val services = (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
    .getRunningServices(Int.MAX_VALUE)
  services.any {
    it.service.packageName == context.packageName && it.foreground &&
      it.service.className == "app.heisuca.sessao.HeisucaSessaoService"
  }
}.getOrDefault(false)
