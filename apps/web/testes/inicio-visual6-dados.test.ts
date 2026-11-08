import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarFileiras } from '../src/comp/fileiras-inicio.ts';
import type { Item } from '../src/api/tipos.ts';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { runInNewContext } from 'node:vm';
import ts from 'typescript';

const filme = (Id: string): Item => ({ Id, Name: Id, Type: 'Movie' });
const ep = (Id: string, SeriesId?: string): Item => ({ Id, Name: Id, Type: 'Episode', SeriesId });

test('Home: montar fileiras preserva a origem e a união legada sem repetir série/ID', () => {
  const retomar = [filme('f'), ep('s1e1', 's1'), ep('solto')];
  const proximos = [filme('f'), ep('s1e2', 's1'), ep('s2e1', 's2'), ep('s2e2', 's2'), ep('outro')];
  for (const item of [...retomar, ...proximos]) Object.freeze(item);
  Object.freeze(retomar); Object.freeze(proximos);
  const d = montarFileiras(retomar, proximos);
  assert.equal(d.retomar, retomar);
  assert.deepEqual(d.proximos.map(i => i.Id), ['s2e1', 'outro']);
  assert.deepEqual(d.continuar.map(i => i.Id), ['f', 's1e1', 'solto', 's2e1', 'outro']);
  // Ausência de posição não transforma um Continuar em Próximo.
  assert.equal(d.retomar[0].UserData, undefined);
  assert.deepEqual(montarFileiras([], []), { retomar: [], proximos: [], continuar: [] });
  assert.deepEqual(montarFileiras([], [ep('a'), ep('b'), ep('a')]).proximos.map(i => i.Id), ['a', 'b']);
});

// Executa o carregador real com portas em memória: nenhuma requisição de rede.
function carregador(falhar = false) {
  const chamadas: string[] = [], lib = { ...filme('lib'), CollectionType: 'movies' };
  let liberar!: (libs: Item[]) => void;
  const bibliotecas = new Promise<Item[]>(ok => { liberar = ok; });
  const m = { exports: {} as Record<string, any> };
  const js = ts.transpileModule(readFileSync(new URL('../src/dados/inicio.ts', import.meta.url), 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText;
  runInNewContext(js, { module: m, exports: m.exports, require: (nome: string) => {
    if (nome.includes('/fileiras-inicio')) return { montarFileiras };
    if (nome.includes('/api/')) return {
      destaque: async () => [], pode: () => false,
      continuar: async () => { chamadas.push('continuar'); if (falhar) throw new Error('offline'); return [ep('cont', 's1')]; },
      proximos: async () => { chamadas.push('proximos'); if (falhar) throw new Error('offline'); return [ep('duplicado', 's1'), ep('prox', 's2')]; },
      bibliotecasDeVideo: () => { chamadas.push('bibliotecas'); return falhar ? Promise.reject(new Error('offline')) : bibliotecas; },
      novidades: async () => [filme('novo')],
    };
    throw new Error(`dependência inesperada: ${nome}`);
  } });
  return { api: m.exports, chamadas, liberar: () => liberar([lib]), lib };
}
const s = { servidor: 'falso', usuarioId: 'u', token: 't' };
const json = (v: unknown) => JSON.parse(JSON.stringify(v));

test('Home: crítico e cache resolvem antes das bibliotecas; cada origem é lida só uma vez', { timeout: 2000 }, async () => {
  const { api, chamadas, liberar, lib } = carregador();
  const a = api.prepararInicio(s), b = api.prepararInicio(s);
  const [inicial, cache] = await Promise.all([a, b]);
  assert.deepEqual(json(inicial), json(cache));
  assert.deepEqual(json(cache.retomar).map((i: Item) => i.Id), ['cont']);
  assert.deepEqual(json(cache.proximos).map((i: Item) => i.Id), ['prox']);
  assert.deepEqual(json(cache.continuar).map((i: Item) => i.Id), ['cont', 'prox']);
  assert.deepEqual(json(cache.bibliotecas), []);
  liberar();
  const sec = await api.carregarSecundario(s);
  assert.deepEqual(json(sec.bibliotecas), [lib]);
  assert.equal(sec.porBiblioteca[0].itens[0].Id, 'novo');
  assert.deepEqual(chamadas.sort(), ['bibliotecas', 'continuar', 'proximos']);
});

test('Home: falhas e ausência de cache mantêm todas as listas vazias e tipadas', async () => {
  const { api } = carregador(true);
  const semCache = await api.carregarSecundario(s);
  assert.deepEqual(json(semCache), { bibliotecas: [], porBiblioteca: [], emBreve: { tv: [], movie: [] } });
  const d = await api.prepararInicio(s), sec = await api.carregarSecundario(s);
  for (const nome of ['retomar', 'proximos', 'continuar', 'bibliotecas']) assert.deepEqual(json(d[nome]), []);
  assert.deepEqual(json(sec), json(semCache));
});

test('Home: renderiza Continuar/Próximo antes do secundário e Mídia depois, sem ler API', async () => {
  const nativo = createRequire(import.meta.url), estados: unknown[] = [], efeitos: (() => void)[] = [];
  let indice = 0, montar = true, liberar!: (d: unknown) => void;
  const secundario = new Promise(ok => { liberar = ok; });
  const m = { exports: {} as Record<string, any> };
  const js = ts.transpileModule(readFileSync(new URL('../src/telas/Inicio.tsx', import.meta.url), 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022,
      jsx: ts.JsxEmit.ReactJSX, jsxImportSource: 'preact' },
  }).outputText;
  runInNewContext(js, { module: m, exports: m.exports, require: (nome: string) => {
    if (nome === 'preact/jsx-runtime') return nativo(nome);
    if (nome === 'preact/hooks') return {
      useState: (valor: unknown) => { const k = indice++; if (montar) estados[k] = valor;
        return [estados[k], (v: unknown) => { estados[k] = typeof v === 'function' ? v(estados[k]) : v; }]; },
      useRef: (v: unknown) => ({ current: v }), useLayoutEffect: () => {},
      useEffect: (f: () => void) => { if (montar) efeitos.push(f); },
    };
    if (nome.includes('/api/')) return new Proxy({}, { get: (_, chave) => {
      throw new Error(`Home não deve ler API: ${String(chave)}`);
    } });
    if (nome.endsWith('/dados/inicio')) return {
      prepararInicio: async () => ({ destaque: [], ...montarFileiras([ep('cont', 's1')], [ep('prox', 's2')]),
        emAlta: { titulo: 'Em alta no Brasil', itens: [filme('top')] },
        bibliotecas: [], porBiblioteca: [], emBreve: { tv: [], movie: [] } }),
      carregarSecundario: () => secundario, hashDoDestaque: () => '',
    };
    if (nome.endsWith('/Fileira')) return { Fileira: 'fileira-teste' };
    if (nome.endsWith('/paleta')) return { usePaleta: () => {} };
    return {};
  } });
  const render = () => {
    indice = 0;
    const arvore = m.exports.Inicio({ s, pedir: () => {} });
    return arvore.props.children.flat(Infinity).filter((n: any) => n?.type === 'fileira-teste');
  };
  render();
  for (const efeito of efeitos) efeito();
  for (let k = 0; k < 8; k++) await Promise.resolve();
  montar = false;
  let linhas = render();
  assert.deepEqual(Array.from(linhas, (n: any) => n.props.titulo), ['Continuar', 'Próximo', 'Em alta no Brasil']);
  assert.equal(linhas[0].props.children[0].props.i.Id, 'cont');
  assert.equal(linhas[1].props.children[0].props.i.Id, 'prox');
  const biblioteca = filme('lib');
  liberar({ bibliotecas: [biblioteca], porBiblioteca: [{ biblioteca, itens: [filme('novo')] }],
    emBreve: { tv: [], movie: [{ nome: 'Estreia', tipo: 'movie' }] } });
  for (let k = 0; k < 8; k++) await Promise.resolve();
  linhas = render();
  assert.deepEqual(Array.from(linhas, (n: any) => n.props.titulo), ['Continuar', 'Próximo', 'Em alta no Brasil', 'Mídia', 'lib', 'Em breve']);
  assert.equal(linhas[3].props.children[0].props.b.Id, 'lib');
});
