package com.edde746.plezy

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * CGFLIX (Etapa 1E): armazenamento seguro pequeno para o cookie de sessão do Seerr.
 * O valor é cifrado com AES-GCM por uma chave do Android Keystore (não sai do aparelho e não
 * entra em backup) e só o texto cifrado vai para um SharedPreferences próprio. Sem dependência
 * nova. As operações rodam numa thread própria; a resposta volta na principal.
 */
internal object CgflixSecureStoreChannel {
  private const val TAG = "CgflixSecureStore"
  private const val CHANNEL = "br.com.docaio.cgflix/secure_store"
  private const val KEY_ALIAS = "cgflix_secure_store_v1"
  private const val PREFS = "cgflix_secure_store"
  private const val TRANSFORMATION = "AES/GCM/NoPadding"
  private const val IV_BYTES = 12
  private const val TAG_BITS = 128

  private val worker = Executors.newSingleThreadExecutor()

  fun register(messenger: BinaryMessenger, context: Context) {
    val appContext = context.applicationContext
    val main = Handler(Looper.getMainLooper())
    MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
      val key = call.argument<String>("key")
      if (key.isNullOrEmpty()) {
        result.error("bad_args", "key is required", null)
        return@setMethodCallHandler
      }
      if (call.method !in setOf("read", "write", "delete")) {
        result.notImplemented()
        return@setMethodCallHandler
      }
      worker.execute {
        try {
          val value =
            when (call.method) {
              "read" -> read(appContext, key)
              "write" -> write(appContext, key, call.argument<String>("value") ?: "")
              else -> prefs(appContext).edit().remove(key).apply()
            }
          main.post { result.success(value as? String) }
        } catch (e: Exception) {
          // Nunca loga o valor: só o tipo do erro.
          Log.w(TAG, "falhou: ${call.method} (${e.javaClass.simpleName})")
          main.post { result.error("secure_store", e.javaClass.simpleName, null) }
        }
      }
    }
  }

  private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

  private fun secretKey(): SecretKey {
    val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
    val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
    generator.init(
      KeyGenParameterSpec
        .Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
        .setKeySize(256)
        .build()
    )
    return generator.generateKey()
  }

  private fun write(context: Context, key: String, value: String) {
    val cipher = Cipher.getInstance(TRANSFORMATION)
    cipher.init(Cipher.ENCRYPT_MODE, secretKey())
    val sealed = cipher.iv + cipher.doFinal(value.toByteArray(Charsets.UTF_8))
    prefs(context).edit().putString(key, Base64.encodeToString(sealed, Base64.NO_WRAP)).apply()
  }

  private fun read(context: Context, key: String): String? {
    val stored = prefs(context).getString(key, null) ?: return null
    return try {
      val sealed = Base64.decode(stored, Base64.NO_WRAP)
      val cipher = Cipher.getInstance(TRANSFORMATION)
      cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(TAG_BITS, sealed, 0, IV_BYTES))
      String(cipher.doFinal(sealed, IV_BYTES, sealed.size - IV_BYTES), Charsets.UTF_8)
    } catch (e: Exception) {
      // Chave trocada (app reinstalado, Keystore limpo): o valor se perdeu; o app entra de novo.
      Log.w(TAG, "valor ilegível, apagando (${e.javaClass.simpleName})")
      prefs(context).edit().remove(key).apply()
      null
    }
  }
}
