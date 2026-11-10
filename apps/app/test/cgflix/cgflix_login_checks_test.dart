import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_login_checks.dart';
import 'package:heisuca/utils/url_utils.dart';

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
        'http://127.0.0.1:8096',
        'http://localhost:8096',
        '192.168.0.10:8096',
        'jellyfin:8096',
        'https://seu.servidor.com/jellyfin',
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

  group('só HTTPS', () {
    test('http:// em servidor externo é recusado com a mensagem certa', () {
      for (final bad in ['http://exemplo.com', 'http://192.168.0.10:8096', 'HTTP://exemplo.com', 'http://[fd00::1]:8096']) {
        expect(cgflixServerAddressProblem([bad]), 'Use um endereço https://', reason: bad);
      }
      expect(cgflixServerAddressProblem(['https://ok.com', 'http://exemplo.com']), cgflixHttpsRequiredMessage);
    });

    test('https:// é aceito', () {
      expect(cgflixServerAddressProblem(['https://exemplo.com']), isNull);
      expect(cgflixIsCleartextRefused('https://exemplo.com'), isFalse);
    });

    test('127.0.0.1 e localhost são aceitos (proxy local)', () {
      expect(cgflixServerAddressProblem(['http://127.0.0.1:8096']), isNull);
      expect(cgflixIsCleartextRefused('http://localhost:3000/stream'), isFalse);
    });

    test('candidatos de endereço sem esquema nunca incluem http:// externo', () {
      final candidates = expandBaseUrlCandidates('exemplo.com', guesses: const [
        (scheme: 'http', port: 8096), (scheme: 'https', port: null), (scheme: 'http', port: null),
      ]);
      expect(candidates, ['https://exemplo.com']);
      expect(expandBaseUrlCandidates('127.0.0.1', guesses: const [(scheme: 'http', port: 8096)]),
          ['http://127.0.0.1:8096']);
    });
  });
}
