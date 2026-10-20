import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_login_checks.dart';

void main() {
  group('usuário', () {
    test('vazio pede para preencher', () {
      expect(cgflixLoginMissing(''), cgflixLoginMissingMessage);
      expect(cgflixLoginMissing('  '), cgflixLoginMissingMessage);
      expect(cgflixLoginMissingMessage, 'Preencha o usuário.');
    });

    test('preenchido segue para o servidor, com ou sem senha', () {
      expect(cgflixLoginMissing('maria'), isNull);
    });
  });

  group('endereço do servidor', () {
    test('vazio', () {
      expect(cgflixServerAddressProblem(const []), cgflixServerEmptyMessage);
      expect(cgflixServerAddressProblem(const ['  ']), cgflixServerEmptyMessage);
    });

    test('endereços que valem', () {
      for (final ok in [
        'https://seu.servidor.com',
        'seu.servidor.com',
        'http://192.168.0.10:8096',
        '192.168.0.10:8096',
        'jellyfin:8096',
        'https://seu.servidor.com/jellyfin',
        'http://[fd00::1]:8096',
      ]) {
        expect(cgflixServerAddressProblem([ok]), isNull, reason: ok);
      }
    });

    test('endereços tortos', () {
      for (final bad in ['seu servidor', 'https://', 'ftp://seu.servidor.com', '@@@', 'https://a b.com', 'http:// x']) {
        expect(cgflixServerAddressProblem([bad]), cgflixServerInvalidMessage, reason: bad);
      }
    });

    test('um endereço torto entre vários também avisa', () {
      expect(cgflixServerAddressProblem(['seu.servidor.com', 'a b']), cgflixServerInvalidMessage);
    });
  });
}
