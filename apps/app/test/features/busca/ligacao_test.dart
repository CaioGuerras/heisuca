import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_navigation.dart';
import 'package:heisuca/cgflix/search/cgflix_search_extras.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/features/busca/ligacao.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_person.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/media/server_capabilities.dart';
import 'package:heisuca/providers/hidden_libraries_provider.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/screens/search_screen.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:heisuca/services/storage_service.dart';
import 'package:heisuca/utils/media_server_http_client.dart';
import 'package:provider/provider.dart';

import '../../design/componentes/apoio.dart';
import '../../test_helpers/prefs.dart';

/// Servidor de mentira: devolve os títulos e as pessoas que o teste pôs, ou falha.
class _Servidor extends MediaServerClient {
  List<MediaItem> titulos = const [];
  List<MediaPerson> pessoas = const [];
  Object? erro;
  final buscas = <String>[];

  @override
  ServerId get serverId => ServerId('casa');

  @override
  String? get serverName => 'Casa';

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
  }) async {
    buscas.add(query);
    if (erro != null) throw erro!;
    return titulos;
  }

  @override
  Future<List<MediaPerson>> searchPeople(
    String query, {
    int limit = defaultPeopleSearchLimit,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async => pessoas;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

MediaItem _titulo(String id, String nome, MediaKind tipo) =>
    MediaItem(id: id, backend: MediaBackend.jellyfin, kind: tipo, title: nome, serverId: 'casa', serverName: 'Casa');

Future<void> _abrir(WidgetTester tester, _Servidor servidor, {bool empilhada = false}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final gerente = MultiServerManager()..debugRegisterClientForTesting(servidor);
  final servidores = MultiServerProvider(gerente, DataAggregationService(gerente));
  final ocultas = HiddenLibrariesProvider();
  addTearDown(ocultas.dispose);
  addTearDown(servidores.dispose);
  addTearDown(gerente.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MultiServerProvider>.value(value: servidores),
        ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: ocultas),
      ],
      child: naTela(
        empilhada
            ? Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => const LigacaoDaBusca(focoInicial: false))),
                  child: const Text('Abrir a busca'),
                ),
              )
            : const LigacaoDaBusca(focoInicial: false),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> _buscar(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
    // O HiddenLibrariesProvider lê isto; dentro do fake-async a ida real às preferências não termina.
    await StorageService.getInstance();
  });
  tearDown(SettingsService.resetForTesting);

  testWidgets('digitar busca e mostra títulos e pessoas, com a fonte', (tester) async {
    final servidor = _Servidor()
      ..titulos = [_titulo('f1', 'Duna', MediaKind.movie), _titulo('s1', 'Duna: A Profecia', MediaKind.show)]
      ..pessoas = [
        MediaPerson(id: 'p1', name: 'Duna Pessoa', backend: MediaBackend.jellyfin, serverId: ServerId('casa')),
      ];
    await _abrir(tester, servidor);
    await _buscar(tester, 'duna');

    expect(servidor.buscas, ['duna']);
    expect(find.byType(Cartao), findsNWidgets(2));
    expect(find.text('Duna'), findsOneWidget);
    expect(find.text('Duna Pessoa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nada encontrado: aviso no lugar dos cartões', (tester) async {
    final servidor = _Servidor();
    await _abrir(tester, servidor);
    await _buscar(tester, 'xyzw');

    expect(find.text('Nada encontrado'), findsOneWidget);
    expect(find.byType(Cartao), findsNothing);
  });

  testWidgets('servidor falha: aviso com "Tentar novamente", que busca de novo', (tester) async {
    final servidor = _Servidor()..erro = StateError('fora do ar');
    await _abrir(tester, servidor);
    await _buscar(tester, 'dark');

    expect(find.text('Nenhum servidor respondeu'), findsOneWidget);
    servidor
      ..erro = null
      ..titulos = [_titulo('s1', 'Dark', MediaKind.show)];
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(servidor.buscas, ['dark', 'dark']);
    expect(find.text('Dark'), findsWidgets);
    expect(find.text('Nenhum servidor respondeu'), findsNothing);
  });

  testWidgets('busca que achou algo entra no histórico; limpar o campo mostra os recentes', (tester) async {
    final servidor = _Servidor()..titulos = [_titulo('f1', 'Alien', MediaKind.movie)];
    await _abrir(tester, servidor);
    await _buscar(tester, 'alien');

    await tester.tap(find.bySemanticsLabel('Limpar a busca'));
    await tester.pumpAndSettle();
    expect(find.text('Buscas recentes'), findsOneWidget);
    expect(find.text('alien'), findsOneWidget);
    expect(await cgflixReadSearchHistory(), ['alien']);
  });

  testWidgets('tocar um recente põe o texto no campo e busca', (tester) async {
    final servidor = _Servidor()..titulos = [_titulo('f1', 'Naruto', MediaKind.show)];
    await _abrir(tester, servidor);
    await _buscar(tester, 'naruto');
    await tester.tap(find.bySemanticsLabel('Limpar a busca'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('naruto'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(servidor.buscas, ['naruto', 'naruto']);
    expect(find.byType(Cartao), findsOneWidget);
  });
  testWidgets('enviar pelo teclado antes da pausa busca uma vez só', (tester) async {
    final servidor = _Servidor()..titulos = [_titulo('f1', 'Duna', MediaKind.movie)];
    await _abrir(tester, servidor);
    await tester.enterText(find.byType(TextField), 'duna');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(servidor.buscas, ['duna']);
    expect(find.byType(Cartao), findsOneWidget);
  });

  testWidgets('como aba não há seta de voltar; aberta por cima de outra tela, há', (tester) async {
    await _abrir(tester, _Servidor());
    expect(find.bySemanticsLabel('Voltar'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _abrir(tester, _Servidor(), empilhada: true);
    await tester.tap(find.text('Abrir a busca'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Voltar'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir a busca'), findsOneWidget);
  });

  testWidgets('busca nova entra no topo do histórico já gravado, sem apagar os antigos', (tester) async {
    await cgflixWriteSearchHistory(['naruto']);
    final servidor = _Servidor()..titulos = [_titulo('f1', 'Alien', MediaKind.movie)];
    await _abrir(tester, servidor);
    await _buscar(tester, 'alien');
    expect(await cgflixReadSearchHistory(), ['alien', 'naruto']);
  });

  testWidgets('a busca do app abre a V2 no celular e a antiga no computador', (tester) async {
    late Widget celular;
    late Widget computador;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          celular = CgflixPages.search(context);
          debugDefaultTargetPlatformOverride = TargetPlatform.linux;
          computador = CgflixPages.search(context);
          debugDefaultTargetPlatformOverride = null;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(celular, isA<LigacaoDaBusca>());
    expect(computador, isA<SearchScreen>());
  });
}
