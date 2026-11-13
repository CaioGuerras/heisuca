import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/navigation/navigation_tabs.dart';
import 'package:heisuca/screens/main_screen.dart';

void main() {
  bool naBarra({
    required bool infantil,
    required bool semConexao,
    NavigationTabId abaAtual = NavigationTabId.discover,
  }) => baixadosNaBarraDaCasca(infantil: infantil, semConexao: semConexao, abaAtual: abaAtual);

  test('fora do modo infantil os baixados estão sempre na barra', () {
    expect(naBarra(infantil: false, semConexao: false), isTrue);
    expect(naBarra(infantil: false, semConexao: true), isTrue);
  });

  test('modo infantil com conexão: os baixados ficam fora da barra', () {
    expect(naBarra(infantil: true, semConexao: false), isFalse);
    expect(naBarra(infantil: true, semConexao: false, abaAtual: NavigationTabId.libraries), isFalse);
  });

  test('modo infantil sem conexão: os baixados entram na barra', () {
    expect(naBarra(infantil: true, semConexao: true), isTrue);
  });

  test('modo infantil com a tela dos baixados aberta: a barra mostra onde a pessoa está', () {
    expect(naBarra(infantil: true, semConexao: false, abaAtual: NavigationTabId.downloads), isTrue);
  });
}
