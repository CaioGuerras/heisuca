import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/heisuca/heisuca_lista_plex.dart';
import 'package:heisuca/heisuca/heisuca_state_store.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/providers/offline_mode_provider.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:provider/provider.dart';

/// Conta Plex de mentira: guarda o que foi gravado e deixa o teste segurar ou derrubar a resposta.
class _Conta implements ListaDoPlex {
  bool? naConta = false;
  final gravados = <bool>[];
  bool falha = false;
  Completer<void>? esperaDaPergunta;

  @override
  Future<bool?> estaNaLista() async {
    await esperaDaPergunta?.future;
    return naConta;
  }

  @override
  Future<void> gravar(bool naLista) async {
    gravados.add(naLista);
    if (falha) throw StateError('sem rede');
    naConta = naLista;
  }
}

/// Servidor que acusa qualquer tentativa de favoritar nele: no Plex a lista é da conta.
class _Servidor extends MediaServerClient {
  int favoritadas = 0;

  @override
  ServerId get serverId => ServerId('amigo');

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<void> setFavorite(MediaItem item, bool isFavorite) async {
    favoritadas++;
    throw UnsupportedError('Plex does not support user favorites.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

MediaItem _filme(String id) =>
    MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Filme do amigo', serverId: 'amigo');

void main() {
  late _Conta conta;
  late _Servidor servidor;

  Future<BuildContext> montar(WidgetTester tester) async {
    conta = _Conta();
    servidor = _Servidor();
    ListaDoPlex.fabricaDeTeste = (context, item, cliente) => conta;
    addTearDown(() => ListaDoPlex.fabricaDeTeste = null);
    final gerente = MultiServerManager()..debugRegisterClientForTesting(servidor);
    final servidores = MultiServerProvider(gerente, DataAggregationService(gerente));
    addTearDown(servidores.dispose);
    addTearDown(gerente.dispose);
    final semRede = OfflineModeProvider(gerente);
    addTearDown(semRede.dispose);
    late BuildContext contexto;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: servidores),
          ChangeNotifierProvider.value(value: semRede),
        ],
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

  testWidgets('título de servidor Plex: "Minha lista" grava na conta, não no servidor', (tester) async {
    final contexto = await montar(tester);
    final item = _filme('plex-1');
    final loja = HeisucaStateStore.instance;

    final resultado = await loja.toggleFavorite(contexto, item);
    await tester.pump();

    expect(resultado, isTrue);
    expect(conta.gravados, [true]);
    expect(servidor.favoritadas, 0);
    expect(loja.isFavorite(item), isTrue);
    expect(find.text('Adicionado à sua lista do Plex'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('tirar da lista também vai para a conta', (tester) async {
    final contexto = await montar(tester);
    final item = _filme('plex-2');
    final loja = HeisucaStateStore.instance;
    await loja.toggleFavorite(contexto, item);

    final resultado = await loja.toggleFavorite(contexto, item);
    await tester.pump();

    expect(resultado, isFalse);
    expect(conta.gravados, [true, false]);
    expect(loja.isFavorite(item), isFalse);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a conta recusa a gravação: a tela volta e não diz que adicionou', (tester) async {
    final contexto = await montar(tester);
    conta.falha = true;
    final item = _filme('plex-3');
    final loja = HeisucaStateStore.instance;

    final resultado = await loja.toggleFavorite(contexto, item);
    await tester.pump();

    expect(resultado, isFalse);
    expect(loja.isFavorite(item), isFalse);
    expect(find.text('Adicionado à sua lista do Plex'), findsNothing);
    expect(find.text('Não foi possível atualizar os favoritos'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('ao abrir o título, a tela passa a mostrar o que a conta tem', (tester) async {
    final contexto = await montar(tester);
    conta.naConta = true;
    final item = _filme('plex-4');
    final loja = HeisucaStateStore.instance;
    var avisos = 0;
    void ouviu() => avisos++;
    loja.addListener(ouviu);
    addTearDown(() => loja.removeListener(ouviu));
    expect(loja.isFavorite(item), isFalse);

    await loja.conferirLista(contexto, item);

    expect(loja.isFavorite(item), isTrue);
    expect(avisos, 1);
    expect(conta.gravados, isEmpty);
  });

  testWidgets('resposta atrasada da conta não desfaz o toque feito enquanto ela vinha', (tester) async {
    final contexto = await montar(tester);
    conta.esperaDaPergunta = Completer<void>();
    final item = _filme('plex-5');
    final loja = HeisucaStateStore.instance;

    final pergunta = loja.conferirLista(contexto, item);
    await loja.toggleFavorite(contexto, item);
    // A resposta velha diz "fora da lista"; o toque já pôs na lista.
    conta.naConta = false;
    conta.esperaDaPergunta!.complete();
    await pergunta;
    await tester.pump();

    expect(loja.isFavorite(item), isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a conta não sabe responder: a tela fica como estava', (tester) async {
    final contexto = await montar(tester);
    conta.naConta = null;
    final item = _filme('plex-6');
    final loja = HeisucaStateStore.instance;

    await loja.conferirLista(contexto, item);

    expect(loja.isFavorite(item), isFalse);
  });
}
