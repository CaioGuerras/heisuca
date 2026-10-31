import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../../integration_test/support/pip_overflow_policy.dart';

void main() {
  test('P1: não expande diagnóstico fora da lista antes de delegar ao framework', () {
    for (final exception in [StateError('falha comum'), FlutterError('A RenderFlex overflowed by 1 pixels on the right.')]) {
      var reads = 0;
      final details = FlutterErrorDetails(exception: exception, library: 'rendering library',
        informationCollector: () { reads++; return [ErrorDescription('diagnóstico completo')]; });
      expect(pipHudWarning(details, phase: 'fora', width: 986, height: 444), isNull);
      expect(reads, 0, reason: 'Não construir a árvore de erro em janela cheia ou para exceção não candidata.');
    }
  });
  const cases = [
    ('widgets/video_controls_header.dart:59:12', 'right', 151),
    ('mobile_video_controls.dart:389:16', 'right', 7.2),
    ('mobile_video_controls.dart:239:14', 'bottom', 212),
  ];
  for (final entry in cases) {
    test('HUD conhecido: ${entry.$1}, só na fase e janela PiP', () {
      bool allowed({String phase = 'ativo', double width = 240.8, double height = 108.2,
        String? source, String? message}) => knownPipHudOverflow(
          message: message ?? 'A RenderFlex overflowed by ${entry.$3} pixels on the ${entry.$2}.',
          source: source ?? entry.$1, phase: phase, width: width, height: height);
      expect(allowed(), isTrue);
      expect(allowed(width: 227.8, height: 128), isTrue);
      expect(allowed(phase: 'entrada'), isTrue);
      expect(allowed(phase: 'saída'), isTrue);
      expect(allowed(width: 914, height: 411), isFalse);
      expect(allowed(phase: 'fora'), isFalse);
      expect(allowed(source: 'login.dart:59:12'), isFalse);
      expect(allowed(message: 'Null check operator used on a null value'), isFalse);
      expect(allowed(width: 0), isFalse);
      expect(allowed(width: 321), isFalse);
    });
  }

  test('trata exceção ao inspecionar elemento já descartado (disposed RenderFlex)', () {
    final details = _ThrowingDiagnosticsFlutterErrorDetails(
      exception: FlutterError('A RenderFlex overflowed by 10 pixels on the bottom.'),
      library: 'rendering library',
      informationCollector: () => [
        ErrorDescription('The overflowed RenderFlex was: RenderFlex#527a5 relayoutBoundary=up1 DISPOSED OVERFLOWING'),
        ErrorDescription('creator: Column ← MobileVideoControls ← [mobile_video_controls.dart:239:14]'),
      ],
    );

    final warning = pipHudWarning(details, phase: 'ativo', width: 200, height: 100);
    expect(warning, isNotNull);
    expect(warning!['tipo'], 'overflow HUD PiP');
    expect(warning['widget'], 'mobile_video_controls.dart:239:14');
  });

  test('trata erro assíncrono emitido pelo widget inspector sobre elemento descartado', () {
    final inspectorDetails = FlutterErrorDetails(
      exception: FlutterError('Element._debugCheckStateIsActiveForAncestorLookup was called on a deactivated element'),
      library: 'widget inspector',
    );
    expect(pipHudWarning(inspectorDetails, phase: 'ativo', width: 200, height: 100), isNotNull);
    expect(pipHudWarning(inspectorDetails, phase: 'fora', width: 200, height: 100), isNotNull);

    // Mensagem autêntica do framework Flutter quando um Element desativado é inspecionado
    final realFlutterInspectorDetails = FlutterErrorDetails(
      exception: FlutterError("Looking up a deactivated widget's ancestor is unsafe. At this point the state of the widget's element tree is no longer stable."),
      library: 'widget inspector',
      stack: StackTrace.fromString('#0 Element._debugCheckStateIsActiveForAncestorLookup\n#1 _describeRelevantUserCode\n#2 _parseDiagnosticsNode'),
    );
    expect(pipHudWarning(realFlutterInspectorDetails, phase: 'saída', width: 200, height: 100), isNotNull);
    expect(pipHudWarning(realFlutterInspectorDetails, phase: 'fora', width: 200, height: 100), isNotNull);

    // Erros não relacionados do widget inspector continuam propagando para o framework
    final unrelatedInspectorDetails = FlutterErrorDetails(
      exception: FlutterError('Outro erro do widget inspector não relacionado a elemento descartado'),
      library: 'widget inspector',
    );
    expect(pipHudWarning(unrelatedInspectorDetails, phase: 'ativo', width: 200, height: 100), isNull);
    expect(pipHudWarning(unrelatedInspectorDetails, phase: 'fora', width: 200, height: 100), isNull);
  });

  test('trata RenderFlex DISPOSED OVERFLOWING autêntico sem criador expandido', () {
    final details = _ThrowingDiagnosticsFlutterErrorDetails(
      exception: FlutterError('A RenderFlex overflowed by 196 pixels on the bottom.'),
      library: 'rendering library',
      informationCollector: () => [
        ErrorDescription('The specific RenderFlex in question is: RenderFlex#527a5 DISPOSED OVERFLOWING:'),
        ErrorDescription('constraints: BoxConstraints(0.0<=w<=227.8, 0.0<=h<=40.0)'),
      ],
    );

    final warning = pipHudWarning(details, phase: 'ativo', width: 227.8, height: 128.0);
    expect(warning, isNotNull);
    expect(warning!['tipo'], 'overflow HUD PiP');
    expect(warning['widget'], 'mobile_video_controls.dart:239:14');
  });
}

class _ThrowingDiagnosticsFlutterErrorDetails extends FlutterErrorDetails {
  _ThrowingDiagnosticsFlutterErrorDetails({
    required super.exception,
    super.library,
    super.informationCollector,
  });

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
    throw FlutterError('Element._debugCheckStateIsActiveForAncestorLookup was called on a disposed element');
  }
}
