package app.heisuca

import java.io.File

/**
 * Contenção dos arquivos que o app entrega ao player externo pelo FileProvider.
 *
 * O FileProvider tem `root-path` (os downloads padrão ficam em `<dados>/app_flutter/downloads`, fora de
 * `files/` e `cache/`), então a trava fica aqui: o caminho canônico (segue symlink e `..`) não pode cair
 * dentro dos dados privados do app, salvo em `app_flutter/downloads` e no cache. Assim `shared_prefs`,
 * `databases`, `files`, `no_backup` e o resto de `app_flutter` nunca ganham URI.
 * Fora dos dados do app (cartão SD, pasta de download escolhida pelo usuário) é aceito: só o caminho do
 * arquivo chega ao Kotlin.
 */
internal object ExternalFileContainment {
  /** Devolve o arquivo canônico quando pode ser compartilhado, ou null quando deve ser recusado. */
  fun resolveShareable(path: String, privateRoots: List<File>, allowedInsidePrivate: List<File>): File? {
    if (path.isBlank() || path.contains('\u0000')) return null
    val canonical = try {
      File(path).canonicalFile
    } catch (_: java.io.IOException) {
      return null
    }
    val roots = privateRoots.map(::canonicalOrSelf)
    if (roots.none { isInside(canonical, it) }) return canonical
    val exceptions = allowedInsidePrivate.map(::canonicalOrSelf)
    return if (exceptions.any { isInside(canonical, it) }) canonical else null
  }

  private fun canonicalOrSelf(file: File): File = try {
    file.canonicalFile
  } catch (_: java.io.IOException) {
    file.absoluteFile
  }

  /** Compara por componentes de caminho: `/a/app_flutter2` não está dentro de `/a/app_flutter`. */
  private fun isInside(file: File, root: File): Boolean {
    var current: File? = file
    while (current != null) {
      if (current == root) return true
      current = current.parentFile
    }
    return false
  }
}
