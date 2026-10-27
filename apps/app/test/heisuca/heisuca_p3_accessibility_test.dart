import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/home/cgflix_cards.dart';
import 'package:heisuca/heisuca/heisuca_design_system.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/widgets/expressive_button_group.dart';

void main() {
  testWidgets('P3 opções mantêm a fonte 200% quando o rótulo precisa de mais espaço', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(2)), child: child!),
      home: Scaffold(body: Align(alignment: Alignment.topLeft,
        child: SizedBox(width: 220, child: ExpressiveButtonGroup<int>(
          segments: const [ButtonSegment(value: 0, label: Text('Compacto')),
            ButtonSegment(value: 1, label: Text('Confortável'))],
          selected: 0, onChanged: (_) {}))))));
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderBox>(find.text('Confortável'));
    final painted = MatrixUtils.transformRect(paragraph.getTransformTo(null), Offset.zero & paragraph.size);
    expect(painted.height, greaterThanOrEqualTo(40));
    expect(tester.takeException(), isNull);
  });
  testWidgets('P3 botão Heisuca recebe foco e ativa por teclado', (tester) async {
    var activations = 0;
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(), home: Scaffold(
      body: HeisucaSpringPressable(onTap: () => activations++,
        child: const SizedBox(width: 160, height: 56, child: Text('Iniciar sessão'))),
    )));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);
  });

  testWidgets('P3 Continuar assistindo respeita fonte 200% sem limitar a escala', (tester) async {
    final episode = MediaItem.jellyfin(id: 'episodio', kind: MediaKind.episode,
      title: 'O começo', grandparentTitle: 'Uma série', parentIndex: 1, index: 1);
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(2)), child: child!),
      home: Scaffold(body: ListView(children: [CgflixWideCard(item: episode, client: null, siteStyle: true)]))));
    await tester.pump();
    final title = find.text('Uma série');
    expect(MediaQuery.textScalerOf(tester.element(title)).scale(12), 24);
    expect(tester.takeException(), isNull);
  });
}
