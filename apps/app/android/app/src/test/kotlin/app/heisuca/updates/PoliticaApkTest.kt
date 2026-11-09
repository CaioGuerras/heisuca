package app.heisuca.updates

import java.io.File
import java.nio.file.Files
import java.security.MessageDigest
import org.junit.Assert.*
import org.junit.Test

class PoliticaApkTest {
  private val certificado = "a".repeat(64)
  private val pacote = "app.heisuca.player.teste.home"
  private fun validar(apk: IdentidadeApk, esperado: Long = 42, assinatura: String = certificado) =
    PoliticaApk.identidadeValida(pacote, 41, esperado, assinatura, setOf(certificado), apk)

  @Test fun escolheNaOrdemDoAparelho() {
    assertEquals("arm64-v8a", PoliticaApk.escolherAbi(listOf("universal", "armeabi-v7a", "arm64-v8a"), listOf("arm64-v8a", "armeabi-v7a")))
    assertEquals("armeabi-v7a", PoliticaApk.escolherAbi(listOf("arm64-v8a", "armeabi-v7a"), listOf("armeabi-v7a")))
  }
  @Test fun universalEhSomenteReserva() {
    assertEquals("universal", PoliticaApk.escolherAbi(listOf("arm64-v8a", "universal"), listOf("x86_64")))
    assertNull(PoliticaApk.escolherAbi(listOf("arm64-v8a"), listOf("armeabi-v7a")))
  }
  @Test fun pacoteBuildECertificadoValidosPassam() {
    assertTrue(validar(IdentidadeApk(pacote, 42, setOf(certificado))))
  }
  @Test fun assinaturaDoArquivoPrecisaConferirComFeedEInstalado() {
    assertFalse(validar(IdentidadeApk(pacote, 42, setOf("b".repeat(64)))))
    assertFalse(validar(IdentidadeApk(pacote, 42, emptySet())))
    assertFalse(validar(IdentidadeApk(pacote, 42, setOf(certificado, "b".repeat(64)))))
    assertFalse(validar(IdentidadeApk(pacote, 42, setOf("b".repeat(64))), assinatura = "b".repeat(64)))
    assertFalse(validar(IdentidadeApk(pacote, 42, setOf(certificado)), assinatura = "invalida"))
  }
  @Test fun nuncaInstalaOutroPacoteOutroBuildOuDowngrade() {
    assertFalse(validar(IdentidadeApk("outro.app", 42, setOf(certificado))))
    assertFalse(validar(IdentidadeApk(pacote, 43, setOf(certificado))))
    for (build in listOf(0L, 40L, 41L)) {
      assertFalse(validar(IdentidadeApk(pacote, build, setOf(certificado)), esperado = build))
    }
  }
  @Test fun somenteApkDoDiretorioPrivadoDoAtualizador() {
    val cache = Files.createTempDirectory("heisuca-apk-politica-").toFile()
    val pasta = File(cache, "updates").apply { mkdirs() }
    val arquivo = File(pasta, "teste.apk").apply { writeText("arquivo sintetico") }
    assertTrue(PoliticaApk.arquivoPermitido(cache, arquivo))
    assertFalse(PoliticaApk.arquivoPermitido(cache, File(cache, "fora.apk").apply { writeText("fora") }))
    assertFalse(PoliticaApk.arquivoPermitido(cache, File(pasta, "teste.part").apply { writeText("parcial") }))
    val externo = Files.createTempFile("heisuca-fora-", ".apk").toFile()
    val elo = File(pasta, "elo.apk")
    Files.createSymbolicLink(elo.toPath(), externo.toPath())
    assertFalse(PoliticaApk.arquivoPermitido(cache, elo))
    val eloExterno = File(cache, "elo-fora.apk")
    Files.createSymbolicLink(eloExterno.toPath(), arquivo.toPath())
    assertFalse(PoliticaApk.arquivoPermitido(cache, eloExterno))
  }
  @Test fun reconfereConteudoDoArquivoAntesDoIntent() {
    val arquivo = Files.createTempFile("heisuca-conteudo-", ".apk").toFile().apply { writeText("sintetico") }
    val hash = MessageDigest.getInstance("SHA-256").digest(arquivo.readBytes()).joinToString("") { "%02x".format(it) }
    assertTrue(PoliticaApk.conteudoValido(arquivo, arquivo.length(), hash))
    assertFalse(PoliticaApk.conteudoValido(arquivo, arquivo.length() + 1, hash))
    assertFalse(PoliticaApk.conteudoValido(arquivo, arquivo.length(), "0".repeat(64)))
  }
}
