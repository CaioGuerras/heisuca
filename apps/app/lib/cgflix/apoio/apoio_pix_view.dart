// CGFLIX: apoio por Pix (QR + "copia e cola" + chave). Só nos APKs fora da Play.
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import 'apoio.dart';
import 'apoio_pix.dart';
import 'br_code.dart';

class ApoioPixLivre implements Apoio {
  const ApoioPixLivre();

  @override
  bool get disponivel => true;

  @override
  Widget conteudo(BuildContext context) => const ApoioPixView();
}

/// Payload "copia e cola" do CGFLIX (calculado uma vez).
final String cgflixPixCopiaECola = BrCode.estatico(chave: ApoioPix.chave, nome: ApoioPix.nome, cidade: ApoioPix.cidade);

class ApoioPixView extends StatelessWidget {
  const ApoioPixView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          // QR sempre escuro sobre branco (é o que os bancos leem melhor), nos dois temas.
          child: Container(
            key: const ValueKey('cgflix-apoio-qr'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(
              data: cgflixPixCopiaECola,
              semanticsLabel: 'QR Code do Pix',
              size: 232,
              padding: const EdgeInsets.all(8),
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No app do seu banco, escolha Pix e leia o QR Code ou use o "copia e cola". '
          'O valor é você quem escolhe.',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('cgflix-apoio-copiaecola'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => _copiar(context, cgflixPixCopiaECola, 'Pix copia e cola copiado'),
          icon: const AppIcon(Symbols.content_copy_rounded, fill: 1),
          label: const Text('Copiar Pix copia e cola'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('cgflix-apoio-chave'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => _copiar(context, ApoioPix.chave, 'Chave Pix copiada'),
          icon: const AppIcon(Symbols.key_rounded, fill: 1),
          label: const Text('Copiar chave'),
        ),
        const SizedBox(height: 12),
        Text(
          'Chave (${ApoioPix.tipoDaChave}): ${ApoioPix.chave} · ${ApoioPix.nome}',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static Future<void> _copiar(BuildContext context, String texto, String aviso) async {
    await Clipboard.setData(ClipboardData(text: texto));
    // Android 13+ já mostra o aviso do sistema ao copiar: não repete.
    if (await _sistemaAvisaAoCopiar()) return;
    if (context.mounted) showAppSnackBar(context, aviso);
  }

  static bool? _avisoDoSistema;

  static Future<bool> _sistemaAvisaAoCopiar() async {
    if (_avisoDoSistema case final cached?) return cached;
    var avisa = false;
    try {
      if (Platform.isAndroid) avisa = (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33;
    } catch (_) {
      // Sem a informação (testes, outra plataforma): mostra o aviso do app.
    }
    return _avisoDoSistema = avisa;
  }
}
