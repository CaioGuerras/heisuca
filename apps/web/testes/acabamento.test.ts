import { test } from 'node:test';
import assert from 'node:assert/strict';
import { faixaClassificacao, totalEpisodios } from '../src/dados/acabamento.ts';
import type { Item } from '../src/api/tipos.ts';

test('ClassInd normaliza faixas brasileiras sem converter classificações estrangeiras', () => {
  for (const faixa of ['L', '10', '12', '14', '16', '18']) {
    assert.equal(faixaClassificacao(faixa), faixa);
    assert.equal(faixaClassificacao(` br-${faixa.toLowerCase()} `), faixa);
  }
  assert.equal(faixaClassificacao('Livre'), 'L');
  for (const valor of ['', 'TV-14', 'PG-13', 'BR-15', 'BR-120', '14 anos']) assert.equal(faixaClassificacao(valor), null);
});

const temp = (IndexNumber: number, ChildCount?: number): Item => ({ Id: String(IndexNumber), Name: 'Temporada', Type: 'Season', IndexNumber, ChildCount });
test('total de episódios exige contagens completas e não soma especiais às temporadas regulares', () => {
  assert.equal(totalEpisodios([temp(0, 4), temp(1, 10), temp(2, 8)]), 18);
  assert.equal(totalEpisodios([temp(1, 0)]), 0);
  for (const lista of [[], [temp(0, 4)], [temp(1, 10), temp(2)], [temp(1, -2)], [temp(1, NaN)], [temp(1, 1.5)]]) {
    assert.equal(totalEpisodios(lista), null);
  }
});
