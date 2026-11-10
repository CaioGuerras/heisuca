import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/vibracao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pedidos = <Object?>[];
  var agora = DateTime(2026, 11, 10, 12);

  setUp(() {
    pedidos.clear();
    Vibracao.zerar();
    Vibracao.relogio = () => agora;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (chamada) async {
        if (chamada.method == 'HapticFeedback.vibrate') pedidos.add(chamada.arguments);
        return null;
      },
    );
  });

  tearDown(() {
    Vibracao.relogio = DateTime.now;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  test('cada sentido tem o seu toque', () async {
    await Vibracao.confirmar.tocar();
    await Vibracao.alternar.tocar();
    await Vibracao.passo.tocar();
    expect(pedidos, [
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.selectionClick',
    ]);
  });

  test('passos seguidos não viram zumbido', () async {
    for (var i = 0; i < 10; i++) {
      await Vibracao.passo.tocar();
      agora = agora.add(const Duration(milliseconds: 10));
    }
    // 100 ms de arrasto, um passo a cada 40 ms: 0, 40 e 80 ms.
    expect(pedidos.length, 3);

    agora = agora.add(Vibracao.intervaloDoPasso);
    await Vibracao.passo.tocar();
    expect(pedidos.length, 4);
  });

  test('o limite do passo não segura os outros toques', () async {
    await Vibracao.passo.tocar();
    await Vibracao.confirmar.tocar();
    await Vibracao.confirmar.tocar();
    expect(pedidos.length, 3);
  });
}
