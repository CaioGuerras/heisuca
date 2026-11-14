import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/heisuca/heisuca_context_menu.dart';
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
  Completer<void>? esperaDaGravacao;

  /// Para cada pedido da ponte, na ordem: o contexto de quem pediu estava dentro do perfil?
  final pedidosDeDentroDoPerfil = <bool>[];

  @override
  Future<bool?> estaNaLista() async {
    await esperaDaPergunta?.future;
    return naConta;
  }

  @override
  Future<void> gravar(bool naLista) async {
    gravados.add(naLista);
    // Como a conta de verdade: a lista em memória muda antes de o servidor responder e volta se ele recusar.
    final antes = naConta;
    naConta = naLista;
    await esperaDaGravacao?.future;
    if (falha) {
      naConta = antes;
      throw StateError('sem rede');
    }
  }
}

/// Servidor que acusa qualquer tentativa de favoritar nele: no Plex a lista é da conta.
class _Servidor extends MediaServerClient {
  int favoritadas = 0;

  /// Marcações de visto que chegaram ao servidor.
  final vistos = <bool>[];

  @override
  Future<void> markWatched(MediaItem item) async => vistos.add(true);

  @override
  Future<void> markUnwatched(MediaItem item) async => vistos.add(false);

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

/// Marca o que só existe dentro do perfil (no app, as fontes de catálogo com a conta Plex).
class _DoPerfil {
  const _DoPerfil();
}

bool _dentroDoPerfil(BuildContext context) {
  try {
    Provider.of<_DoPerfil>(context, listen: false);
    return true;
  } on ProviderNotFoundException {
    return false;
  }
}

MediaItem _filme(String id) =>
    MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Filme do amigo', serverId: 'amigo');

void main() {
  late _Conta conta;
  late _Servidor servidor;

  /// Como a troca de perfil no app: o navegador raiz (e o menu aberto nele) fica, a tela do perfil sai.
  late Future<void> Function() trocarDePerfil;

  Future<BuildContext> montar(WidgetTester tester) async {
    conta = _Conta();
    servidor = _Servidor();
    ListaDoPlex.fabricaDeTeste = (context, item, cliente) {
      conta.pedidosDeDentroDoPerfil.add(_dentroDoPerfil(context));
      return conta;
    };
    addTearDown(() => ListaDoPlex.fabricaDeTeste = null);
    final gerente = MultiServerManager()..debugRegisterClientForTesting(servidor);
    final servidores = MultiServerProvider(gerente, DataAggregationService(gerente));
    addTearDown(servidores.dispose);
    addTearDown(gerente.dispose);
    final semRede = OfflineModeProvider(gerente);
    addTearDown(semRede.dispose);
    late BuildContext contexto;
    Widget app(Widget inicio) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: servidores),
        ChangeNotifierProvider.value(value: semRede),
      ],
      child: MaterialApp(home: inicio),
    );
    await tester.pumpWidget(
      app(
        // Como no app: o que é do perfil fica abaixo do navegador raiz.
        Provider<_DoPerfil>.value(
          value: const _DoPerfil(),
          child: Scaffold(
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
    trocarDePerfil = () => tester.pumpWidget(app(const Scaffold(body: Text('Quem está assistindo?'))));
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
    expect(find.text('Não foi possível atualizar a sua lista'), findsOneWidget);
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

  testWidgets('pergunta feita com a gravação a caminho não vira "o que a conta tem" se a gravação falhar', (
    tester,
  ) async {
    final contexto = await montar(tester);
    final item = _filme('plex-7');
    final loja = HeisucaStateStore.instance;
    await loja.conferirLista(contexto, item);
    expect(loja.isFavorite(item), isFalse);

    conta
      ..esperaDaGravacao = Completer<void>()
      ..falha = true;
    final gravacao = loja.toggleFavorite(contexto, item);
    // O menu abre com a gravação ainda a caminho: a conta responde com o que mostra, não com o que o servidor tem.
    await loja.conferirLista(contexto, item);
    conta.esperaDaGravacao!.complete();
    await gravacao;
    await tester.pump();

    expect(conta.naConta, isFalse);
    expect(loja.isFavorite(item), isFalse, reason: 'a conta recusou: a tela volta para "fora da lista"');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('menu do cartão sem ação própria grava com o contexto de quem abriu, não com o do diálogo', (
    tester,
  ) async {
    final contexto = await montar(tester);
    final item = _filme('plex-8');

    unawaited(HeisucaContextMenu.show(contexto, item: item));
    await tester.pumpAndSettle();
    conta.pedidosDeDentroDoPerfil.clear();
    await tester.tap(find.text('Minha lista'));
    await tester.pumpAndSettle();

    expect(conta.gravados, [true]);
    expect(conta.pedidosDeDentroDoPerfil, [true], reason: 'o diálogo fica no navegador raiz, fora do perfil');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('menu do cartão: título de Jellyfin mostra "Favoritar"; título de Plex mostra "Minha lista"', (
    tester,
  ) async {
    final contexto = await montar(tester);
    final doJellyfin = MediaItem(
      id: 'jf-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: 'Filme nosso',
      serverId: 'casa',
    );

    unawaited(HeisucaContextMenu.show(contexto, item: doJellyfin));
    await tester.pumpAndSettle();
    expect(find.text('Favoritar'), findsOneWidget);
    expect(find.text('Minha lista'), findsNothing);
    Navigator.of(contexto, rootNavigator: true).pop();
    await tester.pumpAndSettle();

    unawaited(HeisucaContextMenu.show(contexto, item: _filme('plex-13')));
    await tester.pumpAndSettle();
    expect(find.text('Minha lista'), findsOneWidget);
    expect(find.text('Favoritar'), findsNothing);
  });

  testWidgets('menu de um episódio de Plex não oferece "Minha lista": a lista da conta só guarda filme e série', (
    tester,
  ) async {
    final contexto = await montar(tester);
    final episodio = MediaItem(
      id: 'plex-ep-1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Piloto',
      serverId: 'amigo',
    );

    unawaited(HeisucaContextMenu.show(contexto, item: episodio));
    await tester.pumpAndSettle();

    expect(find.text('Marcar como visto'), findsOneWidget, reason: 'o menu abriu');
    expect(find.text('Minha lista'), findsNothing);
    expect(find.text('Favoritar'), findsNothing);
  });

  testWidgets('perfil trocado com o menu aberto: "Minha lista" não muda nada nem estoura', (tester) async {
    final contexto = await montar(tester);
    final item = _filme('plex-9');
    final loja = HeisucaStateStore.instance;
    var avisos = 0;
    void contar() => avisos++;
    loja.addListener(contar);
    addTearDown(() => loja.removeListener(contar));

    unawaited(HeisucaContextMenu.show(contexto, item: item));
    await tester.pumpAndSettle();
    await trocarDePerfil();
    await tester.pump();
    expect(contexto.mounted, isFalse, reason: 'a tela que abriu o menu saiu com o perfil');
    expect(find.text('Minha lista'), findsOneWidget, reason: 'o menu fica: está no navegador raiz');
    conta.pedidosDeDentroDoPerfil.clear();
    avisos = 0;

    await tester.tap(find.text('Minha lista'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(conta.gravados, isEmpty);
    expect(conta.pedidosDeDentroDoPerfil, isEmpty, reason: 'ninguém consulta a conta com o contexto de quem saiu');
    expect(loja.isFavorite(item), isFalse, reason: 'sem gravação possível, a tela não mostra o título na lista');
    expect(avisos, 0);
  });

  testWidgets('perfil trocado com o menu aberto: "Marcar como visto" do menu não grava nem estoura', (tester) async {
    final contexto = await montar(tester);
    final item = _filme('plex-11');
    final loja = HeisucaStateStore.instance;

    // Menu sem ação própria de visto, como no Início e no Explorar.
    unawaited(HeisucaContextMenu.show(contexto, item: item));
    await tester.pumpAndSettle();
    await trocarDePerfil();
    await tester.pump();
    expect(contexto.mounted, isFalse, reason: 'a tela que abriu o menu saiu com o perfil');
    expect(find.text('Marcar como visto'), findsOneWidget, reason: 'o menu fica: está no navegador raiz');
    var avisos = 0;
    void contar() => avisos++;
    loja.addListener(contar);
    addTearDown(() => loja.removeListener(contar));

    await tester.tap(find.text('Marcar como visto'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(servidor.vistos, isEmpty, reason: 'o servidor segue acessível, mas quem pediu já não está no perfil');
    expect(loja.isWatched(item), isFalse);
    expect(avisos, 0);
    expect(find.text('Marcado como visto'), findsNothing);
  });

  testWidgets('menu sem ação própria, com quem abriu ainda na tela: "Marcar como visto" grava', (tester) async {
    final contexto = await montar(tester);
    final item = _filme('plex-12');

    unawaited(HeisucaContextMenu.show(contexto, item: item));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar como visto'));
    await tester.pumpAndSettle();

    expect(servidor.vistos, [true]);
    expect(HeisucaStateStore.instance.isWatched(item), isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('perfil trocado: "visto" pedido por quem já saiu não muda nada', (tester) async {
    final contexto = await montar(tester);
    final item = _filme('plex-10');
    final loja = HeisucaStateStore.instance;
    await trocarDePerfil();
    await tester.pump();
    var avisos = 0;
    void contar() => avisos++;
    loja.addListener(contar);
    addTearDown(() => loja.removeListener(contar));

    final resultado = await loja.toggleWatched(contexto, item);
    await tester.pumpAndSettle();

    expect(resultado, isFalse);
    expect(loja.isWatched(item), isFalse);
    expect(avisos, 0, reason: 'nem a troca otimista acontece');
    expect(tester.takeException(), isNull);
  });
}
