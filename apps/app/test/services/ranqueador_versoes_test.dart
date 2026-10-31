import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:heisuca/media/media_part.dart';
import 'package:heisuca/media/media_stream.dart';
import 'package:heisuca/media/media_version.dart';
import 'package:heisuca/services/media_source_ranker.dart';
import 'package:heisuca/services/video_decode_capabilities.dart';

/// Ranqueador de versões (handoff 31/10, itens 1–4 e adendo 1 da sonda).
void main() {
  setUp(VideoDecodeCapabilities.debugReset);
  tearDown(VideoDecodeCapabilities.debugReset);

  Map<String, dynamic> fonte(
    String id,
    String codec, {
    String profile = 'High',
    int bitDepth = 8,
    int? width,
    int? height,
    String? name,
    String? displayTitle,
    List<Map<String, dynamic>> extras = const [],
  }) => {
    'Id': id,
    'Container': 'mkv',
    'Name': ?name,
    'MediaStreams': [
      {
        'Type': 'Video',
        'Codec': codec,
        'Profile': profile,
        'BitDepth': bitDepth,
        'Width': ?width,
        'Height': ?height,
        'DisplayTitle': ?displayTitle,
      },
      ...extras,
      {'Type': 'Audio', 'Language': 'por'},
    ],
  };

  MediaStream video(String codec, {String? profile, int? bitDepth, bool hdr = false}) => MediaStream(
    id: 'v-$codec-$profile',
    kind: MediaStreamKind.video,
    codec: codec,
    profile: profile,
    bitDepth: bitDepth,
    hdr: hdr,
  );

  MediaVersion versao(
    String id, {
    required String codec,
    int? width,
    int? height,
    String? resolution,
    List<List<MediaStream>>? parts,
    String language = 'por',
  }) => MediaVersion(
    id: id,
    width: width,
    height: height,
    videoResolution: resolution,
    videoCodec: codec,
    container: 'mkv',
    parts: [
      for (final (i, streams)
          in (parts ??
                  [
                    [video(codec, profile: codec == 'hevc' ? 'main' : 'high', bitDepth: 8)],
                  ])
              .indexed)
        MediaPart(
          id: '$id-$i',
          streams: [
            ...streams,
            MediaStream(id: '$id-a$i', kind: MediaStreamKind.audio, languageCode: language),
          ],
        ),
    ],
  );

  /// TV box 1080p: H.264 e HEVC Main por hardware, sem Main10, decoder até 4K.
  void tv1080SemMain10() => VideoDecodeCapabilities.debugReset(
    hardwareHevc: true,
    displaySupports4k: false,
    codecHardware: {'h264': true, 'hevc': true},
    codecProfiles: {
      'h264': ['high'],
      'hevc': ['main'],
    },
    codecMaxResolutions: {'h264': '4k60', 'hevc': '4k60'},
  );

  group('item 1: todo stream de vídeo, em todas as partes', () {
    test('parte 2 em HEVC 10-bit reprova a versão mesmo com a parte 1 em H.264', () {
      tv1080SemMain10();
      final multi = versao(
        'multi',
        codec: 'h264',
        width: 1920,
        height: 1080,
        parts: [
          [video('h264', profile: 'high', bitDepth: 8)],
          [video('hevc', profile: 'main 10', bitDepth: 10)],
        ],
      );
      expect(isVersionPlayable(multi), isFalse);
    });

    test('parte 1 incompatível não é apagada pela parte 2 compatível', () {
      tv1080SemMain10();
      final multi = versao(
        'multi',
        codec: 'hevc',
        width: 1920,
        height: 1080,
        parts: [
          [video('hevc', profile: 'main 10', bitDepth: 10)],
          [video('hevc', profile: 'main', bitDepth: 8)],
        ],
      );
      expect(isVersionPlayable(multi), isFalse);
    });

    test('capa embutida (MJPEG/PNG) não reprova nem conta como vídeo', () {
      tv1080SemMain10();
      final comCapa = versao(
        'capa',
        codec: 'h264',
        width: 1920,
        height: 1080,
        parts: [
          [video('h264', profile: 'high', bitDepth: 8), video('mjpeg', bitDepth: 12), video('png')],
        ],
      );
      expect(isVersionPlayable(comCapa), isTrue);

      // Jellyfin: capa como stream "Video" mjpeg não vira o vídeo da fonte.
      final source = fonte(
        'jf-capa',
        'h264',
        width: 1920,
        height: 1080,
        extras: [
          {'Type': 'Video', 'Codec': 'mjpeg', 'Width': 600, 'Height': 900},
        ],
      );
      expect(isSourcePlayable(source), isTrue);
      expect(formatMediaSourceReason(source), 'H.264 em 1080p');
    });
  });

  group('item 2: tela 1080p, ordem 1080p > 4K > 720p', () {
    test('4K não perde para 480p/720p numa tela 1080p', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: true,
        displaySupports4k: false,
        codecHardware: {'h264': true, 'hevc': true},
        codecProfiles: {
          'h264': ['high'],
          'hevc': ['main', 'main10'],
        },
        codecMaxResolutions: {'h264': '4k60', 'hevc': '4k60'},
      );
      final ranked = rankMediaSources([
        fonte('480', 'h264', width: 854, height: 480),
        fonte('4k', 'h264', width: 3840, height: 2160),
        fonte('720', 'h264', width: 1280, height: 720),
        fonte('1080', 'h264', width: 1920, height: 1080),
      ]);
      expect(ranked.map((s) => s['Id']), ['1080', '4k', '720', '480']);
    });

    test('1920x1088 continua na faixa 1080p e cinemascope 1920x800 é 1080p', () {
      tv1080SemMain10();
      final ranked = rankMediaSources([
        fonte('720', 'h264', width: 1280, height: 720),
        fonte('1088', 'h264', width: 1920, height: 1088),
      ]);
      expect(ranked.first['Id'], '1088');

      final scope = rankMediaSources([
        fonte('4k-scope', 'h264', width: 3840, height: 1600),
        fonte('1080-scope', 'h264', width: 1920, height: 800),
      ]);
      expect(scope.first['Id'], '1080-scope');
    });
  });

  group('item 3 + adendo 1: sonda sem prova de 4K', () {
    test('"supported" (sonda antiga) não vale como 4K', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: true,
        displaySupports4k: true,
        codecHardware: {'h264': true, 'hevc': true},
        codecProfiles: {
          'h264': ['high'],
          'hevc': ['main', 'main10'],
        },
        codecMaxResolutions: {'h264': '1080p60', 'hevc': 'supported'},
      );
      final caps = VideoDecodeCapabilities.current;
      expect(
        caps.checkHardwareDecode(codec: 'hevc', profile: 'Main 10', bitDepth: 10, width: 3840, height: 2160),
        isFalse,
      );
      expect(
        caps.checkHardwareDecode(codec: 'hevc', profile: 'Main 10', bitDepth: 10, width: 1920, height: 1080),
        isTrue,
      );
    });

    test('Main10 só em nível 4.1 (fora de profiles_4k) não conta como 4K', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: true,
        displaySupports4k: true,
        codecHardware: {'h264': true, 'hevc': true},
        codecProfiles: {
          'h264': ['high'],
          'hevc': ['main', 'main10'],
        },
        codecMaxResolutions: {'h264': '4k', 'hevc': '4k'},
        codecProfiles4k: {
          'h264': ['high'],
          'hevc': ['main'],
        },
      );
      final caps = VideoDecodeCapabilities.current;
      expect(
        caps.checkHardwareDecode(codec: 'hevc', profile: 'Main 10', bitDepth: 10, width: 3840, height: 2160),
        isFalse,
      );
      expect(caps.checkHardwareDecode(codec: 'hevc', profile: 'Main', bitDepth: 8, width: 3840, height: 2160), isTrue);
      expect(
        caps.checkHardwareDecode(codec: 'hevc', profile: 'Main 10', bitDepth: 10, width: 1920, height: 1080),
        isTrue,
      );
    });

    test('largura/altura acima do máximo medido reprovam o hardware', () {
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: true,
        displaySupports4k: true,
        codecHardware: {'h264': true, 'hevc': true},
        codecMaxResolutions: {'h264': '4k60', 'hevc': '4k60'},
        codecMaxWidths: {'h264': 1920, 'hevc': 4096},
        codecMaxHeights: {'h264': 1088, 'hevc': 2304},
      );
      final caps = VideoDecodeCapabilities.current;
      expect(caps.checkHardwareDecode(codec: 'h264', width: 3840, height: 2160), isFalse);
      expect(caps.checkHardwareDecode(codec: 'h264', width: 1920, height: 1080), isTrue);
      // Vídeo em pé cabe girado.
      expect(caps.checkHardwareDecode(codec: 'h264', width: 1080, height: 1920), isTrue);
      expect(caps.checkHardwareDecode(codec: 'hevc', width: 3840, height: 2160), isTrue);
    });

    test('dimensões nulas: inferidas do texto (videoResolution, DisplayTitle, Name)', () {
      tv1080SemMain10();
      // Plex sem width/height: "4k" no videoResolution.
      final v4k = versao(
        '4k',
        codec: 'hevc',
        resolution: '4k',
        parts: [
          [video('hevc', profile: 'main 10', bitDepth: 10)],
        ],
      );
      final v1080 = versao('1080', codec: 'h264', resolution: '1080');
      expect(rankMediaVersions([v4k, v1080]), [1, 0]);

      // Jellyfin sem Width/Height: "4K" no DisplayTitle, "1080p" no Name.
      final ranked = rankMediaSources([
        fonte('jf-4k', 'h264', displayTitle: '4K H264 SDR'),
        fonte('jf-1080', 'h264', name: 'Filme - 1080p'),
      ]);
      expect(ranked.first['Id'], 'jf-1080');
    });

    test('sem prova nenhuma de tamanho não vira "1080p por hardware" com prioridade máxima', () {
      // Decoder HEVC só até 1080p: fonte sem tamanho é tratada como 4K.
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: true,
        displaySupports4k: false,
        codecHardware: {'h264': true, 'hevc': true},
        codecProfiles: {
          'h264': ['high'],
          'hevc': ['main'],
        },
        codecMaxResolutions: {'h264': '1080p60', 'hevc': '1080p60'},
      );
      final ranked = rankMediaSources([
        fonte('sem-tamanho', 'hevc', profile: 'Main'),
        fonte('720', 'h264', width: 1280, height: 720),
      ]);
      expect(ranked.first['Id'], '720');
      expect(isSourceHardwareDecodable(fonte('sem-tamanho', 'hevc', profile: 'Main')), isFalse);
    });

    test('software com dimensões nulas não aprova o que pode ser 4K', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      VideoDecodeCapabilities.debugReset(
        hardwareHevc: false,
        displaySupports4k: true,
        codecHardware: {'h264': true, 'hevc': false},
        codecProfiles: {
          'h264': ['high'],
        },
      );
      expect(isSourcePlayable(fonte('hevc-sem-tamanho', 'hevc', profile: 'Main')), isFalse);
      expect(isSourcePlayable(fonte('hevc-1080', 'hevc', profile: 'Main', width: 1920, height: 1080)), isTrue);
    });
  });

  group('item 4: ranqueador de MediaVersion (Plex)', () {
    test('mesmos pesos: HW > SW > PT > resolução da tela', () {
      tv1080SemMain10();
      final hevc10 = versao(
        'hevc10-1080',
        codec: 'hevc',
        width: 1920,
        height: 1080,
        parts: [
          [video('hevc', profile: 'main 10', bitDepth: 10)],
        ],
      );
      final h264en = versao('h264-720-en', codec: 'h264', width: 1280, height: 720, language: 'eng');
      final h264pt = versao('h264-480-pt', codec: 'h264', width: 854, height: 480);
      final h264k = versao('h264-4k-pt', codec: 'h264', width: 3840, height: 2160);
      final ordem = rankMediaVersions([hevc10, h264en, h264pt, h264k]);
      expect(
        [
          for (final i in ordem) [hevc10, h264en, h264pt, h264k][i].id,
        ],
        ['h264-4k-pt', 'h264-480-pt', 'h264-720-en', 'hevc10-1080'],
      );
    });

    test('HDR sem BitDepth conta como 10 bits', () {
      tv1080SemMain10();
      final hdr = versao(
        'hdr',
        codec: 'hevc',
        width: 1920,
        height: 1080,
        parts: [
          [video('hevc', hdr: true)],
        ],
      );
      final sdr = versao('sdr', codec: 'h264', width: 1280, height: 720);
      expect(rankMediaVersions([hdr, sdr]), [1, 0]);
      expect(isVersionHardwareDecodable(hdr), isFalse);
    });
  });

  group('adendo 3 (revisão da Dum-e)', () {
    /// Decoder até 1080p: sem prova de tamanho, a fonte conta como 4K e não
    /// ganha hardware.
    void decoder1080() => VideoDecodeCapabilities.debugReset(
      hardwareHevc: true,
      displaySupports4k: false,
      codecHardware: {'h264': true, 'hevc': true},
      codecProfiles: {
        'h264': ['high'],
        'hevc': ['main'],
      },
      codecMaxResolutions: {'h264': '1080p60', 'hevc': '1080p60'},
    );

    test('item 2: "480p"/"SD" no meio do texto prova SD; "sdr" não', () {
      decoder1080();
      expect(isSourceHardwareDecodable(fonte('480', 'h264', name: 'Filme 480p')), isTrue);
      expect(isSourceHardwareDecodable(fonte('576', 'h264', name: 'Filme (576i)')), isTrue);
      expect(isSourceHardwareDecodable(fonte('sd', 'h264', displayTitle: 'SD H264')), isTrue);
      expect(isSourceHardwareDecodable(fonte('sdr', 'h264', displayTitle: 'H264 SDR')), isFalse);
      expect(isVersionHardwareDecodable(versao('plex-sd', codec: 'h264', resolution: 'sd')), isTrue);

      // "Filme 480p" não cai no pior caso (4K) e vence a sem prova.
      final ranked = rankMediaSources([
        fonte('sem-prova', 'h264', name: 'Filme'),
        fonte('480', 'h264', name: 'Filme 480p'),
      ]);
      expect(ranked.first['Id'], '480');
    });

    test('item 3: versão sem faixa de vídeo perde para H.264 1080p com prova', () {
      tv1080SemMain10();
      final semVideo = <String, dynamic>{
        'Id': 'sem-video',
        'Container': 'mkv',
        'MediaStreams': [
          {'Type': 'Audio', 'Language': 'por'},
        ],
      };
      // A com prova está sem PT: antes, a sem vídeo ganhava como "hardware + PT".
      final h264 = <String, dynamic>{
        'Id': 'h264-1080',
        'Container': 'mkv',
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'h264', 'Profile': 'High', 'BitDepth': 8, 'Width': 1920, 'Height': 1080},
          {'Type': 'Audio', 'Language': 'eng'},
        ],
      };
      expect(rankMediaSources([semVideo, h264]).first['Id'], 'h264-1080');
      expect(isSourceHardwareDecodable(semVideo), isFalse);
      // Tocabilidade (diálogo "não toca") segue leniente.
      expect(isSourcePlayable(semVideo), isTrue);

      // Plex: versão sem codec nem streams de vídeo.
      final plexSem = MediaVersion(
        id: 'plex-sem',
        container: 'mkv',
        parts: [
          MediaPart(
            id: 'p',
            streams: [MediaStream(id: 'a', kind: MediaStreamKind.audio, languageCode: 'por')],
          ),
        ],
      );
      final plex1080 = versao('plex-1080', codec: 'h264', width: 1920, height: 1080, language: 'eng');
      expect(rankMediaVersions([plexSem, plex1080]), [1, 0]);
      expect(isVersionHardwareDecodable(plexSem), isFalse);
      expect(isVersionPlayable(plexSem), isTrue);
    });
  });
}
