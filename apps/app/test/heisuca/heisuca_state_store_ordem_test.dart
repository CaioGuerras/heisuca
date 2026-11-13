import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/heisuca/heisuca_state_store.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:provider/provider.dart';

/// Servidor de mentira: cada gravação de favorito espera a vez dela e fica anotada na ordem em que chega.
class _Servidor extends MediaServerClient {
  final esperas = <Completer<void>>[];
  final chegaram = <bool>[];
  bool? favorito;

  /// Posições (na ordem de chegada) das gravações que falham.
  final falham = <int>{};

  @override
  ServerId get serverId => ServerId('casa');

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  Future<void> setFavorite(MediaItem item, bool isFavorite) async {
    final posicao = chegaram.length;
    chegaram.add(isFavorite);
    final espera = Completer<void>();
    esperas.add(espera);
    await espera.future;
    if (falham.remove(posicao)) throw StateError('sem rede');
    favorito = isFavorite;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<BuildContext> _montar(WidgetTester tester, _Servidor servidor) async {
  final gerente = MultiServerManager()..debugRegisterClientForTesting(servidor);
  final servidores = MultiServerProvider(gerente, DataAggregationService(gerente));
  addTearDown(servidores.dispose);
  addTearDown(gerente.dispose);
  late BuildContext contexto;
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: servidores,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              contexto = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return contexto;
}

MediaItem _favorito(String id) => MediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.movie,
  title: 'Título',
  serverId: 'casa',
).copyWith(isFavorite: true);

void main() {
  testWidgets('duas trocas seguidas do mesmo favorito chegam ao servidor uma de cada vez, na ordem', (tester) async {
    final servidor = _Servidor();
    final contexto = await _montar(tester, servidor);
    final item = _favorito('ordem-1');
    final loja = HeisucaStateStore.instance;

    final tirar = loja.toggleFavorite(contexto, item);
    final devolver = loja.toggleFavorite(contexto, item);
    await tester.pump();

    expect(servidor.chegaram, [false], reason: 'a segunda gravação espera a primeira terminar');
    expect(loja.isFavorite(item), isTrue, reason: 'a tela mostra a última escolha na hora');

    servidor.esperas[0].complete();
    await tester.pump();
    await tester.pump();
    expect(servidor.chegaram, [false, true]);
    servidor.esperas[1].complete();
    await tirar;
    await devolver;
    await tester.pump();

    expect(servidor.favorito, isTrue, reason: 'o servidor termina com a última escolha');
    expect(loja.isFavorite(item), isTrue);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a primeira gravação falha e a segunda vale: a tela e o servidor ficam com a última escolha', (
    tester,
  ) async {
    final servidor = _Servidor()..falham.add(0);
    final contexto = await _montar(tester, servidor);
    final item = _favorito('ordem-2');
    final loja = HeisucaStateStore.instance;

    final tirar = loja.toggleFavorite(contexto, item);
    final devolver = loja.toggleFavorite(contexto, item);
    await tester.pump();
    servidor.esperas[0].complete();
    expect(await tirar, isTrue, reason: 'a gravação falhou: o servidor segue com o favorito');
    expect(loja.isFavorite(item), isTrue, reason: 'a falha da primeira não desfaz a escolha mais nova');
    await tester.pump();
    servidor.esperas[1].complete();
    expect(await devolver, isTrue);

    expect(servidor.chegaram, [false, true]);
    expect(servidor.favorito, isTrue);
    expect(loja.isFavorite(item), isTrue);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('gravação sozinha que falha: a tela volta ao que o servidor tem', (tester) async {
    final servidor = _Servidor()..falham.add(0);
    final contexto = await _montar(tester, servidor);
    final item = _favorito('ordem-3');
    final loja = HeisucaStateStore.instance;

    final tirar = loja.toggleFavorite(contexto, item);
    expect(loja.isFavorite(item), isFalse);
    await tester.pump();
    servidor.esperas[0].complete();
    expect(await tirar, isTrue);
    expect(loja.isFavorite(item), isTrue);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
