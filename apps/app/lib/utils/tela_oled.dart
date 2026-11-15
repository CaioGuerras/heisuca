// O Android não informa o tipo de painel; usamos uma lista conservadora de modelos conhecidos.
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

final RegExp _xiaomiNumerica = RegExp(r'\b(11|12|13|14|15)(\b|[a-z])');
final RegExp _redmiNote = RegExp(r'redmi note (1[0-9])\b.*\bpro|redmi note (1[1-9])\b');

/// Verdadeiro só para modelos sabidamente OLED. Na dúvida, falso.
bool aparelhoTemTelaOled({required String marca, required String modelo}) {
  final b = marca.trim().toLowerCase();
  final m = modelo.trim().toLowerCase();
  if (b.isEmpty && m.isEmpty) return false;
  if (b == 'google' || m.startsWith('pixel')) return true;
  if (b == 'oneplus' || b == 'nothing') return true;
  if (b == 'samsung') {
    return ['sm-s', 'sm-g9', 'sm-n', 'sm-f', 'sm-a5', 'sm-a7'].any(m.startsWith);
  }
  if (b == 'motorola' || b == 'lenovo') return m.contains('edge');
  if (b == 'xiaomi' || b == 'redmi' || b == 'poco') {
    if (m.contains('redmi note')) return _redmiNote.hasMatch(m);
    if (m.contains('redmi') || m.contains('poco')) return false;
    return _xiaomiNumerica.hasMatch(m);
  }
  return false;
}

/// Guarda o resultado da detecção, feita uma vez na abertura.
class TelaOled {
  TelaOled._();

  static bool ativa = false;

  /// Só no Android; nas demais plataformas fica falso.
  static Future<void> detectar() async {
    if (!Platform.isAndroid) return;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      ativa = aparelhoTemTelaOled(marca: info.brand, modelo: info.model);
    } catch (_) {
      ativa = false;
    }
  }
}
