import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { apiDe, adaptador, quandoExpirar } from '../src/api/servidor.ts';
import { sessaoAtual, trocarPara, servidoresSalvos, esquecerSessao } from '../src/api/contas.ts';
import { alternarFavorito, alternarVisto, dadosDe } from '../src/estado/usuario.ts';
import type { Sessao, Item } from '../src/api/tipos.ts';

const antiga = JSON.parse(await readFile(new URL('./urls-antigas.json', import.meta.url), 'utf8'));
const s: Sessao = { ...antiga.s, tipo: 'jellyfin', servidorId: 'servidor-a' };
const i: Item = antiga.i;
function armazenamento(inicio: Record<string, string> = {}) {
  const dados = new Map(Object.entries(inicio));
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
    getItem: (k: string) => dados.get(k) ?? null,
    setItem: (k: string, v: string) => { dados.set(k, v); }, removeItem: (k: string) => { dados.delete(k); },
  } });
  return dados;
}

test('importar o contrato e a API em Node não exige document nem acessa localStorage', async () => {
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, get() { throw new Error('não ler'); } });
  const api = await import('../src/api/servidor.ts');
  assert.equal(api.apiDe(s), api.adaptador('jellyfin'));
  assert.equal(api.apiDe({ ...s, servidor: 'https://outro.example.invalid' }), api.apiDe(s));
  assert.throws(() => adaptador('plex'), /ainda não disponível/);
  assert.equal(typeof globalThis.document, 'undefined');
  assert.deepEqual(apiDe(s).capacidades(), { favoritos: true, trocarSenha: true, foto: true,
    legendasRemotas: true, capitulos: true, emAlta: true, emBreve: true });
});

test('sessões/servidores antigos recebem tipo em todos os caminhos sem perder login', () => {
  const legado = antiga.s;
  const dados = armazenamento({ 'heisuca.sessao': JSON.stringify(legado),
    'heisuca.sessoes': JSON.stringify({ antigo: legado }),
    'heisuca.servidores': JSON.stringify([{ id: 'antigo', url: s.servidor, nome: 'Antigo' }]),
  });
  assert.deepEqual(sessaoAtual(), { ...legado, tipo: 'jellyfin' });
  assert.equal(servidoresSalvos()[0].tipo, 'jellyfin');
  assert.deepEqual(trocarPara('antigo'), { ...legado, tipo: 'jellyfin' });
  assert.equal(sessaoAtual()?.token, legado.token);
  assert.equal(trocarPara('desconhecido'), null);
  assert.equal(dados.has('heisuca.sessao'), true);
  // Uma sessão atual com servidorId é removida também do mapa ao sair.
  dados.set('heisuca.sessao', JSON.stringify({ ...legado, servidorId: 'antigo' }));
  esquecerSessao();
  assert.equal(sessaoAtual(), null);
  assert.equal(trocarPara('antigo'), null);
  assert.equal(servidoresSalvos().length, 1);
});

test('tipo explícito é preservado e armazenamento indisponível não quebra saída/troca', () => {
  armazenamento({ 'heisuca.sessao': JSON.stringify({ ...s, tipo: 'plex' }),
    'heisuca.sessoes': JSON.stringify({ plex: { ...s, tipo: 'plex' } }),
    'heisuca.servidores': JSON.stringify([{ id: 'plex', tipo: 'plex' }]) });
  assert.equal(sessaoAtual()?.tipo, 'plex'); assert.equal(trocarPara('plex')?.tipo, 'plex');
  assert.equal(servidoresSalvos()[0].tipo, 'plex');
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, get() { throw new Error('privado'); } });
  assert.equal(sessaoAtual(), null); assert.equal(trocarPara('antigo'), null);
  assert.deepEqual(servidoresSalvos(), []); assert.doesNotThrow(esquecerSessao);
});

test('catálogo/busca/imagens mantêm as URLs capturadas antes da refatoração', async () => {
  armazenamento({ 'heisuca.aparelho': 'aparelho-ficticio' });
  let url = '';
  const anterior = globalThis.fetch;
  globalThis.fetch = async u => { url = String(u); return new Response(JSON.stringify({ Items: [] })); };
  try {
    const api = apiDe(s);
    await api.item(s, i.Id); assert.equal(url, antiga.urls.item);
    await api.episodios(s, 'serie-opaca', 'temporada-opaca'); assert.equal(url, antiga.urls.episodios);
    await api.buscar(s, 'ação & lua', 'biblioteca-opaca'); assert.equal(url, antiga.urls.buscar);
    assert.equal(api.capa(s, i), antiga.urls.capa); assert.equal(api.fundo(s, i), antiga.urls.fundo);
    assert.equal(api.logo(s, i), antiga.urls.logo);
    assert.equal(api.hashDe(s, i), undefined);
  } finally { globalThis.fetch = anterior; }
});

test('requisição pendente conserva sessão e token de origem durante a troca', async () => {
  armazenamento();
  const anterior = globalThis.fetch;
  const chamadas: { url: string; auth: string }[] = [];
  const respostas: (() => void)[] = [];
  globalThis.fetch = (u, init) => new Promise(resolve => {
    chamadas.push({ url: String(u), auth: (init?.headers as Record<string, string>).Authorization });
    respostas.push(() => resolve(new Response(JSON.stringify(i))));
  });
  try {
    const a = apiDe(s).item(s, i.Id);
    const outra = { ...s, servidor: 'https://outro.example.invalid', token: 'outra-ficticia' };
    const b = apiDe(outra).item(outra, i.Id);
    respostas[1](); respostas[0](); await Promise.all([a, b]);
    assert.ok(chamadas[0].url.startsWith(s.servidor)); assert.ok(chamadas[0].auth.includes(s.token));
    assert.ok(chamadas[1].url.startsWith(outra.servidor)); assert.ok(chamadas[1].auth.includes(outra.token));
  } finally { globalThis.fetch = anterior; }
});

test('401 notifica o contrato comum e rejeita a chamada', async () => {
  armazenamento();
  const anterior = globalThis.fetch; let vezes = 0;
  globalThis.fetch = async () => new Response(null, { status: 401 });
  quandoExpirar(() => { vezes++; });
  try { await assert.rejects(apiDe(s).item(s, i.Id), /sessão vencida/); assert.equal(vezes, 1); }
  finally { quandoExpirar(null); globalThis.fetch = anterior; }
});

test('assistido/favorito não se misturam entre servidores/usuários com o mesmo Id, inclusive em rollback', async () => {
  armazenamento();
  const anterior = globalThis.fetch;
  globalThis.fetch = async () => new Response('{}');
  const a = { ...s, servidorId: 'estado-a' }, b = { ...s, servidorId: 'estado-b' }, c = { ...a, usuarioId: 'outro' };
  const it = { ...i, UserData: { Played: false, IsFavorite: false } };
  try {
    await alternarVisto(a, it); await alternarFavorito(a, it);
    assert.equal(dadosDe(a, it).Played, true); assert.equal(dadosDe(a, it).IsFavorite, true);
    assert.deepEqual(dadosDe(b, it), it.UserData); assert.deepEqual(dadosDe(c, it), it.UserData);
    globalThis.fetch = async () => { throw new Error('rede'); };
    await assert.rejects(alternarFavorito(b, it), /rede/);
    assert.deepEqual(dadosDe(b, it), it.UserData); assert.equal(dadosDe(a, it).IsFavorite, true);
  } finally { globalThis.fetch = anterior; }
});
