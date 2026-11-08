import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { apiDe } from '../src/api/servidor.ts';
import type { Item, Sessao } from '../src/api/tipos.ts';
import { prepararInicio } from '../src/dados/inicio.ts';

// Captura REAL anonimizada de GET /hubs?identifier=home.continue,home.ondeck no PMS 1.43.4 do CGSERVER
// (08/11/2026; só cortados elenco, Media e sinopse). Aoashi está nos dois hubs, já iniciado; VisionQuest só no On Deck.
const real = JSON.parse(await readFile(new URL('./plex-respostas/hubs-real-13.json', import.meta.url), 'utf8'));
const s: Sessao = { tipo: 'plex', servidor: 'https://hubs-real-13.example.invalid',
  token: 'ficticio', usuarioId: 'u', nome: 'Teste', servidorId: 'hubs-real-13' };
const api = apiDe(s), ids = (itens: Item[]) => itens.map(i => i.Id);
async function comReal(executar: () => Promise<void>) {
  const anterior = globalThis.fetch, armazenamento = Object.getOwnPropertyDescriptor(globalThis, 'localStorage');
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: { getItem: () => 'ficticio' } });
  globalThis.fetch = async u => new Response(JSON.stringify(new URL(String(u)).pathname === '/hubs' ? real : { MediaContainer: {} }));
  try { await executar(); }
  finally {
    globalThis.fetch = anterior;
    if (armazenamento) Object.defineProperty(globalThis, 'localStorage', armazenamento);
    else Reflect.deleteProperty(globalThis, 'localStorage');
  }
}

test('Plex13: a captura real traz a identidade dos hubs que a separação usa', () => {
  const hubs = real.MediaContainer.Hub.map((h: { hubIdentifier: string; context: string }) => [h.hubIdentifier, h.context]);
  assert.deepEqual(hubs, [['home.continue', 'hub.home.continue'], ['home.ondeck', 'hub.home.ondeck']]);
});

test('Plex13: PMS real — Continuar só o iniciado; o episódio não iniciado do On Deck vai para Próximo', async () => {
  await comReal(async () => {
    const [cont, prox] = await Promise.all([api.continuar(s), api.proximos(s)]);
    assert.deepEqual(ids(cont), ['17928']);
    assert.ok((cont[0].UserData?.PlaybackPositionTicks || 0) > 0);
    assert.deepEqual(ids(prox), ['24039']);
    assert.ok(!prox[0].UserData?.PlaybackPositionTicks);
  });
});

test('Plex13: Home real não mistura Próximo dentro de Continuar (J9-07)', async () => {
  await comReal(async () => {
    const d = await prepararInicio(s, true);
    assert.deepEqual(ids(d.retomar), ['17928']);
    assert.deepEqual(ids(d.proximos), ['24039']);
  });
});
