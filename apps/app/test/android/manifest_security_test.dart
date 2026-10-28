import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

const _manifestPath = 'android/app/src/main/AndroidManifest.xml';
const _xmlDir = 'android/app/src/main/res/xml';
const _gradlePath = 'android/app/build.gradle.kts';

const _componentTags = <String>{'activity', 'activity-alias', 'service', 'receiver', 'provider'};
const _expectedExported = <String>{'.MainActivity', '.IconeIsis', '.IconeHeitor'};
const _allDomains = <String>{
  'root',
  'file',
  'database',
  'sharedpref',
  'external',
  'device_root',
  'device_file',
  'device_database',
  'device_sharedpref',
};

const _androidNs = 'http://schemas.android.com/apk/res/android';

String? _attr(XmlElement e, String name) => e.getAttribute(name, namespaceUri: _androidNs);

void main() {
  late XmlDocument manifest;
  late XmlElement application;

  setUpAll(() {
    manifest = XmlDocument.parse(File(_manifestPath).readAsStringSync());
    application = manifest.rootElement.findElements('application').single;
  });

  Iterable<XmlElement> components() => application.childElements.where((e) => _componentTags.contains(e.name.local));

  test('só MainActivity e os dois ícones são exportados; providers e receivers não', () {
    final exported = components().where((c) => _attr(c, 'exported') == 'true').map((c) => _attr(c, 'name')).toSet();
    expect(exported, _expectedExported);

    for (final c in components().where((c) => const {'provider', 'receiver', 'service'}.contains(c.name.local))) {
      expect(_attr(c, 'exported'), 'false', reason: '${c.name.local} ${_attr(c, 'name')} deve declarar exported=false');
    }
  });

  test('o manifesto não liga debuggable e o buildType release também não', () {
    expect(manifest.findAllElements('application').every((a) => _attr(a, 'debuggable') == null), isTrue);
    expect(File(_manifestPath).readAsStringSync(), isNot(contains('android:debuggable')));

    final gradle = File(_gradlePath).readAsStringSync();
    final start = RegExp(r'\n\s{4}release\s*\{').firstMatch(gradle);
    expect(start, isNotNull, reason: 'bloco buildTypes.release não encontrado');
    var depth = 0;
    var end = start!.end;
    depth = 1;
    while (end < gradle.length && depth > 0) {
      final ch = gradle[end];
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      end++;
    }
    final releaseBlock = gradle.substring(start.start, end);
    expect(releaseBlock, isNot(contains('isDebuggable')));
    expect(releaseBlock, isNot(contains('debuggable')));
  });

  test('backup e transferência entre aparelhos desligados (Android 12+ ignora allowBackup)', () {
    expect(_attr(application, 'allowBackup'), 'false');
    expect(_attr(application, 'fullBackupContent'), 'false');
    final rulesRef = _attr(application, 'dataExtractionRules');
    expect(rulesRef, '@xml/data_extraction_rules');

    final rules = XmlDocument.parse(File('$_xmlDir/${rulesRef!.split('/').last}.xml').readAsStringSync());
    for (final section in ['cloud-backup', 'device-transfer']) {
      final node = rules.rootElement.findElements(section).single;
      final excluded = node.findElements('exclude').map((e) => e.getAttribute('domain')).toSet();
      expect(excluded, _allDomains, reason: '<$section> deve excluir todos os domínios');
      expect(node.findElements('include'), isEmpty, reason: '<$section> não pode incluir nada');
    }
  });

  // O root-path é necessário (downloads padrão em app_flutter/downloads, cartão SD); a segurança vem da
  // contenção no emissor, que tem de rodar antes de qualquer getUriForFile.
  test('root-path só existe com a contenção chamada antes de getUriForFile', () {
    final paths = XmlDocument.parse(File('$_xmlDir/file_provider_paths.xml').readAsStringSync());
    final rootPaths = paths.findAllElements('root-path');
    final kotlin = File('android/app/src/main/kotlin/app/heisuca/ExternalPlayerChannel.kt').readAsStringSync();
    final contencao = kotlin.indexOf('ExternalFileContainment.resolveShareable');
    final uri = kotlin.indexOf('FileProvider.getUriForFile');
    expect(uri, greaterThan(0));
    expect('FileProvider.getUriForFile'.allMatches(kotlin).length, 1, reason: 'todo URI deve sair do mesmo ponto');
    if (rootPaths.isNotEmpty) {
      expect(contencao, greaterThan(0), reason: 'root-path exige a contenção no emissor');
      expect(contencao, lessThan(uri), reason: 'a contenção deve vir antes de getUriForFile');
    }
    // A contenção proíbe os dados privados exceto downloads e cache.
    expect(kotlin, contains('app_flutter/downloads'));
  });

  test('intent-filters de dados: só plezy://play e plezy://live', () {
    final hosts = <String>{};
    for (final data in application.findAllElements('data')) {
      expect(_attr(data, 'scheme'), 'plezy', reason: 'esquema inesperado em <data>');
      expect(_attr(data, 'mimeType'), isNull);
      expect(_attr(data, 'pathPattern') ?? _attr(data, 'path') ?? _attr(data, 'pathPrefix'), isNull);
      hosts.add(_attr(data, 'host') ?? '');
    }
    expect(hosts, {'play', 'live'});

    for (final filter in application.findAllElements('intent-filter')) {
      final categories = filter.findElements('category').map((c) => _attr(c, 'name'));
      if (filter.findElements('data').isNotEmpty) {
        expect(categories, isNot(contains('android.intent.category.BROWSABLE')));
      }
    }
  });
}
