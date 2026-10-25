import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(Platform.environment['HEISUCA_BANCADA_EVIDENCIAS']!);
  await output.create(recursive: true);
  Future<void> adb(List<String> args) async {
    final result = await Process.run('adb', args);
    if (result.exitCode != 0) throw StateError('O adb não concluiu uma operação de captura.');
  }
  Future<void> stopVideo(String name) async {
    await Process.run('adb', ['shell', 'pkill', '-INT', 'screenrecord']);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await adb(['pull', '/sdcard/heisuca-bancada.mp4', '${output.path}/$name.mp4']);
    await adb(['shell', 'rm', '-f', '/sdcard/heisuca-bancada.mp4']);
  }
  await integrationDriver(writeResponseOnFailure: true,
    onScreenshot: (name, image, [args]) async {
      if (name == '01-login') await stopVideo('01-abertura-login');
      if (name == '02-inicio' || name == '05-player-inicio' || name == '07-ficha-retorno') {
        await Process.start('adb', ['shell', 'screenrecord', '--time-limit', '180', '/sdcard/heisuca-bancada.mp4'],
          mode: ProcessStartMode.detachedWithStdio).then((p) { p.stdout.drain<void>(); p.stderr.drain<void>(); });
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (name == '04-ficha') await stopVideo('02-acervo-busca-ficha');
      if (name == '06-player') await stopVideo('03-player-nativo');
      if (name == '11-voce') await stopVideo('04-retorno-abas');
      final capture = await Process.run('adb', ['exec-out', 'screencap', '-p'], stdoutEncoding: null);
      if (capture.exitCode != 0) return false;
      final png = capture.stdout as List<int>;
      if (png.length < 24 || png[0] != 137 || png[1] != 80 || png[2] != 78 || png[3] != 71) return false;
      await File('${output.path}/$name.png').writeAsBytes(png);
      if (args?['voltar'] == true) {
        await adb(['shell', 'input', 'keyevent', '4']);
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      return true;
    }, responseDataCallback: (data) async {
      await File('${output.path}/resultado-teste.json').writeAsString(jsonEncode({
        'testeEncerrado': data?['testeEncerrado'] == true, 'passos': data?['passos'], 'video': data?['video'],
      }));
    });
}
