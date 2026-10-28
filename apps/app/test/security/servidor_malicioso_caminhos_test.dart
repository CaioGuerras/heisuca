import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/services/download_storage_service.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

/// P5 lote 4, caso 2: nomes e ids do servidor nunca escrevem fora da pasta de
/// downloads. Cada caminho produzido é canonicalizado e tem de ficar DENTRO da
/// raiz, sem sobras criadas ao lado dela.
void main() {
  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;
  late DownloadStorageService dss;
  late String downloads;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    tmpRoot = await Directory.systemTemp.createTemp('p5_caminhos_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
    dss = DownloadStorageService.instance;
    await dss.initialize(await SettingsService.getInstance());
    downloads = p.canonicalize((await dss.getDownloadsDirectory()).path);
  });

  tearDown(() async {
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  });

  /// Nomes de componente que um servidor hostil pode mandar.
  final hostileIds = <String>[
    '../../../shared_prefs',
    '..',
    '.',
    '...',
    'a/b',
    r'a\b',
    '/etc/passwd',
    r'C:\Windows\System32',
    '%2e%2e/%2e%2e',
    '%2e%2e%2f',
    'a\u0000b',
    'a\nb\t\r',
    '\u001f\u0001',
    'CON',
    'NUL',
    'com1.txt',
    ' ',
    'x' * 1000,
    '..\u0000/..',
  ];

  final hostileExtensions = <String>[
    'srt/../../../shared_prefs/x',
    '../../x',
    r'..\..\x',
    '/abs',
    'a\u0000b',
    '',
    '.',
    '..',
    'x' * 1000,
    '%2e%2e%2f',
  ];

  void expectContained(String path) {
    final canonical = p.canonicalize(path);
    expect(p.isWithin(downloads, canonical), isTrue, reason: '$path escapou de $downloads');
    final relative = p.relative(canonical, from: downloads);
    for (final part in p.split(relative)) {
      expect(part, isNot('..'));
      expect(part.codeUnits.any((c) => c < 0x20 || c == 0x7f), isFalse, reason: 'controle em "$part"');
      expect(part.length, lessThanOrEqualTo(255));
      expect(part, isNotEmpty);
    }
  }

  /// Nada pode ter sido criado fora de `downloads` (pasta irmã, vizinhos).
  void expectNothingStrayed() {
    final base = p.dirname(downloads);
    final stray = Directory(base)
        .listSync(recursive: true, followLinks: false)
        .map((e) => p.canonicalize(e.path))
        .where((e) => !p.isWithin(downloads, e) && e != downloads)
        .where((e) => !p.basename(e).startsWith('artwork'))
        .toList();
    expect(stray, isEmpty);
  }

  group('ids e extensão vindos do servidor', () {
    test('getMediaDirectory / getVideoFilePath', () async {
      for (final id in hostileIds) {
        for (final rating in hostileIds) {
          expectContained((await dss.getMediaDirectory(ServerId(id.trim().isEmpty ? 'x' : id), rating)).path);
        }
      }
      expectNothingStrayed();
    });

    test('getSubtitlePath / getSubtitlesDirectory com extension hostil', () async {
      for (final ext in hostileExtensions) {
        expectContained(await dss.getSubtitlePath(ServerId('srv'), 'rk-1', 7, ext));
        expectContained((await dss.getSubtitlesDirectory(ServerId('srv'), '../..')).path);
      }
      expectNothingStrayed();
    });

    test('getVideoFilePath com extension hostil', () async {
      for (final ext in hostileExtensions) {
        expectContained(await dss.getVideoFilePath(ServerId('srv'), 'rk-1', ext));
      }
      expectNothingStrayed();
    });

    test('ids legítimos (hex do Jellyfin, número do Plex, UUID) passam inalterados', () async {
      final dir = await dss.getMediaDirectory(
        ServerId('0123abcd-ef01-2345-6789-abcdef012345'),
        '4f1e2d3c4b5a69788796a5b4c3d2e1f0',
      );
      expect(p.basename(dir.path), '4f1e2d3c4b5a69788796a5b4c3d2e1f0');
      expect(p.basename(p.dirname(dir.path)), '0123abcd-ef01-2345-6789-abcdef012345');
      expect(
        await dss.getSubtitlePath(ServerId('s'), '12345', 3, 'srt'),
        endsWith(p.join('12345', 'subtitles', '3.srt')),
      );
    });

    test('ids diferentes que saneiam igual não colidem', () async {
      final a = await dss.getMediaDirectory(ServerId('s'), 'a/b');
      final b = await dss.getMediaDirectory(ServerId('s'), 'a_b');
      expect(a.path, isNot(b.path));
    });
  });

  group('títulos vindos do servidor', () {
    final titles = <String>[
      '..',
      '.',
      '...',
      '',
      '   ',
      '../../x',
      r'..\..\x',
      '/',
      'a\u0000b',
      'a\u001fb\u007f',
      'CON',
      'aux.txt',
      'LPT1',
      'x' * 1000,
      'é' * 400,
      '%2e%2e%2f',
      '<>:"/\\|?*',
    ];

    MediaItem item(MediaKind kind, String title) => testMediaItem(
      id: 'i-${title.length}',
      backend: MediaBackend.jellyfin,
      kind: kind,
      title: title,
      grandparentTitle: title,
      parentTitle: title,
      year: 2020,
      parentIndex: 1,
      index: 1,
    );

    test('filme, episódio e faixa ficam dentro da raiz', () async {
      for (final t in titles) {
        expectContained(await dss.getMovieVideoPath(item(MediaKind.movie, t), 'mkv'));
        expectContained(await dss.getMovieSubtitlePath(item(MediaKind.movie, t), 1, 'srt'));
        expectContained(await dss.getEpisodeVideoPath(item(MediaKind.episode, t), 'mkv'));
        expectContained(await dss.getEpisodeSubtitlePath(item(MediaKind.episode, t), 1, 'srt'));
        expectContained(await dss.getEpisodeThumbnailPath(item(MediaKind.episode, t)));
        expectContained(await dss.getTrackAudioPath(item(MediaKind.track, t), 'mp3'));
      }
      expectNothingStrayed();
    });

    test('componentes SAF não trazem separador, controle, vazio nem nome gigante', () {
      for (final t in titles) {
        final comps = [
          ...dss.getMovieSafPathComponents(item(MediaKind.movie, t)),
          ...dss.getEpisodeSafPathComponents(item(MediaKind.episode, t)),
          ...dss.getTrackSafPathComponents(item(MediaKind.track, t)),
          dss.getMovieSafFileName(item(MediaKind.movie, t), 'mkv'),
          dss.getEpisodeSafFileName(item(MediaKind.episode, t), 'mkv'),
          dss.getTrackSafFileName(item(MediaKind.track, t), 'mp3'),
        ];
        for (final c in comps) {
          expect(c, isNotEmpty);
          expect(c, isNot('..'));
          expect(c, isNot('.'));
          expect(c.contains('/') || c.contains(r'\'), isFalse, reason: c);
          expect(c.codeUnits.any((u) => u < 0x20 || u == 0x7f), isFalse, reason: c);
          expect(c.length, lessThanOrEqualTo(255));
        }
      }
    });
  });

  test('artwork usa hash MD5: caminho do servidor não vira componente', () async {
    final path = await dss.getArtworkPathFromThumb(ServerId('s'), '../../../etc/passwd');
    expect(p.dirname(p.canonicalize(path)), p.canonicalize(dss.artworkDirectoryPath!));
    expect(p.basename(path), matches(RegExp(r'^[0-9a-f]{32}\.jpg$')));
  });
}
