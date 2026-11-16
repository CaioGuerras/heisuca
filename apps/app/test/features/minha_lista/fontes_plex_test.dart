import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/you/cgflix_favorites_screen.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/features/minha_lista/ligacao.dart';
import 'package:heisuca/heisuca/heisuca_lista_plex.dart';
import '../../design/componentes/apoio.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/models/catalog/catalog_item.dart';
import 'package:heisuca/providers/catalog_sources_provider.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/catalog/catalog_source.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/jellyfin_client.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/services/plex_client.dart';
import 'package:heisuca/utils/external_ids.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../test_helpers/backend_client_fixtures.dart';

class _Gerente extends MultiServerManager {
  _Gerente(this.clientes);
  final Map<String, MediaServerClient> clientes;
  @override
  Map<String, MediaServerClient> get navigationOnlineClients => clientes;
}

class _Catalogos extends CatalogSourcesProvider {
  _Catalogos(this.fonte);
  final CatalogSource? fonte;
  @override
  List<CatalogSource> get connectedSources => [?fonte];
}

class _Gravacao implements ListaDoPlex {
  _Gravacao(this.conta);
  final _Conta conta;
  final gravados = <bool>[];
  @override
  Future<bool?> estaNaLista() async => conta.paginas.single.isNotEmpty;
  @override
  Future<void> gravar(bool naLista) async {
    gravados.add(naLista);
    conta.paginas.single.clear();
  }
}

class _Conta extends Fake implements CatalogSource {
  _Conta(this.paginas);
  final List<List<CatalogItem>> paginas;
  bool falhar = false;
  final pedidos = <int>[];
  @override
  CatalogSourceId get id => CatalogSourceId.plex;
  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    expect(row, CatalogRowId.watchlist);
    pedidos.add(page);
    if (falhar) throw TimeoutException('sem conexão');
    return CatalogPage(items: paginas[page - 1], hasMore: page < paginas.length);
  }
}

class _Plex extends Fake implements PlexClient {
  final pedidos = <String?>[];
  bool falhar = false;
  int simultaneos = 0;
  int maximo = 0;
  Future<void> Function()? esperar;
  @override
  Future<List<MediaItem>?> findByExternalIds(
    ExternalIds ids, {
    required MediaKind kind,
    List<String> titles = const [],
    int? year,
    String? plexGuid,
    ExternalSeasonRef? season,
  }) async {
    pedidos.add(plexGuid);
    simultaneos++;
    if (simultaneos > maximo) maximo = simultaneos;
    try {
      if (falhar) throw TimeoutException('servidor fora');
      if (esperar != null) await esperar!();
      if (plexGuid == 'plex://movie/ausente') return [];
      return [
        MediaItem.plex(
          id: 'local-${ids.tmdb}',
          kind: kind,
          title: 'Plex ${ids.tmdb}',
          serverId: 'plex',
          guid: plexGuid,
          raw: {
            'Guid': [
              {'id': 'tmdb://${ids.tmdb}'},
            ],
          },
        ),
      ];
    } finally {
      simultaneos--;
    }
  }
}

CatalogItem _titulo(int id, {String? plex}) => CatalogItem(
  source: CatalogSourceId.plex,
  kind: MediaKind.movie,
  title: 'Catálogo $id',
  ids: CatalogItemIds(plex: plex ?? '$id', tmdb: id),
);

JellyfinClient _jellyfin(String servidor, List<int> ids, {bool emby = false, bool falhar = false}) =>
    testJellyfinClient(
      connection: emby ? testEmbyConnection(machineId: servidor) : testJellyfinConnection(machineId: servidor),
      handler: (request) async {
        if (falhar) throw TimeoutException('sem conexão');
        final biblioteca = request.url.path.endsWith('/Views');
        return http.Response(
          jsonEncode({
            'Items': biblioteca
                ? [
                    {'Id': 'filmes', 'Name': 'Filmes', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
                  ]
                : [
                    for (final id in ids)
                      {
                        'Id': '$id',
                        'Name': 'Jellyfin $id',
                        'Type': 'Movie',
                        'ProviderIds': {'Tmdb': '$id'},
                        'UserData': {'IsFavorite': true},
                      },
                  ],
            'TotalRecordCount': biblioteca ? 1 : ids.length,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      },
    );

Future<CgflixFavoritesSource?> _fonte(
  WidgetTester tester,
  Map<String, MediaServerClient> clientes,
  _Conta? conta, {
  bool mostrar = false,
}) async {
  final gerente = _Gerente(clientes);
  final servidores = MultiServerProvider(gerente, DataAggregationService(gerente));
  final catalogos = _Catalogos(conta);
  addTearDown(servidores.dispose);
  addTearDown(gerente.dispose);
  addTearDown(catalogos.dispose);
  CgflixFavoritesSource? fonte;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MultiServerProvider>.value(value: servidores),
        ChangeNotifierProvider<CatalogSourcesProvider>.value(value: catalogos),
      ],
      child: Builder(
        builder: (context) {
          fonte = CgflixFavoritesSource.of(context);
          return mostrar && fonte != null ? naTela(LigacaoDaMinhaLista(fonte: fonte!)) : const SizedBox();
        },
      ),
    ),
  );
  return fonte;
}

void main() {
  testWidgets('só Plex: a Watchlist entra na Minha lista com o título do servidor', (tester) async {
    final plex = _Plex();
    final conta = _Conta([
      [_titulo(1)],
    ]);
    final fonte = await _fonte(tester, {'plex': plex}, conta);
    expect(fonte, isNotNull, reason: 'Minha lista também existe com só Plex');
    final itens = await tester.runAsync(() => fonte!.load());
    expect(itens!.map((item) => item.title), ['Plex 1']);
    expect(itens.single.isFavorite, isTrue, reason: 'o menu deve oferecer tirar da lista');
    expect(plex.pedidos, ['plex://movie/1']);
  });

  testWidgets('Jellyfin + Emby + Plex: todos entram, sem duplicar o mesmo título', (tester) async {
    final conta = _Conta([
      [_titulo(1), _titulo(2)],
    ]);
    final fonte = await _fonte(tester, {
      'jf': _jellyfin('jf', [1]),
      'emby': _jellyfin('emby', [3], emby: true),
      'plex': _Plex(),
    }, conta);
    final itens = await tester.runAsync(() => fonte!.load());
    expect(itens!.map((item) => item.title), ['Jellyfin 1', 'Jellyfin 3', 'Plex 2']);
  });

  testWidgets('Plex falhando: mantém os favoritos do Jellyfin', (tester) async {
    final conta = _Conta([
      [_titulo(2)],
    ])..falhar = true;
    final fonte = await _fonte(tester, {
      'jf': _jellyfin('jf', [1]),
      'plex': _Plex(),
    }, conta);
    final itens = await tester.runAsync(() => fonte!.load());
    expect(itens!.map((item) => item.title), ['Jellyfin 1']);
    expect(conta.pedidos, [1], reason: 'a falha foi de uma fonte efetivamente consultada');
  });

  testWidgets('sem conta Plex não derruba Jellyfin; todas falhando devolvem erro', (tester) async {
    var fonte = await _fonte(tester, {
      'jf': _jellyfin('jf', [1]),
      'plex': _Plex(),
    }, null);
    expect(await tester.runAsync(() => fonte!.load()), hasLength(1));
    fonte = await _fonte(tester, {'plex': _Plex()}, null);
    await tester.runAsync(() async => expectLater(fonte!.load(), throwsStateError));
  });

  testWidgets('Jellyfin falhando mantém Plex; todas as redes falhando propagam erro', (tester) async {
    final conta = _Conta([
      [_titulo(2)],
    ]);
    final fonte = await _fonte(tester, {'jf': _jellyfin('jf', [], falhar: true), 'plex': _Plex()}, conta);
    expect((await tester.runAsync(() => fonte!.load()))!.map((item) => item.title), ['Plex 2']);
    conta.falhar = true;
    await tester.runAsync(() async => expectLater(fonte!.load(), throwsStateError));
  });

  testWidgets('pagina a Watchlist, resolve uma vez e só inclui o acervo conectado', (tester) async {
    final plex = _Plex();
    final conta = _Conta([
      [_titulo(1)],
      [_titulo(1), _titulo(2), _titulo(3, plex: 'ausente')],
    ]);
    final fonte = await _fonte(tester, {'plex': plex}, conta);
    expect(fonte, isNotNull);
    final itens = await tester.runAsync(() => fonte!.load());
    expect(itens, hasLength(2));
    expect(conta.pedidos, [1, 2]);
    expect(plex.pedidos, ['plex://movie/1', 'plex://movie/2', 'plex://movie/ausente']);
  });

  testWidgets('cartão Plex: tirar da lista grava pela loja padrão e atualiza a aba', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final conta = _Conta([
      [_titulo(98)],
    ]);
    final gravacao = _Gravacao(conta);
    ListaDoPlex.fabricaDeTeste = (context, item, cliente) => gravacao;
    addTearDown(() => ListaDoPlex.fabricaDeTeste = null);
    final fonte = await _fonte(tester, {'plex': _Plex()}, conta, mostrar: true);
    expect(fonte, isNotNull);
    await tester.pumpAndSettle();
    expect(find.text('Plex 98'), findsOneWidget);
    await tester.longPress(find.text('Plex 98'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tirar da Minha lista').hitTestable().first);
    await tester.pumpAndSettle();
    expect(gravacao.gravados, [false]);
    expect(find.text('Plex 98'), findsNothing);
    expect(find.text('Nenhum favorito ainda'), findsOneWidget);
    expect(conta.pedidos, [1, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resolução tem no máximo quatro pedidos simultâneos', (tester) async {
    final plex = _Plex();
    final conta = _Conta([
      [for (var i = 0; i < 12; i++) _titulo(i)],
    ]);
    final fonte = await _fonte(tester, {'plex': plex}, conta);
    expect(fonte, isNotNull);
    await tester.runAsync(() async {
      final bloqueio = Completer<void>();
      plex.esperar = () => bloqueio.future;
      final carga = fonte!.load();
      for (var i = 0; i < 20; i++) {
        await Future<void>.value();
      }
      try {
        expect(plex.pedidos, hasLength(4));
      } finally {
        bloqueio.complete();
      }
      expect(await carga, hasLength(12));
      expect(plex.maximo, 4);
      expect(plex.pedidos.toSet(), hasLength(12));
    });
  });

  testWidgets('servidor Plex falha sem esconder outro Plex que respondeu', (tester) async {
    final conta = _Conta([
      [_titulo(1)],
    ]);
    final fonte = await _fonte(tester, {'fora': _Plex()..falhar = true, 'plex': _Plex()}, conta);
    expect(fonte, isNotNull);
    expect(await tester.runAsync(() => fonte!.load()), hasLength(1));
  });
}
