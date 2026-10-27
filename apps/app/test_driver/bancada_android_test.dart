import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  final output = Directory(Platform.environment['HEISUCA_BANCADA_EVIDENCIAS']!);
  await output.create(recursive: true);
  await integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      await File('${output.path}/resultado-teste.json').writeAsString(
        jsonEncode({
          'testeEncerrado': data?['testeEncerrado'] == true,
          'passos': data?['passos'],
          'avisos': data?['avisos'],
          'capturasNativas': data?['capturasNativas'],
          'video': data?['video'],
          'imagemInicial': data?['imagemInicial'],
          'imagemAposAudio': data?['imagemAposAudio'],
          'imagemAntesDoBack': data?['imagemAntesDoBack'],
          'foraDoApp': data?['foraDoApp'],
          'diagnosticoRetorno': data?['diagnosticoRetorno'],
          'rotasAntesDoBack': data?['rotasAntesDoBack'],
        }),
      );
    },
  );
}
