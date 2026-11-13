import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/heisuca/heisuca_lista_plex.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/models/catalog/catalog_item.dart';
import 'package:heisuca/providers/catalog_sources_provider.dart';
import 'package:heisuca/services/catalog/catalog_source.dart';
import 'package:heisuca/services/plex_client.dart';
import 'package:heisuca/utils/external_ids.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

/// Servidor Plex de mentira: só sabe dizer os números do título (IMDb).
class _ServidorPlex implements PlexClient {
  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async => const ExternalIds(imdb: 'tt0000001');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Servidor que não é Plex.
class _OutroServidor implements MediaServerClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Conta de mentira, do lado da fonte de catálogo: guarda a Watchlist em memória.
class _Conta implements CatalogSource {
  _Conta(this.id, {this.reconhece = true});

  @override
  final CatalogSourceId id;

  /// A conta sabe que título é este?
  final bool reconhece;

  final naLista = <String>{};
  bool carregada = false;
  final gravacoes = <String>[];

  @override
  bool get supportsWatchlist => true;

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async =>
      reconhece ? CatalogItemIds(imdb: external.imdb) : null;

  @override
  Future<void> ensureWatchlistLoaded() async => carregada = true;

  @override
  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids) => carregada ? naLista.contains(ids.canonicalKey) : null;

  @override
  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) async {
    gravacoes.add('+${ids.canonicalKey}');
    naLista.add(ids.canonicalKey!);
  }

  @override
  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids) async {
    gravacoes.add('-${ids.canonicalKey}');
    naLista.remove(ids.canonicalKey);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// As fontes do perfil, com as contas escolhidas pelo teste; o resto do provedor é o de verdade.
class _Fontes extends CatalogSourcesProvider {
  _Fontes(this.contas);

  final List<CatalogSource> contas;

  @override
  List<CatalogSource> get connectedSources => contas;
}

MediaItem _titulo(String id, {MediaKind tipo = MediaKind.movie}) =>
    MediaItem(id: id, backend: MediaBackend.plex, kind: tipo, title: 'Filme do amigo', serverId: 'amigo');

void main() {
  setUp(resetSharedPreferencesForTest);

  /// Monta a árvore com (ou sem) as fontes do perfil e devolve um contexto de dentro dela.
  Future<BuildContext> montar(WidgetTester tester, {_Fontes? fontes}) async {
    expect(ListaDoPlex.fabricaDeTeste, isNull, reason: 'aqui roda a ponte de verdade');
    late BuildContext contexto;
    final folha = Builder(
      builder: (context) {
        contexto = context;
        return const SizedBox.shrink();
      },
    );
    await tester.pumpWidget(
      fontes == null ? folha : ChangeNotifierProvider<CatalogSourcesProvider>.value(value: fontes, child: folha),
    );
    return contexto;
  }

  testWidgets('ponte de verdade: lê, põe e tira da Watchlist da conta Plex', (tester) async {
    final plex = _Conta(CatalogSourceId.plex);
    final outra = _Conta(CatalogSourceId.seerr);
    final fontes = _Fontes([outra, plex]);
    addTearDown(fontes.dispose);
    final contexto = await montar(tester, fontes: fontes);

    final lista = ListaDoPlex.de(contexto, _titulo('p1'), _ServidorPlex());
    expect(lista, isNotNull);

    expect(await lista!.estaNaLista(), isFalse);
    expect(plex.carregada, isTrue, reason: 'a Watchlist é carregada antes da resposta');

    await lista.gravar(true);
    expect(plex.gravacoes, ['+imdb:tt0000001']);
    expect(await lista.estaNaLista(), isTrue);

    await lista.gravar(false);
    expect(plex.gravacoes, ['+imdb:tt0000001', '-imdb:tt0000001']);
    expect(await lista.estaNaLista(), isFalse);

    expect(outra.gravacoes, isEmpty, reason: 'só a conta Plex recebe a gravação');
  });

  testWidgets('ponte de verdade: conta que não reconhece o título não sabe responder e a gravação falha', (
    tester,
  ) async {
    final plex = _Conta(CatalogSourceId.plex, reconhece: false);
    final fontes = _Fontes([plex]);
    addTearDown(fontes.dispose);
    final contexto = await montar(tester, fontes: fontes);

    final lista = ListaDoPlex.de(contexto, _titulo('p2'), _ServidorPlex())!;

    expect(await lista.estaNaLista(), isNull);
    await expectLater(lista.gravar(true), throwsStateError);
    expect(plex.gravacoes, isEmpty);
  });

  testWidgets('ponte de verdade: sem conta Plex ligada a gravação falha', (tester) async {
    final fontes = _Fontes([_Conta(CatalogSourceId.seerr)]);
    addTearDown(fontes.dispose);
    final contexto = await montar(tester, fontes: fontes);

    final lista = ListaDoPlex.de(contexto, _titulo('p3'), _ServidorPlex())!;

    expect(await lista.estaNaLista(), isNull);
    await expectLater(lista.gravar(true), throwsStateError);
  });

  testWidgets('ponte de verdade: só existe para filme ou série de servidor Plex, com as fontes do perfil', (
    tester,
  ) async {
    final fontes = _Fontes([_Conta(CatalogSourceId.plex)]);
    addTearDown(fontes.dispose);
    final contexto = await montar(tester, fontes: fontes);

    expect(ListaDoPlex.de(contexto, _titulo('p4'), _OutroServidor()), isNull);
    expect(ListaDoPlex.de(contexto, _titulo('p4'), null), isNull);
    expect(ListaDoPlex.de(contexto, _titulo('p4', tipo: MediaKind.episode), _ServidorPlex()), isNull);
    expect(ListaDoPlex.de(contexto, _titulo('p4', tipo: MediaKind.show), _ServidorPlex()), isNotNull);

    final semFontes = await montar(tester);
    expect(ListaDoPlex.de(semFontes, _titulo('p4'), _ServidorPlex()), isNull);
  });
}
