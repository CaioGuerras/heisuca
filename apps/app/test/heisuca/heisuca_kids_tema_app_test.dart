import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids_theme.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/profiles/profile.dart';
import '../test_helpers/prefs.dart';

class _Profiles extends ChangeNotifier implements ActiveProfileProvider {
  _Profiles(this._active);
  final Profile _active;
  @override
  Profile? get active => _active;
  @override
  String? get activeId => _active.id;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _kid = Profile.local(id: 'kids-1', displayName: 'Ana', createdAt: DateTime(2026, 11, 17));

/// Monta o MaterialApp do mesmo jeito que o main.dart: tema do kids nas duas versões, `themeMode` do app decide.
Future<Brightness> _brilhoNoKids(WidgetTester tester, {required ThemeMode doApp, required Brightness doCelular}) async {
  tester.platformDispatcher.platformBrightnessTestValue = doCelular;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final profiles = _Profiles(_kid);
  addTearDown(profiles.dispose);
  late Brightness visto;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ActiveProfileProvider>.value(value: profiles),
        ChangeNotifierProvider<HeisucaKids>.value(value: HeisucaKids.instance),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          theme: heisucaKidsTheme(context, dark: false) ?? ThemeData.light(),
          darkTheme: heisucaKidsTheme(context, dark: true) ?? ThemeData.dark(),
          themeMode: doApp,
          home: Builder(
            builder: (inner) {
              visto = Theme.of(inner).brightness;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return visto;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    resetSharedPreferencesForTest();
    HeisucaKids.instance.debugReset();
    await HeisucaKids.instance.save(
      HeisucaKidsRecord(
        parentProfileId: 'pai',
        kidsProfileId: 'kids-1',
        variant: CgflixThemeVariant.ichigo,
        ceiling: 'livre',
        pinHash: computePinHash('2468'),
        name: 'Ana',
      ),
    );
  });

  testWidgets('app em claro e celular em escuro: o modo infantil fica claro', (tester) async {
    expect(await _brilhoNoKids(tester, doApp: ThemeMode.light, doCelular: Brightness.dark), Brightness.light);
  });

  testWidgets('app em escuro e celular em claro: o modo infantil fica escuro', (tester) async {
    expect(await _brilhoNoKids(tester, doApp: ThemeMode.dark, doCelular: Brightness.light), Brightness.dark);
  });

  testWidgets('app em automático: o modo infantil segue o celular', (tester) async {
    expect(await _brilhoNoKids(tester, doApp: ThemeMode.system, doCelular: Brightness.dark), Brightness.dark);
  });
}
