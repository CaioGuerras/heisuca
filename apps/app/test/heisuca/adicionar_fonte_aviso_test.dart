import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_source_scope.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids.dart';
import 'package:heisuca/profiles/profile.dart' show computePinHash;
import 'package:heisuca/profiles/profile_connection.dart';
import 'package:heisuca/screens/settings/add_connection_screen.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';

/// Depois de adicionar uma fonte, o aviso tem de dizer o que a tela de fato mostra.
/// Com o escopo de fonte (celular), a fonte nova passa a ser a vista. Sem o escopo (tela larga),
/// a navegação junta todos os servidores, então "Agora você está vendo" seria falso.
void main() {
  late HeisucaP3Fixture fixture;
  final navigator = GlobalKey<NavigatorState>();

  ProfileConnection ligacao(String id) => ProfileConnection(
    profileId: 'familia',
    connectionId: id,
    userToken: '',
    userIdentifier: 'u',
    tokenAcquiredAt: DateTime.utc(2026),
  );

  Future<void> encerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await fixture.dispose();
    });
  }

  Future<void> adicionar(
    WidgetTester tester, {
    required bool comEscopo,
    Set<String> novos = const {'srv-2'},
    List<String> conexoesAntes = const [],
    List<String> conexoesDepois = const ['jf-novo'],
  }) async {
    await tester.runAsync(() async {
      resetSharedPreferencesForTest();
      fixture = HeisucaP3Fixture();
      await fixture.initialize(settings.ThemeMode.dark);
    });
    fixture.profiles.conexoes = {
      'familia': [for (final id in conexoesAntes) ligacao(id)],
    };
    addTearDown(() => encerrar(tester));
    final botao = Builder(
      builder: (context) =>
          TextButton(onPressed: () => heisucaAddSource(context), child: const Text('Adicionar fonte')),
    );
    await tester.pumpWidget(
      fixture.wrap(
        MaterialApp(
          theme: cgflixDarkTheme(),
          navigatorKey: navigator,
          home: Scaffold(
            body: comEscopo ? HeisucaSourceScope(profileId: 'familia', child: botao) : botao,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Adicionar fonte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AddConnectionScreen), findsOneWidget);
    // O login deu certo e o servidor novo chegou.
    fixture.servers.setExpectedVisibleServerIds({'srv-1', ...novos});
    fixture.profiles.conexoes = {
      'familia': [for (final id in conexoesDepois) ligacao(id)],
    };
    navigator.currentState!.pop(true);
    // A espera pelo servidor novo vai até 12 s.
    for (var i = 0; i < 35 && find.byType(SnackBar).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('no modo infantil a porta de adicionar fonte não abre, venha de onde vier', (tester) async {
    await tester.runAsync(() async {
      resetSharedPreferencesForTest();
      fixture = HeisucaP3Fixture();
      await fixture.initialize(settings.ThemeMode.dark);
      HeisucaKids.instance.debugReset();
      await HeisucaKids.instance.save(
        HeisucaKidsRecord(
          parentProfileId: 'pai',
          kidsProfileId: 'familia',
          variant: CgflixThemeVariant.ichigo,
          ceiling: 'livre',
          pinHash: computePinHash('2468'),
          name: 'Ana',
        ),
      );
    });
    addTearDown(HeisucaKids.instance.debugReset);
    addTearDown(() => encerrar(tester));
    await tester.pumpWidget(
      fixture.wrap(
        MaterialApp(
          theme: cgflixDarkTheme(),
          navigatorKey: navigator,
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  TextButton(onPressed: () => heisucaAddSource(context), child: const Text('Adicionar fonte')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Adicionar fonte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AddConnectionScreen), findsNothing);
  });

  testWidgets('com o escopo de fonte o aviso diz que a fonte nova é a vista', (tester) async {
    await adicionar(tester, comEscopo: true);
    expect(find.textContaining('Agora você está vendo:'), findsOneWidget);
  });

  testWidgets('sem o escopo (tela larga) o aviso não promete mostrar só a fonte nova', (tester) async {
    await adicionar(tester, comEscopo: false);
    expect(find.textContaining('Agora você está vendo:'), findsNothing);
    expect(find.textContaining('Fonte adicionada:'), findsOneWidget);
  });

  testWidgets('sem o escopo, vários servidores novos não abrem a escolha de fonte', (tester) async {
    await adicionar(tester, comEscopo: false, novos: {'srv-2', 'srv-3'});
    expect(find.text('Qual fonte você quer ver?'), findsNothing);
    expect(find.text('2 fontes adicionadas'), findsOneWidget);
  });

  testWidgets('conexão que já estava salva não promete servidor novo', (tester) async {
    await adicionar(
      tester,
      comEscopo: true,
      novos: const {},
      conexoesAntes: ['jf-velho'],
      conexoesDepois: ['jf-velho'],
    );
    expect(find.textContaining('nenhum servidor novo respondeu'), findsNothing);
    expect(find.text('Essa conexão já estava salva. Nenhuma fonte nova foi adicionada.'), findsOneWidget);
  });

  testWidgets('conexão nova cujo servidor ainda não respondeu avisa que ele aparece depois', (tester) async {
    await adicionar(
      tester,
      comEscopo: true,
      novos: const {},
      conexoesAntes: ['jf-velho'],
      conexoesDepois: ['jf-velho', 'jf-novo'],
    );
    expect(find.textContaining('nenhum servidor novo respondeu'), findsOneWidget);
  });
}
