package com.edde746.plezy

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
 * CGFLIX (1.5.0): o ícone do app acompanha o tema, como no Telegram e no CGFLIX Lite. Heitor = ícone
 * verde; Isis e Automático = roxo. São dois `activity-alias` no manifesto (`IconeIsis`, ligado por
 * padrão, e `IconeHeitor`); fica ligado só um.
 *
 * O Flutter só avisa o tema desejado; a troca acontece quando o app sai da tela (nenhuma atividade
 * visível), porque alguns aparelhos fecham o app ao trocar o ícone e o launcher leva alguns segundos
 * para mostrar o novo.
 */
internal object CgflixAppIconChannel {
  private const val TAG = "CgflixAppIcon"
  private const val CHANNEL = "br.com.docaio.cgflix/app_icon"
  private const val ISIS = "com.edde746.plezy.IconeIsis"
  private const val HEITOR = "com.edde746.plezy.IconeHeitor"

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
      wanted = if (call.argument<Boolean>("heitor") == true) HEITOR else ISIS
      result.success(null)
    }
  }

  private fun apply(context: Context) {
    val target = wanted ?: return
    val pm = context.packageManager
    val pkg = context.packageName
    val on = ComponentName(pkg, target)
    val off = ComponentName(pkg, if (target == ISIS) HEITOR else ISIS)
    if (isEnabled(pm, on, default = target == ISIS) && !isEnabled(pm, off, default = off.className == ISIS)) return
    try {
      // Primeiro liga o novo: o launcher nunca fica sem ícone
      pm.setComponentEnabledSetting(on, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
      pm.setComponentEnabledSetting(off, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
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
