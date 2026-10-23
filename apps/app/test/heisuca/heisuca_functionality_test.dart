import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/heisuca/heisuca_add_smb_screen.dart';
import 'package:plezy/heisuca/services/heisuca_device_service.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/track_selection_service.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetSharedPreferencesForTest);

  test('hardware ausente não vira um aparelho flagship', () {
    final profile = HeisucaDeviceProfile.fromMap(const {});
    expect(profile.deviceName, isNull);
    expect(profile.maxRefreshRateHz, isNull);
    expect(profile.hardwareSummary, 'Informações não fornecidas pelo sistema');
  });

  test('usa apenas os sinais reportados pelo Android', () async {
    const channel = MethodChannel('com.plezy/device');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getHeisucaDeviceProfile');
      return {'deviceName': 'Tablet de teste', 'totalMemBytes': 4294967296, 'maxRefreshRateHz': 60.0};
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await HeisucaDeviceService.instance.initialize();
    final profile = HeisucaDeviceService.instance.profile;
    expect(profile.deviceName, 'Tablet de teste');
    expect(profile.chipset, isNull);
    expect(profile.hardwareSummary, contains('60 Hz'));
    expect(profile.hardwareSummary, isNot(contains('HDR')));
  });

  test('português é opt-in, aceita pt-BR e preserva escolha manual e fallback', () async {
    final settings = await SettingsService.getInstance();
    final selector = TrackSelectionService(metadata: MediaItem.jellyfin(id: 'movie', kind: MediaKind.movie, title: 'Teste'));
    final english = AudioTrack(id: '1', language: 'eng', isDefault: true);
    final portuguese = AudioTrack(id: '2', language: 'pt-BR');
    final tracks = [english, portuguese];
    expect(selector.selectAudioTrack(tracks, null)?.track, english);
    await settings.write(SettingsService.heisucaPreferPortugueseAudio, true);
    expect(selector.selectAudioTrack(tracks, null)?.track, portuguese);
    expect(selector.selectAudioTrack(tracks, english)?.track, english);
    expect(selector.selectAudioTrack([english], null)?.track, english);
    await settings.write(SettingsService.heisucaPreferPortugueseAudio, false);
    expect(selector.selectAudioTrack(tracks, null)?.track, english);
  });

  testWidgets('SMB não coleta senha nem anuncia conexão inexistente', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HeisucaAddSmbScreen()));
    expect(find.text('SMB ainda não está disponível nesta versão.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
