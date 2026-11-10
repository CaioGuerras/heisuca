import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_navigation.dart';

class _DecideNoInitState extends StatefulWidget {
  const _DecideNoInitState();
  @override
  State<_DecideNoInitState> createState() => _DecideNoInitStateState();
}

class _DecideNoInitStateState extends State<_DecideNoInitState> {
  late final bool usaVoce;
  @override
  void initState() {
    super.initState();
    usaVoce = cgflixUseYouTab(context); // como a MainScreen faz ao montar as abas
  }

  @override
  Widget build(BuildContext context) => Text(usaVoce ? 'celular' : 'outro');
}

void main() {
  testWidgets('decide a navegação do celular dentro do initState sem consultar o tema', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _DecideNoInitState()));
    expect(tester.takeException(), isNull);
    expect(find.text('celular'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('computador segue a navegação do upstream', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _DecideNoInitState()));
    expect(find.text('outro'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
