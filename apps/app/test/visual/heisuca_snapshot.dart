// Captura visual para revisão (não é teste de aceite): roda só com HEISUCA_SNAPSHOT=1.
//   HEISUCA_SNAPSHOT=1 flutter test test/visual/<arquivo>_test.dart --update-goldens
// Carrega Inter e os ícones Material reais para o PNG ficar igual ao aparelho (sem fotos: rede não existe no teste).
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

bool get heisucaSnapshotEnabled => Platform.environment['HEISUCA_SNAPSHOT'] == '1';

Future<void> heisucaLoadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/sdk/flutter';
  await load('Inter', ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'].map((w) => 'assets/fonts/Inter-$w.ttf').toList());
  await load('MaterialIcons', ['$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  final pubCache = Platform.environment['PUB_CACHE']
      ?? (Directory('/home/caioguerras/.pub-cache').existsSync() ? '/home/caioguerras/.pub-cache' : '${Platform.environment['HOME']}/.pub-cache');
  final pub = '$pubCache/hosted/pub.dev';
  final pubDir = Directory(pub);
  final symbols = pubDir.existsSync()
      ? pubDir.listSync().whereType<Directory>().where((d) => d.path.contains('material_symbols_icons-')).firstOrNull
      : null;
  if (symbols != null) {
    for (final style in ['Rounded', 'Outlined']) {
      await load('packages/material_symbols_icons/MaterialSymbols$style', ['${symbols.path}/lib/fonts/MaterialSymbols$style.ttf']);
    }
  }
  await load('Roboto', ['$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf']);
}

/// Tela alta para caber a página inteira numa imagem só.
void heisucaPhoneView(WidgetTester tester, {double height = 914}) {
  tester.view.physicalSize = Size(412 * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}
