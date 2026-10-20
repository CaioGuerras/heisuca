import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/apoio/apoio_pix.dart';
import 'package:plezy/cgflix/apoio/br_code.dart';

String _cgflix() => BrCode.estatico(chave: ApoioPix.chave, nome: ApoioPix.nome, cidade: ApoioPix.cidade);

void main() {
  test('CRC confere com o exemplo do manual do Banco Central (1D3D)', () {
    const exemplo =
        '00020126580014br.gov.bcb.pix0136123e4567-e12b-12d1-a456-426655440000'
        '5204000053039865802BR5913Fulano de Tal6008BRASILIA62070503***6304';
    expect(BrCode.crc16(exemplo), '1D3D');
  });

  test('payload do CGFLIX campo a campo (igual ao do CGFLIX Lite)', () {
    const esperado =
        '000201' // 00: versão
        '2636' // 26: conta Pix (36 caracteres)
        '0014br.gov.bcb.pix'
        '0114+5522981599647'
        '52040000' // 52: categoria
        '5303986' // 53: real
        '5802BR' // 58: país
        '5906CGFLIX' // 59: nome
        '6014RIO DE JANEIRO' // 60: cidade
        '62070503***' // 62/05: txid
        '6304030A'; // 63: CRC
    expect(_cgflix(), esperado);
  });

  test('CRC do payload gerado confere', () {
    final payload = _cgflix();
    expect(payload.substring(payload.length - 8, payload.length - 4), '6304');
    expect(BrCode.crc16(payload.substring(0, payload.length - 4)), payload.substring(payload.length - 4));
  });

  test('sem valor fixo (sem o campo 54)', () {
    expect(_cgflix(), contains('53039865802BR'));
  });

  test('nome e cidade longos demais são recusados', () {
    expect(
      () => BrCode.estatico(chave: ApoioPix.chave, nome: ApoioPix.nome, cidade: 'SAO JOAO DA BARRA DO NORTE'),
      throwsArgumentError,
    );
    expect(() => BrCode.estatico(chave: ApoioPix.chave, nome: 'N' * 26, cidade: ApoioPix.cidade), throwsArgumentError);
  });

  test('campo com acento é recusado (o BR Code é só ASCII)', () {
    expect(() => BrCode.campo('60', 'SÃO PAULO'), throwsArgumentError);
  });
}
