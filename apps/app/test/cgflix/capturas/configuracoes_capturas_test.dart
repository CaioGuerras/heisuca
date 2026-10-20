// Capturas do refino 2b (item G): Configurações antes (1.6.0) × depois (1.6.1), nos dois temas
// (Isis e Heitor), com a fonte normal e a 200%. Telas reais do app com a Inter e os Material
// Symbols Rounded de verdade, num celular de 412 dp de largura; a altura é grande para caber a
// tela inteira (a captura mostra a lista toda, sem precisar rolar).
//
// Só roda quando pedido (não pesa no `flutter test` comum):
//   CGFLIX_CAPTURAS=docs/prints/refino2b/depois flutter test test/cgflix/capturas/configuracoes_capturas_test.dart
// O "antes" é o mesmo teste rodado na 1.6.0 (as telas que eram cartões são abertas com um toque).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/account_preferences_screen.dart';
import 'package:plezy/screens/settings/playback_settings_screen.dart';
import 'package:plezy/screens/settings/settings_screen.dart';
import 'package:plezy/screens/settings/subtitle_styling_screen.dart';

import '../../test_helpers/cgflix_config_harness.dart';

final _destino = Platform.environment['CGFLIX_CAPTURAS'];

/// Fonte normal e fonte 200% (Configurações do Android › Tamanho da fonte no máximo).
const _escalas = {'fonte100': 1.0, 'fonte200': 2.0};

Future<void> _carregarFontes() async {
  Future<void> carregar(String familia, List<String> arquivos) async {
    final loader = FontLoader(familia);
    for (final arquivo in arquivos) {
      loader.addFont(Future.value(ByteData.sublistView(File(arquivo).readAsBytesSync())));
    }
    await loader.load();
  }

  await carregar('Inter', [
    for (final peso in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/Inter-$peso.ttf',
  ]);
  final pacote = File('.dart_tool/package_config.json').readAsStringSync();
  final raiz = RegExp(r'"rootUri":\s*"([^"]*material_symbols_icons[^"]*)"').firstMatch(pacote)!.group(1)!;
  final dir = Uri.parse(raiz).isAbsolute ? Uri.parse(raiz).toFilePath() : '.dart_tool/$raiz';
  await carregar('packages/material_symbols_icons/MaterialSymbolsRounded', [
    '$dir/lib/fonts/MaterialSymbolsRounded.ttf',
  ]);
}

Future<void> _salvar(WidgetTester tester, String nome) async {
  await tester.runAsync(() async {
    final image = await captureImage(tester.element(find.byKey(const ValueKey('cgflix-captura'))));
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final arquivo = File('$_destino/$nome.png')..createSync(recursive: true);
    arquivo.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Toca no item [texto] (abre a subtela ou o cartão) e espera a animação.
Future<void> _abrir(WidgetTester tester, String texto) async {
  final alvo = find.text(texto).first;
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Rola a lista até [texto] ficar no topo (cartão aberto no meio da tela principal).
Future<void> _noTopo(WidgetTester tester, String texto) async {
  final alvo = find.text(texto).last;
  await tester.runAsync(() => Scrollable.ensureVisible(tester.element(alvo), alignment: 0));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  final pular = _destino == null ? 'defina CGFLIX_CAPTURAS=<pasta> para gerar as capturas' : null;
  setUpAll(() async {
    if (_destino == null) return;
    await _carregarFontes();
    await LocaleSettings.setLocale(AppLocale.pt);
  });
  prepararConfiguracoes();

  for (final variante in CgflixThemeVariant.values) {
    for (final MapEntry(key: fonte, value: escala) in _escalas.entries) {
      final prefixo = '${variante.name}-$fonte';

      testWidgets('$prefixo: tela principal, Baixados e Avançado', skip: pular != null, (tester) async {
        await montarConfiguracoes(tester, variante, escala, const SettingsScreen());
        await _salvar(tester, '$prefixo-01-principal');

        await _abrir(tester, 'Baixados');
        await _noTopo(tester, 'Baixados');
        await _salvar(tester, '$prefixo-05-baixados');

        await montarConfiguracoes(tester, variante, escala, const SettingsScreen());
        await _abrir(tester, 'Avançado');
        await _noTopo(tester, 'Avançado');
        await _salvar(tester, '$prefixo-06-avancado');
      });

      testWidgets('$prefixo: Ao assistir', skip: pular != null, (tester) async {
        await montarConfiguracoes(tester, variante, escala, const PlaybackSettingsScreen());
        await _salvar(tester, '$prefixo-02-ao-assistir');
      });

      testWidgets('$prefixo: Áudio e legenda', skip: pular != null, (tester) async {
        await montarConfiguracoes(tester, variante, escala, const AccountPreferencesScreen(targets: [configAlvo]));
        await _salvar(tester, '$prefixo-03-audio-e-legenda');
      });

      testWidgets('$prefixo: Estilo das legendas', skip: pular != null, (tester) async {
        await montarConfiguracoes(tester, variante, escala, const SubtitleStylingScreen());
        await _salvar(tester, '$prefixo-04-estilo-das-legendas');
      });
    }
  }
}
