import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/heisuca/heisuca_device_screen.dart';

void main() {
  test('Regra do Caio: limite físico independe da preferência de efeitos', () {
    const gib = 1024 * 1024 * 1024;
    expect(
      heisucaDeviceTier(reduced: false, is64Bit: false, memory: 2 * gib),
      2,
    );
    expect(
      heisucaDeviceTier(reduced: false, is64Bit: false, memory: 2 * gib + 1),
      0,
    );
    expect(
      heisucaDeviceTier(reduced: false, is64Bit: true, memory: 2 * gib),
      0,
    );
    expect(heisucaDeviceTier(reduced: false, lowMemory: true), 2);
    expect(heisucaDeviceTier(reduced: true), 1);
    expect(heisucaDeviceTier(reduced: false), 0);
  });
}
