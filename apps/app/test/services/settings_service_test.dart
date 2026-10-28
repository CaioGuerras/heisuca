import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/models/audio_channel_limit.dart';
import 'package:heisuca/models/audio_quality_preset.dart';
import 'package:heisuca/models/transcode_quality_preset.dart';
import 'package:heisuca/services/base_shared_preferences_service.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/utils/platform_detector.dart';

import '../test_helpers/prefs.dart';

void main() {
  test('continuar ouvindo exige escolha explícita', () async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    expect(settings.read(SettingsService.continueListening), isFalse);
    await settings.write(SettingsService.continueListening, true);
    expect(settings.read(SettingsService.continueListening), isTrue);
  });
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.debugSetAutomotiveOverride(null);
  });

  group('SettingsService.parseMpvConfigText', () {
    test('parses plain key=value lines', () {
      final out = SettingsService.parseMpvConfigText('hwdec=auto\nvolume=100');
      expect(out, {'hwdec': 'auto', 'volume': '100'});
    });

    test('trims whitespace around key and value', () {
      final out = SettingsService.parseMpvConfigText('  hwdec   =   auto  ');
      expect(out, {'hwdec': 'auto'});
    });

    test('skips blank lines', () {
      final out = SettingsService.parseMpvConfigText('\n\nhwdec=auto\n\n');
      expect(out, {'hwdec': 'auto'});
    });

    test('skips # comment lines (even with leading whitespace)', () {
      final out = SettingsService.parseMpvConfigText('# this is a comment\n  # indented comment\nhwdec=auto');
      expect(out, {'hwdec': 'auto'});
    });

    test('skips lines without an = sign', () {
      final out = SettingsService.parseMpvConfigText('justakey\nfoo=bar');
      expect(out, {'foo': 'bar'});
    });

    test('skips lines starting with = (empty key)', () {
      final out = SettingsService.parseMpvConfigText('=value\nfoo=bar');
      expect(out, {'foo': 'bar'});
    });

    test('preserves = signs in value (splits on first only)', () {
      final out = SettingsService.parseMpvConfigText('params=a=1,b=2');
      expect(out, {'params': 'a=1,b=2'});
    });

    test('allows empty value', () {
      final out = SettingsService.parseMpvConfigText('flag=');
      expect(out, {'flag': ''});
    });

    test('later duplicate key overrides earlier', () {
      final out = SettingsService.parseMpvConfigText('k=1\nk=2');
      expect(out, {'k': '2'});
    });

    test('empty input yields empty map', () {
      expect(SettingsService.parseMpvConfigText(''), isEmpty);
    });

    test('strips one pair of matching single quotes around the value (#2025)', () {
      final out = SettingsService.parseMpvConfigText("sub-font = 'NetflixSans-Bold'");
      expect(out, {'sub-font': 'NetflixSans-Bold'});
    });

    test('strips one pair of matching double quotes around the value', () {
      final out = SettingsService.parseMpvConfigText('sub-font = "Netflix Sans"');
      expect(out, {'sub-font': 'Netflix Sans'});
    });

    test('strips quotes from numeric values so the property API can parse them', () {
      final out = SettingsService.parseMpvConfigText("sub-pos = '85'\nsub-blur = '0.2'");
      expect(out, {'sub-pos': '85', 'sub-blur': '0.2'});
    });

    test('keeps an unmatched leading quote verbatim', () {
      final out = SettingsService.parseMpvConfigText("k='abc");
      expect(out, {'k': "'abc"});
    });

    test('keeps mismatched quote kinds verbatim', () {
      final out = SettingsService.parseMpvConfigText('k=\'abc"');
      expect(out, {'k': '\'abc"'});
    });

    test('keeps interior quotes', () {
      final out = SettingsService.parseMpvConfigText("k=it's");
      expect(out, {'k': "it's"});
    });

    test('empty quoted value yields empty string', () {
      final out = SettingsService.parseMpvConfigText("flag=''");
      expect(out, {'flag': ''});
    });

    test('strips only the outer quote pair', () {
      final out = SettingsService.parseMpvConfigText('k="\'a\'"');
      expect(out, {'k': "'a'"});
    });
  });

  group('SettingsService episode action', () {
    test('defaults to play and resets to play', () async {
      final settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.episodeAction), EpisodeAction.play);

      await settings.write(SettingsService.episodeAction, EpisodeAction.details);
      expect(settings.read(SettingsService.episodeAction), EpisodeAction.details);

      await settings.resetAllSettings();
      expect(settings.read(SettingsService.episodeAction), EpisodeAction.play);
    });
  });

  group('SettingsService skip marker modes', () {
    test('default to showing the button, independently per marker kind', () async {
      final settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.skipIntroMode), SkipMarkerMode.button);
      expect(settings.read(SettingsService.skipCreditsMode), SkipMarkerMode.button);

      await settings.write(SettingsService.skipIntroMode, SkipMarkerMode.off);
      expect(settings.read(SettingsService.skipIntroMode), SkipMarkerMode.off);
      expect(settings.read(SettingsService.skipCreditsMode), SkipMarkerMode.button);
    });

    test('migrate the legacy auto-skip booleans: on → auto, off → button (#2138)', () async {
      resetSharedPreferencesForTest(initialAsync: const {'auto_skip_intro': true, 'auto_skip_credits': false});
      final settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.skipIntroMode), SkipMarkerMode.auto);
      expect(settings.read(SettingsService.skipCreditsMode), SkipMarkerMode.button);
      expect(settings.prefs.containsKey('auto_skip_intro'), isFalse, reason: 'migrated once, then forgotten');
      expect(settings.prefs.containsKey('auto_skip_credits'), isFalse);

      // An explicit choice still works after ordinary upgrade migration.
      await settings.write(SettingsService.skipIntroMode, SkipMarkerMode.off);
      expect(settings.read(SettingsService.skipIntroMode), SkipMarkerMode.off);
    });

    test('canonical modes win over coexisting legacy booleans on first read', () async {
      resetSharedPreferencesForTest(
        initialAsync: const {
          'auto_skip_intro': true,
          'skip_intro_mode': 'off',
          'auto_skip_credits': false,
          'skip_credits_mode': 'auto',
        },
      );
      var settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.skipIntroMode), SkipMarkerMode.off);
      expect(settings.read(SettingsService.skipCreditsMode), SkipMarkerMode.auto);
      expect(settings.prefs.containsKey('auto_skip_intro'), isFalse);
      expect(settings.prefs.containsKey('auto_skip_credits'), isFalse);

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.skipIntroMode), SkipMarkerMode.off);
      expect(settings.read(SettingsService.skipCreditsMode), SkipMarkerMode.auto);
    });

    test('writing a mode before its first read replaces the legacy choice', () async {
      resetSharedPreferencesForTest(initialAsync: const {'auto_skip_intro': true, 'auto_skip_credits': false});
      final settings = await SettingsService.getInstance();

      await settings.write(SettingsService.skipIntroMode, SkipMarkerMode.off);
      await settings.write(SettingsService.skipCreditsMode, SkipMarkerMode.auto);

      expect(settings.read(SettingsService.skipIntroMode), SkipMarkerMode.off);
      expect(settings.read(SettingsService.skipCreditsMode), SkipMarkerMode.auto);
    });

    for (final introAuto in [true, false]) {
      for (final readBeforeReset in [false, true]) {
        test('reset preserves intro=$introAuto before migration=${!readBeforeReset}', () async {
          resetSharedPreferencesForTest(
            initialAsync: {'auto_skip_intro': introAuto, 'auto_skip_credits': !introAuto, 'seek_time_small': 45},
          );
          var settings = await SettingsService.getInstance();
          final introMode = introAuto ? SkipMarkerMode.auto : SkipMarkerMode.button;
          final creditsMode = introAuto ? SkipMarkerMode.button : SkipMarkerMode.auto;
          if (readBeforeReset) {
            expect(settings.read(SettingsService.skipIntroMode), introMode);
            expect(settings.read(SettingsService.skipCreditsMode), creditsMode);
          }

          await settings.resetAllSettings();

          expect(settings.read(SettingsService.skipIntroMode), introMode);
          expect(settings.read(SettingsService.skipCreditsMode), creditsMode);
          expect(settings.read(SettingsService.seekTimeSmall), 10);

          BaseSharedPreferencesService.resetForTesting();
          SettingsService.resetForTesting();
          settings = await SettingsService.getInstance();
          expect(settings.read(SettingsService.skipIntroMode), introMode);
          expect(settings.read(SettingsService.skipCreditsMode), creditsMode);
        });
      }
    }

    test('reset preserves canonical authority without materializing an absent mode', () async {
      resetSharedPreferencesForTest(initialAsync: const {'skip_intro_mode': 'off', 'auto_skip_intro': true});
      final settings = await SettingsService.getInstance();

      await settings.resetAllSettings();

      expect(settings.read(SettingsService.skipIntroMode), SkipMarkerMode.off);
      expect(settings.prefs.containsKey('auto_skip_intro'), isFalse);
      expect(settings.prefs.containsKey('skip_credits_mode'), isFalse);
      expect(settings.read(SettingsService.skipCreditsMode), SkipMarkerMode.button);
      expect(settings.prefs.containsKey('skip_credits_mode'), isFalse);
    });
  });

  group('SettingsService audio channel limit', () {
    for (final (downmix, limit) in [(true, AudioChannelLimit.stereo), (false, AudioChannelLimit.original)]) {
      test('migrates the legacy downmix toggle=$downmix to ${limit.name} (#2442)', () async {
        resetSharedPreferencesForTest(initialAsync: {'audio_downmix': downmix});
        final settings = await SettingsService.getInstance();

        expect(settings.read(SettingsService.audioChannelLimit), limit);
        expect(settings.prefs.containsKey('audio_downmix'), isFalse, reason: 'migrated once, then forgotten');
      });
    }

    test('reset clears an unread legacy stereo downmix instead of restoring it', () async {
      resetSharedPreferencesForTest(initialAsync: const {'audio_downmix': true});
      var settings = await SettingsService.getInstance();

      await settings.resetAllSettings();
      expect(settings.read(SettingsService.audioChannelLimit), AudioChannelLimit.original);

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.audioChannelLimit), AudioChannelLimit.original);
    });
  });

  group('SettingsService music quality', () {
    test('defaults to original and persists changes by enum name', () async {
      var settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.musicQualityPreset), AudioQualityPreset.original);

      await settings.write(SettingsService.musicQualityPreset, AudioQualityPreset.medium);
      expect(settings.prefs.getString(SettingsService.musicQualityPreset.key), 'medium');

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.musicQualityPreset), AudioQualityPreset.medium);
    });
  });

  group('SettingsService cellular quality', () {
    test('defaults to null (follow the general default) and persists by enum name', () async {
      var settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.cellularQualityPreset), isNull);

      await settings.write(SettingsService.cellularQualityPreset, TranscodeQualityPreset.p720_2mbps);
      expect(settings.prefs.getString(SettingsService.cellularQualityPreset.key), 'p720_2mbps');

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.cellularQualityPreset), TranscodeQualityPreset.p720_2mbps);
    });

    test('writing null removes the key', () async {
      final settings = await SettingsService.getInstance();

      await settings.write(SettingsService.cellularQualityPreset, TranscodeQualityPreset.p1080_8mbps);
      await settings.write(SettingsService.cellularQualityPreset, null);

      expect(settings.prefs.containsKey(SettingsService.cellularQualityPreset.key), isFalse);
      expect(settings.read(SettingsService.cellularQualityPreset), isNull);
    });

    test('an unrecognized stored value reads as null, not a fallback preset', () async {
      final settings = await SettingsService.getInstance();

      await settings.prefs.setString(SettingsService.cellularQualityPreset.key, 'p9999_removed');

      expect(settings.read(SettingsService.cellularQualityPreset), isNull);
    });
  });

  group('SettingsService app locale', () {
    test('persists script-specific locales by enum name', () async {
      var settings = await SettingsService.getInstance();

      await settings.write(SettingsService.appLocale, AppLocale.zhHant);
      expect(settings.prefs.getString(SettingsService.appLocale.key), 'zhHant');

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.appLocale), AppLocale.zhHant);
    });

    test('continues to read legacy language-code values', () async {
      var settings = await SettingsService.getInstance();
      await settings.prefs.setString(SettingsService.appLocale.key, 'zh');

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.appLocale), AppLocale.zh);
    });
  });

  group('SettingsService platform gates', () {
    test('audio passthrough stays available on Apple TV and non-macOS desktop, never macOS', () {
      // Platform.is* is unmockable, so the desktop expectation follows the
      // test host: hidden on a macOS host (#1964), available elsewhere.
      expect(PlatformDetector.supportsAudioPassthrough(), Platform.isMacOS ? isFalse : isTrue);

      TvDetectionService.debugSetAppleTVOverride(true);

      expect(PlatformDetector.supportsAudioPassthrough(), isTrue);
    });

    test('audio passthrough defaults off on a non-TV host and honors explicit writes', () async {
      final settings = await SettingsService.getInstance();
      // The Android-TV default-on branch depends on Platform.isAndroid, which
      // is false (and unmockable) on the test host, so the default is off here.
      expect(settings.read(SettingsService.audioPassthrough), isFalse);

      await settings.write(SettingsService.audioPassthrough, true);
      expect(settings.read(SettingsService.audioPassthrough), isTrue);

      await settings.write(SettingsService.audioPassthrough, false);
      expect(settings.read(SettingsService.audioPassthrough), isFalse);
    });

    test('audio passthrough defaults on for Apple TV until the viewer turns it off (#1300)', () async {
      final settings = await SettingsService.getInstance();
      TvDetectionService.debugSetAppleTVOverride(true);

      expect(settings.read(SettingsService.audioPassthrough), isTrue);

      await settings.write(SettingsService.audioPassthrough, false);
      expect(settings.read(SettingsService.audioPassthrough), isFalse);
    });

    test('forces auto PiP off on Apple TV even when stored enabled', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.autoPip, true);

      TvDetectionService.debugSetAppleTVOverride(true);

      expect(settings.read(SettingsService.autoPip), isFalse);
    });

    test('forces auto PiP off on automotive while honoring the stored value elsewhere', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.autoPip, true);

      // The pref can only surface a stored true where the host itself supports
      // PiP. That term is Platform.isAndroid/isIOS/isMacOS, unmockable and false
      // on the Linux and Windows CI hosts, where the gate pins the pref off no
      // matter what is stored. pictureInPictureAllowed covers the automotive
      // veto itself on every host.
      final hostSupportsPip = PlatformDetector.supportsPictureInPicture();
      expect(settings.read(SettingsService.autoPip), hostSupportsPip ? isTrue : isFalse);

      TvDetectionService.debugSetAutomotiveOverride(true);

      expect(settings.read(SettingsService.autoPip), isFalse);
    });
  });

  group('SettingsService Watch Together relay', () {
    test('typed writes canonicalize valid bases and reject invalid replacement', () async {
      final settings = await SettingsService.getInstance();

      await settings.write(SettingsService.customRelayUrl, '  HTTPS://Relay.Example.Test/path///  ');
      expect(settings.read(SettingsService.customRelayUrl), 'https://relay.example.test/path');

      await expectLater(
        settings.write(SettingsService.customRelayUrl, 'ws://relay.example.test'),
        throwsFormatException,
      );
      expect(settings.read(SettingsService.customRelayUrl), 'https://relay.example.test/path');

      await settings.write(SettingsService.customRelayUrl, '   ');
      expect(settings.read(SettingsService.customRelayUrl), isNull);
    });

    test('startup canonicalizes valid history and removes invalid history', () async {
      resetSharedPreferencesForTest(
        initialAsync: {SettingsService.customRelayUrl.key: '  http://Relay.Example.Test:8080/prefix// '},
      );
      SettingsService.resetForTesting();
      var settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.customRelayUrl), 'http://relay.example.test:8080/prefix');

      resetSharedPreferencesForTest(
        initialAsync: {SettingsService.customRelayUrl.key: 'https://relay.example.test/path?wrong=route'},
      );
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.customRelayUrl), isNull);
    });
  });

  group('SettingsService listenables', () {
    test('refreshListenables updates active prefs outside the resettable surface', () async {
      final settings = await SettingsService.getInstance();
      final pref = SettingsService.autoHidePerformanceOverlay;
      final scrobble = settings.listenable(pref);

      expect(scrobble.value, isTrue);

      await settings.prefs.setBool(pref.key, false);
      expect(scrobble.value, isTrue);

      settings.refreshListenables();

      expect(scrobble.value, isFalse);
    });

  });
  group('BaseSharedPreferencesService initialization generations', () {
    test('a reset-raced initialization resolves to the replacement backend', () async {
      resetSharedPreferencesForTest(initialAsync: const {'generation_marker': 'old'});
      final firstOnInit = Completer<void>();
      final firstStarted = Completer<void>();
      var constructions = 0;

      final raced = BaseSharedPreferencesService.initializeInstance<_GenerationTestPreferences>(() {
        final construction = constructions++;
        return _GenerationTestPreferences(
          construction,
          onInitStarted: construction == 0 ? firstStarted : null,
          onInitGate: construction == 0 ? firstOnInit : null,
        );
      });
      await firstStarted.future;

      resetSharedPreferencesForTest(initialAsync: const {'generation_marker': 'new'});
      final replacement = await BaseSharedPreferencesService.initializeInstance<_GenerationTestPreferences>(
        () => _GenerationTestPreferences(constructions++),
      );
      firstOnInit.complete();
      final recovered = await raced;

      expect(recovered, same(replacement));
      expect(recovered.construction, 1);
      expect(recovered.readString('generation_marker'), 'new');
      expect(constructions, 2);
    });
  });
}

class _GenerationTestPreferences extends BaseSharedPreferencesService {
  _GenerationTestPreferences(this.construction, {this.onInitStarted, this.onInitGate});

  final int construction;
  final Completer<void>? onInitStarted;
  final Completer<void>? onInitGate;

  @override
  Future<void> onInit() async {
    onInitStarted?.complete();
    await onInitGate?.future;
  }
}
