import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/media/media_version.dart';
import 'package:heisuca/services/jellyfin_media_info_mapper.dart';
import 'package:heisuca/services/media_source_ranker.dart';
import 'package:heisuca/services/video_decode_capabilities.dart';

void main() {
  setUp(() {
    VideoDecodeCapabilities.debugReset();
  });

  tearDown(() {
    VideoDecodeCapabilities.debugReset();
  });

  group('MediaSourceRanker (TV-1 G3)', () {
    test('tabela: firetv-9 sem HEVC -> H.264', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: false,
        hardwareAv1: false,
        displaySupports4k: false,
        codecHardware: {'h264': true, 'hevc': false, 'av1': false},
      );

      final hevcSource = {
        'Id': 'src-hevc',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'hevc', 'Profile': 'Main', 'Height': 1080, 'Width': 1920},
          {'Type': 'Audio', 'Language': 'por'},
        ],
      };
      final h264Source = {
        'Id': 'src-h264',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'h264', 'Profile': 'High', 'Height': 1080, 'Width': 1920},
          {'Type': 'Audio', 'Language': 'por'},
        ],
      };

      final ranked = rankMediaSources([hevcSource, h264Source]);
      expect(ranked.first['Id'], 'src-h264');
    });

    test('tabela: HEVC 4K + H.264 1080p em tela 1080p -> H.264', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: true,
        displaySupports4k: false,
        codecHardware: {'h264': true, 'hevc': true},
        codecProfiles: {
          'hevc': ['main', 'main10'],
          'h264': ['high'],
        },
        codecMaxResolutions: {'hevc': '4k60', 'h264': '1080p60'},
      );

      final hevc4k = {
        'Id': 'src-hevc-4k',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'hevc', 'Profile': 'Main 10', 'BitDepth': 10, 'Height': 2160, 'Width': 3840},
          {'Type': 'Audio', 'Language': 'por'},
        ],
      };
      final h2641080p = {
        'Id': 'src-h264-1080p',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'h264', 'Profile': 'High', 'Height': 1080, 'Width': 1920},
          {'Type': 'Audio', 'Language': 'por'},
        ],
      };

      final ranked = rankMediaSources([hevc4k, h2641080p]);
      expect(ranked.first['Id'], 'src-h264-1080p');
    });

    test('tabela: em tela 4K com Main10 -> HEVC', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: true,
        displaySupports4k: true,
        codecHardware: {'h264': true, 'hevc': true},
        codecProfiles: {
          'hevc': ['main', 'main10'],
          'h264': ['high'],
        },
        codecMaxResolutions: {'hevc': '4k60', 'h264': '1080p60'},
      );

      final hevc4k = {
        'Id': 'src-hevc-4k',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'hevc', 'Profile': 'Main 10', 'BitDepth': 10, 'Height': 2160, 'Width': 3840},
          {'Type': 'Audio', 'Language': 'por'},
        ],
      };
      final h2641080p = {
        'Id': 'src-h264-1080p',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'h264', 'Profile': 'High', 'Height': 1080, 'Width': 1920},
          {'Type': 'Audio', 'Language': 'por'},
        ],
      };

      final ranked = rankMediaSources([h2641080p, hevc4k]);
      expect(ranked.first['Id'], 'src-hevc-4k');
    });

    test('tabela: anime H.264 Hi10P sem High10 -> aviso (isSourcePlayable false)', () {
      VideoDecodeCapabilities.debugReset(
        codecHardware: {'h264': true},
        codecProfiles: {
          'h264': ['high'], // no high10
        },
      );

      final animeHi10p = {
        'Id': 'src-anime-hi10p',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'h264', 'Profile': 'High 10', 'BitDepth': 10, 'Height': 1080, 'Width': 1920},
          {'Type': 'Audio', 'Language': 'jpn'},
          {'Type': 'Subtitle', 'Language': 'por'},
        ],
      };

      expect(isSourcePlayable(animeHi10p), isFalse);
      expect(formatMediaSourceReason(animeHi10p), 'H.264 10-bit em 1080p');
    });

    test('versão: anime H.264 Hi10P SDR sem High10 -> isVersionPlayable false', () {
      VideoDecodeCapabilities.debugReset(
        codecHardware: {'h264': true},
        codecProfiles: {
          'h264': ['high'], // sem high10
        },
      );

      Map<String, dynamic> fonte(String id, String profile, int bitDepth) => {
        'Id': id,
        'Container': 'mkv',
        'Width': 1920,
        'Height': 1080,
        'MediaStreams': [
          // SDR: sem VideoRange HDR, o 10 bits só aparece em BitDepth.
          {'Type': 'Video', 'Index': 0, 'Codec': 'h264', 'Profile': profile, 'BitDepth': bitDepth},
          {'Type': 'Audio', 'Index': 1, 'Language': 'jpn'},
        ],
      };

      final versions = jellyfinSourcesToVersions([
        fonte('src-hi10p', 'High 10', 10),
        fonte('src-high', 'High', 8),
      ]);

      expect(isVersionPlayable(versions[0]), isFalse);
      expect(isVersionPlayable(versions[1]), isTrue);
    });

    test('tabela: sonda vazia -> mantém a 1ª fonte', () {
      VideoDecodeCapabilities.debugReset(); // unprobed

      final src1 = {
        'Id': 'src-primeira',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'hevc', 'Height': 1080, 'Width': 1920},
          {'Type': 'Audio', 'Language': 'eng'},
        ],
      };
      final src2 = {
        'Id': 'src-segunda',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'h264', 'Height': 1080, 'Width': 1920},
          {'Type': 'Audio', 'Language': 'eng'},
        ],
      };

      final ranked = rankMediaSources([src1, src2]);
      expect(ranked.first['Id'], 'src-primeira');
    });

    test('prioriza versão com faixa em português (áudio por ou legenda pt/pb)', () {
      VideoDecodeCapabilities.debugReset(
        displaySupports4k: false,
        codecHardware: {'h264': true},
        codecProfiles: {'h264': ['high']},
      );

      final srcEng = {
        'Id': 'src-eng',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'h264', 'Height': 1080, 'Width': 1920},
          {'Type': 'Audio', 'Language': 'eng'},
        ],
      };
      final srcPt = {
        'Id': 'src-pt',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'h264', 'Height': 1080, 'Width': 1920},
          {'Type': 'Audio', 'Language': 'por'},
        ],
      };

      final ranked = rankMediaSources([srcEng, srcPt]);
      expect(ranked.first['Id'], 'src-pt');
    });
  });

  // Tabela pedida em 31/10 (versão pelo aparelho): cada linha é um aparelho e
  // um conjunto de versões do mesmo filme; a escolha manual fica nos testes do
  // bundle (jellyfin_playback_bundle_test.dart).
  group('versão pelo aparelho (tabela 31/10)', () {
    Map<String, dynamic> fonte(String id, String codec, String profile, int bitDepth, int width, int height) => {
      'Id': id,
      'Container': 'mkv',
      'Width': width,
      'Height': height,
      'MediaStreams': [
        {'Type': 'Video', 'Codec': codec, 'Profile': profile, 'BitDepth': bitDepth, 'Width': width, 'Height': height},
        {'Type': 'Audio', 'Language': 'por'},
      ],
    };

    final h264_1080 = fonte('h264-1080', 'h264', 'High', 8, 1920, 1080);
    final hevc10_4k = fonte('hevc10-4k', 'hevc', 'Main 10', 10, 3840, 2160);
    final hevc8_1080 = fonte('hevc8-1080', 'hevc', 'Main', 8, 1920, 1080);

    void boxSemMain10({bool tela4k = true}) => VideoDecodeCapabilities.debugReset(
      hardwareHevc: true,
      displaySupports4k: tela4k,
      codecHardware: {'h264': true, 'hevc': true},
      codecProfiles: {'h264': ['high'], 'hevc': ['main']},
      codecMaxResolutions: {'h264': '1080p60', 'hevc': '4k60'},
    );

    void tvComMain10() => VideoDecodeCapabilities.debugReset(
      hardwareHevc: true,
      displaySupports4k: true,
      codecHardware: {'h264': true, 'hevc': true},
      codecProfiles: {'h264': ['high'], 'hevc': ['main', 'main10']},
      codecMaxResolutions: {'h264': '4k60', 'hevc': '4k60'},
    );

    test('1 versão: devolvida como está, mesmo que o aparelho não a decodifique', () {
      boxSemMain10();
      final ranked = rankMediaSources([hevc10_4k]);
      expect(ranked.map((s) => s['Id']), ['hevc10-4k']);
    });

    test('H.264 + HEVC 10-bit em aparelho sem Main10 -> H.264', () {
      boxSemMain10();
      expect(rankMediaSources([hevc10_4k, h264_1080]).first['Id'], 'h264-1080');
    });

    test('H.264 + HEVC 10-bit em aparelho com Main10 e tela 4K -> HEVC 4K', () {
      tvComMain10();
      expect(rankMediaSources([h264_1080, hevc10_4k]).first['Id'], 'hevc10-4k');
    });

    test('4K em tela 1080p -> 1080p, mesmo com Main10', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: true,
        displaySupports4k: false,
        codecHardware: {'h264': true, 'hevc': true},
        codecProfiles: {'h264': ['high'], 'hevc': ['main', 'main10']},
        codecMaxResolutions: {'h264': '1080p60', 'hevc': '4k60'},
      );
      expect(rankMediaSources([hevc10_4k, h264_1080]).first['Id'], 'h264-1080');
    });

    test('4K em tela 4K mas decodificador HEVC só até 1080p -> 1080p', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: true,
        displaySupports4k: true,
        codecHardware: {'h264': true, 'hevc': true},
        codecProfiles: {'h264': ['high'], 'hevc': ['main', 'main10']},
        codecMaxResolutions: {'h264': '1080p60', 'hevc': '1080p60'},
      );
      expect(rankMediaSources([hevc10_4k, h264_1080]).first['Id'], 'h264-1080');
    });

    test('sem HEVC por hardware: HEVC 8-bit 1080p (software) vence HEVC 10-bit 4K', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: false,
        displaySupports4k: true,
        codecHardware: {'h264': true, 'hevc': false},
        codecProfiles: {'h264': ['high']},
      );
      expect(rankMediaSources([hevc10_4k, hevc8_1080]).first['Id'], 'hevc8-1080');
    });

    test('rótulo da versão marca 10-bit por BitDepth/perfil (Hi10P SDR)', () {
      final versions = jellyfinSourcesToVersions([
        fonte('h264-hi10p', 'h264', 'High 10', 10, 1920, 1080),
        h264_1080,
      ]);
      expect(formatVersionReason(versions[0]), 'H.264 10-bit em 1080p');
      expect(formatVersionReason(versions[1]), 'H.264 em 1080p');
    });

    test('rótulo: parte seguinte em 8-bit não apaga o 10-bit da anterior', () {
      final versions = jellyfinSourcesToVersions([
        fonte('h264-hi10p', 'h264', 'High 10', 10, 1920, 1080),
        h264_1080,
      ]);
      final multi = MediaVersion(
        id: 'multi',
        width: 1920,
        height: 1080,
        videoCodec: 'h264',
        parts: [...versions[0].parts, ...versions[1].parts],
      );
      expect(formatVersionReason(multi), 'H.264 10-bit em 1080p');
    });
  });
}
