import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:heisuca/services/plex_auth_service.dart';
import 'package:heisuca/utils/media_server_http_client.dart';

void main() {
  for (final product in <String?>[null, 'Heisuca']) {
    test('identidade Plex: ${product ?? 'padrão preservado'}', () async {
      final client = MediaServerHttpClient(client: MockClient((request) async {
        expect(request.headers['X-Plex-Product'], product ?? 'CGFLIX');
        return http.Response('{"id":1,"code":"ABCD"}', 201,
            headers: {'content-type': 'application/json'});
      }));
      final auth = PlexAuthService.forTesting(http: client, productName: product);
      addTearDown(auth.dispose);
      await auth.createPin();
      final fragment = Uri.parse(auth.getAuthUrl('ABCD')).fragment;
      expect(Uri.splitQueryString(fragment.substring(1))['context[device][product]'],
          product ?? 'CGFLIX');
    });
  }
}
