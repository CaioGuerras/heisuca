import 'package:flutter_test/flutter_test.dart';
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
}
