import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/services/playback_diagnostics.dart';
import 'package:heisuca/services/updates/apk_installer.dart';
import 'package:heisuca/services/updates/update_feed_client.dart';
import 'package:heisuca/services/updates/update_downloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('app.heisuca/updates');
  late PlaybackDiagnosticStore registro;
  late Directory pasta;
  late List<MethodCall> chamadas;
  final apk = ApkAtualizacao('universal', Uri.parse('https://feed.example/app.apk'), 128, 'a' * 64);
  late OfertaAtualizacao oferta;
  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('heisuca-instalador-teste-');
    registro = PlaybackDiagnosticStore(directory: () async => pasta);
    oferta = OfertaAtualizacao('estavel', '2.0.34', 2042, 'Melhorias.', 'b' * 64, [apk]);
    chamadas = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, (call) async {
      chamadas.add(call);
      return switch (call.method) {
        'estado' => {'habilitado': true, 'build': 2041, 'versao': '2.0.34', 'espacoLivre': 999999999},
        'escolherAbi' => 'universal',
        'validar' => true,
        'instalar' => 'permissao',
        _ => null,
      };
    });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, null),
  );
  test('ABI escolhida pelo Android fica no registro local C sem URL', () async {
    final instalador = ApkInstaller(diagnosticos: registro);
    expect((await instalador.selecionar(oferta)).abi, 'universal');
    await registro.flush();
    final linhas = (await (await registro.currentFile).readAsLines()).map((l) => jsonDecode(l) as Map).toList();
    expect(linhas.single['event'], 'updateAbi');
    expect(linhas.single['abi'], 'universal');
    expect(jsonEncode(linhas), isNot(contains('feed.example')));
  });
  test('Play/canal nativo ausente fica desligado', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, null);
    expect((await const ApkInstaller().estado()).habilitado, isFalse);
  });
  test('certificado inválido vindo da validação nativa impede instalação', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      canal,
      (_) async => throw PlatformException(code: 'arquivoInvalido'),
    );
    await expectLater(
      const ApkInstaller().validar(File('${pasta.path}/app.apk'), oferta, apk),
      throwsA(isA<FalhaAtualizacao>().having((e) => e.codigo, 'causa', 'arquivoInvalido')),
    );
    expect(chamadas.where((c) => c.method == 'instalar'), isEmpty);
  });
}
