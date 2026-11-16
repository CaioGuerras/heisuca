package app.heisuca.sessao

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.util.UnstableApi
import com.google.common.util.concurrent.FutureCallback
import com.google.common.util.concurrent.Futures
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Uma porta por processo, compartilhada por vídeo e música. */
@UnstableApi
object SessaoBridge {
  var estado = EstadoSessao()
    private set
  var onStateChanged: (() -> Unit)? = null
  private var contexto: Context? = null
  private var metodos: MethodChannel? = null
  private var eventos: EventChannel? = null
  private var sink: EventChannel.EventSink? = null
  private var servico: HeisucaSessaoService? = null
  private val principal = Handler(Looper.getMainLooper())
  private var geracaoArte = 0L
  private var artePendente: String? = null
  val temTransporte: Boolean get() = sink != null

  fun attach(context: Context, messenger: BinaryMessenger) {
    contexto = context.applicationContext
    metodos?.setMethodCallHandler(null)
    eventos?.setStreamHandler(null)
    metodos = MethodChannel(messenger, "app.heisuca.sessao/metodos").also { it.setMethodCallHandler(::receber) }
    eventos = EventChannel(messenger, "app.heisuca.sessao/eventos").also {
      it.setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) { sink = events }
        override fun onCancel(arguments: Any?) { sink = null }
      })
    }
  }
  fun detach() {
    limpar()
    metodos?.setMethodCallHandler(null); eventos?.setStreamHandler(null)
    metodos = null; eventos = null; sink = null; contexto = null; onStateChanged = null
  }
  internal fun anexar(servico: HeisucaSessaoService) {
    this.servico = servico
    servico.atualizar(estado)
    artePendente?.let { carregarArte(it, geracaoArte) }
  }
  internal fun desanexar(servico: HeisucaSessaoService) {
    if (this.servico === servico) this.servico = null
  }
  private fun receber(call: MethodCall, result: MethodChannel.Result) {
    try {
      when (call.method) {
        "setMetadata" -> {
          val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
          geracaoArte++
          val anterior = estado
          val id = args["mediaId"] as? String ?: args["title"] as? String ?: ""
          atualizar(estado.copy(mediaId = id, titulo = args["title"] as? String ?: "",
            subtitulo = args["artist"] as? String ?: "", album = args["album"] as? String,
            artworkUrl = null, duracaoMs = (args["duration"] as? Number)?.toLong()?.coerceAtLeast(0) ?: 0,
            posicaoMs = if (anterior.mediaId == id) anterior.posicaoMs else 0,
            isVideo = args["isVideo"] as? Boolean ?: true))
          iniciar()
          artePendente = args["artworkUrl"] as? String
          artePendente?.let { carregarArte(it, geracaoArte) }
        }
        "setPlaybackState" -> {
          val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
          atualizar(estado.copy(estado = args["state"] as? String ?: "paused",
            posicaoMs = (args["position"] as? Number)?.toLong()?.coerceAtLeast(0) ?: 0,
            velocidade = (args["speed"] as? Number)?.toFloat()?.takeIf { it.isFinite() && it > 0 } ?: 1f))
          if (estado.tocando) iniciar()
        }
        "enableControls", "disableControls" -> {
          val comandos = (call.arguments as? List<*>)?.filterIsInstance<String>()?.toSet() ?: emptySet()
          atualizar(estado.copy(comandos = if (call.method == "enableControls") estado.comandos + comandos else estado.comandos - comandos))
        }
        "setBackgroundMode" -> Unit // A Media3 decide a promoção com base no estado confirmado do transporte.
        "clear" -> limpar()
        else -> { result.notImplemented(); return }
      }
      result.success(null)
    } catch (e: IllegalStateException) {
      result.error("sessao_indisponivel", "Não foi possível manter os controles do sistema.", null)
    }
  }
  private fun iniciar() {
    if (servico != null || !estado.temItem) return
    contexto?.startService(Intent(contexto, HeisucaSessaoService::class.java))
  }
  internal fun atualizar(novo: EstadoSessao) {
    estado = novo
    contexto?.let { UltimoItemSessao.salvar(it, novo) }
    servico?.atualizar(novo)
    onStateChanged?.invoke()
  }
  private fun limpar() {
    geracaoArte++
    artePendente = null
    estado = EstadoSessao()
    servico?.atualizar(estado)
    servico?.encerrar()
    contexto?.stopService(Intent(contexto, HeisucaSessaoService::class.java))
    onStateChanged?.invoke()
  }
  private fun carregarArte(url: String, geracao: Long) {
    val loader = servico?.arte ?: return
    Futures.addCallback(loader.guardar(Uri.parse(url)), object : FutureCallback<Uri> {
      override fun onSuccess(uri: Uri) {
        principal.post { if (geracao == geracaoArte && estado.temItem) atualizar(estado.copy(artworkUrl = uri.toString())) }
      }
      override fun onFailure(t: Throwable) { /* A ausência de capa não interrompe a reprodução. */ }
    }, { comando -> comando.run() })
  }
  fun dispatch(acao: String) {
    when (acao) {
      "play" -> if ("play" in estado.comandos) enviar("play")
      "pause" -> if ("pause" in estado.comandos) enviar("pause")
      "togglePlayPause" -> dispatch(if (estado.tocando) "pause" else "play")
      "next", "nextTrack" -> if ("next" in estado.comandos) enviar("nextTrack")
      "previous", "previousTrack" -> if ("previous" in estado.comandos) enviar("previousTrack")
      "skipForward", "skipBackward" -> if (acao in estado.comandos) enviar(acao, mapOf("interval" to 10000L))
      "stop" -> if ("stop" in estado.comandos) enviar("stop")
    }
  }
  internal fun enviar(acao: String, args: Map<String, Any> = emptyMap()) { sink?.success(mapOf("type" to acao) + args) }
}
