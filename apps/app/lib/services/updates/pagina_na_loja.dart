import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Texto do item "Atualizações" na versão da loja: quem atualiza é a Play Store.
const textoAtualizacoesNaLoja = 'Pela Play Store. Toque para abrir';

/// Abre a página do app na Play Store. Tenta o app da loja e, se não houver, o site da loja.
/// O pacote vem do próprio app instalado, então vale para qualquer variante publicada na loja.
Future<void> abrirPaginaNaLoja() async {
  final pacote = (await PackageInfo.fromPlatform()).packageName;
  final destinos = [
    Uri.parse('market://details?id=$pacote'),
    Uri.https('play.google.com', '/store/apps/details', {'id': pacote}),
  ];
  for (final destino in destinos) {
    try {
      if (await launchUrl(destino, mode: LaunchMode.externalApplication)) return;
    } catch (e) {
      debugPrint('Play Store indisponível em ${destino.scheme}: $e');
    }
  }
}
