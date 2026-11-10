import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/services/jellyfin_mappers.dart';
import 'package:heisuca/utils/url_utils.dart';

/// P5 lote 4, caso 3: HTML/JS em títulos e sinopses. Nenhuma tela renderiza
/// HTML: os mappers entregam o texto literal e links só abrem se forem http(s).
void main() {
  const payloads = [
    '<script>alert(1)</script>',
    '<img src=x onerror=alert(1)>',
    '&lt;b&gt;negrito&amp;&#x41;',
    '[link](javascript:alert(1))',
    '**markdown**',
  ];

  test('mappers entregam título e sinopse como texto literal', () {
    for (final payload in payloads) {
      final item = JellyfinMappers.mediaItem(
        {
          'Id': 'a',
          'Name': payload,
          'Overview': payload,
          'Type': 'Movie',
          'Taglines': [payload],
        },
        serverId: ServerId('srv'),
        absolutizer: null,
      );
      expect(item?.title, payload);
      expect(item?.summary, payload);
      expect(item?.tagline, payload);
    }
  });

  test('o app não depende de pacote que interpreta HTML/Markdown/WebView', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dependencies = pubspec.split('dev_dependencies:').first;
    for (final pkg in [
      'flutter_html',
      'flutter_markdown',
      'markdown',
      'webview_flutter',
      'flutter_inappwebview',
      'html',
      'flutter_widget_from_html',
    ]) {
      expect(RegExp('^\\s{2}$pkg:', multiLine: true).hasMatch(dependencies), isFalse, reason: pkg);
    }
  });

  test('links vindos do servidor só abrem se forem http(s)', () {
    for (final bad in [
      'javascript:alert(1)',
      'file:///etc/passwd',
      'content://com.android.contacts/contacts',
      'intent:#Intent;action=android.intent.action.CALL;end',
      'tel:112',
      'data:text/html,<script>alert(1)</script>',
      'http://',
      '',
      'sem esquema',
    ]) {
      expect(webUrlOrNull(bad), isNull, reason: bad);
    }
    expect(webUrlOrNull('https://www.youtube.com/watch?v=abc')?.host, 'www.youtube.com');
    expect(webUrlOrNull(' http://exemplo.com/x ')?.host, 'exemplo.com');
  });
}
