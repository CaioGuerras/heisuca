import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/conta/cgflix_conta.dart';
import 'package:heisuca/cgflix/conta/cgflix_minha_conta_screen.dart';
import 'package:heisuca/focus/focusable_text_field.dart';
import 'package:heisuca/heisuca/heisuca_add_webdav_screen.dart';
import 'package:heisuca/heisuca/heisuca_library_screen.dart';
import 'package:heisuca/heisuca/heisuca_search_screen.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids_flow.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids_identity.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_library.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/media/library_query.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/profiles/profile.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/screens/profile/pin_entry_dialog.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/utils/media_server_http_client.dart';
import 'package:heisuca/utils/platform_detector.dart';

class _Profiles extends ChangeNotifier implements ActiveProfileProvider {
  _Profiles(this._active);
  final Profile _active;
  @override
  Profile? get active => _active;
  @override
  String? get activeId => _active.id;
  @override
  List<Profile> get profiles => [_active];
  @override
  String? avatarUrlFor(String profileId) => null;
  @override
  bool get isBinding => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConta implements CgflixConta {
  @override
  Future<CgflixPerfil> perfil() async => const CgflixPerfil(nome: 'Teste');
  @override
  Future<void> trocarFoto(Uint8List jpeg) async {}
  @override
  Future<void> removerFoto() async {}
  @override
  Future<CgflixSenhaResultado> trocarSenha({required String atual, required String nova}) async =>
      CgflixSenhaResultado.ok;
}

class _MockClient extends MediaServerClient {
  _MockClient(this.name, this.kind);
  final String name;
  final MediaBackend kind;

  @override
  ServerId get serverId => ServerId(name);
  @override
  MediaBackend get backend => kind;
  @override
  Future<List<MediaLibrary>> fetchLibraries() async => [
        MediaLibrary(id: 'films', backend: kind, title: 'Filmes', kind: MediaKind.movie, serverId: name),
      ];
  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async {
    return LibraryPage(
      items: [MediaItem(id: '$name-$libraryId', backend: kind, kind: libraryKind!, title: 'Título', serverId: name)],
      totalCount: 1,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final sentStates = <bool>[];

  setUp(() async {
    sentStates.clear();
    TvDetectionService.debugReset();
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);

    const channel = MethodChannel('app.heisuca/text_input');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setNativeTextInputFocused') {
        sentStates.add(call.arguments as bool);
      }
      return null;
    });
  });

  tearDown(() {
    const channel = MethodChannel('app.heisuca/text_input');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    TvDetectionService.debugReset();
    TvDetectionService.setForceTVSync(false);
  });

  group('T2: Telas Heisuca com ponte de foco IME na TV', () {
    testWidgets('HeisucaSearchScreen em TV reporta foco para o canal nativo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.isis),
        home: const Scaffold(body: HeisucaSearchScreen()),
      ));
      await tester.pumpAndSettle();

      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      await tester.tap(field);
      await tester.pump();
      await tester.pump();

      expect(sentStates, contains(true));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump();
      expect(sentStates.last, isFalse);
    });

    testWidgets('HeisucaAddWebDavScreen em TV reporta foco para o canal nativo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.isis),
        home: const Scaffold(body: HeisucaAddWebDavScreen()),
      ));
      await tester.pumpAndSettle();

      final field = find.byType(TextFormField).first;
      await tester.tap(field);
      await tester.pump();
      await tester.pump();

      expect(sentStates, contains(true));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump();
      expect(sentStates.last, isFalse);
    });

    testWidgets('HeisucaLibraryScreen em TV reporta foco para o canal nativo', (tester) async {
      final client = _MockClient('LibA', MediaBackend.jellyfin);
      final manager = MultiServerManager()..debugRegisterClientForTesting(client);
      final servers = MultiServerProvider(manager, DataAggregationService(manager));
      addTearDown(servers.dispose);
      addTearDown(manager.dispose);
      manager.setNavigationSource(Object(), 'LibA');

      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: servers,
        child: MaterialApp(
          theme: cgflixAppTheme(CgflixThemeVariant.isis),
          home: const Scaffold(body: HeisucaLibraryScreen()),
        ),
      ));
      await tester.pumpAndSettle();

      final searchField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Buscar nesta biblioteca',
      );
      expect(searchField, findsOneWidget);
      await tester.tap(searchField);
      await tester.pump();
      await tester.pump();

      expect(sentStates, contains(true));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump();
      expect(sentStates.last, isFalse);
    });

    testWidgets('CgflixMinhaContaScreen em TV reporta foco para o canal nativo', (tester) async {
      final fake = _FakeConta();
      await tester.pumpWidget(MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.isis),
        home: Scaffold(body: CgflixMinhaContaScreen(conta: fake)),
      ));
      await tester.pumpAndSettle();

      final field = find.byType(TextField).first;
      await tester.tap(field);
      await tester.pump();
      await tester.pump();

      expect(sentStates, contains(true));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump();
      expect(sentStates.last, isFalse);
    });

    testWidgets('pin_entry_dialog usa FocusableTextField no layout móvel', (tester) async {
      TvDetectionService.debugSetAppleTVOverride(false);
      TvDetectionService.setForceTVSync(false);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    await showPinEntryDialog(context, 'Protected Profile');
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(FocusableTextField), findsOneWidget);
    });

    testWidgets('HeisucaKidsSetupScreen em TV reporta foco para o canal nativo', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: cgflixAppTheme(CgflixThemeVariant.isis),
        home: const HeisucaKidsSetupScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      await tester.tap(field);
      await tester.pump();
      await tester.pump();

      expect(sentStates, contains(true));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump();
      expect(sentStates.last, isFalse);
    });

    testWidgets('HeisucaKidsIdentityScreen em TV reporta foco para o canal nativo', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final parent = Profile.local(id: 'parent', displayName: 'Responsável', createdAt: DateTime(2026, 10, 23));
      final profiles = _Profiles(parent);
      addTearDown(profiles.dispose);

      const record = HeisucaKidsRecord(
        parentProfileId: 'parent',
        kidsProfileId: 'kids',
        variant: CgflixThemeVariant.ichigo,
        ceiling: 'livre',
        pinHash: '1234',
        name: 'Criança',
      );

      await tester.pumpWidget(ChangeNotifierProvider<ActiveProfileProvider>.value(
        value: profiles,
        child: MaterialApp(
          theme: cgflixAppTheme(CgflixThemeVariant.isis),
          home: const HeisucaKidsIdentityScreen(record: record),
        ),
      ));
      await tester.pumpAndSettle();

      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      await tester.tap(field);
      await tester.pump();
      await tester.pump();

      expect(sentStates, contains(true));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump();
      expect(sentStates.last, isFalse);
    });
  });
}
