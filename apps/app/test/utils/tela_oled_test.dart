import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/utils/tela_oled.dart';

void main() {
  bool oled(String marca, String modelo) => aparelhoTemTelaOled(marca: marca, modelo: modelo);

  test('modelos sabidamente OLED', () {
    expect(oled('motorola', 'motorola edge 60 pro'), isTrue);
    expect(oled('Google', 'Pixel 8'), isTrue);
    expect(oled('samsung', 'SM-S921B'), isTrue);
    expect(oled('samsung', 'SM-A546E'), isTrue);
    expect(oled('OnePlus', 'CPH2449'), isTrue);
    expect(oled('Nothing', 'A063'), isTrue);
    expect(oled('Xiaomi', '13T Pro'), isTrue);
    expect(oled('Xiaomi', 'Redmi Note 12 Pro'), isTrue);
  });

  test('modelos que não são OLED ou sem certeza', () {
    expect(oled('motorola', 'moto g54'), isFalse);
    expect(oled('Xiaomi', 'Redmi 12C'), isFalse);
    expect(oled('samsung', 'SM-A145M'), isFalse);
    expect(oled('', ''), isFalse);
  });
}
