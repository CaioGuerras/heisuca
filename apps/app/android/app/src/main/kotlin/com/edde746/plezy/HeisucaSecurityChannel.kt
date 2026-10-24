package com.edde746.plezy

import android.app.Activity
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.hardware.fingerprint.FingerprintManager
import android.os.Build
import android.os.CancellationSignal
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Autenticação do Android: nenhuma digital, senha ou PIN passa pelo Dart. */
class HeisucaSecurityChannel(private val activity: Activity) {
  private var signal: CancellationSignal? = null
  private var pending: MethodChannel.Result? = null
  private fun finish(ok: Boolean, expected: MethodChannel.Result? = pending) { if (pending !== expected) return; val r = pending; pending = null; signal = null; r?.success(ok) }
  @Suppress("DEPRECATION")
  private fun available(): Boolean = when {
    Build.VERSION.SDK_INT >= 30 -> activity.getSystemService(BiometricManager::class.java)
      ?.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS
    Build.VERSION.SDK_INT >= 29 -> activity.getSystemService(BiometricManager::class.java)
      ?.canAuthenticate() == BiometricManager.BIOMETRIC_SUCCESS
    Build.VERSION.SDK_INT >= 28 -> activity.getSystemService(FingerprintManager::class.java)
      ?.let { it.isHardwareDetected && it.hasEnrolledFingerprints() } == true
    else -> false
  }
  fun attach(messenger: BinaryMessenger) {
    MethodChannel(messenger, "app.heisuca/security").setMethodCallHandler { call, result ->
      when (call.method) {
        "available" -> result.success(available() && (call.argument<Boolean>("deviceCredential") != true || Build.VERSION.SDK_INT >= 29))
        "authenticate" -> {
          if (Build.VERSION.SDK_INT < 28 || pending != null) result.success(false) else authenticate(call, result)
        }
        else -> result.notImplemented()
      }
    }
  }
  // Android 9+ (BiometricPrompt, mainExecutor): isolado para o lint NewApi enxergar a guarda de versão.
  @RequiresApi(28)
  private fun authenticate(call: MethodCall, result: MethodChannel.Result) {
    pending = result
    try {
      val builder = BiometricPrompt.Builder(activity).setTitle("Heisuca")
        .setSubtitle(call.argument<String>("reason") ?: "Confirme sua identidade")
      val credential = call.argument<Boolean>("deviceCredential") == true && Build.VERSION.SDK_INT >= 29
      if (Build.VERSION.SDK_INT >= 30) {
        builder.setAllowedAuthenticators(
          BiometricManager.Authenticators.BIOMETRIC_STRONG or
            if (credential) BiometricManager.Authenticators.DEVICE_CREDENTIAL else 0)
      } else if (credential && Build.VERSION.SDK_INT >= 29) {
        @Suppress("DEPRECATION")
        builder.setDeviceCredentialAllowed(true)
      }
      if (!credential) builder.setNegativeButton("Cancelar", activity.mainExecutor) { _, _ -> finish(false, result) }
      val cancel = CancellationSignal(); signal = cancel
      builder.build().authenticate(cancel, activity.mainExecutor, object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationSucceeded(authentication: BiometricPrompt.AuthenticationResult) { finish(true, result) }
        override fun onAuthenticationError(code: Int, message: CharSequence) { finish(false, result) }
      })
    } catch (_: Exception) { finish(false, result) }
  }

  fun dispose() { signal?.cancel(); finish(false) }
}
