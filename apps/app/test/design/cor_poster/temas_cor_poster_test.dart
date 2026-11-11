import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';
import 'package:heisuca/design/tema.dart';

void main() {
  test('cada tema da V2 tem o seu papel de cor do pôster, pelo nome', () {
    for (final tema in TemaHeisuca.todos) {
      expect(TemasCorPoster.de(tema.nome).nome, tema.nome);
    }
  });

  test('nome desconhecido cai no tema padrão', () {
    expect(TemasCorPoster.de('não existe'), TemasCorPoster.shikkoku);
  });
}
