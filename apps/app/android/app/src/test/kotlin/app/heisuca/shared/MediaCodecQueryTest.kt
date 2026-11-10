package app.heisuca.shared

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.MediaCodecInfoBuilder

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [25, 28])
class MediaCodecQueryTest {

  @Test
  fun preApi29CodecQueryDoesNotInvokeApi29HardwareFlag() {
    val codecInfo = MediaCodecInfoBuilder.newBuilder()
      .setName("OMX.qcom.video.decoder.avc")
      .setIsHardwareAccelerated(false)
      .build()

    assertTrue(MediaCodecQuery.isHardwareAccelerated(codecInfo))
  }

  @Test
  fun recognizesKnownPlatformAndFfmpegSoftwareCodecNames() {
    listOf(
      "OMX.google.h264.decoder",
      "OMX.FFMPEG.VIDEO.DECODER",
      "c2.android.avc.decoder",
      "c2.android.av1-dav1d.decoder",
      "c2.ffmpeg.vp9.decoder",
      "vendor.video.sw.decoder"
    ).forEach { name ->
      assertTrue("expected software codec: $name", MediaCodecQuery.isSoftwareCodecName(name))
    }
  }

  @Test
  fun doesNotMisclassifyVendorHardwareCodecNames() {
    listOf(
      "OMX.qcom.video.decoder.avc",
      "OMX.MTK.VIDEO.DECODER.HEVC",
      "c2.qti.avc.decoder",
      "c2.exynos.hevc.decoder",
      "c2.google.av1.decoder"
    ).forEach { name ->
      assertFalse("expected hardware codec: $name", MediaCodecQuery.isSoftwareCodecName(name))
    }
  }

  @Test
  fun api29RequiresPlatformHardwareFlagAndNonSoftwareComponentName() {
    assertFalse(MediaCodecQuery.isHardwareAccelerated(29, true, "c2.ffmpeg.aac.decoder"))
    assertFalse(MediaCodecQuery.isHardwareAccelerated(29, false, "c2.qti.avc.decoder"))
    assertTrue(MediaCodecQuery.isHardwareAccelerated(29, true, "c2.qti.avc.decoder"))
    // Tensor's BigOcean AV1 block (#2272): the platform flag decides.
    assertTrue(MediaCodecQuery.isHardwareAccelerated(33, true, "c2.google.av1.decoder"))
  }

  @Test
  fun preApi29RetainsNameBasedFallback() {
    assertFalse(MediaCodecQuery.isHardwareAccelerated(28, true, "OMX.google.h264.decoder"))
    assertTrue(MediaCodecQuery.isHardwareAccelerated(28, false, "OMX.qcom.video.decoder.avc"))
  }

  @Test
  fun mapsGatedCodecsToTheMimeTypesDecodersAdvertise() {
    assertEquals(
      mapOf("hevc" to true, "av1" to true),
      MediaCodecQuery.hardwareVideoDecodeSupport(
        setOf("video/avc", "video/hevc", "video/av01", "audio/mp4a-latm")
      )
    )
    assertEquals(
      mapOf("hevc" to true, "av1" to false),
      MediaCodecQuery.hardwareVideoDecodeSupport(setOf("video/avc", "video/hevc"))
    )
  }

  @Test
  fun queryCapabilitiesReturnsExpectedStructureAndOldHevcAv1Keys() {
    val caps = MediaCodecQuery.queryCapabilities(null)
    assertTrue(caps.containsKey("hevc"))
    assertTrue(caps.containsKey("av1"))
    assertTrue(caps.containsKey("displaySupports4k"))
    assertTrue(caps.containsKey("codecs"))
    val codecs = caps["codecs"] as Map<*, *>
    assertTrue(codecs.containsKey("h264"))
    assertTrue(codecs.containsKey("hevc"))
    assertTrue(codecs.containsKey("av1"))
    assertTrue(codecs.containsKey("vp9"))
  }
  @Test
  fun hardwareSemMedidaNaoViraQuatroK() {
    // Antes: hardware presente sem resposta de taxa virava "supported" (= 4K).
    assertEquals("sd", MediaCodecQuery.maxResolutionLabel(true, false, false, false, false, false))
    assertEquals("1080p", MediaCodecQuery.maxResolutionLabel(true, false, false, false, false, true))
    assertEquals("4k", MediaCodecQuery.maxResolutionLabel(true, false, false, true, false, true))
    assertEquals("4k60", MediaCodecQuery.maxResolutionLabel(true, true, true, true, true, true))
    assertEquals("none", MediaCodecQuery.maxResolutionLabel(false, false, false, false, false, false))
  }

  @Test
  fun main10SoContaEmQuatroKComNivelCinco() {
    val main10 = android.media.MediaCodecInfo.CodecProfileLevel.HEVCProfileMain10
    val nivel41 = android.media.MediaCodecInfo.CodecProfileLevel.HEVCMainTierLevel41
    val nivel51 = android.media.MediaCodecInfo.CodecProfileLevel.HEVCMainTierLevel51
    assertTrue(MediaCodecQuery.profilesFor4k("hevc", main10, nivel41).isEmpty())
    assertEquals(listOf("main10"), MediaCodecQuery.profilesFor4k("hevc", main10, nivel51))
    val high = android.media.MediaCodecInfo.CodecProfileLevel.AVCProfileHigh
    assertTrue(
      MediaCodecQuery.profilesFor4k("h264", high, android.media.MediaCodecInfo.CodecProfileLevel.AVCLevel5).isEmpty()
    )
    assertEquals(
      listOf("high"),
      MediaCodecQuery.profilesFor4k("h264", high, android.media.MediaCodecInfo.CodecProfileLevel.AVCLevel51)
    )
  }

  @Test
  fun av1Hdr10EHdr10PlusContamComoMain10() {
    // Constantes da API 29 inlinadas na compilação: valem também nos SDKs 25/28 do teste.
    val main8 = android.media.MediaCodecInfo.CodecProfileLevel.AV1ProfileMain8
    val main10 = android.media.MediaCodecInfo.CodecProfileLevel.AV1ProfileMain10
    val hdr10 = android.media.MediaCodecInfo.CodecProfileLevel.AV1ProfileMain10HDR10
    val hdr10Plus = android.media.MediaCodecInfo.CodecProfileLevel.AV1ProfileMain10HDR10Plus
    val nivel5 = android.media.MediaCodecInfo.CodecProfileLevel.AV1Level5
    val nivel41 = android.media.MediaCodecInfo.CodecProfileLevel.AV1Level41
    assertEquals(0x1000, hdr10)
    assertEquals(0x2000, hdr10Plus)

    assertEquals(listOf("main"), MediaCodecQuery.profileNames("av1", main8))
    listOf(main10, hdr10, hdr10Plus).forEach { perfil ->
      assertEquals(listOf("main10"), MediaCodecQuery.profileNames("av1", perfil))
      assertEquals(listOf("main10"), MediaCodecQuery.profilesFor4k("av1", perfil, nivel5))
      assertTrue(MediaCodecQuery.profilesFor4k("av1", perfil, nivel41).isEmpty())
    }
  }
}
