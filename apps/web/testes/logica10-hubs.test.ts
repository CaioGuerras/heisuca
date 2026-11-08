import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { apiDe } from '../src/api/servidor.ts';
import type { Item, Sessao } from '../src/api/tipos.ts';
import { montarFileiras } from '../src/comp/fileiras-inicio.ts';
import { prepararInicio } from '../src/dados/inicio.ts';

const fixture = JSON.parse(await readFile(new URL('./plex-respostas/hubs-logica10.json', import.meta.url), 'utf8'));
const s: Sessao = { tipo: 'plex', servidor: 'https://hubs-logica10.example.invalid',
  token: 'ficticio', usuarioId: 'u', nome: 'Teste', servidorId: 'hubs-logica10' };
const api = apiDe(s), ids = (itens: Item[]) => itens.map(i => i.Id);
const retomadas = ['filme', 'em-curso', 'continuar-sem-posicao', 'contexto-sem-posicao', 'serie-diretorio', 'ondeck-em-curso'];
async function comFixture(executar: (chamadas: URL[]) => Promise<void>) {
  const anterior = globalThis.fetch, armazenamento = Object.getOwnPropertyDescriptor(globalThis, 'localStorage');
  const chamadas: URL[] = [], antes = JSON.stringify(fixture);
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: { getItem: () => 'ficticio' } });
  globalThis.fetch = async u => {
    const url = new URL(String(u)); chamadas.push(url);
    return new Response(JSON.stringify(url.pathname === '/hubs' ? fixture : { MediaContainer: {} }));
  };
  try { await executar(chamadas); assert.equal(JSON.stringify(fixture), antes); }
  finally {
    globalThis.fetch = anterior;
    if (armazenamento) Object.defineProperty(globalThis, 'localStorage', armazenamento);
    else Reflect.deleteProperty(globalThis, 'localStorage');
  }
}

test('Lógica10: Plex separa Continuar/Próximo por hubIdentifier/context antes de perder o envelope', async () => {
  await comFixture(async chamadas => {
    const [cont, prox] = await Promise.all([api.continuar(s), api.proximos(s)]);
    assert.deepEqual(ids(cont), retomadas);
    assert.deepEqual(ids(prox), ['seguinte-s1', 'proximo']);
    assert.equal(cont.find(i => i.Id === 'continuar-sem-posicao')?.UserData?.PlaybackPositionTicks, undefined);
    assert.equal(cont.find(i => i.Id === 'ondeck-em-curso')?.UserData?.PlaybackPositionTicks, 120_000_000);
    assert.equal(prox.find(i => i.Id === 'proximo')?.UserData?.PlaybackPositionTicks, 0);
    assert.equal(cont.find(i => i.Id === 'serie-diretorio')?.Type, 'Series');
    assert.equal(chamadas.length, 2, 'não acrescenta consultas à rede');
    assert.ok(chamadas.every(u => u.pathname === '/hubs' && u.searchParams.get('identifier') === 'home.continue,home.ondeck'));
  });
});

test('Lógica10: fileiras conservam a origem Plex e Próximo permanece visível após a deduplicação', async () => {
  await comFixture(async () => {
    const cont = await api.continuar(s), prox = await api.proximos(s);
    for (const i of [...cont, ...prox]) Object.freeze(i);
    Object.freeze(cont); Object.freeze(prox);
    const d = montarFileiras(cont, prox);
    assert.deepEqual(ids(d.retomar), retomadas);
    assert.deepEqual(ids(d.proximos), ['proximo']);
    assert.deepEqual(ids(d.continuar), [...retomadas, 'proximo']);
    assert.ok(![...d.retomar, ...d.proximos].some(i => /^(?:recente|sem-origem|filme-ondeck)/.test(i.Id)));
  });
});

test('Lógica10: carregador real da Home recebe as duas listas separadas pela fachada Plex', async () => {
  await comFixture(async chamadas => {
    const d = await prepararInicio(s, true);
    assert.deepEqual(ids(d.retomar), retomadas);
    assert.deepEqual(ids(d.proximos), ['proximo']);
    assert.deepEqual(ids(d.continuar), [...retomadas, 'proximo']);
    assert.equal(chamadas.filter(u => u.pathname === '/hubs').length, 2);
  });
});
