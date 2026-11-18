import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/platform/desktop_connection_vault.dart';
import 'package:heisuca/desktop/remote/desktop_servers_controller.dart';
import 'package:heisuca/desktop/ui/desktop_library_screen.dart';
import 'package:heisuca/media/library_query.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_library.dart';
import 'package:heisuca/media/media_part.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/media/media_version.dart';
import 'package:heisuca/utils/media_server_http_client.dart' show AbortController;

class _FakeMediaServerClient implements MediaServerClient {
  _FakeMediaServerClient({
    required MediaBackend backend,
    String? serverName,
    Map<String, String> streamHeaders = const <String, String>{},
    this.onFetchLibraries,
    this.onFetchLibraryPagedContent,
    this.onFetchItemWithOnDeck,
    this.onFetchChildrenPage,
    this.onThumbnailUrl,
  }) : _backend = backend, // ignore: prefer_initializing_formals
       _serverName = serverName, // ignore: prefer_initializing_formals
       _streamHeaders = streamHeaders; // ignore: prefer_initializing_formals

  final MediaBackend _backend;
  final String? _serverName;
  final Map<String, String> _streamHeaders;

  bool closed = false;
  Future<List<MediaLibrary>> Function()? onFetchLibraries;
  Future<LibraryPage<MediaItem>> Function(
    String libraryId,
    LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  )? onFetchLibraryPagedContent;
  Future<List<MediaItem>> Function(String query, int limit, AbortController? abort)? onSearchItems;
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> Function(String id)? onFetchItemWithOnDeck;
  Future<LibraryPage<MediaItem>> Function(String parentId, int? start, int? size, AbortController? abort)?
      onFetchChildrenPage;
  String Function(String? path)? onThumbnailUrl;

  @override
  MediaBackend get backend => _backend;

  @override
  String? get serverName => _serverName;

  @override
  Map<String, String> get streamHeaders => _streamHeaders;

  @override
  void close() {
    closed = true;
  }

  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) {
    if (onThumbnailUrl != null) return onThumbnailUrl!(path);
    return path ?? '';
  }

  @override
  Future<List<MediaLibrary>> fetchLibraries() {
    if (onFetchLibraries != null) return onFetchLibraries!();
    return Future<List<MediaLibrary>>.value(const <MediaLibrary>[]);
  }

  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) {
    if (onFetchLibraryPagedContent != null) {
      return onFetchLibraryPagedContent!(libraryId, query, libraryKind, abort);
    }
    return Future<LibraryPage<MediaItem>>.value(const LibraryPage<MediaItem>(items: <MediaItem>[], totalCount: 0));
  }

  @override
  Future<List<MediaItem>> searchItems(
    String query, {
    int limit = 100,
    AbortController? abort,
    Set<String> excludedLibraryIds = const <String>{},
  }) {
    if (onSearchItems != null) return onSearchItems!(query, limit, abort);
    return Future<List<MediaItem>>.value(const <MediaItem>[]);
  }

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem item)? onItemReady,
  }) {
    if (onFetchItemWithOnDeck != null) return onFetchItemWithOnDeck!(id);
    return Future<({MediaItem? item, MediaItem? onDeckEpisode})>.value((item: null, onDeckEpisode: null));
  }

  @override
  Future<LibraryPage<MediaItem>> fetchChildrenPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) {
    if (onFetchChildrenPage != null) return onFetchChildrenPage!(parentId, start, size, abort);
    return Future<LibraryPage<MediaItem>>.value(const LibraryPage<MediaItem>(items: <MediaItem>[], totalCount: 0));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeServersController extends DesktopServersController {
  _FakeServersController({
    List<DesktopServerConnection> initialConnections = const <DesktopServerConnection>[],
    bool persistentSessions = false,
  }) : _connections = List<DesktopServerConnection>.of(initialConnections),
       _persistentSessions = persistentSessions, // ignore: prefer_initializing_formals
       super(vault: MemoryDesktopConnectionVault());

  final List<DesktopServerConnection> _connections;
  final bool _persistentSessions;
  bool _busy = false;
  bool _restoring = false;
  String? _error;
  String? _plexCode;
  bool _disposed = false;

  int cancelCalls = 0;
  ({String baseUrl, String username, String password})? lastJellyfinCall;
  Future<void> Function(_FakeServersController controller, Future<void> Function(Uri)? openBrowser)? onSignInPlex;
  Future<void> Function(
    _FakeServersController controller, {
    required String baseUrl,
    required String username,
    required String password,
  })? onSignInJellyfin;

  @override
  List<DesktopServerConnection> get connections => List<DesktopServerConnection>.unmodifiable(_connections);

  @override
  bool get busy => _busy;

  @override
  bool get restoring => _restoring;

  @override
  String? get error => _error;

  @override
  String? get plexCode => _plexCode;

  @override
  bool get persistentSessions => _persistentSessions;

  void updateTestState({
    bool? busy,
    bool? restoring,
    String? error,
    bool resetError = false,
    String? plexCode,
    bool resetPlexCode = false,
    List<DesktopServerConnection>? connections,
  }) {
    if (busy != null) _busy = busy;
    if (restoring != null) _restoring = restoring;
    if (resetError) {
      _error = null;
    } else if (error != null) {
      _error = error;
    }
    if (resetPlexCode) {
      _plexCode = null;
    } else if (plexCode != null) {
      _plexCode = plexCode;
    }
    if (connections != null) {
      _connections
        ..clear()
        ..addAll(connections);
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void clearError() {
    if (_error == null) return;
    _error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void cancelAuthentication() {
    cancelCalls++;
    _busy = false;
    _plexCode = null;
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> restore() async {}

  @override
  Future<void> signInPlex({Future<void> Function(Uri)? openBrowser}) async {
    if (onSignInPlex != null) {
      await onSignInPlex!(this, openBrowser);
    }
  }

  @override
  Future<void> signInJellyfin({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    lastJellyfinCall = (baseUrl: baseUrl, username: username, password: password);
    if (onSignInJellyfin != null) {
      await onSignInJellyfin!(this, baseUrl: baseUrl, username: username, password: password);
    }
  }

  @override
  Future<void> disconnect(String id) async {
    _connections.removeWhere((conn) => conn.id == id);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final conn in _connections) {
      conn.client.close();
    }
    _connections.clear();
    super.dispose();
  }
}

Widget _buildTestApp({
  required DesktopServersController servers,
  required Future<void> Function(DesktopServerConnection, MediaItem, int?) onPlay,
  bool wrapWithParentRoute = false,
  double textScale = 1.0,
}) {
  final screen = DesktopLibraryScreen(servers: servers, onPlay: onPlay);
  return MaterialApp(
    theme: ThemeData.dark(),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      );
    },
    home: wrapWithParentRoute
        ? Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(builder: (_) => screen),
                    ),
                  ),
                  child: const Text('Abrir bibliotecas'),
                ),
              ),
            ),
          )
        : screen,
  );
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('sem conexões exibe ações reais e aviso de sessão temporária sem texto DPAPI', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final transientController = _FakeServersController(persistentSessions: false);
    addTearDown(transientController.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        servers: transientController,
        onPlay: (server, item, index) async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum servidor conectado'), findsOneWidget);
    expect(find.text('Conectar Plex'), findsWidgets);
    expect(find.text('Conectar Jellyfin'), findsWidgets);
    expect(find.textContaining('termina ao fechar'), findsWidgets);
    expect(find.textContaining('DPAPI'), findsNothing);

    final persistentController = _FakeServersController(persistentSessions: true);
    addTearDown(persistentController.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        servers: persistentController,
        onPlay: (server, item, index) async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('termina ao fechar'), findsNothing);
    expect(find.textContaining('DPAPI'), findsNothing);
  });

  testWidgets('exibe ambos backends nomeados e alterna entre Plex e Jellyfin', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final plexClient = _FakeMediaServerClient(
      backend: MediaBackend.plex,
      serverName: 'Sala Plex',
      onFetchLibraries: () async => const <MediaLibrary>[
        MediaLibrary(id: 'lib-plex', backend: MediaBackend.plex, title: 'Filmes Plex', kind: MediaKind.movie),
      ],
      onFetchLibraryPagedContent: (libraryId, query, libraryKind, abort) async => LibraryPage<MediaItem>(
        items: <MediaItem>[
          MediaItem(id: 'p1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Filme no Plex', year: 2024),
        ],
        totalCount: 1,
      ),
    );
    final jellyfinClient = _FakeMediaServerClient(
      backend: MediaBackend.jellyfin,
      serverName: 'Estúdio Jellyfin',
      onFetchLibraries: () async => const <MediaLibrary>[
        MediaLibrary(id: 'lib-jf', backend: MediaBackend.jellyfin, title: 'Séries JF', kind: MediaKind.show),
      ],
      onFetchLibraryPagedContent: (libraryId, query, libraryKind, abort) async => LibraryPage<MediaItem>(
        items: <MediaItem>[
          MediaItem(id: 'j1', backend: MediaBackend.jellyfin, kind: MediaKind.show, title: 'Série no Jellyfin'),
        ],
        totalCount: 1,
      ),
    );

    final controller = _FakeServersController(
      initialConnections: <DesktopServerConnection>[
        DesktopServerConnection(id: 'plex-1', name: 'Sala Plex', backend: MediaBackend.plex, client: plexClient),
        DesktopServerConnection(
          id: 'jf-1',
          name: 'Estúdio Jellyfin',
          backend: MediaBackend.jellyfin,
          client: jellyfinClient,
        ),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_buildTestApp(servers: controller, onPlay: (s, i, idx) async {}));
    await tester.pumpAndSettle();

    expect(find.text('Plex: Sala Plex'), findsOneWidget);
    expect(find.text('Jellyfin: Estúdio Jellyfin'), findsOneWidget);
    expect(find.text('Filme no Plex'), findsOneWidget);

    await tester.tap(find.text('Jellyfin: Estúdio Jellyfin'));
    await tester.pumpAndSettle();

    expect(find.text('Séries JF'), findsOneWidget);
    expect(find.text('Série no Jellyfin'), findsOneWidget);
  });

  testWidgets('erro de fetch não é exibido como acervo vazio', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var shouldFail = true;
    final client = _FakeMediaServerClient(
      backend: MediaBackend.jellyfin,
      serverName: 'Servidor JF',
      onFetchLibraries: () async => const <MediaLibrary>[
        MediaLibrary(id: 'lib-1', backend: MediaBackend.jellyfin, title: 'Filmes', kind: MediaKind.movie),
      ],
      onFetchLibraryPagedContent: (libraryId, query, libraryKind, abort) async {
        if (shouldFail) {
          throw StateError('http://segredo.local/token=xyz123');
        }
        return const LibraryPage<MediaItem>(items: <MediaItem>[], totalCount: 0);
      },
    );
    final controller = _FakeServersController(
      initialConnections: <DesktopServerConnection>[
        DesktopServerConnection(id: 'jf-1', name: 'Servidor JF', backend: MediaBackend.jellyfin, client: client),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_buildTestApp(servers: controller, onPlay: (s, i, idx) async {}));
    await tester.pumpAndSettle();

    expect(find.text('Erro ao carregar acervo'), findsOneWidget);
    expect(find.text('Nenhum item encontrado nesta biblioteca.'), findsNothing);
    expect(find.textContaining('segredo.local'), findsNothing);
    expect(find.textContaining('xyz123'), findsNothing);

    shouldFail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Acervo vazio'), findsOneWidget);
    expect(find.text('Nenhum item encontrado nesta biblioteca.'), findsOneWidget);
  });

  testWidgets('trocar fonte aborta requisição pendente e ignora página atrasada', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final staleCompleter = Completer<LibraryPage<MediaItem>>();
    AbortController? capturedAbortA;

    final clientA = _FakeMediaServerClient(
      backend: MediaBackend.plex,
      serverName: 'Servidor A',
      onFetchLibraries: () async => const <MediaLibrary>[
        MediaLibrary(id: 'lib-a', backend: MediaBackend.plex, title: 'Biblioteca A', kind: MediaKind.movie),
      ],
      onFetchLibraryPagedContent: (libraryId, query, libraryKind, abort) {
        capturedAbortA = abort;
        return staleCompleter.future;
      },
    );
    final clientB = _FakeMediaServerClient(
      backend: MediaBackend.jellyfin,
      serverName: 'Servidor B',
      onFetchLibraries: () async => const <MediaLibrary>[
        MediaLibrary(id: 'lib-b', backend: MediaBackend.jellyfin, title: 'Biblioteca B', kind: MediaKind.movie),
      ],
      onFetchLibraryPagedContent: (libraryId, query, libraryKind, abort) async => LibraryPage<MediaItem>(
        items: <MediaItem>[
          MediaItem(id: 'b1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, title: 'Filme Atual B'),
        ],
        totalCount: 1,
      ),
    );

    final controller = _FakeServersController(
      initialConnections: <DesktopServerConnection>[
        DesktopServerConnection(id: 'srv-a', name: 'Servidor A', backend: MediaBackend.plex, client: clientA),
        DesktopServerConnection(id: 'srv-b', name: 'Servidor B', backend: MediaBackend.jellyfin, client: clientB),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_buildTestApp(servers: controller, onPlay: (s, i, idx) async {}));
    await tester.pump();
    await tester.pump();

    expect(capturedAbortA, isNotNull);
    expect(capturedAbortA!.isAborted, isFalse);

    await tester.tap(find.text('Jellyfin: Servidor B'));
    await tester.pumpAndSettle();

    expect(capturedAbortA!.isAborted, isTrue);
    expect(find.text('Filme Atual B'), findsOneWidget);

    staleCompleter.complete(
      LibraryPage<MediaItem>(
        items: <MediaItem>[
          MediaItem(id: 'a-old', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Filme Velho A'),
        ],
        totalCount: 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Filme Atual B'), findsOneWidget);
    expect(find.text('Filme Velho A'), findsNothing);
  });

  testWidgets('busca e paginação carregam mais itens sem duplicatas respeitando limit 50', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final capturedQueries = <LibraryQuery>[];
    final client = _FakeMediaServerClient(
      backend: MediaBackend.plex,
      serverName: 'Plex Acervo',
      onFetchLibraries: () async => const <MediaLibrary>[
        MediaLibrary(
          id: 'lib-movies',
          backend: MediaBackend.plex,
          title: 'Filmes',
          kind: MediaKind.movie,
          defaultBrowseKinds: <MediaKind>[MediaKind.movie],
        ),
      ],
      onFetchLibraryPagedContent: (libraryId, query, libraryKind, abort) async {
        capturedQueries.add(query);
        if (query.search == 'Horizonte') {
          return LibraryPage<MediaItem>(
            items: <MediaItem>[
              MediaItem(id: 'm9', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Horizonte Perdido'),
            ],
            totalCount: 1,
          );
        }
        if (query.offset == 0) {
          return LibraryPage<MediaItem>(
            items: <MediaItem>[
              MediaItem(id: 'm1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Filme Um'),
              MediaItem(id: 'm2', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Filme Dois'),
            ],
            totalCount: 3,
            offset: 0,
          );
        }
        return LibraryPage<MediaItem>(
          items: <MediaItem>[
            MediaItem(id: 'm2', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Filme Dois'),
            MediaItem(id: 'm3', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Filme Três'),
          ],
          totalCount: 3,
          offset: 2,
        );
      },
    );
    final controller = _FakeServersController(
      initialConnections: <DesktopServerConnection>[
        DesktopServerConnection(id: 'plex-1', name: 'Plex Acervo', backend: MediaBackend.plex, client: client),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_buildTestApp(servers: controller, onPlay: (s, i, idx) async {}));
    await tester.pumpAndSettle();

    expect(capturedQueries.first.limit, 50);
    expect(find.text('Filme Um'), findsOneWidget);
    expect(find.text('Filme Dois'), findsOneWidget);

    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    expect(find.text('Filme Dois'), findsOneWidget);
    expect(find.text('Filme Três'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Horizonte');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(capturedQueries.last.search, 'Horizonte');
    expect(find.text('Horizonte Perdido'), findsOneWidget);
  });

  testWidgets('modal Jellyfin oculta senha, valida HTTP(S), limpa senha em finally e exibe erro seguro', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = _FakeServersController();
    controller.onSignInJellyfin = (ctrl, {required baseUrl, required username, required password}) async {
      ctrl.updateTestState(error: 'Credenciais invalidas ou acesso negado.');
    };
    addTearDown(controller.dispose);

    await tester.pumpWidget(_buildTestApp(servers: controller, onPlay: (s, i, idx) async {}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Conectar Jellyfin').first);
    await tester.pumpAndSettle();

    final editableTexts = tester.widgetList<EditableText>(find.byType(EditableText)).toList();
    expect(editableTexts.length, 3);
    expect(editableTexts[2].obscureText, isTrue);

    final fields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(fields.at(0), 'ftp://servidor');
    await tester.enterText(fields.at(1), 'usuario');
    await tester.enterText(fields.at(2), 'minha-senha-secreta');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(controller.lastJellyfinCall, isNull);
    expect(find.textContaining('http:// ou https://'), findsOneWidget);

    await tester.enterText(fields.at(0), 'https://jf.local:8096');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(controller.lastJellyfinCall, isNotNull);
    expect(controller.lastJellyfinCall!.baseUrl, 'https://jf.local:8096');
    expect(controller.lastJellyfinCall!.username, 'usuario');
    expect(controller.lastJellyfinCall!.password, 'minha-senha-secreta');
    expect(find.text('Credenciais invalidas ou acesso negado.'), findsWidgets);
    expect(tester.widget<TextField>(fields.at(2)).controller!.text, isEmpty);
  });

  testWidgets('modal Plex exibe código PIN, busy, cancela autenticação e omite URI/token', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authCompleter = Completer<void>();
    final controller = _FakeServersController();
    bool receivedOpenBrowser = false;
    controller.onSignInPlex = (ctrl, openBrowser) async {
      receivedOpenBrowser = openBrowser != null;
      ctrl.updateTestState(busy: true, plexCode: 'K7P9');
      await authCompleter.future;
    };
    addTearDown(controller.dispose);

    await tester.pumpWidget(_buildTestApp(servers: controller, onPlay: (s, i, idx) async {}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Conectar Plex').first);
    await tester.pump();
    await tester.pump();

    expect(receivedOpenBrowser, isTrue);
    expect(find.text('K7P9'), findsOneWidget);
    expect(find.textContaining('plex.tv'), findsNothing);
    expect(find.textContaining('token'), findsNothing);

    await tester.tap(find.text('Cancelar'));
    authCompleter.complete();
    await tester.pumpAndSettle();

    expect(controller.cancelCalls, 1);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('ficha com versões seleciona índice, chama onPlay e fecha rota ou mantém contexto em erro', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = const MediaItem.plex(
      id: 'mov-1',
      kind: MediaKind.movie,
      title: 'Viagem Orbital',
      summary: 'Resumo verídico do filme.',
      year: 2023,
      durationMs: 7200000,
      mediaVersions: <MediaVersion>[
        MediaVersion(
          id: 'v1',
          name: 'Original',
          videoResolution: '4k',
          videoCodec: 'hevc',
          container: 'mkv',
          bitrate: 20000000,
          parts: <MediaPart>[MediaPart(id: 'pt1', sizeBytes: 4294967296)],
        ),
        MediaVersion(
          id: 'v2',
          name: 'Compacta',
          videoResolution: '1080',
          videoCodec: 'h264',
          container: 'mp4',
          bitrate: 6000000,
        ),
      ],
    );

    final client = _FakeMediaServerClient(
      backend: MediaBackend.plex,
      serverName: 'Plex Home',
      streamHeaders: const <String, String>{'X-Plex-Token': 'secret-hdr'},
      onThumbnailUrl: (path) => 'https://img.invalid$path',
      onFetchLibraries: () async => const <MediaLibrary>[
        MediaLibrary(id: 'lib-1', backend: MediaBackend.plex, title: 'Filmes', kind: MediaKind.movie),
      ],
      onFetchLibraryPagedContent: (libraryId, query, libraryKind, abort) async =>
          LibraryPage<MediaItem>(items: <MediaItem>[movie], totalCount: 1),
      onFetchItemWithOnDeck: (id) async => (item: movie, onDeckEpisode: null),
    );
    final controller = _FakeServersController(
      initialConnections: <DesktopServerConnection>[
        DesktopServerConnection(id: 'plex-1', name: 'Plex Home', backend: MediaBackend.plex, client: client),
      ],
    );
    addTearDown(controller.dispose);

    var failPlay = true;
    DesktopServerConnection? playedServer;
    MediaItem? playedItem;
    int? playedVersion;

    await tester.pumpWidget(
      _buildTestApp(
        servers: controller,
        wrapWithParentRoute: true,
        onPlay: (server, item, versionIndex) async {
          playedServer = server;
          playedItem = item;
          playedVersion = versionIndex;
          if (failPlay) {
            throw StateError('http://internal/token=leak');
          }
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir bibliotecas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Viagem Orbital'));
    await tester.pumpAndSettle();

    expect(find.text('Resumo verídico do filme.'), findsOneWidget);
    expect(find.text('Versões disponíveis'), findsOneWidget);
    expect(find.textContaining('Compacta · 1080p · H264 · MP4'), findsOneWidget);

    await tester.tap(find.textContaining('Compacta · 1080p · H264 · MP4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assistir'));
    await tester.pumpAndSettle();

    expect(find.byType(DesktopLibraryScreen), findsOneWidget);
    expect(find.textContaining('não foi possível iniciar a reprodução', findRichText: false), findsNothing);
    expect(find.text('Não foi possível iniciar a reprodução neste momento.'), findsOneWidget);
    expect(find.textContaining('leak'), findsNothing);
    expect(playedVersion, 1);

    failPlay = false;
    await tester.tap(find.text('Assistir'));
    await tester.pumpAndSettle();

    expect(playedServer?.id, 'plex-1');
    expect(playedItem?.id, 'mov-1');
    expect(playedVersion, 1);
    expect(find.byType(DesktopLibraryScreen), findsNothing);
  });

  testWidgets('ficha de série navega por onDeck, temporadas e episódios sem abrir série direto no player', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final show = const MediaItem.jellyfin(id: 'show-1', kind: MediaKind.show, title: 'Série Teste');
    final season = const MediaItem.jellyfin(id: 'season-1', kind: MediaKind.season, title: 'Temporada 1', index: 1);
    final episode = const MediaItem.jellyfin(
      id: 'ep-1',
      kind: MediaKind.episode,
      title: 'Piloto',
      parentIndex: 1,
      index: 1,
      grandparentTitle: 'Série Teste',
    );

    final client = _FakeMediaServerClient(
      backend: MediaBackend.jellyfin,
      serverName: 'JF Séries',
      onFetchLibraries: () async => const <MediaLibrary>[
        MediaLibrary(id: 'lib-shows', backend: MediaBackend.jellyfin, title: 'Séries', kind: MediaKind.show),
      ],
      onFetchLibraryPagedContent: (libraryId, query, libraryKind, abort) async =>
          LibraryPage<MediaItem>(items: <MediaItem>[show], totalCount: 1),
      onFetchItemWithOnDeck: (id) async => id == 'show-1'
          ? (item: show, onDeckEpisode: episode)
          : (item: null, onDeckEpisode: null),
      onFetchChildrenPage: (parentId, start, size, abort) async {
        if (parentId == 'show-1') {
          return LibraryPage<MediaItem>(items: <MediaItem>[season], totalCount: 1);
        }
        if (parentId == 'season-1') {
          return LibraryPage<MediaItem>(items: <MediaItem>[episode], totalCount: 1);
        }
        return const LibraryPage<MediaItem>(items: <MediaItem>[], totalCount: 0);
      },
    );
    final controller = _FakeServersController(
      initialConnections: <DesktopServerConnection>[
        DesktopServerConnection(id: 'jf-1', name: 'JF Séries', backend: MediaBackend.jellyfin, client: client),
      ],
    );
    addTearDown(controller.dispose);

    final played = <MediaItem>[];
    await tester.pumpWidget(
      _buildTestApp(
        servers: controller,
        onPlay: (server, item, index) async {
          played.add(item);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Série Teste'));
    await tester.pumpAndSettle();

    expect(find.text('Continuar: T1 E1 · Piloto'), findsOneWidget);
    expect(find.text('Temporada 1'), findsOneWidget);

    await tester.tap(find.text('Temporada 1'));
    await tester.pumpAndSettle();

    expect(find.text('Piloto'), findsOneWidget);
    await tester.tap(find.byTooltip('Assistir'));
    await tester.pumpAndSettle();

    expect(played.length, 1);
    expect(played.single.id, 'ep-1');
  });

  testWidgets('layout 800x600 com textScale 200% não sofre overflow e botão Voltar executa Navigator.pop', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = const MediaItem.plex(
      id: 'm-resp',
      kind: MediaKind.movie,
      title: 'Filme com Título Extenso para Escala Duzentos por Cento',
      summary: 'Sinopse suficientemente longa para testar rolagem em janela de oitocentos por seiscentos.',
      year: 2025,
    );
    final client = _FakeMediaServerClient(
      backend: MediaBackend.plex,
      serverName: 'Plex Compacto',
      onFetchLibraries: () async => const <MediaLibrary>[
        MediaLibrary(id: 'lib-1', backend: MediaBackend.plex, title: 'Filmes', kind: MediaKind.movie),
      ],
      onFetchLibraryPagedContent: (libraryId, query, libraryKind, abort) async =>
          LibraryPage<MediaItem>(items: <MediaItem>[movie], totalCount: 1),
    );
    final controller = _FakeServersController(
      initialConnections: <DesktopServerConnection>[
        DesktopServerConnection(id: 'plex-1', name: 'Plex Compacto', backend: MediaBackend.plex, client: client),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        servers: controller,
        wrapWithParentRoute: true,
        textScale: 2.0,
        onPlay: (s, i, idx) async {},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir bibliotecas'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.textContaining('Filme com Título Extenso'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Filme com Título Extenso'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Voltar à grade'), findsOneWidget);
    await tester.ensureVisible(find.text('Voltar'));
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopLibraryScreen), findsNothing);
  });
}
