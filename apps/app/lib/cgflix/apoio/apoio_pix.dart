// Heisuca: dados do Pix da gorjeta ("Apoie o Heisuca"). Para trocar a chave, só este arquivo.
// O QR e o "copia e cola" saem daqui (BR Code estático, sem valor: a pessoa digita o valor no banco).
abstract final class ApoioPix {
  static const chave = '+5522981599647';
  static const tipoDaChave = 'telefone';

  /// Até 25 caracteres (campo 59 do BR Code).
  static const nome = 'HEISUCA';

  /// Até 15 caracteres, sem acento (campo 60 do BR Code).
  static const cidade = 'RIO DE JANEIRO';
}
