import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/utils/device_identity.dart';

void main() {
  group('nomeDoAparelho', () {
    test('não repete a marca e capitaliza', () {
      expect(nomeDoAparelho('motorola', 'motorola edge 60 pro'), 'Motorola Edge 60 Pro');
    });
    test('modelo em maiúsculas fica como está', () {
      expect(nomeDoAparelho('samsung', 'SM-S921B'), 'Samsung SM-S921B');
    });
    test('marca em minúsculas e modelo com maiúscula', () {
      expect(nomeDoAparelho('google', 'Pixel 8'), 'Google Pixel 8');
    });
    test('nome já salvo com repetição é limpo', () {
      expect(nomeDoAparelho('', '', 'motorola motorola edge 60 pro'), 'Motorola Edge 60 Pro');
      expect(nomeDoAparelho('', 'motorola motorola edge 60 pro'), 'Motorola Edge 60 Pro');
    });
    test('nome que já começa em maiúscula não é mexido', () {
      expect(nomeDoAparelho('Motorola', 'MOTOROLA edge'), 'MOTOROLA edge');
    });
  });
}
