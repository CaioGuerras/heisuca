import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/heisuca/heisuca_device_status.dart';
import 'package:heisuca/heisuca/services/heisuca_device_service.dart';
import 'package:heisuca/services/device_performance.dart';

void main() {
  tearDown(DevicePerformance.debugReset);

  Future<void> showStatus(WidgetTester tester, CgflixThemeVariant theme, {double scale = 1}) async {
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(theme), home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)), child: Builder(builder: (context) => Scaffold(
        body: TextButton(onPressed: () => showDialog<void>(context: context, builder: (_) => MediaQuery(
          data: MediaQuery.of(context), child: const HeisucaDeviceStatusDialog(
            profile: HeisucaDeviceProfile(renderer: 'Impeller', lowMemory: false),
            effectsPreference: 'automática', exoPlayer: false, hardwareDecoding: true))), child: const Text('Abrir')))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  for (final setting in [
    (memory: 2.0, reduced: true, label: 'Reduzido'),
    (memory: 3.6, reduced: false, label: 'Padrão'),
    (memory: 7.4, reduced: false, label: 'Topo de linha'),
  ]) {
    testWidgets('medidor apresenta nível real ${setting.label}', (tester) async {
      DevicePerformance.debugReset(autoReduced: setting.reduced,
        totalMemBytes: (setting.memory * 1024 * 1024 * 1024).round());
      await showStatus(tester, CgflixThemeVariant.isis);
      expect(find.bySemanticsLabel('Nível atual: ${setting.label}'), findsOneWidget);
      expect(find.text('No máximo'), findsNothing);
      expect(find.textContaining('Cache de imagens:'), findsNothing);
      expect(find.textContaining('orçamento'), findsNothing);
      expect(find.textContaining('Pressão de memória'), findsNothing);
      await tester.tap(find.text('Detalhes técnicos'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cache de imagens:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('memória desconhecida não é apresentada como hardware de topo', (tester) async {
    DevicePerformance.debugReset();
    await showStatus(tester, CgflixThemeVariant.isis);
    expect(find.bySemanticsLabel('Nível ainda não informado'), findsOneWidget);
    expect(find.textContaining('O sistema não informou a memória'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final theme in [CgflixThemeVariant.isis, CgflixThemeVariant.heitor]) {
    testWidgets('popup ${theme.name}: fonte grande em tela estreita continua acessível', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DevicePerformance.debugReset(autoReduced: false, totalMemBytes: (3.6 * 1024 * 1024 * 1024).round());
      await showStatus(tester, theme, scale: 2);
      await tester.scrollUntilVisible(find.text('Detalhes técnicos'), 200, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('Detalhes técnicos'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Fechar'), 200, scrollable: find.byType(Scrollable).last);
      expect(find.text('Fechar').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      expect(find.text('Funções e desempenho'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
