package app.heisuca.sessao

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import androidx.media3.common.util.UnstableApi
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.ExecutionException
import java.util.concurrent.TimeUnit

@UnstableApi
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class ArteRetomadaSessaoTest {
  private val contexto: Context get() = RuntimeEnvironment.getApplication()

  @Test fun imagemGrandeViraCapaPequenaSemPonteDeBitmap() {
    val loader = ArteSessaoLoader(contexto)
    try {
      val imagem = Bitmap.createBitmap(1024, 2048, Bitmap.Config.ARGB_8888)
      val saida = ByteArrayOutputStream()
      imagem.compress(Bitmap.CompressFormat.PNG, 100, saida)
      val capa = loader.decodeBitmap(saida.toByteArray()).get(10, TimeUnit.SECONDS)
      assertEquals(256, capa.width)
      assertEquals(512, capa.height)
    } finally { loader.fechar() }
  }

  @Test fun segundaLeituraUsaOBitmapDoCache() {
    val loader = ArteSessaoLoader(contexto)
    try {
      val pasta = File(contexto.cacheDir, "arte-sessao").apply { mkdirs() }
      val arquivo = File(pasta, "capa-pequena.png")
      val imagem = Bitmap.createBitmap(16, 16, Bitmap.Config.ARGB_8888)
      arquivo.outputStream().use { imagem.compress(Bitmap.CompressFormat.PNG, 100, it) }
      val primeira = loader.loadBitmap(Uri.fromFile(arquivo)).get(10, TimeUnit.SECONDS)
      val segunda = loader.loadBitmap(Uri.fromFile(arquivo)).get(10, TimeUnit.SECONDS)
      assertSame(primeira, segunda)
    } finally { loader.fechar() }
  }

  @Test fun imagemInvalidaOuOrigemInseguraNaoSaiDoCachePrivado() {
    val loader = ArteSessaoLoader(contexto)
    try {
      for (uri in listOf(Uri.parse("http://servidor.invalid/capa"), Uri.parse("content://outro/capa"),
          Uri.fromFile(File(contexto.cacheDir, "fora-do-cache.png")))) {
        try { loader.loadBitmap(uri).get(10, TimeUnit.SECONDS); fail("Origem indevida aceita: ${uri.scheme}") }
        catch (e: ExecutionException) { assertTrue(e.cause is java.io.IOException) }
      }
      try { loader.decodeBitmap(byteArrayOf(1, 2, 3)).get(10, TimeUnit.SECONDS); fail("Imagem inválida aceita") }
      catch (e: ExecutionException) { assertTrue(e.cause is java.io.IOException) }
    } finally { loader.fechar() }
  }

  @Test fun ultimoItemNaoPersisteUrlAutenticadaNemApagaPosicaoNoClear() {
    val estado = EstadoSessao(mediaId = "42", titulo = "Filme", subtitulo = "2026", posicaoMs = 23000,
      artworkUrl = "https://servidor.invalid/capa?token=sintetico", duracaoMs = 120000)
    UltimoItemSessao.salvar(contexto, estado)
    UltimoItemSessao.salvar(contexto, EstadoSessao())
    val ultimo = requireNotNull(UltimoItemSessao.ler(contexto))
    assertEquals("42", ultimo.mediaId)
    assertEquals("Filme", ultimo.titulo)
    assertEquals(23000L, ultimo.posicaoMs)
    assertNull(ultimo.artworkUrl)
  }

  @Test fun retomadaOfereceMetadadosMasNaoInventaMotorComProcessoFechado() {
    val ultimo = EstadoSessao(mediaId = "42", titulo = "Filme", posicaoMs = 23000)
    val apresentacao = RetomadaSessao.preparar(ultimo, EstadoSessao(), false, false).get()
    assertEquals("Filme", apresentacao.mediaItems.single().mediaMetadata.title)
    assertEquals(23000L, apresentacao.startPositionMs)
    try { RetomadaSessao.preparar(ultimo, EstadoSessao(), false, true).get(); fail("Retomada sem transporte foi aceita") }
    catch (e: ExecutionException) { assertTrue(e.cause is UnsupportedOperationException) }
    val retomada = RetomadaSessao.preparar(ultimo, ultimo, true, true).get()
    assertEquals(23000L, retomada.startPositionMs)
  }
}
