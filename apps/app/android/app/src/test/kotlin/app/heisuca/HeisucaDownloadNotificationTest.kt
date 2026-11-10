package app.heisuca

import com.bbflight.background_downloader.*
import org.junit.Assert.*
import org.junit.Test

class HeisucaDownloadNotificationTest {
  private val config = NotificationConfig(null, null, null, null, null, true, false, "heisuca_downloads")
  private fun task(id: String) = Task(taskId = id, url = "https://example.invalid/video", filename = "$id.mp4",
    headers = emptyMap(), baseDirectory = BaseDirectory.temporary, group = "downloads",
    updates = Updates.statusAndProgress, allowPause = true, taskType = "DownloadTask")

  @Test fun grupoPausadoNaoAnunciaDownloadConcluido() {
    val group = GroupNotification("heisuca_downloads", config)
    val task = task("a")
    group.update(task, NotificationType.running)
    assertTrue(group.update(task, NotificationType.paused))
    assertFalse(group.isFinished)
    assertEquals(0, group.numFinished)
    assertEquals(setOf(task), group.pausedTasks)
    assertTrue(group.runningTasks.isEmpty())
    group.update(task, NotificationType.running)
    group.update(task, NotificationType.complete)
    assertTrue(group.isFinished)
  }
  @Test fun cancelarEPausarUsamSomenteTarefasDoGrupo() {
    val first = GroupNotification("a", config)
    val second = GroupNotification("b", config)
    val a = task("a"); val b = task("b")
    first.update(a, NotificationType.running)
    second.update(b, NotificationType.running)
    assertEquals(setOf(a), first.runningTasks)
    assertFalse(first.runningTasks.contains(b))
    first.update(a, NotificationType.canceled)
    assertTrue(first.isFinished)
    assertEquals(setOf(b), second.runningTasks)
  }
}
