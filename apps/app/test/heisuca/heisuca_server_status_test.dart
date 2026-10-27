import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/heisuca/widgets/heisuca_server_status.dart';
import 'package:heisuca/media/media_browser_dialect.dart';
import 'package:heisuca/services/jellyfin_endpoint_discovery.dart';
import 'package:heisuca/utils/media_server_http_client.dart';

class _Discovery extends JellyfinEndpointDiscovery {
  final requests = <({AbortController? abort, Completer<JellyfinServerInfo> result})>[];
  @override
  Future<JellyfinServerInfo> probe(
    String url, {
    Duration timeout = const Duration(seconds: 8),
    AbortController? abort,
  }) {
    final result = Completer<JellyfinServerInfo>();
    requests.add((abort: abort, result: result));
    return result.future;
  }
}

void main() {
  const info = JellyfinServerInfo(
    serverName: 'Cinema da família',
    machineId: 'fake',
    version: '10.11.0',
    dialect: MediaBrowserDialect.jellyfin,
  );

  testWidgets('login com uma letra não anuncia servidor nem pronto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: cgflixAppTheme(CgflixThemeVariant.isis), home: const HeisucaLoginScreen()),
    );
    final server = find.descendant(
      of: find.byKey(const ValueKey('heisuca-login-server')),
      matching: find.byType(TextField),
    );
    await tester.enterText(server, 'a');
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('pronto'), findsNothing);
    expect(find.textContaining('CGSERVER'), findsNothing);
    expect(find.text('Outros servidores e pastas locais'), findsOneWidget);
    expect(find.text('+ Outros servidores e pastas locais'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mostra resposta real, cancela por tecla e ignora resposta antiga', (tester) async {
    final controller = TextEditingController();
    final discovery = _Discovery();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeisucaServerStatus(controller: controller, discovery: discovery),
        ),
      ),
    );
    expect(find.textContaining('Procurando'), findsNothing);
    controller.text = 'https://cinema.example';
    await tester.pump(const Duration(milliseconds: 499));
    expect(discovery.requests, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(discovery.requests, hasLength(1));
    controller.text = 'https://outro.example';
    expect(discovery.requests.first.abort!.isAborted, isTrue);
    discovery.requests.first.result.complete(info);
    await tester.pump();
    expect(find.textContaining('Cinema da família'), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    discovery.requests.last.result.complete(info);
    await tester.pump();
    await tester.pump();
    expect(find.text('Jellyfin 10.11.0 · Cinema da família'), findsOneWidget);
    expect(find.textContaining('●'), findsNothing);
    controller.clear();
    await tester.pump();
    expect(find.textContaining('Cinema da família'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('erro não vira on-line e dispose cancela sonda', (tester) async {
    final controller = TextEditingController(text: 'https://cinema.example');
    final discovery = _Discovery();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeisucaServerStatus(controller: controller, discovery: discovery),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    discovery.requests.single.result.completeError(Exception('fora do ar'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Nenhum servidor respondeu'), findsOneWidget);
    controller.text = 'https://outro.example';
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(discovery.requests.last.abort!.isAborted, isTrue);
    discovery.requests.last.result.complete(info);
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
