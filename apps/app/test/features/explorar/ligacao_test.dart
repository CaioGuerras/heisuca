import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/features/explorar/ligacao.dart';
import 'package:heisuca/features/explorar/modelo.dart';
import 'package:heisuca/media/library_query.dart';
import 'package:heisuca/media/media_filter.dart';

MediaFilter _filtro(String campo) => MediaFilter.fromJson({
  'filter': campo,
  'filterType': 'string',
  'key': '/x/$campo',
  'title': campo,
  'type': 'filter',
});

void main() {
  test('o campo vale com ou sem o tipo na frente', () {
    expect(campoSemTipo('genre'), 'genre');
    expect(campoSemTipo('show.genre'), 'genre');
    expect(campoSemTipo('episode.unwatched'), 'unwatched');
  });

  test('acha o gênero e o "não vistos" como cada servidor os chama', () {
    final jellyfin = [_filtro('unwatched'), _filtro('genre')];
    expect(filtroDeGenero(jellyfin)?.filter, 'genre');
    expect(filtroDeNaoVistos(jellyfin)?.filter, 'unwatched');

    final plexDeSerie = [_filtro('show.genre'), _filtro('unwatchedLeaves'), _filtro('year')];
    expect(filtroDeGenero(plexDeSerie)?.filter, 'show.genre', reason: 'o filtro sai com o nome que o servidor deu');
    expect(filtroDeNaoVistos(plexDeSerie)?.filter, 'unwatchedLeaves');

    expect(filtroDeGenero([_filtro('year')]), isNull);
    expect(filtroDeNaoVistos([_filtro('year')]), isNull);
  });

  test('só o nome vai de A a Z; as outras ordens começam pelo maior', () {
    for (final ordem in OrdemDoExplorar.values) {
      final doServidor = ordemDoServidor(ordem);
      expect(
        doServidor.direction,
        ordem == OrdemDoExplorar.titulo ? LibrarySortDirection.ascending : LibrarySortDirection.descending,
        reason: ordem.rotulo,
      );
    }
    expect(ordemDoServidor(OrdemDoExplorar.recentes).field, 'addedAt');
    expect(ordemDoServidor(OrdemDoExplorar.lancamento).field, 'originallyAvailableAt');
    expect(ordemDoServidor(OrdemDoExplorar.nota).field, 'rating');
  });
}
