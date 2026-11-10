import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/home/cgflix_cards.dart';
import 'package:heisuca/heisuca/heisuca_design_system.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/widgets/expressive_button_group.dart';

/// Altura pintada do segmento "Confortável" a 200% de fonte, para um [minHeight] dado.
Future<double> _segmentHeightAt200(WidgetTester tester, double minHeight) async {
  await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(),
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: const TextScaler.linear(2)), child: child!),
    home: Scaffold(body: Align(alignment: Alignment.topLeft,
      child: SizedBox(width: 220, child: ExpressiveButtonGroup<int>(
        minHeight: minHeight,
        segments: const [ButtonSegment(value: 0, label: Text('Compacto')),
          ButtonSegment(value: 1, label: Text('Confortável'))],
        selected: 0, onChanged: (_) {}))))));
  await tester.pumpAndSettle();
  final segment = find.ancestor(of: find.text('Confortável'), matching: find.byType(AnimatedContainer)).first;
  final box = tester.renderObject<RenderBox>(segment);
  return MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size).height;
}

/// Alvo mínimo de toque do Heisuca (dp).
const double _minTap = 48;

void main() {
  testWidgets('P3 opções mantêm a fonte 200% e alvo de toque >= 48', (tester) async {
    final height = await _segmentHeightAt200(tester, 48);
    expect(height, greaterThanOrEqualTo(_minTap));
    expect(tester.takeException(), isNull);
  });
  testWidgets('P3 prova negativa: minHeight 40 fica abaixo do alvo de 48', (tester) async {
    // Fonte normal: o rótulo não empurra a altura, então vale o minHeight configurado.
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(), home: Scaffold(body: Align(
      alignment: Alignment.topLeft, child: SizedBox(width: 300, child: ExpressiveButtonGroup<int>(
        minHeight: 40, segments: const [ButtonSegment(value: 0, label: Text('A')),
          ButtonSegment(value: 1, label: Text('B'))], selected: 0, onChanged: (_) {}))))));
    await tester.pumpAndSettle();
    final box = tester.renderObject<RenderBox>(
      find.ancestor(of: find.text('A'), matching: find.byType(AnimatedContainer)).first);
    expect(box.size.height, lessThan(_minTap), reason: 'a checagem >= 48 reprovaria este botão');
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

  testWidgets('P3 Continuar assistindo em fonte 200% sem overflow, título visível e dentro do card', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    final episode = MediaItem.jellyfin(id: 'episodio', kind: MediaKind.episode,
      title: 'O começo', grandparentTitle: 'Uma série', parentIndex: 1, index: 1);
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(2)), child: child!),
      home: Scaffold(body: ListView(children: [CgflixWideCard(item: episode, client: null, siteStyle: true)]))));
    await tester.pump();
    final title = find.text('Uma série');
    expect(title, findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(errors.where((e) => e.toString().contains('overflowed')), isEmpty);
    final card = tester.getRect(find.byType(CgflixWideCard));
    final text = tester.getRect(title);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(text.width, greaterThan(0));
    expect(text.height, greaterThan(0));
    expect(card.overlaps(text), isTrue);
    expect(text.left, greaterThanOrEqualTo(card.left - 0.5));
    expect(text.right, lessThanOrEqualTo(card.right + 0.5));
    expect(text.bottom, lessThanOrEqualTo(card.bottom + 0.5));
    expect(text.top, greaterThanOrEqualTo(card.top));
    expect(text.bottom, lessThanOrEqualTo(screen.height));
  });
}
