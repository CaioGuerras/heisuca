import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/services/bif_thumbnail_service.dart';
import '../test_helpers/bif_fixtures.dart';

void main() {
  test('XFAIL conhecido: BIF mantém outra cópia do arquivo no isolate', () async {
    // O port está bloqueado pelo contrato de fonte/partTimeline. Não é skip:
    // executa a reprodução e aceita SOMENTE o resultado conhecido (16).
    // XPASS também quebra o portão, exigindo retirar esta exceção explicitamente.
    // Diagnóstico: docs/DIAGNOSTICO_O_COMPATIBILIDADE_2026-10-26.md.
    final bytes = buildBif([
      (timestamp: 0, bytes: [0x10, 0x20]),
    ]);
    final source = BifThumbnailService();
    addTearDown(source.dispose);
    await source.load(() async => bytes);
    expect(source.isAvailable, isTrue);
    final thumbnail = source.getThumbnail(Duration.zero)!;
    expect(thumbnail, [0x10, 0x20]);
    final offset = ByteData.sublistView(bytes).getUint32(68, Endian.little);
    bytes[offset] = 0xFE;
    if (thumbnail.first == 254) {
      fail('XPASS: BIF já compartilha o buffer. Retire o xfail e exija 254.');
    }
    expect(thumbnail.first, 16, reason: 'Somente a falha conhecida pode passar como XFAIL.');
    // ignore: avoid_print
    print('XFAIL BIF: esperado 254, obtido 16; cópia conhecida, sem correção nesta etapa.');
  });
}
