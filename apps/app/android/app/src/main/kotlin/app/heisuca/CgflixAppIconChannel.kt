package app.heisuca

import android.app.Activity
import android.app.Application
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * O ícone acompanha Shikkoku, Hisui ou Sumi; só um alias fica ativo.
 * IconeIsis e IconeHeitor conservam os identificadores históricos das instalações.
 * A troca acontece quando a última tela sai do primeiro plano para preservar o launcher.
 */
internal object CgflixAppIconChannel {
  private const val TAG = "CgflixAppIcon"
  private const val CHANNEL = "br.com.docaio.cgflix/app_icon"
  private const val ISIS = "app.heisuca.IconeIsis"
  private const val HEITOR = "app.heisuca.IconeHeitor"

  private const val SUMI = "app.heisuca.IconeSumi"

  @Volatile private var wanted: String? = null
  private var callbacksRegistered = false

  fun register(messenger: BinaryMessenger, activity: Activity) {
    val app = activity.application
    if (!callbacksRegistered) {
      callbacksRegistered = true
      app.registerActivityLifecycleCallbacks(BackgroundWatcher(app))
    }
    MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
      if (call.method != "setTheme") {
        result.notImplemented()
        return@setMethodCallHandler
      }
      wanted = when (call.argument<String>("tema")) {
        "sumi" -> SUMI
        "hisui" -> HEITOR
        else -> if (call.argument<Boolean>("heitor") == true) HEITOR else ISIS
      }
      result.success(null)
    }
  }

  private fun apply(context: Context) {
    val target = wanted ?: return
    val pm = context.packageManager
    val pkg = context.packageName
    val on = ComponentName(pkg, target)
    val others = listOf(ISIS, HEITOR, SUMI).filter { it != target }.map { ComponentName(pkg, it) }
    if (isEnabled(pm, on, default = target == ISIS) && others.none { isEnabled(pm, it, default = it.className == ISIS) }) return
    try {
      // Primeiro liga o novo: o launcher nunca fica sem ícone.
      pm.setComponentEnabledSetting(on, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
      others.forEach { pm.setComponentEnabledSetting(it, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP) }
    } catch (e: Exception) {
      Log.w(TAG, "não deu para trocar o ícone do app", e)
    }
  }

  private fun isEnabled(pm: PackageManager, component: ComponentName, default: Boolean) = when (pm.getComponentEnabledSetting(component)) {
    PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
    PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> default
    else -> false
  }

  /** Aplica o ícone quando a última tela visível do app sai da tela. */
  private class BackgroundWatcher(private val app: Application) : Application.ActivityLifecycleCallbacks {
    private var started = 0

    override fun onActivityStarted(activity: Activity) {
      started++
    }

    override fun onActivityStopped(activity: Activity) {
      started--
      // Girar a tela recria a atividade: não é sair do app
      if (started <= 0 && !activity.isChangingConfigurations) {
        started = 0
        apply(app)
      }
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

    override fun onActivityResumed(activity: Activity) {}

    override fun onActivityPaused(activity: Activity) {}

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {}
  }
}
