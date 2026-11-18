import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/desktop_preferences.dart';

void main() {
  test('histórico aceita só arquivos locais, nunca URLs, userinfo ou payload inválido', () {
    final preferences = DesktopPreferences();
    addTearDown(preferences.dispose);
    for (final uri in ['https://host/video?token=CANARIO', 'file://user:pass@host/video',
      'file://@host/video', 'FILE://@host/video', 'file:///a?token=x', 'file:///a#fragment', 'file:///a%0Afile']) {
      preferences.recordLocal(uri: uri, title: 'Teste', positionMs: 10, durationMs: 1000);
    }
    expect(preferences.recents, isEmpty);
    preferences.recordLocal(uri: 'file:///C:/Filmes/ação%20teste.mkv', title: 'Ação teste',
      positionMs: 12000, durationMs: 60000);
    expect(preferences.recents.single.resumePositionMs, 12000);
  });

  test('recentes têm limite, deduplicam, retomam e filme concluído recomeça', () {
    final preferences = DesktopPreferences();
    addTearDown(preferences.dispose);
    for (var i = 0; i < 15; i++) {
      preferences.recordLocal(uri: 'file:///tmp/video$i.mkv', title: 'Vídeo $i', positionMs: 0, durationMs: 100000);
    }
    expect(preferences.recents, hasLength(12));
    preferences.recordLocal(uri: 'file:///tmp/video8.mkv', title: 'Vídeo 8', positionMs: 96000, durationMs: 100000);
    expect(preferences.recents.first.uri, endsWith('video8.mkv'));
    expect(preferences.recents.where((entry) => entry.uri.endsWith('video8.mkv')), hasLength(1));
    expect(preferences.recents.first.resumePositionMs, 0);
    expect(() => preferences.recents.clear(), throwsUnsupportedError);
  });

  test('ticks não geram escrita/notificação a cada frame, flush guarda offset final', () {
    final preferences = DesktopPreferences();
    addTearDown(preferences.dispose);
    var notifications = 0;
    preferences.addListener(() => notifications++);
    for (var i = 0; i < 10; i++) {
      preferences.recordLocal(uri: 'file:///tmp/video.mkv', title: 'Vídeo', positionMs: i * 1000, durationMs: 100000);
    }
    expect(notifications, 1);
    preferences.recordLocal(uri: 'file:///tmp/video.mkv', title: 'Vídeo', positionMs: 9500, durationMs: 100000, force: true);
    expect(preferences.recents.single.positionMs, 9500);
  });

  test('tema e histórico sobrevivem reabertura; limpar não apaga vídeo', () async {
    final directory = await Directory.systemTemp.createTemp('heisuca-prefs-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/settings.json');
    final video = await File('${directory.path}/meu-video.mkv').writeAsString('Arquivo do usuário');
    final preferences = DesktopPreferences(file: () async => file);
    addTearDown(preferences.dispose);
    preferences.setTheme('hisui');
    preferences.recordLocal(uri: video.uri.toString(), title: 'Meu vídeo', positionMs: 30000, durationMs: 60000);
    await preferences.flush();
    final restored = DesktopPreferences(file: () async => file);
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.theme, 'hisui');
    expect(restored.recents.single.positionMs, 30000);
    restored.clearRecents();
    await restored.flush();
    expect((jsonDecode(await file.readAsString()) as Map)['recents'], isEmpty);
    expect(await video.readAsString(), 'Arquivo do usuário');
  });

  test('escolha durante load preserva tema novo e mescla arquivos; limpar não ressuscita histórico', () async {
    final directory = await Directory.systemTemp.createTemp('heisuca-prefs-race-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/settings.json');
    await file.writeAsString(jsonEncode({'version': 1, 'theme': 'sumi', 'recents': [
      {'uri': 'file:///tmp/old.mkv', 'title': 'Antigo', 'positionMs': 10000, 'durationMs': 60000},
    ]}));
    final gate = Completer<File>();
    final preferences = DesktopPreferences(file: () => gate.future);
    addTearDown(preferences.dispose);
    final load = preferences.load();
    preferences.setTheme('hisui');
    preferences.recordLocal(uri: 'file:///tmp/new.mkv', title: 'Novo', positionMs: 20000, durationMs: 60000);
    gate.complete(file);
    await load;
    await preferences.flush();
    expect(preferences.theme, 'hisui');
    expect(preferences.recents.map((entry) => entry.title), ['Novo', 'Antigo']);
    final secondGate = Completer<File>();
    final cleared = DesktopPreferences(file: () => secondGate.future);
    addTearDown(cleared.dispose);
    final pendingLoad = cleared.load();
    cleared.clearRecents();
    secondGate.complete(file);
    await pendingLoad;
    await cleared.flush();
    expect(cleared.recents, isEmpty);
  });

  test('dados corrompidos e falha de IO não expõem conteúdo nem quebram fila', () async {
    final directory = await Directory.systemTemp.createTemp('heisuca-prefs-error-');
    addTearDown(() => directory.delete(recursive: true));
    final file = await File('${directory.path}/settings.json').writeAsString('CANARIO_PRIVADO {invalid');
    final preferences = DesktopPreferences(file: () async => file);
    addTearDown(preferences.dispose);
    await preferences.load();
    expect(preferences.persistenceError, isNotNull);
    expect(preferences.persistenceError, isNot(contains('CANARIO_PRIVADO')));
    preferences.setTheme('sumi');
    await preferences.flush();
    expect(preferences.persistenceError, isNull);
    expect((jsonDecode(await file.readAsString()) as Map)['theme'], 'sumi');
  });
}
