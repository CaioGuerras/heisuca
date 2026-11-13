import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/features/explorar/ligacao.dart';
import 'package:heisuca/features/explorar/tela_explorar.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/library_filter_result.dart';
import 'package:heisuca/media/library_query.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_filter.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_library.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/utils/media_server_http_client.dart';
import 'package:provider/provider.dart';

import '../../design/componentes/apoio.dart';

MediaFilter _filtro(String campo) => MediaFilter.fromJson({
  'filter': campo,
  'filterType': 'string',
  'key': '/x/$campo',
  'title': campo,
  'type': 'filter',
});

/// Servidor de mentira: duas bibliotecas, páginas contadas e falhas marcadas pelo teste.
class _Servidor extends MediaServerClient {
  /// Quantos títulos cada biblioteca tem no total.
  final total = <String, int>{'filmes': 2, 'series': 2};

  /// Quantos títulos uma página devolve.
  int porPagina = 60;

  /// Pedidos de filtros que ainda vão falhar, por biblioteca.
  final filtrosQueFalham = <String, int>{};

  /// Pedidos de página que ainda vão falhar, pelo ponto de partida da página.
  final paginasQueFalham = <int, int>{};

  /// Pedidos de filtros que ainda vão voltar pela metade (sem os gêneros e sem erro), por biblioteca.
  /// É o que o cliente do Jellyfin devolve quando a consulta dos filtros estoura o tempo.
  final filtrosPelaMetade = <String, int>{};

  /// Esperas que os próximos pedidos de filtros de cada biblioteca cumprem antes de responder, na ordem.
  final esperasDosFiltros = <String, List<Completer<void>>>{};

  final pedidosDeFiltros = <String>[];
  final pedidosDePagina = <(String, LibraryQuery)>[];

  @override
  ServerId get serverId => ServerId('casa');

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  Future<List<MediaLibrary>> fetchLibraries() async => [
    MediaLibrary(id: 'filmes', backend: backend, title: 'Filmes', kind: MediaKind.movie, serverId: 'casa'),
    MediaLibrary(id: 'series', backend: backend, title: 'Séries', kind: MediaKind.show, serverId: 'casa'),
  ];

  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind}) async {
    pedidosDeFiltros.add(libraryId);
    final faltam = filtrosQueFalham[libraryId] ?? 0;
    if (faltam > 0) {
      filtrosQueFalham[libraryId] = faltam - 1;
      throw StateError('sem filtros');
    }
    final esperas = esperasDosFiltros[libraryId];
    if (esperas != null && esperas.isNotEmpty) await esperas.removeAt(0).future;
    final pelaMetade = filtrosPelaMetade[libraryId] ?? 0;
    if (pelaMetade > 0) {
      filtrosPelaMetade[libraryId] = pelaMetade - 1;
      return LibraryFilterResult(filters: [_filtro('unwatched')], cachedValues: const {});
    }
    return LibraryFilterResult(
      filters: [_filtro('unwatched'), _filtro('genre')],
      cachedValues: {
        'genre': [MediaFilterValue(key: 'acao', title: 'Ação')],
      },
    );
  }

  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async {
    pedidosDePagina.add((libraryId, query));
    final faltam = paginasQueFalham[query.offset] ?? 0;
    if (faltam > 0) {
      paginasQueFalham[query.offset] = faltam - 1;
      throw StateError('sem página');
    }
    final fim = (query.offset + porPagina).clamp(0, total[libraryId]!);
    return LibraryPage(
      items: [
        for (var i = query.offset; i < fim; i++)
          MediaItem(id: '$libraryId-$i', backend: backend, kind: libraryKind!, title: 'Título $i', serverId: 'casa'),
      ],
      totalCount: total[libraryId]!,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _abrir(WidgetTester tester, _Servidor servidor) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final gerente = MultiServerManager()..debugRegisterClientForTesting(servidor);
  final servidores = MultiServerProvider(gerente, DataAggregationService(gerente));
  addTearDown(servidores.dispose);
  addTearDown(gerente.dispose);
  await tester.pumpWidget(ChangeNotifierProvider.value(value: servidores, child: naTela(const LigacaoDoExplorar())));
  await tester.pumpAndSettle();
}

bool _pedeNaoVistos(LibraryQuery pedido) => pedido.filters.any((filtro) => filtro.field == 'unwatched');

void main() {
  testWidgets('filtros que não chegaram são pedidos de novo ao puxar para atualizar', (tester) async {
    final servidor = _Servidor()..filtrosQueFalham['series'] = 1;
    await _abrir(tester, servidor);

    await tester.tap(find.text('Não vistos'));
    await tester.pumpAndSettle();
    expect(servidor.pedidosDePagina.last.$1, 'filmes');
    expect(_pedeNaoVistos(servidor.pedidosDePagina.last.$2), isTrue);

    // A biblioteca seguinte não devolve os filtros: a lista vem inteira e a pílula some.
    await tester.tap(find.text('Séries'));
    await tester.pumpAndSettle();
    expect(servidor.pedidosDePagina.last.$1, 'series');
    expect(_pedeNaoVistos(servidor.pedidosDePagina.last.$2), isFalse);
    expect(find.text('Não vistos'), findsNothing);
    expect(find.text('Título 0'), findsOneWidget, reason: 'sem filtros a biblioteca continua navegável');

    final antes = servidor.pedidosDeFiltros.where((id) => id == 'series').length;
    await tester.widget<TelaExplorar>(find.byType(TelaExplorar)).aoAtualizar!();
    await tester.pumpAndSettle();

    expect(servidor.pedidosDeFiltros.where((id) => id == 'series').length, antes + 1);
    expect(find.text('Não vistos'), findsOneWidget);
    expect(servidor.pedidosDePagina.last.$1, 'series');
    expect(
      _pedeNaoVistos(servidor.pedidosDePagina.last.$2),
      isTrue,
      reason: 'a escolha de "não vistos" segue ligada e volta a valer quando o filtro chega',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtros que voltam pela metade, sem erro, são pedidos de novo ao puxar para atualizar', (tester) async {
    final servidor = _Servidor()..filtrosPelaMetade['filmes'] = 1;
    await _abrir(tester, servidor);
    expect(find.text('Ação'), findsNothing);
    expect(find.text('Título 0'), findsOneWidget);

    final antes = servidor.pedidosDeFiltros.length;
    await tester.widget<TelaExplorar>(find.byType(TelaExplorar)).aoAtualizar!();
    await tester.pumpAndSettle();

    expect(servidor.pedidosDeFiltros.length, antes + 1);
    expect(find.text('Ação'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resposta atrasada dos filtros não recarrega a grade depois de ir e voltar de biblioteca', (
    tester,
  ) async {
    final servidor = _Servidor();
    await _abrir(tester, servidor);
    await tester.tap(find.text('Não vistos'));
    await tester.pumpAndSettle();

    // A primeira ida às séries fica esperando os filtros; a pessoa volta aos filmes e vai às séries de novo.
    final atrasada = Completer<void>();
    servidor.esperasDosFiltros['series'] = [atrasada];
    await tester.tap(find.text('Séries'));
    await tester.pump();
    await tester.tap(find.text('Filmes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Séries'));
    await tester.pumpAndSettle();
    expect(find.text('Título 0'), findsOneWidget);
    final antes = servidor.pedidosDePagina.length;

    atrasada.complete();
    await tester.pumpAndSettle();

    expect(servidor.pedidosDePagina.length, antes, reason: 'a resposta velha não pede a primeira página outra vez');
    expect(find.text('Título 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('com os filtros em mãos, puxar para atualizar não os pede de novo', (tester) async {
    final servidor = _Servidor();
    await _abrir(tester, servidor);
    final antes = servidor.pedidosDeFiltros.length;

    await tester.widget<TelaExplorar>(find.byType(TelaExplorar)).aoAtualizar!();
    await tester.pumpAndSettle();

    expect(servidor.pedidosDeFiltros.length, antes);
    expect(servidor.pedidosDePagina.last.$2.offset, 0);
  });

  testWidgets('página seguinte que falha: "Tentar de novo" pede só ela e a grade segue', (tester) async {
    final servidor = _Servidor()
      ..porPagina = 3
      ..total['filmes'] = 5
      ..paginasQueFalham[3] = 1;
    await _abrir(tester, servidor);

    // A grade curta pede a segunda página sozinha; ela falha e os três primeiros títulos ficam.
    expect(servidor.pedidosDePagina.map((pedido) => pedido.$2.offset), [0, 3]);
    expect(find.text('Título 2'), findsOneWidget);
    expect(find.text('Título 3'), findsNothing);
    expect(find.text('Não foi possível carregar mais títulos.'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(servidor.pedidosDePagina.map((pedido) => pedido.$2.offset), [0, 3, 3]);
    expect(find.text('Título 4'), findsOneWidget);
    expect(find.text('Não foi possível carregar mais títulos.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
