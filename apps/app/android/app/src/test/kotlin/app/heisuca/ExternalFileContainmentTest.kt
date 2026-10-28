package app.heisuca

import java.io.File
import java.nio.file.Files
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

class ExternalFileContainmentTest {
  private lateinit var base: File
  private lateinit var dataDir: File
  private lateinit var sdCard: File
  private lateinit var roots: List<File>
  private lateinit var allowed: List<File>

  @Before
  fun setUp() {
    base = Files.createTempDirectory("heisuca-contencao").toFile().canonicalFile
    dataDir = File(base, "data/data/app.heisuca.player.teste").apply { mkdirs() }
    for (d in listOf("app_flutter/downloads/Series", "shared_prefs", "databases", "files", "cache", "no_backup")) {
      File(dataDir, d).mkdirs()
    }
    sdCard = File(base, "storage/1234-ABCD/Filmes").apply { mkdirs() }
    roots = listOf(dataDir)
    allowed = listOf(File(dataDir, "app_flutter/downloads"), File(dataDir, "cache"))
  }

  @After
  fun tearDown() {
    base.deleteRecursively()
  }

  private fun resolve(path: String) = ExternalFileContainment.resolveShareable(path, roots, allowed)

  @Test
  fun downloadNormalPassa() {
    val video = File(dataDir, "app_flutter/downloads/Series/S01E01 [ab12].mkv").apply { writeText("x") }
    assertEquals(video.canonicalFile, resolve(video.path))
  }

  @Test
  fun legendaAoLadoPassa() {
    val legenda = File(dataDir, "app_flutter/downloads/Series/S01E01 [ab12].por.srt").apply { writeText("x") }
    assertNotNull(resolve(legenda.path))
  }

  @Test
  fun cachePassa() {
    assertNotNull(resolve(File(dataDir, "cache/legenda.srt").path))
  }

  @Test
  fun pontoPontoSaindoParaSharedPrefsEhRecusado() {
    assertNull(resolve(File(dataDir, "app_flutter/downloads/../../shared_prefs/x.xml").path))
    assertNull(resolve(File(dataDir, "app_flutter/downloads/Series/../../../databases/plezy_downloads.db").path))
  }

  @Test
  fun symlinkParaDatabasesEhRecusado() {
    val alvo = File(dataDir, "databases/plezy_downloads.db").apply { writeText("x") }
    val elo = File(dataDir, "app_flutter/downloads/Series/falso.mkv")
    Files.createSymbolicLink(elo.toPath(), alvo.toPath())
    assertNull(resolve(elo.path))
  }

  @Test
  fun symlinkParaDiretorioDeSharedPrefsEhRecusado() {
    val elo = File(dataDir, "app_flutter/downloads/pasta")
    Files.createSymbolicLink(elo.toPath(), File(dataDir, "shared_prefs").toPath())
    assertNull(resolve(File(elo, "x.xml").path))
  }

  @Test
  fun caminhoDentroDeSharedPrefsEhRecusado() {
    assertNull(resolve(File(dataDir, "shared_prefs/FlutterSecureStorage.xml").path))
  }

  @Test
  fun outrasPastasPrivadasSaoRecusadas() {
    for (d in listOf("databases/x", "files/x", "no_backup/x", "app_flutter/x", "app_flutter/downloads_outro/x")) {
      assertNull(d, resolve(File(dataDir, d).path))
    }
  }

  @Test
  fun cartaoSdPassa() {
    val video = File(sdCard, "filme.mkv").apply { writeText("x") }
    assertEquals(video.canonicalFile, resolve(video.path))
    assertNotNull(resolve("/storage/1234-ABCD/Filmes/inexistente.mkv"))
  }

  @Test
  fun symlinkDoCartaoParaDentroDoAppEhRecusado() {
    val elo = File(sdCard, "atalho.xml")
    val alvo = File(dataDir, "shared_prefs/x.xml").apply { writeText("x") }
    Files.createSymbolicLink(elo.toPath(), alvo.toPath())
    assertNull(resolve(elo.path))
  }

  @Test
  fun vazioEBrancoSaoRecusados() {
    assertNull(resolve(""))
    assertNull(resolve("   "))
    assertNull(resolve("a\u0000b"))
  }
}
