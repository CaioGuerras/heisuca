package app.heisuca.updates

import java.io.File
import java.security.MessageDigest

data class IdentidadeApk(val pacote: String, val build: Long, val assinaturas: Set<String>)

object PoliticaApk {
  fun escolherAbi(disponiveis: List<String>, suportadas: List<String>): String? =
    suportadas.firstOrNull { it in disponiveis && it in setOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64") }
      ?: "universal".takeIf { it in disponiveis }
  fun identidadeValida(pacote: String, instalado: Long, esperado: Long, assinatura: String,
    assinaturasAtuais: Set<String>, arquivo: IdentidadeApk): Boolean {
    val certificado = assinatura.lowercase()
    return Regex("[0-9a-f]{64}").matches(certificado) && esperado > instalado &&
      arquivo.pacote == pacote && arquivo.build == esperado &&
      arquivo.assinaturas.map { it.lowercase() }.toSet() == setOf(certificado) &&
      certificado in assinaturasAtuais.map { it.lowercase() }
  }
  fun arquivoPermitido(cache: File, arquivo: File): Boolean = try {
    val real = arquivo.canonicalFile
    val pasta = File(cache, "updates").canonicalFile
    real.isFile && real.extension == "apk" && real.parentFile == pasta && arquivo.absoluteFile.parentFile.canonicalFile == pasta
  } catch (_: Exception) { false }
  fun conteudoValido(arquivo: File, bytes: Long, sha256: String): Boolean = try {
    if (bytes <= 0 || bytes > 1024L * 1024 * 1024 || arquivo.length() != bytes || !Regex("[0-9a-fA-F]{64}").matches(sha256)) {
      false
    } else {
      val resumo = MessageDigest.getInstance("SHA-256")
      arquivo.inputStream().buffered().use { entrada ->
        val parte = ByteArray(64 * 1024)
        while (true) {
          val lidos = entrada.read(parte)
          if (lidos < 0) break
          resumo.update(parte, 0, lidos)
        }
      }
      resumo.digest().joinToString("") { "%02x".format(it) }.equals(sha256, ignoreCase = true)
    }
  } catch (_: Exception) { false }
}
