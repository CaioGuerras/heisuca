package app.heisuca.sessao

import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaSession
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/** O sistema pode apresentar o último item; só um transporte vivo pode voltar a tocá-lo. */
@UnstableApi
internal object RetomadaSessao {
  fun preparar(ultimo: EstadoSessao?, atual: EstadoSessao, conectado: Boolean,
    reproduzir: Boolean): ListenableFuture<MediaSession.MediaItemsWithStartPosition> {
    if (ultimo == null) return Futures.immediateFailedFuture(UnsupportedOperationException("Abra um conteúdo no app."))
    if (reproduzir && (!conectado || !atual.temItem || atual.mediaId != ultimo.mediaId)) {
      return Futures.immediateFailedFuture(UnsupportedOperationException("Abra o conteúdo no app para continuar."))
    }
    return Futures.immediateFuture(MediaSession.MediaItemsWithStartPosition(listOf(PortaSessaoPlayer.item(ultimo)), 0, ultimo.posicaoMs))
  }
}
