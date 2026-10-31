package app.heisuca.shared

import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.os.Build
import android.view.Display
import java.util.Locale

/** Canonical decoder lookup and hardware classification for native playback. */
internal object MediaCodecQuery {
  /**
   * Codecs whose advertised support is decided by hardware: both have a
   * software decoder behind them, but a software HEVC or AV1 decode on
   * phone/TV-class hardware drops frames.
   */
  private val HARDWARE_GATED_VIDEO_MIME_TYPES = mapOf(
    "hevc" to "video/hevc",
    "av1" to "video/av01"
  )

  /** Codec name -> whether this device has a hardware decoder for it. */
  fun hardwareVideoDecodeSupport(
    hardwareMimeTypes: Set<String> = hardwareDecoderMimeTypes()
  ): Map<String, Boolean> = HARDWARE_GATED_VIDEO_MIME_TYPES.mapValues { (_, mimeType) -> mimeType in hardwareMimeTypes }

  /**
   * Whether the active display mode supports 4K (3840x2160 or higher).
   */
  fun displaySupports4k(display: Display?): Boolean {
    if (display == null) return false
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      val modes = try {
        display.supportedModes
      } catch (e: Throwable) {
        null
      } ?: return false
      return modes.any { mode ->
        val maxDim = maxOf(mode.physicalWidth, mode.physicalHeight)
        val minDim = minOf(mode.physicalWidth, mode.physicalHeight)
        maxDim >= 3840 && minDim >= 2160
      }
    }
    return false
  }

  /**
   * Details per codec (hardware decoder present, supported profiles, max resolution and fps).
   * Profiles checked:
   * - H.264: High, High 10
   * - HEVC: Main, Main 10
   * - AV1: Main, Main 10
   * - VP9: 0, 2
   * Max resolution/fps checked via VideoCapabilities.areSizeAndRateSupported for:
   * 3840x2160@24/60 and 1920x1080@60.
   *
   * Medida real, sem palpite: decoder de hardware que não responde à taxa
   * (comum em TV box) é medido pelo tamanho (`isSizeSupported`) e pelos limites
   * `supportedWidths/Heights`; "ter hardware" sozinho não prova 4K. Perfil e
   * nível são cruzados no MESMO decoder: `profiles_4k` só lista um perfil se
   * aquele decoder aceita 3840x2160 e declara nível suficiente para 4K nele
   * (HEVC/VP9/AV1 nível 5, H.264 nível 5.1). Ex.: Main10 só até o nível 4.1
   * não conta como Main10 em 4K.
   */
  fun queryCodecDetails(
    codecKind: Int = MediaCodecList.REGULAR_CODECS
  ): Map<String, Map<String, Any>> {
    val codecs = mapOf(
      "h264" to "video/avc",
      "hevc" to "video/hevc",
      "av1" to "video/av01",
      "vp9" to "video/x-vnd.on2.vp9"
    )

    val allDecoders = try {
      MediaCodecList(codecKind).codecInfos.filter { !it.isEncoder && isHardwareAccelerated(it) }
    } catch (e: Throwable) {
      emptyList()
    }

    val result = mutableMapOf<String, Map<String, Any>>()

    for ((codecKey, mimeType) in codecs) {
      val matchingDecoders = allDecoders.filter { info ->
        info.supportedTypes.any { it.equals(mimeType, ignoreCase = true) }
      }

      val hasHardware = matchingDecoders.isNotEmpty()
      val profiles = mutableSetOf<String>()
      var can4k60 = false
      var can4k24 = false
      var can1080p60 = false
      var fits4k = false
      var fits1080 = false
      var maxWidth = 0
      var maxHeight = 0
      val profiles4k = mutableSetOf<String>()

      for (decoder in matchingDecoders) {
        val caps = try {
          decoder.getCapabilitiesForType(mimeType)
        } catch (e: Throwable) {
          null
        } ?: continue

        val profileLevels = caps.profileLevels
        if (profileLevels != null) {
          for (pl in profileLevels) {
            when (codecKey) {
              "h264" -> {
                if (pl.profile == MediaCodecInfo.CodecProfileLevel.AVCProfileHigh) profiles.add("high")
                if (pl.profile == MediaCodecInfo.CodecProfileLevel.AVCProfileHigh10) profiles.add("high10")
              }
              "hevc" -> {
                if (pl.profile == MediaCodecInfo.CodecProfileLevel.HEVCProfileMain) profiles.add("main")
                if (pl.profile == MediaCodecInfo.CodecProfileLevel.HEVCProfileMain10) profiles.add("main10")
              }
              "av1" -> {
                if (pl.profile == 1) profiles.add("main")
                if (pl.profile == 2) profiles.add("main10")
              }
              "vp9" -> {
                if (pl.profile == MediaCodecInfo.CodecProfileLevel.VP9Profile0) {
                  profiles.add("0")
                  profiles.add("profile0")
                }
                if (pl.profile == MediaCodecInfo.CodecProfileLevel.VP9Profile2) {
                  profiles.add("2")
                  profiles.add("profile2")
                }
              }
            }
          }
        }

        val videoCaps = caps.videoCapabilities
        if (videoCaps != null) {
          val decoderFits4k = try { videoCaps.isSizeSupported(3840, 2160) } catch (e: Throwable) { false }
          if (decoderFits4k) fits4k = true
          if (!fits1080) {
            fits1080 = try { videoCaps.isSizeSupported(1920, 1080) } catch (e: Throwable) { false }
          }
          val width = try { videoCaps.supportedWidths.upper } catch (e: Throwable) { 0 }
          val height = try { videoCaps.supportedHeights.upper } catch (e: Throwable) { 0 }
          // Guarda o par do decoder de maior área (não mistura largura de um
          // com altura de outro).
          if (width.toLong() * height > maxWidth.toLong() * maxHeight) {
            maxWidth = width
            maxHeight = height
          }
          if (decoderFits4k && profileLevels != null) {
            for (pl in profileLevels) {
              profiles4k.addAll(profilesFor4k(codecKey, pl.profile, pl.level))
            }
          }
          if (!can4k60) {
            can4k60 = try { videoCaps.areSizeAndRateSupported(3840, 2160, 60.0) } catch (e: Throwable) { false }
          }
          if (!can4k24) {
            can4k24 = try { videoCaps.areSizeAndRateSupported(3840, 2160, 24.0) } catch (e: Throwable) { false }
          }
          if (!can1080p60) {
            can1080p60 = try { videoCaps.areSizeAndRateSupported(1920, 1080, 60.0) } catch (e: Throwable) { false }
          }
        }
      }

      val maxRes = maxResolutionLabel(hasHardware, can4k60, can4k24, fits4k, can1080p60, fits1080)

      result[codecKey] = mapOf(
        "hardware" to hasHardware,
        "profiles" to profiles.toList(),
        "max_resolution" to maxRes,
        "can_4k_60" to can4k60,
        "can_4k_24" to can4k24,
        "can_1080p_60" to can1080p60,
        "supports_4k" to (can4k60 || can4k24 || fits4k),
        "supports_1080p60" to can1080p60,
        "max_width" to maxWidth,
        "max_height" to maxHeight,
        "profiles_4k" to profiles4k.toList()
      )
    }

    return result
  }

  /**
   * Rótulo da resolução máxima medida. Sem medida de tamanho nem de taxa o
   * resultado é "sd" (há hardware, mas nada prova 1080p nem 4K); nunca o
   * antigo "supported", que o app tratava como 4K.
   */
  internal fun maxResolutionLabel(
    hasHardware: Boolean,
    can4k60: Boolean,
    can4k24: Boolean,
    fits4k: Boolean,
    can1080p60: Boolean,
    fits1080: Boolean
  ): String = when {
    !hasHardware -> "none"
    can4k60 -> "4k60"
    can4k24 -> "4k24"
    fits4k -> "4k"
    can1080p60 -> "1080p60"
    fits1080 -> "1080p"
    else -> "sd"
  }

  /** Nível mínimo para 3840x2160, por codec (constantes do CodecProfileLevel). */
  internal fun minLevelFor4k(codecKey: String): Int? = when (codecKey) {
    "h264" -> MediaCodecInfo.CodecProfileLevel.AVCLevel51
    "hevc" -> MediaCodecInfo.CodecProfileLevel.HEVCMainTierLevel5
    "vp9" -> MediaCodecInfo.CodecProfileLevel.VP9Level5
    "av1" -> 0x1000 // AV1Level5 (constante só existe a partir da API 29)
    else -> null
  }

  /**
   * Nomes do perfil [profile] que valem em 4K num decoder que já aceita
   * 3840x2160, se o [level] declarado para esse perfil chega ao mínimo.
   */
  internal fun profilesFor4k(codecKey: String, profile: Int, level: Int): List<String> {
    val minLevel = minLevelFor4k(codecKey) ?: return emptyList()
    if (level < minLevel) return emptyList()
    return when (codecKey) {
      "h264" -> when (profile) {
        MediaCodecInfo.CodecProfileLevel.AVCProfileHigh -> listOf("high")
        MediaCodecInfo.CodecProfileLevel.AVCProfileHigh10 -> listOf("high10")
        else -> emptyList()
      }
      "hevc" -> when (profile) {
        MediaCodecInfo.CodecProfileLevel.HEVCProfileMain -> listOf("main")
        MediaCodecInfo.CodecProfileLevel.HEVCProfileMain10 -> listOf("main10")
        else -> emptyList()
      }
      "av1" -> when (profile) {
        1 -> listOf("main")
        2 -> listOf("main10")
        else -> emptyList()
      }
      "vp9" -> when (profile) {
        MediaCodecInfo.CodecProfileLevel.VP9Profile0 -> listOf("0", "profile0")
        MediaCodecInfo.CodecProfileLevel.VP9Profile2 -> listOf("2", "profile2")
        else -> emptyList()
      }
      else -> emptyList()
    }
  }

  /**
   * Complete hardware decode capabilities, keeping the legacy `hevc` and `av1` booleans
   * while adding per-codec profiles, maximum resolution/fps, and 4K display capability.
   */
  fun queryCapabilities(
    display: Display? = null,
    codecKind: Int = MediaCodecList.REGULAR_CODECS
  ): Map<String, Any> {
    val codecs = queryCodecDetails(codecKind)
    val display4k = displaySupports4k(display)
    val hevcHw = codecs["hevc"]?.get("hardware") == true
    val av1Hw = codecs["av1"]?.get("hardware") == true

    return mapOf(
      "hevc" to hevcHw,
      "av1" to av1Hw,
      "displaySupports4k" to display4k,
      "display_4k" to display4k,
      "codecs" to codecs,
      "profiles" to codecs.mapValues { (_, v) -> (v["profiles"] as? List<*>) ?: emptyList<String>() }
    )
  }

  /**
   * Every MIME type served by a hardware decoder, lowercased. One walk answers
   * for all codecs, unlike [findHardwareDecoder], which rescans per lookup.
   */
  private fun hardwareDecoderMimeTypes(): Set<String> {
    val mimeTypes = HashSet<String>()
    for (info in MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos) {
      if (info.isEncoder || !isHardwareAccelerated(info)) continue
      for (type in info.supportedTypes) mimeTypes.add(type.lowercase(Locale.ROOT))
    }
    return mimeTypes
  }

  /**
   * Whether a hardware `video/avc` decoder advertises H.264 High 10 (Hi10P).
   * Decoders that do not advertise it either refuse the stream (this is what
   * the mpv/FFmpeg MediaCodec path sees) or, on some SoCs, accept it and
   * render garbage; neither is a reason to let the hardware path try first
   * (#2065). Answered once per process: the codec list is static.
   */
  fun hardwareAvcHigh10Support(): Boolean = hardwareAvcHigh10.value

  private val hardwareAvcHigh10: Lazy<Boolean> = lazy {
    findHardwareDecoder("video/avc") { info, type ->
      val profiles = try {
        info.getCapabilitiesForType(type).profileLevels
      } catch (e: IllegalArgumentException) {
        return@findHardwareDecoder false
      }
      profiles.any { it.profile == MediaCodecInfo.CodecProfileLevel.AVCProfileHigh10 }
    } != null
  }

  /** Whether a hardware AV1 decoder exists; software MediaCodec AV1 components do not count (#2272). */
  fun hardwareAv1Support(): Boolean = hardwareAv1.value

  private val hardwareAv1: Lazy<Boolean> = lazy {
    findHardwareDecoder("video/av01") != null
  }

  /**
   * Whether the hardware AV1 decoder is Tensor's BigOcean block
   * (`c2.google.av1.decoder`, Pixel 6+). Its vendor service dies when a new
   * instance starts while the previous one is still being torn down (#2272);
   * [app.heisuca.mpv.GpuVoPolicy.needsParkedRebuild] keeps the two apart.
   */
  fun hardwareAv1IsBigOcean(): Boolean = bigOceanAv1.value

  private val bigOceanAv1: Lazy<Boolean> = lazy {
    findHardwareDecoder("video/av01")?.name?.lowercase(Locale.ROOT)?.startsWith("c2.google.av1") == true
  }

  fun findHardwareDecoder(
    mimeType: String,
    codecKind: Int = MediaCodecList.REGULAR_CODECS,
    predicate: (MediaCodecInfo, String) -> Boolean = { _, _ -> true }
  ): MediaCodecInfo? {
    for (info in MediaCodecList(codecKind).codecInfos) {
      if (info.isEncoder || !isHardwareAccelerated(info)) continue
      for (type in info.supportedTypes) {
        if (type.equals(mimeType, ignoreCase = true) && predicate(info, type)) {
          return info
        }
      }
    }
    return null
  }

  /**
   * MediaFormat MIME type for an mpv/FFmpeg codec name, for the codecs a
   * hardware decoder may serve; null for anything else.
   */
  fun mimeTypeForCodec(codec: String?): String? = when (codec?.lowercase(Locale.ROOT)) {
    "h264" -> "video/avc"
    "hevc" -> "video/hevc"
    "av1" -> "video/av01"
    "vp9" -> "video/x-vnd.on2.vp9"
    "vp8" -> "video/x-vnd.on2.vp8"
    "mpeg2video" -> "video/mpeg2"
    "mpeg4" -> "video/mp4v-es"
    else -> null
  }

  private val PERFORMANCE_POINT_RATES = intArrayOf(240, 120, 90, 60, 50, 30, 25, 24)

  /**
   * The highest frame rate the hardware decoder for [mimeType] advertises at
   * [width]x[height]: the manufacturer's performance points on API 31+, the
   * capability range below it. Null when there is no hardware decoder, the
   * size is outside what it declares, or the platform answers nothing —
   * the caller then applies its own ceiling.
   */
  fun maxDecoderFrameRate(mimeType: String, width: Int, height: Int): Int? {
    if (width <= 0 || height <= 0) return null
    val info = findHardwareDecoder(mimeType) ?: return null
    val video = try {
      info.getCapabilitiesForType(mimeType).videoCapabilities
    } catch (e: IllegalArgumentException) {
      return null
    } ?: return null
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      val points = video.supportedPerformancePoints
      if (!points.isNullOrEmpty()) {
        // The platform exposes only coverage, not the point's own rate:
        // ask for the rates a declaration would use, highest first.
        for (rate in PERFORMANCE_POINT_RATES) {
          val wanted = MediaCodecInfo.VideoCapabilities.PerformancePoint(width, height, rate)
          if (points.any { it.covers(wanted) }) return rate
        }
      }
    }
    return try {
      video.getSupportedFrameRatesFor(width, height).upper.toInt().takeIf { it > 0 }
    } catch (e: IllegalArgumentException) {
      null
    }
  }

  fun isHardwareAccelerated(info: MediaCodecInfo): Boolean {
    val name = info.name
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      isHardwareAccelerated(Build.VERSION.SDK_INT, info.isHardwareAccelerated, name)
    } else {
      // MediaCodecInfo.isHardwareAccelerated() does not exist before API 29.
      // Keep the call inside the version gate so older Fire OS releases do not
      // fail with NoSuchMethodError while initializing playback.
      isHardwareAccelerated(Build.VERSION.SDK_INT, false, name)
    }
  }

  internal fun isHardwareAccelerated(
    sdkInt: Int,
    platformReportsHardware: Boolean,
    name: String
  ): Boolean {
    // API 29 added manufacturer-provided classification, but some Codec2
    // builders still flag known software components as hardware. Require both
    // signals there; older releases expose only component names.
    return if (sdkInt >= Build.VERSION_CODES.Q) {
      platformReportsHardware && !isSoftwareCodecName(name)
    } else {
      !isSoftwareCodecName(name)
    }
  }

  /**
   * Component names Android itself ships as software. `c2.google.*` is not
   * one of them: it is the Tensor vendor prefix (`c2.google.av1.decoder` is
   * the BigOcean hardware AV1 block on Pixel 6+), and API 29's platform flag
   * classifies it (#2272). Google's software components are `c2.android.*`.
   */
  internal fun isSoftwareCodecName(name: String): Boolean {
    val normalized = name.lowercase(Locale.ROOT)
    return normalized.startsWith("omx.google.") ||
      normalized.startsWith("omx.ffmpeg.") ||
      normalized.startsWith("c2.android.") ||
      normalized.startsWith("c2.ffmpeg.") ||
      normalized.contains(".sw.")
  }
}
