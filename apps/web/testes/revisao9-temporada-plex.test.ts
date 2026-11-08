import { test } from 'node:test';
import assert from 'node:assert/strict';
import { apiDe, type Sessao } from '../src/api/servidor.ts';

test('Revisão9: temporada Plex conserva a série pai para o redirecionamento do Título', async () => {
  const s: Sessao = { tipo: 'plex', servidor: 'https://pms.example.invalid', token: 'ficticio', usuarioId: 'u', nome: 'Teste' };
  const anterior = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({ MediaContainer: { Metadata: [
    { ratingKey: 'temporada', type: 'season', title: 'Temporada 1', parentRatingKey: 'serie', parentTitle: 'Série', index: 1 },
    { ratingKey: 'episodio', type: 'episode', title: 'Piloto', parentRatingKey: 'temporada', grandparentRatingKey: 'serie',
      parentTitle: 'Temporada 1', grandparentTitle: 'Série', index: 1 },
  ] } }));
  try {
    const [temporada, episodio] = await apiDe(s).porIds(s, ['temporada', 'episodio']);
    assert.equal(temporada.SeriesId, 'serie', 'Título usa SeriesId para abrir a série de uma temporada');
    assert.equal(temporada.SeriesName, 'Série');
    assert.equal(episodio.SeriesId, 'serie'); assert.equal(episodio.SeasonId, 'temporada');
    assert.equal(episodio.SeriesName, 'Série'); assert.equal(episodio.SeasonName, 'Temporada 1');
  } finally { globalThis.fetch = anterior; }
});
