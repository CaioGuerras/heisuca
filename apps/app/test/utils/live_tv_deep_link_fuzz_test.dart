import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/services/system_shelf_service.dart';
import 'package:heisuca/utils/live_tv_deep_link.dart';

/// Entradas hostis fixas para plezy://live e plezy://play.
final _hostis = <String>[
  '',
  ' ',
  'javascript:alert(1)',
  'JAVASCRIPT:alert(1)',
  'file:///data/data/app.heisuca.player.teste/shared_prefs/x.xml',
  'content://app.heisuca.player.teste.fileprovider/root/data/data/x',
  'intent://live#Intent;scheme=plezy;package=app.heisuca.player.teste;end',
  'http://live/?channel=4.1',
  'https://live?channel=4.1',
  'plezy:live?channel=4.1',
  'plezy://',
  'plezy://%zz',
  'plezy://live?channel=%zz',
  'plezy://live?channel=',
  'plezy://live?channel=%20%20',
  'plezy://live?channel=4.1&start=lixo',
  'plezy://live?channel=4.1&server=../..',
  'plezy://live?channel=../../etc/passwd',
  'plezy://live?channel=..%2F..%2Fetc%2Fpasswd',
  'plezy://live?channel=a%00b',
  'plezy://live?channel=a\u0000b\u0007\u001b[31m',
  'plezy://live?channel=${'A' * (1024 * 1024)}',
  'plezy://live/../../x?channel=4.1',
  'plezy://evil@live?channel=4.1',
  'plezy://live@evil?channel=4.1',
  'plezy://live:99999?channel=4.1',
  'plezy://live#channel=4.1',
  'plezy://play?content_id=plezy_x_1',
  'PLEZY://LIVE?channel=4.1',
  'Plezy://Live?channel=4.1&START=Beginning',
];

/// Corpo de um plezy://live válido: a chave é o caso, o valor diz se é aceito.
const _validos = <String, String>{
  'plezy://live?channel=4.1': '4.1',
  'plezy://live?channel=4.1&start=beginning': '4.1',
  'plezy://live?channel=4.1&start=live&server=abc': '4.1',
  'plezy://live?channel=Globo%20HD': 'Globo HD',
  'PLEZY://LIVE?channel=4.1': '4.1',
  'plezy://live?channel=../../etc/passwd': '../../etc/passwd',
};

String _aleatoria(Random r) {
  const pedacos = <String>[
    'plezy', 'PLEZY', 'live', 'LIVE', 'play', 'http', 'file', 'content', 'intent', 'javascript',
    '://', ':', '/', '//', '?', '&', '=', '#', '%', '%00', '%zz', '%2e%2e%2f', '../', '..\\', '\u0000',
    '\u0007', '\u001b', ' ', '\n', 'channel', 'server', 'start', 'beginning', 'now', 'lixo', '4.1',
    '@', '[', ']', 'ç', '\u{1F600}', 'content_id', 'plezy_srv_123',
  ];
  final n = 1 + r.nextInt(14);
  return List.generate(n, (_) => pedacos[r.nextInt(pedacos.length)]).join();
}

void main() {
  group('LiveTvDeepLink.tryParse (fuzz)', () {
    test('entradas hostis fixas nunca lançam e só plezy://live válido passa', () {
      for (final entrada in _hostis) {
        LiveTvDeepLink? r;
        expect(() => r = LiveTvDeepLink.tryParse(entrada), returnsNormally, reason: _resumo(entrada));
        if (r != null) {
          final uri = Uri.parse(entrada);
          expect(uri.scheme, 'plezy', reason: _resumo(entrada));
          expect(uri.host, 'live', reason: _resumo(entrada));
          expect(r!.channel, isNotEmpty);
        }
      }
    });

    test('esquemas estranhos, vazio e URI malformada devolvem null', () {
      for (final entrada in [
        '',
        'javascript:alert(1)',
        'file:///data/data/app.heisuca.player.teste/shared_prefs/x.xml',
        'content://app.heisuca.player.teste.fileprovider/root/x',
        'intent://live#Intent;end',
        'http://live/?channel=4.1',
        'plezy://%zz',
        'plezy://live',
        'plezy://live?channel=',
        'plezy://live?channel=4.1&start=lixo',
        'plezy://play?content_id=plezy_x_1',
      ]) {
        expect(LiveTvDeepLink.tryParse(entrada), isNull, reason: _resumo(entrada));
      }
    });

    test('plezy://live válido é aceito, com esquema/host em maiúsculas', () {
      _validos.forEach((entrada, canal) {
        final r = LiveTvDeepLink.tryParse(entrada);
        expect(r, isNotNull, reason: entrada);
        expect(r!.channel, canal);
      });
    });

    test('canal com ../ é só texto de busca: não casa com nada nem vira caminho', () {
      final r = LiveTvDeepLink.tryParse('plezy://live?channel=../../etc/passwd&server=../..')!;
      expect(r.channel, '../../etc/passwd');
      expect(r.serverId, '../..');
      // selectChannel compara com chaves/identificadores/números; sem canais, não há resultado.
      expect(r.selectChannel(const []), isNull);
    });

    test('canal de 1 MB não lança', () {
      final r = LiveTvDeepLink.tryParse('plezy://live?channel=${'A' * (1024 * 1024)}');
      expect(r, isNotNull);
      expect(r!.channel.length, 1024 * 1024);
    });

    test('caracteres de controle e %00 ficam no texto, sem exceção', () {
      final r = LiveTvDeepLink.tryParse('plezy://live?channel=a%00b%07c');
      expect(r, isNotNull);
      expect(r!.channel, 'a\u0000b\u0007c');
    });

    test('500 entradas aleatórias com semente fixa: nunca lança; não-nulo só para plezy://live', () {
      final r = Random(20261028);
      var aceitas = 0;
      for (var i = 0; i < 500; i++) {
        final entrada = _aleatoria(r);
        LiveTvDeepLink? res;
        expect(() => res = LiveTvDeepLink.tryParse(entrada), returnsNormally, reason: _resumo(entrada));
        if (res != null) {
          aceitas++;
          final uri = Uri.parse(entrada);
          expect(uri.scheme, 'plezy', reason: _resumo(entrada));
          expect(uri.host, 'live', reason: _resumo(entrada));
          expect(res!.channel.trim(), isNotEmpty, reason: _resumo(entrada));
        }
      }
      // Sanidade do gerador: a maioria absoluta deve ser rejeitada.
      expect(aceitas, lessThan(250));
    });
  });

  group('SystemShelfService.parseContentId (plezy://play, content_id) (fuzz)', () {
    test('entradas hostis nunca lançam; só plezy_<servidor>_<chave> passa', () {
      final r = Random(20261028);
      final entradas = <String>[
        ..._hostis,
        'plezy_',
        'plezy__',
        'plezy_a',
        'plezy_a_',
        'plezy__x',
        'plezy_ _x',
        'plezy_../_../../etc',
        'plezy_srv_1_2_3',
        'plezy_\u0000_\u0000',
        'PLEZY_srv_1',
        for (var i = 0; i < 500; i++) _aleatoria(r),
        'plezy_srv_${'9' * (1024 * 1024)}',
      ];
      for (final entrada in entradas) {
        (ServerId, String)? res;
        expect(() => res = SystemShelfService.parseContentId(entrada), returnsNormally, reason: _resumo(entrada));
        if (res != null) {
          expect(entrada.startsWith('plezy_'), isTrue, reason: _resumo(entrada));
          expect(entrada.substring(6).contains('_'), isTrue, reason: _resumo(entrada));
        }
      }
      expect(SystemShelfService.parseContentId('plezy_srv_1'), isNotNull);
      expect(SystemShelfService.parseContentId('plezy_a'), isNull);
      expect(SystemShelfService.parseContentId('javascript:alert(1)'), isNull);
    });
  });
}

String _resumo(String s) => s.length > 120 ? '${s.substring(0, 120)}... (${s.length} chars)' : s;
