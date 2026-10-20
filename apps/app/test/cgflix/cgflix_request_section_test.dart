// Etapa 1E (A): busca com pedidos embutidos. Seerr falso (sem rede): disponível, pedido,
// baixando, Seerr fora do ar e a escolha de temporadas. Nunca aparece formulário de login.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/cgflix/requests/cgflix_requests_ui.dart';
import 'package:plezy/cgflix/requests/cgflix_seerr.dart';
import 'package:plezy/cgflix/search/cgflix_search_extras.dart';
import 'package:plezy/screens/libraries/state_messages.dart';

class _FakeRequests implements CgflixRequestsBackend {
  bool up = true;
  final requested = <(int, List<int>?)>[];

  @override
  Future<List<CgflixRequestable>> search(String query) async {
    if (!up) throw const CgflixRequestsUnavailable('fora do ar');
    return const [
      CgflixRequestable(tmdbId: 1, isMovie: true, title: 'Duna', year: 2021),
      CgflixRequestable(tmdbId: 2, isMovie: false, title: 'Duna: A Profecia', year: 2024),
      CgflixRequestable(tmdbId: 3, isMovie: true, title: 'Duna: Parte Dois', state: CgflixRequestState.requested),
      CgflixRequestable(tmdbId: 4, isMovie: true, title: 'Duna (1984)', state: CgflixRequestState.downloading),
    ];
  }

  @override
  Future<List<CgflixSeasonChoice>> seasons(int tmdbId) async => const [
    CgflixSeasonChoice(number: 1, name: 'Temporada 1', episodes: 6, lockedLabel: 'Já temos'),
    CgflixSeasonChoice(number: 2, name: 'Temporada 2', episodes: 6),
    CgflixSeasonChoice(number: 3, name: 'Temporada 3', episodes: 8),
  ];

  @override
  Future<void> request(CgflixRequestable item, {List<int>? seasons}) async => requested.add((item.tmdbId, seasons));

  @override
  Future<List<CgflixMyRequest>> myRequests() async => const [
    CgflixMyRequest(
      id: 1,
      tmdbId: 2,
      isMovie: false,
      status: CgflixMyRequestStatus.waitingApproval,
      title: 'Duna: A Profecia',
      seasons: [2],
    ),
    CgflixMyRequest(id: 2, tmdbId: 1, isMovie: true, status: CgflixMyRequestStatus.available, title: 'Duna'),
  ];

  @override
  Future<CgflixTitleInfo> titleInfo(int tmdbId, {required bool isMovie}) async =>
      (title: 'Título $tmdbId', year: null, posterUrl: null);
}

void main() {
  late _FakeRequests fake;
  setUp(() {
    fake = _FakeRequests();
    CgflixRequests.debugOverride = fake;
  });
  tearDown(() => CgflixRequests.debugOverride = null);

  Future<void> pumpEmpty(WidgetTester tester, {Size size = const Size(412, 914), double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: cgflixAppTheme(),
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                child: CgflixRequestPrompt(
                  enabled: true,
                  query: 'Duna',
                  child: const StateMessageWidget(message: 'Nada encontrado', icon: Icons.search_off),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra "Disponível para pedir" com Pedir e os selos Pedido/Baixando', (tester) async {
    await pumpEmpty(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Disponível para pedir'), findsOneWidget);
    expect(find.bySemanticsLabel('Pedir Duna'), findsOneWidget);
    expect(find.text('Pedido'), findsOneWidget);
    expect(find.text('Baixando'), findsOneWidget);
    // Nada de login do Seerr no meio da busca.
    expect(find.textContaining('Conectar'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  for (final (name, size, scale) in [
    ('deitado', const Size(914, 412), 1.0),
    ('deitado, teclado aberto, fonte 200%', const Size(914, 180), 2.0),
  ]) {
    testWidgets('$name: sem overflow', (tester) async {
      await pumpEmpty(tester, size: size, scale: scale);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('filme: pede direto e confirma discretamente', (tester) async {
    await pumpEmpty(tester);
    await tester.tap(
      find.descendant(of: find.byKey(const ValueKey('cgflix-pedir-filme-1')), matching: find.text('Pedir')),
    );
    await tester.pumpAndSettle();
    expect(fake.requested, [(1, null)]);
    expect(find.text(cgflixRequestDoneMessage), findsOneWidget);
    // O cartão vira "Pedido".
    expect(find.text('Pedido'), findsNWidgets(2));
  });

  testWidgets('série: escolhe as temporadas (padrão: todas as que faltam)', (tester) async {
    await pumpEmpty(tester);
    await tester.tap(
      find.descendant(of: find.byKey(const ValueKey('cgflix-pedir-serie-2')), matching: find.text('Pedir')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pedir Duna: A Profecia'), findsOneWidget);
    expect(find.text('Já temos'), findsOneWidget);
    expect(find.text('Pedir todas'), findsOneWidget);
    // Tira a temporada 3: pede só a 2.
    await tester.tap(find.text('Temporada 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedir 1 temporada'));
    await tester.pumpAndSettle();
    expect(fake.requested.single.$1, 2);
    expect(fake.requested.single.$2, [2]);
    expect(find.text(cgflixRequestDoneMessage), findsOneWidget);
  });

  testWidgets('série com todas marcadas pede "todas"', (tester) async {
    await pumpEmpty(tester);
    await tester.tap(
      find.descendant(of: find.byKey(const ValueKey('cgflix-pedir-serie-2')), matching: find.text('Pedir')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedir todas'));
    await tester.pumpAndSettle();
    expect(fake.requested, [(2, null)]);
  });

  testWidgets('Seerr fora do ar: só o aviso pequeno, sem formulário', (tester) async {
    fake.up = false;
    await pumpEmpty(tester);
    expect(find.text('Disponível para pedir'), findsNothing);
    expect(find.text(cgflixRequestsUnavailableMessage), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Nada encontrado'), findsOneWidget);
  });

  testWidgets('Meus pedidos: lista nativa com a situação', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(), home: const CgflixMyRequestsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Meus pedidos'), findsOneWidget);
    expect(find.text('Duna: A Profecia'), findsOneWidget);
    expect(find.text('Aguardando aprovação'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.textContaining('Temporada 2'), findsOneWidget);
  });
}
