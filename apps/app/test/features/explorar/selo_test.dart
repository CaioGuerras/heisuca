import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/features/explorar/ligacao.dart';
import 'package:heisuca/media/media_kind.dart';

void main() {
  test('selo por tipo: série conta temporadas, coleção conta filmes, filme e vazio ficam sem selo', () {
    expect(seloDe(MediaKind.show, 3), '3 temp.');
    expect(seloDe(MediaKind.collection, 1), '1 filme');
    expect(seloDe(MediaKind.collection, 4), '4 filmes');
    expect(seloDe(MediaKind.movie, 2), isNull);
    expect(seloDe(MediaKind.show, null), isNull);
    expect(seloDe(MediaKind.show, 0), isNull);
  });
}
