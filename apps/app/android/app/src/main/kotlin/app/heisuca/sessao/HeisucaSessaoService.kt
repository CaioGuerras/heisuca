package app.heisuca.sessao

import android.app.PendingIntent
import android.content.Intent
import android.content.res.Configuration
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.DefaultMediaNotificationProvider
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import java.util.Locale

/** A notificação e o ciclo de primeiro plano pertencem à sessão padrão da Media3. */
@UnstableApi
class HeisucaSessaoService : MediaSessionService() {
  private lateinit var porta: PortaSessaoPlayer
  lateinit var arte: ArteSessaoLoader
    private set
  private var sessao: MediaSession? = null
  private var rotaAudio: RotaAudioSessao? = null

  override fun onCreate() {
    super.onCreate()
    criarSessao()
  }
  private fun criarSessao() {
    porta = PortaSessaoPlayer(Looper.getMainLooper(), SessaoBridge::enviar)
    arte = ArteSessaoLoader(this)
    val configuracao = Configuration(resources.configuration).apply { setLocale(Locale.forLanguageTag("pt-BR")) }
    val provider = DefaultMediaNotificationProvider.Builder(createConfigurationContext(configuracao)).build()
    setMediaNotificationProvider(provider)
    val abrir = Intent(this, app.heisuca.MainActivity::class.java)
    val atividade = PendingIntent.getActivity(this, 0, abrir, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    sessao = MediaSession.Builder(this, porta).setId("heisuca").setBitmapLoader(arte)
      .setSessionActivity(atividade).setCallback(object : MediaSession.Callback {
        override fun onConnect(session: MediaSession, controller: MediaSession.ControllerInfo): MediaSession.ConnectionResult {
          if (!controller.isTrusted && controller.packageName != packageName) return MediaSession.ConnectionResult.reject()
          return super.onConnect(session, controller)
        }
        override fun onPlaybackResumption(session: MediaSession, controller: MediaSession.ControllerInfo,
          isForPlayback: Boolean): ListenableFuture<MediaSession.MediaItemsWithStartPosition> {
          return RetomadaSessao.preparar(UltimoItemSessao.ler(this@HeisucaSessaoService),
            SessaoBridge.estado, SessaoBridge.temTransporte, isForPlayback)
        }
        override fun onAddMediaItems(session: MediaSession, controller: MediaSession.ControllerInfo,
          mediaItems: List<MediaItem>): ListenableFuture<List<MediaItem>> {
          val atual = SessaoBridge.estado
          if (!atual.temItem || mediaItems.size != 1 || mediaItems.first().mediaId != atual.mediaId) {
            return Futures.immediateFailedFuture(UnsupportedOperationException("Abra o conteúdo no app."))
          }
          return Futures.immediateFuture(listOf(PortaSessaoPlayer.item(atual)))
        }
      }).build()
    addSession(requireNotNull(sessao))
    SessaoBridge.anexar(this)
    rotaAudio = RotaAudioSessao(this, { SessaoBridge.estado }, SessaoBridge::dispatch).also { it.registrar() }
  }
  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    if (sessao == null) criarSessao()
    return super.onStartCommand(intent, flags, startId)
  }
  fun atualizar(estado: EstadoSessao) { if (sessao != null) porta.atualizar(estado) }
  fun encerrar() {
    val atual = sessao ?: return
    sessao = null
    rotaAudio?.fechar(); rotaAudio = null
    removeSession(atual)
    atual.release(); porta.release(); arte.fechar()
    SessaoBridge.desanexar(this)
    stopForeground(STOP_FOREGROUND_REMOVE)
    stopSelf()
  }
  override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? = sessao
  override fun onDestroy() {
    encerrar()
    super.onDestroy()
  }
}
