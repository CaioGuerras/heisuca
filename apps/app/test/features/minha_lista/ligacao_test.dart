import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/you/cgflix_favorites_screen.dart';
import 'package:heisuca/features/minha_lista/ligacao.dart';
import 'package:heisuca/features/minha_lista/tela_minha_lista.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:provider/provider.dart';

import '../../design/componentes/apoio.dart';

MediaItem _item(String id, MediaKind tipo, {String? biblioteca, int? ano}) => MediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: tipo,
  title: 'Título $id',
  serverId: 'casa',
  libraryTitle: biblioteca,
  year: ano,
);

Future<void> _abrir(WidgetTester tester, CgflixFavoritesSource fonte) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final gerente = MultiServerManager();
  final servidores = MultiServerProvider(gerente, DataAggregationService(gerente));
  addTearDown(servidores.dispose);
  addTearDown(gerente.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: servidores,
      child: naTela(LigacaoDaMinhaLista(fonte: fonte)),
    ),
  );
  await tester.pump();
}

void main() {
  test('agruparFavoritos: Séries, Filmes e Animes, nesta ordem; grupo vazio não entra', () {
    final grupos = agruparFavoritos([
      _item('f1', MediaKind.movie),
      _item('a1', MediaKind.show, biblioteca: 'Animes'),
      _item('s1', MediaKind.show),
      _item('f2', MediaKind.movie),
    ]);
    expect(grupos.map((grupo) => grupo.titulo), ['Séries', 'Filmes', 'Animes']);
    expect(grupos[1].itens.map((item) => item.id), ['f1', 'f2'], reason: 'a ordem da fonte é mantida');

    expect(agruparFavoritos([_item('f1', MediaKind.movie)]).map((grupo) => grupo.chave), ['filmes']);
    expect(agruparFavoritos(const []), isEmpty);
  });

  testWidgets('favoritos viram fileiras por tipo, com o ano embaixo do título', (tester) async {
    await _abrir(
      tester,
      CgflixFavoritesSource(load: () async => [_item('f1', MediaKind.movie, ano: 1999), _item('s1', MediaKind.show)]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Séries'), findsOneWidget);
    expect(find.text('Filmes'), findsOneWidget);
    expect(find.text('Título f1'), findsOneWidget);
    expect(find.text('1999'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem favoritos: aviso que diz como guardar um título', (tester) async {
    await _abrir(tester, CgflixFavoritesSource(load: () async => const []));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum favorito ainda'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
  });

  testWidgets('falha na carga: aviso com "Tentar novamente", que pede a lista outra vez', (tester) async {
    var pedidos = 0;
    await _abrir(
      tester,
      CgflixFavoritesSource(
        load: () async {
          pedidos++;
          if (pedidos == 1) throw StateError('sem rede');
          return [_item('f1', MediaKind.movie)];
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar a sua lista'), findsOneWidget);
    expect(find.text('Nenhum favorito ainda'), findsNothing);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(pedidos, 2);
    expect(find.text('Título f1'), findsOneWidget);
    expect(find.text('Não foi possível carregar a sua lista'), findsNothing);
  });

  testWidgets('falha ao atualizar com a lista na tela: a lista fica', (tester) async {
    var pedidos = 0;
    await _abrir(
      tester,
      CgflixFavoritesSource(
        load: () async {
          pedidos++;
          if (pedidos == 2) throw StateError('sem rede');
          return [_item('f1', MediaKind.movie)];
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.widget<TelaMinhaLista>(find.byType(TelaMinhaLista)).aoAtualizar!();
    await tester.pumpAndSettle();
    expect(pedidos, 2);
    expect(find.text('Título f1'), findsOneWidget);
    expect(find.text('Não foi possível carregar a sua lista'), findsNothing);
  });

  testWidgets('resposta velha não passa por cima da nova', (tester) async {
    final primeira = Completer<List<MediaItem>>();
    var pedidos = 0;
    await _abrir(
      tester,
      CgflixFavoritesSource(
        load: () {
          pedidos++;
          return pedidos == 1 ? primeira.future : Future.value([_item('novo', MediaKind.movie)]);
        },
      ),
    );
    await tester.widget<TelaMinhaLista>(find.byType(TelaMinhaLista)).aoAtualizar!();
    await tester.pumpAndSettle();
    expect(find.text('Título novo'), findsOneWidget);

    primeira.complete([_item('velho', MediaKind.movie)]);
    await tester.pumpAndSettle();
    expect(find.text('Título novo'), findsOneWidget);
    expect(find.text('Título velho'), findsNothing);
  });
}
