// CGFLIX: BR Code estático do Pix (padrão EMV do Banco Central), sem valor fixo.
// Campos: 00 (versão), 26 (`br.gov.bcb.pix` + chave), 52 `0000`, 53 `986` (real), 58 `BR`,
// 59 nome, 60 cidade, 62/05 txid `***` e 63 CRC16-CCITT (polinômio 0x1021, início 0xFFFF).
import 'dart:convert';

abstract final class BrCode {
  /// Payload "copia e cola" sem valor (a pessoa escolhe quanto no app do banco).
  static String estatico({required String chave, required String nome, required String cidade, String txid = '***'}) {
    if (nome.length > 25) throw ArgumentError.value(nome, 'nome', 'mais de 25 caracteres');
    if (cidade.length > 15) throw ArgumentError.value(cidade, 'cidade', 'mais de 15 caracteres');
    final conta = campo('00', 'br.gov.bcb.pix') + campo('01', chave);
    final semCrc =
        '${campo('00', '01')}'
        '${campo('26', conta)}'
        '${campo('52', '0000')}'
        '${campo('53', '986')}'
        '${campo('58', 'BR')}'
        '${campo('59', nome)}'
        '${campo('60', cidade)}'
        '${campo('62', campo('05', txid))}'
        '6304';
    return semCrc + crc16(semCrc);
  }

  /// Campo EMV: id (2 dígitos) + tamanho (2 dígitos) + valor. Só ASCII imprimível.
  static String campo(String id, String valor) {
    if (valor.isEmpty || valor.length > 99 || valor.codeUnits.any((c) => c < 32 || c > 126)) {
      throw ArgumentError.value(valor, id, 'campo inválido');
    }
    return '$id${valor.length.toString().padLeft(2, '0')}$valor';
  }

  /// CRC16-CCITT (FALSE): polinômio 0x1021, início 0xFFFF, em 4 dígitos hexadecimais maiúsculos.
  static String crc16(String texto) {
    var crc = 0xFFFF;
    for (final byte in utf8.encode(texto)) {
      crc ^= byte << 8;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) : (crc << 1);
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
