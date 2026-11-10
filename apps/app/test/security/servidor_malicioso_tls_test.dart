import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/exceptions/media_server_exceptions.dart';
import 'package:heisuca/utils/certificate_trust.dart';
import 'package:heisuca/utils/media_server_http_client.dart';

import 'malicious_server_harness.dart';

/// P5 lote 4, caso 6: certificado TLS inválido. O servidor usa o par
/// autoassinado de `test/fixtures/tls` (SÓ DE TESTE); o cliente padrão do app
/// (o mesmo `platform.createPlatformClient`) tem de recusar o handshake.
void main() {
  late MaliciousServer server;

  setUp(() async {
    final context = SecurityContext()
      ..useCertificateChain('test/fixtures/tls/selfsigned_cert.pem')
      ..usePrivateKey('test/fixtures/tls/selfsigned_key.pem');
    server = await MaliciousServer.startSecure(context);
    server.jsonObject('/System/Info/Public', {'Id': 'x', 'ServerName': 'falso'});
    CertificateTrust.debugReset();
  });
  tearDown(() async => server.stop());

  test('certificado autoassinado é recusado pelo caminho normal e nenhum pedido chega ao servidor', () async {
    final http = MediaServerHttpClient(baseUrl: server.baseUrl, defaultHeaders: {'X-Emby-Token': maliciousTestToken});
    addTearDown(http.close);
    await expectLater(
      http.get('/System/Info/Public').timeout(const Duration(seconds: 30)),
      throwsA(isA<MediaServerHttpException>()),
    );
    expect(server.seen, isEmpty, reason: 'o handshake falhou, logo o token não pode ter sido enviado');
  });

  test('o contexto de confiança não aceita o certificado de teste', () {
    // Sem autoridades de usuário carregadas, o app usa o padrão do SDK.
    expect(CertificateTrust.contextFor('127.0.0.1'), isNull);
  });

  test('nenhum código do app desliga a validação de TLS', () {
    final offenders = <String>[];
    final pattern = RegExp(
      r'badCertificateCallback\s*=|onBadCertificate|bypassTLSCertificateValidation|acceptUntrustedCertificates',
    );
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (pattern.hasMatch(line)) offenders.add('${entity.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
