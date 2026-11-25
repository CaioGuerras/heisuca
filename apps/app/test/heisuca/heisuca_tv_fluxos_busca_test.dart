import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/requests/cgflix_requests_ui.dart';
import 'package:heisuca/cgflix/requests/cgflix_seerr.dart';
import 'package:heisuca/features/busca/ligacao.dart';
import 'package:heisuca/features/busca/tela_busca_tv.dart';
import 'package:heisuca/features/explorar/ligacao.dart';
import 'package:heisuca/features/titulo/menu_do_titulo_tv.dart';
import 'package:heisuca/heisuca/heisuca_state_store.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_pecas.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/library_filter_result.dart';
import 'package:heisuca/media/library_query.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_library.dart';
import 'package:heisuca/media/media_person.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/media/server_capabilities.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/utils/media_server_http_client.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/platform_detector.dart';

import 'package:provider/provider.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/providers/hidden_libraries_provider.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/providers/offline_mode_provider.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import '../test_helpers/prefs.dart';

class _Pedidos extends Fake implements CgflixRequestsBackend {
  @override
  Future<List<CgflixRequestable>> search(String query) async => const [
    CgflixRequestable(tmdbId: 17, isMovie: true, title: 'Um pedido distante'),
  ];
}

/// Respostas em memória para testar os fluxos, sem banco nem rede no caminho da busca.
class _Servidor extends MediaServerClient {
  _Servidor(this.item);
  final MediaItem item;
  @override
  ServerId get serverId => ServerId('srv-1');
  @override
  String get serverName => 'Acervo da família';
  @override
  MediaBackend get backend => MediaBackend.jellyfin;
  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;
  @override
  Future<List<MediaItem>> searchItems(
    String query, {
    int limit = 100,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async => [item];
  @override
  Future<List<MediaPerson>> searchPeople(
    String query, {
    int limit = defaultPeopleSearchLimit,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async => [];
  @override
  Future<List<MediaLibrary>> fetchLibraries() async => [
    MediaLibrary(id: 'filmes', backend: backend, title: 'Filmes', kind: MediaKind.movie, serverId: 'srv-1'),
  ];
  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind}) async =>
      const LibraryFilterResult(filters: [], cachedValues: {});
  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async => LibraryPage(items: [item], totalCount: 1);
  @override
  Future<void> setFavorite(MediaItem item, bool favorite) async {}
  @override
  Future<void> markWatched(MediaItem item) async {}
  @override
  Future<void> markUnwatched(MediaItem item) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final filme = MediaItem.jellyfin(
    id: 'filme-tv-fluxo',
    serverId: 'srv-1',
    kind: MediaKind.movie,
    title: 'Uma viagem para lembrar',
  );
  late MultiServerManager gerente;
  late MultiServerProvider servidores;
  late HiddenLibrariesProvider ocultas;
  setUp(() async {
    resetSharedPreferencesForTest();
    await LocaleSettings.setLocale(AppLocale.pt);
    TvDetectionService.debugSetTvOverride(true);
    CgflixRequests.debugOverride = _Pedidos();
    await settings.SettingsService.getInstance();
    gerente = MultiServerManager()..debugRegisterClientForTesting(_Servidor(filme));
    servidores = MultiServerProvider(gerente, DataAggregationService(gerente));
    ocultas = HiddenLibrariesProvider();
    await ocultas.ensureInitialized();
  });
  tearDown(() {
    TvDetectionService.debugSetTvOverride(null);
    CgflixRequests.debugOverride = null;
    ocultas.dispose();
    servidores.dispose();
    gerente.dispose();
  });

  Future<void> montar(WidgetTester tester, Widget tela, double letra) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: servidores),
          ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: ocultas),
          ChangeNotifierProvider<OfflineModeProvider>(create: (_) => OfflineModeProvider(gerente)),
        ],
        child: MaterialApp(
          theme: TemaHeisuca.shikkoku.paraMaterial(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
            child: child!,
          ),
          home: tela,
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  for (final letra in [1.0, 2.0]) {
    testWidgets('Pedir da biblioteca abre Busca com foco e pedidos reais, letra $letra', (tester) async {
      await montar(tester, const LigacaoDoExplorar(naTv: true), letra);
      final pedir = find.byKey(const ValueKey('explorar-tv-pedir'));
      expect(pedir, findsOneWidget);
      Focus.of(tester.element(find.descendant(of: pedir, matching: find.byType(GestureDetector)).first)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.byType(TelaBuscaTv), findsOneWidget);
      final campo = tester.widget<TextField>(find.byKey(const ValueKey('busca-tv-campo')));
      expect(campo.focusNode!.hasFocus, isTrue, reason: 'rota avulsa precisa aceitar o controle imediatamente');
      campo.controller!.text = 'distante';
      await tester.runAsync(() async {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await Future<void>.delayed(Duration.zero);
      });
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.byType(CgflixRequestSection), findsOneWidget);
      expect(find.text('Um pedido distante'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Menu da Busca acompanha alteração de lista enquanto permanece aberto', (tester) async {
    await montar(tester, const LigacaoDaBusca(naTv: true), 2);
    final campo = tester.widget<TextField>(find.byKey(const ValueKey('busca-tv-campo')));
    campo.controller!.text = 'viagem';
    campo.focusNode!.requestFocus();
    await tester.pump();
    await tester.runAsync(() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await Future<void>.delayed(Duration.zero);
    });
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    final estado = tester.widget<TelaBuscaTv>(find.byType(TelaBuscaTv));
    expect(estado.buscando, isFalse, reason: 'a resposta do servidor em memória precisa terminar');
    expect(
      estado.buscou,
      isTrue,
      reason:
          'buscando=${estado.buscando} aviso=${estado.aviso} foco=${campo.focusNode!.hasFocus} texto=${campo.controller!.text}',
    );
    expect(find.byType(CartaoTv), findsOneWidget);
    final cartao = find.byType(CartaoTv);
    tester.widget<CartaoTv>(cartao).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(find.byType(MenuDoTituloTv), findsOneWidget);
    final anterior = HeisucaStateStore.instance.isFavorite(filme);
    final contexto = tester.element(find.byType(LigacaoDaBusca));
    await HeisucaStateStore.instance.toggleFavorite(contexto, filme);
    await tester.pump();
    expect(tester.widget<BotaoTv>(find.widgetWithText(BotaoTv, 'Minha lista')).selecionado, !anterior);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Biblioteca reflete alteração de visto sem sair nem recarregar a tela', (tester) async {
    await montar(tester, const LigacaoDoExplorar(naTv: true), 2);
    final cartao = find.byType(CartaoTv);
    expect(cartao, findsOneWidget);
    final anterior = HeisucaStateStore.instance.isWatched(filme);
    final contexto = tester.element(find.byType(LigacaoDoExplorar));
    final resultado = await HeisucaStateStore.instance.toggleWatched(contexto, filme);
    expect(resultado, !anterior, reason: 'o servidor confirmou a alteração');
    await tester.pump();
    expect(tester.widget<CartaoTv>(cartao).progresso, anterior ? null : 1);
  });
}
