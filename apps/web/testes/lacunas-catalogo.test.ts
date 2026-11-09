import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { apiDe, pode, type Sessao, type Item } from '../src/api/servidor.ts';
import { lerBuscas, registrarBusca, removerBusca, limparBuscas } from '../src/dados/buscas-recentes.ts';
import { lerOrdem, guardarOrdem } from '../src/dados/ordem-biblioteca.ts';
import { compartilharTitulo } from '../src/dados/compartilhar.ts';
const s: Sessao = { tipo: 'jellyfin', servidor: 'https://teste.invalid', token: 'ficticio', usuarioId: 'u', nome: 'Teste' };
const fonte = (n: string) => readFileSync(new URL(`../src/${n}`, import.meta.url), 'utf8');
const dados = new Map<string, string>();
const guardar = () => Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
  getItem: (k: string) => dados.get(k) || null, setItem: (k: string, v: string) => dados.set(k, v), removeItem: (k: string) => dados.delete(k),
} });
async function rede(resposta: unknown, rodar: (urls: URL[]) => Promise<void>, status = 200) {
  guardar(); const antes = globalThis.fetch; const urls: URL[] = [];
  globalThis.fetch = async u => { urls.push(new URL(String(u))); return new Response(JSON.stringify(resposta), { status }); };
  try { await rodar(urls); } finally { globalThis.fetch = antes; }
}

test('4: Trickplay recorta coluna/linha, troca folha e limita ao último quadro; Plex só tempo', () => {
  const i: Item = { Id: 'filme', Name: '', Type: 'Movie', Trickplay: { fonte: { '160': {
    Width: 160, Height: 90, TileWidth: 3, TileHeight: 2, Interval: 1000, ThumbnailCount: 10,
  } } } };
  const api = apiDe(s);
  const p = api.previaImagem(s, i, 4.5)!;
  assert.deepEqual([p.x, p.y, p.largura, p.altura], [160, 90, 160, 90]);
  assert.match(p.url, /\/Videos\/filme\/Trickplay\/160\/0.jpg\?api_key=ficticio/);
  const q = api.previaImagem(s, i, 999)!;
  assert.match(q.url, /\/1.jpg\?/); assert.deepEqual([q.x, q.y], [0, 90]);
  assert.equal(api.previaImagem(s, { ...i, Trickplay: {} }, 4), null);
  assert.equal(api.previaImagem(s, { ...i, Trickplay: { fonte: { '160': { Width: 160, Height: 90, TileWidth: 0, TileHeight: 2, Interval: 0, ThumbnailCount: 1 } } } }, 4), null);
  const px = { ...s, tipo: 'plex' as const }; assert.equal(apiDe(px).previaImagem(px, i, 4), null);
});

test('6: similares usam adaptador e Plex desativa por sessão quando endpoint não existe', async () => {
  await rede({ Items: [{ Id: 'outro', Name: 'Outro', Type: 'Movie' }] }, async urls => {
    assert.equal((await apiDe(s).similares(s, 'filme')).length, 1);
    assert.equal(urls[0].pathname, '/Items/filme/Similar');
    assert.equal(urls[0].searchParams.get('limit'), '12');
    assert.equal(urls[0].searchParams.get('fields'), 'PrimaryImageAspectRatio');
  });
  const px = { ...s, tipo: 'plex' as const };
  await rede({ MediaContainer: { Metadata: [{ ratingKey: '2', title: 'Outro', type: 'movie' }] } }, async urls => {
    assert.equal((await apiDe(px).similares(px, '1')).length, 1);
    assert.equal(urls[0].pathname, '/library/metadata/1/similar'); assert.equal(pode(px, 'similares'), true);
  });
  await rede({}, async () => { assert.deepEqual(await apiDe(px).similares(px, '1'), []); assert.equal(pode(px, 'similares'), false); }, 404);
  assert.equal(pode({ ...px }, 'similares'), true);
  const indisponivel = { ...px };
  await rede({}, async () => { assert.deepEqual(await apiDe(indisponivel).similares(indisponivel, '1'), []); assert.equal(pode(indisponivel, 'similares'), false); }, 503);
});

test('7: trailer local passa pelo adaptador; remoto abre protegido; compartilhar tem cópia e cancelamento', async () => {
  await rede([{ Id: 'trailer', Name: '', Type: 'Trailer' }], async urls => {
    assert.equal((await apiDe(s).trailers(s, 'filme'))[0].Id, 'trailer'); assert.equal(urls[0].pathname, '/Items/filme/LocalTrailers');
  });
  let copiado = '', compartilhado = '';
  const nav = { share: async (d: { url: string }) => { compartilhado = d.url; }, clipboard: { writeText: async (t: string) => { copiado = t; } } };
  assert.equal(await compartilharTitulo(nav, 'Título', 'https://site.invalid/#/t/1'), 'compartilhado'); assert.match(compartilhado, /#\/t\/1$/);
  assert.equal(await compartilharTitulo({ clipboard: nav.clipboard }, 'Título', 'link'), 'copiado'); assert.equal(copiado, 'link');
  assert.equal(await compartilharTitulo({ ...nav, share: async () => { throw { name: 'AbortError' }; } }, '', 'x'), 'cancelado');
  const t = fonte('telas/Titulo.tsx'); assert.match(t, /rel="noopener"/); assert.match(t, /Link copiado/);
});

test('8: quatro ordens e filtro são enviados ao servidor, preservando paginação', async () => {
  const jf = ['SortName', 'DateCreated', 'PremiereDate', 'CommunityRating'];
  const px = ['titleSort', 'addedAt:desc', 'originallyAvailableAt:desc', 'rating:desc'];
  for (const [n, ordem] of ['nome', 'adicionados', 'lancamento', 'nota'].entries()) {
    await rede({ Items: [], TotalRecordCount: 0 }, async urls => {
      await apiDe(s).daBiblioteca(s, 'b', 60, 60, { ordem, naoVistos: true });
      const q = urls[0].searchParams; assert.equal(q.get('sortBy'), jf[n]); assert.equal(q.get('sortOrder'), n === 0 ? 'Ascending' : 'Descending');
      assert.equal(q.get('filters'), 'IsUnplayed'); assert.equal(q.get('startIndex'), '60');
    });
    const p = { ...s, tipo: 'plex' as const };
    await rede({ MediaContainer: { Metadata: [], totalSize: 0 } }, async urls => {
      await apiDe(p).daBiblioteca(p, 'b', 60, 60, { ordem, naoVistos: true });
      assert.equal(urls[0].searchParams.get('sort'), px[n]); assert.equal(urls[0].searchParams.get('unwatched'), '1');
      assert.equal(urls[0].searchParams.get('X-Plex-Container-Start'), '60');
    });
  }
  guardarOrdem('a', { ordem: 'nota', naoVistos: true }); assert.equal(lerOrdem('a').ordem, 'nota'); assert.equal(lerOrdem('b').ordem, 'nome');
  assert.match(fonte('telas/Biblioteca.tsx'), /aria-busy=\{ocupado\}/);
});

test('9: recentes guardam apenas oito textos distintos, removem, limpam e toleram armazenamento inválido', () => {
  guardar(); limparBuscas();
  for (let i = 0; i < 10; i++) registrarBusca(`Filme ${i}`);
  assert.equal(lerBuscas().length, 8); registrarBusca(' filme 5 '); assert.equal(lerBuscas()[0], 'filme 5'); assert.equal(lerBuscas().length, 8);
  removerBusca('filme 5'); assert.ok(!lerBuscas().includes('filme 5')); limparBuscas(); assert.deepEqual(lerBuscas(), []);
  dados.set('heisuca.buscas', '{quebrado'); assert.deepEqual(lerBuscas(), []);
  dados.set('heisuca.buscas', '[2,null,"  ","Busca"]'); assert.deepEqual(lerBuscas(), ['Busca']);
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, get() { throw new Error('bloqueado'); } });
  assert.deepEqual(lerBuscas(), []); assert.doesNotThrow(() => { registrarBusca('x'); removerBusca('x'); limparBuscas(); guardarOrdem('a', { ordem: 'nome', naoVistos: false }); });
  assert.equal(lerOrdem('a').ordem, 'nome');
  assert.match(fonte('telas/Busca.tsx'), /registrarBusca\(termo\); irTitulo/);
});
