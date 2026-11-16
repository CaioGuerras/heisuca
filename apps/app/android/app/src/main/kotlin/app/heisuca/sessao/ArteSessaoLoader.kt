package app.heisuca.sessao

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.LruCache
import androidx.media3.common.util.BitmapLoader
import androidx.media3.common.util.UnstableApi
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.MoreExecutors
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.net.URL
import java.net.HttpURLConnection
import java.security.MessageDigest
import java.util.concurrent.Executors

/** Arte pequena em cache privado; URLs autenticadas nunca viram metadados públicos da sessão. */
@UnstableApi
class ArteSessaoLoader(context: Context) : BitmapLoader {
  private val pasta = File(context.cacheDir, "arte-sessao").apply { mkdirs() }
  private val executor = MoreExecutors.listeningDecorator(Executors.newSingleThreadExecutor())
  private val memoria = object : LruCache<String, Bitmap>(4 * 1024 * 1024) {
    override fun sizeOf(key: String, value: Bitmap): Int = value.allocationByteCount
  }
  override fun supportsMimeType(mimeType: String): Boolean = mimeType.startsWith("image/")
  override fun decodeBitmap(data: ByteArray): ListenableFuture<Bitmap> = executor.submit<Bitmap> { reduzir(data) }
  override fun loadBitmap(uri: Uri): ListenableFuture<Bitmap> {
    memoria.get(uri.toString())?.let { return Futures.immediateFuture(it) }
    return executor.submit<Bitmap> {
      val bytes = if (uri.scheme == "file") {
        val arquivo = File(requireNotNull(uri.path)).canonicalFile
        if (!arquivo.path.startsWith(pasta.canonicalPath + File.separator)) throw IOException("Arte indisponível.")
        if (arquivo.length() > 8 * 1024 * 1024) throw IOException("Imagem muito grande.")
        arquivo.readBytes()
      } else {
        if (uri.scheme != "https") throw IOException("Arte indisponível.")
        val conexao = (URL(uri.toString()).openConnection() as HttpURLConnection).apply {
          connectTimeout = 10000; readTimeout = 10000; instanceFollowRedirects = false
        }
        if (conexao.responseCode !in 200..299) {
          conexao.disconnect()
          throw IOException("Arte indisponível.")
        }
        try { conexao.getInputStream().use { entrada ->
          val saida = ByteArrayOutputStream()
          val bloco = ByteArray(8192)
          while (true) {
            val n = entrada.read(bloco)
            if (n < 0) break
            if (saida.size() + n > 8 * 1024 * 1024) throw IOException("Imagem muito grande.")
            saida.write(bloco, 0, n)
          }
          saida.toByteArray()
        } } finally { conexao.disconnect() }
      }
      reduzir(bytes).also { memoria.put(uri.toString(), it) }
    }
  }
  fun guardar(uri: Uri): ListenableFuture<Uri> {
    if (uri.scheme != "https") return Futures.immediateFailedFuture(IOException("Arte indisponível."))
    val chave = MessageDigest.getInstance("SHA-256").digest(uri.toString().toByteArray()).joinToString("") { "%02x".format(it) }
    val arquivo = File(pasta, "$chave.png")
    if (arquivo.isFile) return Futures.immediateFuture(Uri.fromFile(arquivo))
    return Futures.transform(loadBitmap(uri), { bitmap ->
      arquivo.outputStream().use { bitmap!!.compress(Bitmap.CompressFormat.PNG, 100, it) }
      pasta.listFiles()?.filter { it.isFile && it != arquivo }?.sortedByDescending { it.lastModified() }?.drop(31)?.forEach { it.delete() }
      Uri.fromFile(arquivo)
    }, executor)
  }
  fun fechar() { executor.shutdownNow(); memoria.evictAll() }
  private fun reduzir(bytes: ByteArray): Bitmap {
    if (bytes.size > 8 * 1024 * 1024) throw IOException("Imagem muito grande.")
    val limites = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, limites)
    if (limites.outWidth <= 0 || limites.outHeight <= 0) throw IOException("Imagem inválida.")
    var amostra = 1
    while (maxOf(limites.outWidth, limites.outHeight) / amostra > 1024) amostra *= 2
    val imagem = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = amostra })
      ?: throw IOException("Imagem inválida.")
    val maior = maxOf(imagem.width, imagem.height)
    if (maior <= 512) return imagem
    val escala = 512.0 / maior
    return Bitmap.createScaledBitmap(imagem, (imagem.width * escala).toInt().coerceAtLeast(1),
      (imagem.height * escala).toInt().coerceAtLeast(1), true).also { if (it !== imagem) imagem.recycle() }
  }
}
