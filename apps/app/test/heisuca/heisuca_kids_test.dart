import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plezy/cgflix/cgflix_palette.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/heisuca/heisuca_profile_screen.dart';
import 'package:plezy/heisuca/kids/heisuca_kids.dart';
import 'package:plezy/heisuca/kids/heisuca_kids_opening.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/services/jellyfin_client.dart';
import '../test_helpers/prefs.dart';
import '../visual/heisuca_snapshot.dart';

class _Profiles extends ChangeNotifier implements ActiveProfileProvider {
  _Profiles(this._active);
  final Profile _active;
  @override Profile? get active => _active;
  @override String? get activeId => _active.id;
  @override List<Profile> get profiles => [_active];
  @override String? avatarUrlFor(String profileId) => null;
  @override bool get isBinding => false;
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _now = DateTime(2026, 10, 23);
final _parent = Profile.local(id: 'pai', displayName: 'Caio', createdAt: _now);
final _child = Profile.local(id: 'kids-1', displayName: 'Ana', createdAt: _now);
final _record = HeisucaKidsRecord(parentProfileId: 'pai', kidsProfileId: 'kids-1', variant: CgflixThemeVariant.ichigo,
  ceiling: 'livre', pinHash: computePinHash('2468'), name: 'Ana');

Future<void> _pumpYou(WidgetTester tester, Profile active, {CgflixThemeVariant theme = CgflixThemeVariant.isis}) async {
  tester.view.physicalSize = const Size(412, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final profiles = _Profiles(active);
  addTearDown(profiles.dispose);
  await tester.pumpWidget(MultiProvider(providers: [
    ChangeNotifierProvider<ActiveProfileProvider>.value(value: profiles),
    ChangeNotifierProvider<HeisucaKids>.value(value: HeisucaKids.instance),
  ], child: MaterialApp(theme: cgflixAppTheme(theme), home: const HeisucaProfileScreen())));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() { resetSharedPreferencesForTest(); HeisucaKids.instance.debugReset(); });

  group('registro do modo infantil', () {
    test('grava, relê e acha pelo responsável e pelo perfil infantil', () async {
      await HeisucaKids.instance.save(_record);
      HeisucaKids.instance.debugReset();
      await HeisucaKids.instance.load();
      final r = HeisucaKids.instance.forParent('pai')!;
      expect(r.kidsProfileId, 'kids-1');
      expect(HeisucaKids.instance.isKids('kids-1'), isTrue);
      expect(HeisucaKids.instance.isKids('pai'), isFalse);
      expect(HeisucaKids.instance.variantFor('kids-1'), CgflixThemeVariant.ichigo);
      expect(verifyPin('2468', r.pinHash), isTrue);
      expect(verifyPin('0000', r.pinHash), isFalse);
      final raw = (await SharedPreferences.getInstance()).getString('heisuca.kids.v1')!;
      expect(raw, isNot(contains('2468')), reason: 'o PIN nunca é gravado em texto');
    });
    test('registro corrompido não trava a abertura e tema adulto não vira kids', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('heisuca.kids.v1', '{quebrado');
      await HeisucaKids.instance.load();
      expect(HeisucaKids.instance.loaded, isTrue);
      await prefs.setString('heisuca.kids.v1', '[{"pai":"p","kids":"k","tema":"isis","pin":"x"}]');
      await HeisucaKids.instance.load();
      expect(HeisucaKids.instance.isKids('k'), isFalse);
    });
  });

  test('temas Ichigo e Sorairo com as cores oficiais, claros e fora do seletor', () {
    expect(CgflixPalette.ichigo.accent, const Color(0xFFD62D45));
    expect(CgflixPalette.ichigo.background, const Color(0xFFFFF5F3));
    expect(CgflixPalette.sorairo.accent, const Color(0xFF1F6FC5));
    expect(CgflixPalette.sorairo.isLight, isTrue);
    expect(cgflixAppTheme(CgflixThemeVariant.ichigo).extension<CgflixPalette>()?.variant, CgflixThemeVariant.ichigo);
    expect(cgflixAppTheme(CgflixThemeVariant.sorairo).colorScheme.primary, const Color(0xFF1F6FC5));
    expect([for (final v in CgflixThemeVariant.values) if (!v.isKids) v], [CgflixThemeVariant.isis, CgflixThemeVariant.heitor]);
  });

  test('mensagens da ativação no servidor em português', () {
    expect(const CgflixKidsException(404).message, contains('não oferece'));
    expect(const CgflixKidsException(429).message, contains('Muitas tentativas'));
  });

  testWidgets('responsável vê a entrada do modo infantil', (tester) async {
    await HeisucaKids.instance.load();
    await _pumpYou(tester, _parent);
    expect(find.text('Modo infantil'), findsOneWidget);
    expect(find.text('Trocar perfil'), findsOneWidget);
    expect(find.textContaining('144'), findsNothing, reason: 'não anunciar 144 Hz sem verificar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('modo infantil: só Favoritos, Bibliotecas e a saída com PIN', (tester) async {
    await HeisucaKids.instance.save(_record);
    await _pumpYou(tester, _child, theme: CgflixThemeVariant.ichigo);
    expect(find.text('Sair do modo infantil'), findsOneWidget);
    for (final hidden in ['Trocar perfil', 'Sair da Conta', 'Fonte atual', 'Baixados & Offline', 'Configurações Heisuca', 'Sobre o Heisuca']) {
      expect(find.text(hidden), findsNothing, reason: '$hidden não pode aparecer para a criança');
    }
    expect(find.text('Favoritos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final variant in [CgflixThemeVariant.ichigo, CgflixThemeVariant.sorairo]) {
    testWidgets('abertura kids ${variant.name} monta e termina', (tester) async {
      var done = false;
      tester.view.physicalSize = const Size(412, 914);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: HeisucaKidsOpening(variant: variant, name: 'Ana', onFinished: () => done = true)));
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.text('Oi, Ana!'), findsOneWidget);
      expect(find.text('Vamos assistir?'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1700));
      expect(done, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('captura da abertura kids (HEISUCA_SNAPSHOT=1)', skip: !heisucaSnapshotEnabled, (tester) async {
    await heisucaLoadFonts();
    await tester.runAsync(() async {
      final loader = FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka-VF.ttf'));
      await loader.load();
    });
    heisucaPhoneView(tester);
    for (final variant in [CgflixThemeVariant.ichigo, CgflixThemeVariant.sorairo]) {
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false,
        home: HeisucaKidsOpening(key: ValueKey(variant), variant: variant, name: 'Ana')));
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
      await expectLater(find.byType(HeisucaKidsOpening), matchesGoldenFile('../visual/out/kids_${variant.name}.png'));
    }
    await tester.pumpWidget(const SizedBox());
  });

  test('conexão do usuário infantil do servidor é reconhecida (não é emprestada nem ligada a adulto)', () {
    JellyfinConnection conn(String user) => JellyfinConnection(id: 'm/$user', baseUrl: 'https://servidor.exemplo',
      serverName: 'CGFLIX', serverMachineId: 'm', userId: user, userName: user, accessToken: 't', deviceId: 'd',
      createdAt: DateTime(2026));
    expect(heisucaIsKidsConnection(conn('caioguerras-kids')), isTrue);
    expect(heisucaIsKidsConnection(conn('caioguerras')), isFalse);
    expect(heisucaIsKidsConnection(conn('kidsfan')), isFalse);
  });
}
