import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mesmo canal entregue pelo Android ao Flutter; não simula um drag no conteúdo.
Future<void> sendPredictiveBack(WidgetTester tester, String method, {int edge = 0, double progress = 0}) async {
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final x = edge == 0 ? 5 + progress * width / 2 : width - 5 - progress * width / 2;
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, {
      'touchOffset': [x, 300.0], 'progress': progress, 'swipeEdge': edge,
    })), (_) {});
  await tester.pump();
}
