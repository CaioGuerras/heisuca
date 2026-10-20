package com.edde746.plezy

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.min

/**
 * CGFLIX (Minha conta, 1.5.0): prepara a foto escolhida no seletor do sistema para o Jellyfin.
 * Quadrado central de até 512 px, em JPEG, com a rotação do EXIF aplicada. Decodifica já reduzida
 * (foto de câmera tem 12 MP+) numa thread própria; a resposta volta na principal.
 */
internal object CgflixPhotoChannel {
  private const val CHANNEL = "br.com.docaio.cgflix/photo"
  private const val SIDE = 512

  private val worker = Executors.newSingleThreadExecutor()

  fun register(messenger: BinaryMessenger) {
    val main = Handler(Looper.getMainLooper())
    MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
      if (call.method != "squareJpeg") {
        result.notImplemented()
        return@setMethodCallHandler
      }
      val path = call.argument<String>("path")
      if (path.isNullOrEmpty()) {
        result.error("bad_args", "path is required", null)
        return@setMethodCallHandler
      }
      worker.execute {
        try {
          val bytes = squareJpeg(File(path))
          main.post { result.success(bytes) }
        } catch (e: Throwable) {
          main.post { result.error("decode_failed", e.javaClass.simpleName, null) }
        }
      }
    }
  }

  private fun squareJpeg(file: File): ByteArray {
    val bitmap = decode(file)
    val side = min(bitmap.width, bitmap.height)
    val square = Bitmap.createBitmap(bitmap, (bitmap.width - side) / 2, (bitmap.height - side) / 2, side, side)
    val scaled = if (side > SIDE) Bitmap.createScaledBitmap(square, SIDE, SIDE, true) else square
    return ByteArrayOutputStream().use {
      scaled.compress(Bitmap.CompressFormat.JPEG, 88, it)
      it.toByteArray()
    }
  }

  private fun decode(file: File): Bitmap {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      // ImageDecoder já aplica a rotação do EXIF
      return ImageDecoder.decodeBitmap(ImageDecoder.createSource(file)) { decoder, info, _ ->
        val scale = max(1, min(info.size.width, info.size.height) / SIDE)
        decoder.setTargetSize(info.size.width / scale, info.size.height / scale)
        decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
      }
    }
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(file.path, bounds)
    var sample = 1
    while (min(bounds.outWidth, bounds.outHeight) / (sample * 2) >= SIDE) sample *= 2
    val bitmap =
      BitmapFactory.decodeFile(file.path, BitmapFactory.Options().apply { inSampleSize = sample })
        ?: error("not an image")
    val degrees =
      when (ExifInterface(file.path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
        ExifInterface.ORIENTATION_ROTATE_90 -> 90f
        ExifInterface.ORIENTATION_ROTATE_180 -> 180f
        ExifInterface.ORIENTATION_ROTATE_270 -> 270f
        else -> 0f
      }
    if (degrees == 0f) return bitmap
    return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, Matrix().apply { postRotate(degrees) }, true)
  }
}
