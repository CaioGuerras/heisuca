import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/heisuca/heisuca_logo.dart';
import 'package:plezy/heisuca/heisuca_opening_splash.dart';
import 'package:plezy/services/device_performance.dart';

void main() {
  tearDown(DevicePerformance.debugReset);
  for (final light in [false, true]) {
    testWidgets('abertura usa marca SVG e slogan AA, tema ${light ? "Hisui" : "Shikkoku"}', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: cgflixAppTheme(light ? CgflixThemeVariant.heitor : CgflixThemeVariant.isis),
          home: HeisucaOpeningSplash(onAnimationFinished: () => completed++),
        ),
      );
      await tester.pumpAndSettle();
      final logo = tester.widget<HeisucaLogo>(find.byType(HeisucaLogo));
      expect(logo.siteHeader, isTrue);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        'assets/heisuca/marca_site_${light ? "hisui" : "shikkoku"}.svg',
      );
      expect(find.text('HEISUCA'), findsNothing);
      final slogan = tester.widget<Text>(find.text('Nada entre você e o filme.'));
      final bg = tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor!;
      final fg = slogan.style!.color!;
      final ratio = (fg.computeLuminance() + .05) / (bg.computeLuminance() + .05);
      expect(ratio < 1 ? 1 / ratio : ratio, greaterThanOrEqualTo(4.5));
      expect(completed, 1);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('abertura respeita reduzir movimento sem prender a inicialização', (tester) async {
    var completed = 0;
    DevicePerformance.debugReset(autoReduced: true);
    await tester.pumpWidget(MaterialApp(home: HeisucaOpeningSplash(onAnimationFinished: () => completed++)));
    await tester.pump();
    expect(completed, 1);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
