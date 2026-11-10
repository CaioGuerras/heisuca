package app.heisuca.updates

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.StatFs
import android.provider.Settings
import androidx.core.content.FileProvider
import app.heisuca.BuildConfig
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

/** Só a variante direta registra o canal. A decisão final pertence ao instalador do Android. */
class ApkInstaller(private val atividade: Activity) : MethodChannel.MethodCallHandler {
  private val executorCriado = lazy { Executors.newSingleThreadExecutor { Thread(it, "heisuca-atualizador").apply { isDaemon = true } } }
  private val executor by executorCriado
  private var canal: MethodChannel? = null
  private var fechado = false

  fun registrar(mensageiro: BinaryMessenger) {
    if (!BuildConfig.HEISUCA_ATUALIZADOR) return
    canal = MethodChannel(mensageiro, "app.heisuca/updates").also { it.setMethodCallHandler(this) }
  }

  @Suppress("DEPRECATION")
  override fun onMethodCall(chamada: MethodCall, resultado: MethodChannel.Result) {
    if (!BuildConfig.HEISUCA_ATUALIZADOR || fechado) { resultado.error("desligado", null, null); return }
    when (chamada.method) {
      "estado" -> {
        val atual = atividade.packageManager.getPackageInfo(atividade.packageName, 0)
        resultado.success(mapOf("habilitado" to true, "build" to versao(atual),
          "versao" to (atual.versionName ?: ""), "abis" to Build.SUPPORTED_ABIS.toList(),
          "espacoLivre" to StatFs(atividade.cacheDir.path).availableBytes))
      }
      "escolherAbi" -> resultado.success(PoliticaApk.escolherAbi(
        chamada.argument<List<String>>("abis").orEmpty().take(8), Build.SUPPORTED_ABIS.toList()))
      "validar", "instalar" -> executor.execute {
        val arquivo = chamada.argument<String>("arquivo")?.let { File(it) }
        val permitido = arquivo != null && PoliticaApk.arquivoPermitido(atividade.cacheDir, arquivo)
        val valido = try {
          permitido && conferir(arquivo!!, chamada)
        } catch (_: Exception) { false }
        if (!valido && permitido) { try { arquivo.delete() } catch (_: Exception) { /* Nunca instalar um arquivo rejeitado. */ } }
        atividade.runOnUiThread {
          if (atividade.isDestroyed || atividade.isFinishing) { resultado.error("encerrado", null, null) }
          else if (!valido) { resultado.error("arquivoInvalido", null, null) }
          else if (chamada.method == "validar") { resultado.success(true) }
          else entregar(arquivo!!, resultado)
        }
      }
      else -> resultado.notImplemented()
    }
  }

  @Suppress("DEPRECATION")
  private fun conferir(arquivo: File, chamada: MethodCall): Boolean {
    val bytes = chamada.argument<Number>("bytes")?.toLong() ?: return false
    val hash = chamada.argument<String>("sha256") ?: return false
    if (!PoliticaApk.conteudoValido(arquivo, bytes, hash)) return false
    val flags = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
    val apk = atividade.packageManager.getPackageArchiveInfo(arquivo.path, flags) ?: return false
    val instalado = atividade.packageManager.getPackageInfo(atividade.packageName, flags)
    return PoliticaApk.identidadeValida(atividade.packageName, versao(instalado),
      chamada.argument<Number>("build")?.toLong() ?: return false,
      chamada.argument<String>("assinatura") ?: return false, assinaturas(instalado),
      IdentidadeApk(apk.packageName, versao(apk), assinaturas(apk)))
  }

  @Suppress("DEPRECATION")
  private fun assinaturas(info: PackageInfo): Set<String> {
    val certificados = if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures
    return certificados.orEmpty().map { assinatura ->
      MessageDigest.getInstance("SHA-256").digest(assinatura.toByteArray()).joinToString("") { "%02x".format(it) }
    }.toSet()
  }

  @Suppress("DEPRECATION")
  private fun versao(info: PackageInfo): Long = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

  @Suppress("DEPRECATION")
  private fun entregar(arquivo: File, resultado: MethodChannel.Result) {
    val permitido = if (Build.VERSION.SDK_INT >= 26) atividade.packageManager.canRequestPackageInstalls()
      else Settings.Secure.getInt(atividade.contentResolver, Settings.Secure.INSTALL_NON_MARKET_APPS, 0) == 1
    if (!permitido) {
      try {
        val tela = if (Build.VERSION.SDK_INT >= 26) Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
          Uri.parse("package:${atividade.packageName}")) else Intent(Settings.ACTION_SECURITY_SETTINGS)
        atividade.startActivity(tela)
        resultado.success("permissao")
      } catch (_: Exception) { resultado.success("permissaoManual") }
      return
    }
    try {
      val uri = FileProvider.getUriForFile(atividade, "${atividade.packageName}.fileprovider", arquivo)
      val pedido = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
        setDataAndType(uri, "application/vnd.android.package-archive")
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        clipData = ClipData.newRawUri("Atualização Heisuca", uri)
      }
      atividade.startActivity(pedido)
      resultado.success("aberto")
    } catch (_: Exception) { resultado.error("instaladorIndisponivel", null, null) }
  }

  fun fechar() {
    fechado = true
    canal?.setMethodCallHandler(null)
    // O executor só existe quando uma validação foi pedida; encerramento não interrompe arquivos.
    if (executorCriado.isInitialized()) executor.shutdown()
    canal = null
  }
}
