import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';

import 'package:heisuca/desktop/platform/desktop_connection_vault.dart';

Uint8List _fakeCipherTransform(Uint8List input) {
  return Uint8List.fromList(input.map((b) => b ^ 0x5A).toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MemoryDesktopConnectionVault', () {
    test('persistent deve retornar false', () {
      final vault = MemoryDesktopConnectionVault();
      expect(vault.persistent, isFalse);
    });

    test('read em cofre recem-criado retorna lista vazia', () async {
      final vault = MemoryDesktopConnectionVault();
      final entries = await vault.read();
      expect(entries, isEmpty);
    });

    test('grava e le entradas com sucesso', () async {
      final vault = MemoryDesktopConnectionVault();
      final original = [
        {'id': 'srv1', 'name': 'Plex Server', 'token': 'sec-1'},
        {'id': 'srv2', 'name': 'Jellyfin', 'token': 'sec-2'},
      ];

      await vault.write(original);
      final loaded = await vault.read();

      expect(loaded.length, equals(2));
      expect(loaded[0]['id'], equals('srv1'));
      expect(loaded[1]['name'], equals('Jellyfin'));
    });

    test('garante JSON deepcopy na escrita e leitura', () async {
      final vault = MemoryDesktopConnectionVault();
      final sourceMap = {'id': 'srv1', 'meta': {'token': 'orig'}};
      final list = [sourceMap];

      await vault.write(list);

      // Modifica lista e mapa de origem apos write
      list.add({'id': 'srv2'});
      (sourceMap['meta'] as Map<String, dynamic>)['token'] = 'mutated';

      final read1 = await vault.read();
      expect(read1.length, equals(1));
      expect((read1[0]['meta'] as Map)['token'], equals('orig'));

      // Modifica mapa retornado por read
      (read1[0]['meta'] as Map)['token'] = 'tampered';
      final read2 = await vault.read();
      expect((read2[0]['meta'] as Map)['token'], equals('orig'));
    });
  });

  group('PlatformWindowsVault', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vault_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('persistent deve retornar true', () {
      final vault = PlatformWindowsVault(
        getDirectory: () async => tempDir,
        protect: (data) async => data,
        unprotect: (data) async => data,
      );
      expect(vault.persistent, isTrue);
    });

    test('read em arquivo inexistente retorna lista vazia', () async {
      final vault = PlatformWindowsVault(
        getDirectory: () async => tempDir,
        protect: (data) async => data,
        unprotect: (data) async => data,
      );
      final entries = await vault.read();
      expect(entries, isEmpty);
    });

    test('escrita cifra payload e leitura decifra corretamente', () async {
      final vault = PlatformWindowsVault(
        getDirectory: () async => tempDir,
        protect: (data) async => _fakeCipherTransform(data),
        unprotect: (data) async => _fakeCipherTransform(data),
      );

      final entries = [
        {'id': 'plex_1', 'token': 'super_secret'}
      ];
      await vault.write(entries);

      final file = File('${tempDir.path}/${PlatformWindowsVault.fileName}');
      expect(await file.exists(), isTrue);

      final rawBytes = await file.readAsBytes();
      final asString = String.fromCharCodes(rawBytes);
      expect(asString.contains('super_secret'), isFalse);

      final restored = await vault.read();
      expect(restored.length, equals(1));
      expect(restored.first['id'], equals('plex_1'));
      expect(restored.first['token'], equals('super_secret'));
    });

    test('read lanca DesktopVaultException seguro em arquivo corrompido', () async {
      final file = File('${tempDir.path}/${PlatformWindowsVault.fileName}');
      await file.writeAsBytes(Uint8List.fromList([0x00, 0x01, 0x02, 0x03]), flush: true);

      final vault = PlatformWindowsVault(
        getDirectory: () async => tempDir,
        protect: (data) async => data,
        unprotect: (data) async => throw const DesktopVaultException('Corrupted cipher'),
      );

      expect(() => vault.read(), throwsA(isA<DesktopVaultException>()));
    });

    test('read lanca DesktopVaultException quando decifrado nao e JSON valido', () async {
      final file = File('${tempDir.path}/${PlatformWindowsVault.fileName}');
      await file.writeAsBytes(Uint8List.fromList(utf8.encode('not-a-json')), flush: true);

      final vault = PlatformWindowsVault(
        getDirectory: () async => tempDir,
        protect: (data) async => data,
        unprotect: (data) async => data,
      );

      expect(() => vault.read(), throwsA(isA<DesktopVaultException>()));
    });

    test('falha no protect nao grava arquivo em claro e lanca erro', () async {
      final vault = PlatformWindowsVault(
        getDirectory: () async => tempDir,
        protect: (data) async => throw const DesktopVaultException('DPAPI Blocked'),
        unprotect: (data) async => data,
      );

      expect(
        () => vault.write([{'secret': 'plain'}]),
        throwsA(isA<DesktopVaultException>()),
      );

      final file = File('${tempDir.path}/${PlatformWindowsVault.fileName}');
      expect(await file.exists(), isFalse);
    });

    test('escritas concorrentes sao serializadas sem corrupcao de dados', () async {
      final vault = PlatformWindowsVault(
        getDirectory: () async => tempDir,
        protect: (data) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _fakeCipherTransform(data);
        },
        unprotect: (data) async => _fakeCipherTransform(data),
      );

      final futures = <Future<void>>[];
      for (var i = 0; i < 10; i++) {
        futures.add(vault.write([
          {'index': i}
        ]));
      }
      await Future.wait(futures);

      final readResult = await vault.read();
      expect(readResult.length, equals(1));
      expect(readResult.first['index'], equals(9));
    });
  });

  group('MethodChannel Fake Integration', () {
    late Directory tempDir;
    const channel = MethodChannel('heisuca/desktop_vault');

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vault_channel_test_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'protect') {
          final bytes = methodCall.arguments as Uint8List;
          return _fakeCipherTransform(bytes);
        } else if (methodCall.method == 'unprotect') {
          final bytes = methodCall.arguments as Uint8List;
          return _fakeCipherTransform(bytes);
        }
        return null;
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('roundtrip via MethodChannel falso', () async {
      final vault = PlatformWindowsVault(
        getDirectory: () async => tempDir,
        channel: channel,
      );

      await vault.write([
        {'server': 'remote_1', 'key': 'secret_key'}
      ]);

      final loaded = await vault.read();
      expect(loaded.length, equals(1));
      expect(loaded.first['server'], equals('remote_1'));
      expect(loaded.first['key'], equals('secret_key'));
    });
  });

  group('createDesktopConnectionVault', () {
    test('retorna instancia funcional de DesktopConnectionVault', () {
      final vault = createDesktopConnectionVault();
      expect(vault, isA<DesktopConnectionVault>());
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        expect(vault.persistent, isTrue);
      } else {
        expect(vault.persistent, isFalse);
      }
    });
  });
  test('cofre serializa leitura com escrita pendente e congela pedido', () async {
    final dir = await Directory.systemTemp.createTemp('vault_queue_test_');
    addTearDown(() => dir.delete(recursive: true));
    final gate = Completer<void>();
    final vault = PlatformWindowsVault(
      getDirectory: () async => dir,
      protect: (bytes) async { await gate.future; return _fakeCipherTransform(bytes); },
      unprotect: (bytes) async => _fakeCipherTransform(bytes),
    );
    final entries = <Map<String, dynamic>>[{'id': 'original'}];
    final write = vault.write(entries);
    entries.first['id'] = 'changed';
    final read = vault.read();
    gate.complete();
    await write;
    expect((await read).single['id'], 'original');
    final disk = await File('${dir.path}/${PlatformWindowsVault.fileName}').readAsBytes();
    expect(utf8.decode(disk, allowMalformed: true), isNot(contains('original')));
  });

  test('falha de escrita não quebra fila e exceção não revela entrada', () async {
    final dir = await Directory.systemTemp.createTemp('vault_recovery_test_');
    addTearDown(() => dir.delete(recursive: true));
    var attempts = 0;
    final vault = PlatformWindowsVault(
      getDirectory: () async => dir,
      protect: (bytes) async {
        if (++attempts == 1) throw StateError('CANARIO_NAO_EXIBIR');
        return _fakeCipherTransform(bytes);
      },
      unprotect: (bytes) async => _fakeCipherTransform(bytes),
    );
    await expectLater(vault.write([{'id':'one'}]), throwsA(predicate<Object>(
      (e) => e is DesktopVaultException && !e.toString().contains('CANARIO_NAO_EXIBIR'))));
    await vault.write([{'id': 'two'}]);
    expect((await vault.read()).single['id'], 'two');
    await expectLater(vault.write([{'invalid': Object()}]), throwsA(isA<DesktopVaultException>()));
  });

}
