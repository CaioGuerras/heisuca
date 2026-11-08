import { test } from 'node:test';
import assert from 'node:assert/strict';
import { filtrarProximos } from '../src/comp/fileiras-inicio.ts';
import type { Item } from '../src/api/tipos.ts';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { runInNewContext } from 'node:vm';
import ts from 'typescript';
const filme = (Id: string): Item => ({ Id, Name: Id, Type: 'Movie' });
const ep = (Id: string, SeriesId?: string): Item => ({ Id, Name: Id, Type: 'Episode', SeriesId });

test('Próximo não repete ID nem série de Continuar e preserva a ordem do servidor', () => {
  const continuar = [filme('f1'), ep('s1e1', 's1')];
  const proximos = [filme('f1'), ep('s1e2', 's1'), ep('s2e1', 's2'), ep('s3e4', 's3')];
  assert.deepEqual(filtrarProximos(continuar, proximos), proximos.slice(2));
});
test('Próximo deduplica ID/série na própria lista sem eliminar episódios de série desconhecida', () => {
  const proximos = [ep('a'), ep('b'), ep('a'), ep('c', 's'), ep('d', 's')];
  assert.deepEqual(filtrarProximos([], proximos).map(i => i.Id), ['a', 'b', 'c']);
});
test('Próximo usa origem, tolera listas vazias e não muda os dados recebidos', () => {
  const cont = Object.freeze([Object.freeze(ep('a', 's1'))]);
  const prox = Object.freeze([Object.freeze(ep('b', 's1')), Object.freeze(ep('c', 's2'))]);
  assert.deepEqual(filtrarProximos(cont as Item[], prox as Item[]).map(i => i.Id), ['c']);
  assert.deepEqual(filtrarProximos([], []), []);
  assert.equal(cont.length, 1); assert.equal(prox.length, 2);
  assert.deepEqual(filtrarProximos([{ ...filme('s'), Type: 'Series' }], [ep('x', 's')]), []);
});

test('Home rende a ordem do plano, usa a origem da API e abre biblioteca pelo cartão de Mídia', async () => {
  const nativo = createRequire(import.meta.url);
  const estados: unknown[] = [];
  let indice = 0, montar = true;
  const efeitos: (() => void)[] = [], chamadas: string[] = [], navegacoes: string[] = [];
  const biblioteca = { ...filme('lib'), Name: 'Filmes' };
  const modulo = { exports: {} as Record<string, any> };
  const vazio = { destaque: [], continuar: [filme('antigo-merge')],
    emAlta: { titulo: 'Em alta no Brasil', itens: [filme('top')] },
    porBiblioteca: [], emBreve: { tv: [], movie: [] } };
  const js = ts.transpileModule(readFileSync(new URL('../src/telas/Inicio.tsx', import.meta.url), 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022,
      jsx: ts.JsxEmit.ReactJSX, jsxImportSource: 'preact' },
  }).outputText;
  runInNewContext(js, { module: modulo, exports: modulo.exports, require: (nome: string) => {
    if (nome === 'preact/jsx-runtime') return nativo(nome);
    if (nome === 'preact/hooks') return {
      useState: (valor: unknown) => { const k = indice++; if (montar) estados[k] = valor;
        return [estados[k], (v: unknown) => { estados[k] = typeof v === 'function' ? v(estados[k]) : v; }]; },
      useRef: (v: unknown) => ({ current: v }), useLayoutEffect: () => {},
      useEffect: (f: () => void) => { if (montar) efeitos.push(f); },
    };
    if (nome.includes('/api/')) return {
      continuar: async () => { chamadas.push('continuar'); return [ep('em-curso', 's1')]; },
      proximos: async () => { chamadas.push('proximos'); return [ep('repetido', 's1'), ep('proximo', 's2')]; },
      bibliotecasDeVideo: async () => { chamadas.push('bibliotecas'); return [biblioteca]; },
    };
    if (nome.endsWith('/dados/inicio')) return {
      prepararInicio: async () => vazio,
      carregarSecundario: async () => ({ porBiblioteca: [{ biblioteca, itens: [filme('novidade')] }],
        emBreve: { tv: [], movie: [{ nome: 'Estreia', tipo: 'movie' }] } }),
      hashDoDestaque: () => '',
    };
    if (nome.endsWith('/fileiras-inicio')) return { filtrarProximos };
    if (nome.endsWith('/Fileira')) return { Fileira: 'fileira-teste' };
    if (nome.endsWith('/paleta')) return { usePaleta: () => {} };
    if (nome.endsWith('/rota')) return { irAba: (r: string) => navegacoes.push(r) };
    return {};
  } });
  modulo.exports.Inicio({ s: { token: 't', servidor: 'falso', usuarioId: 'u' }, pedir: () => {} });
  for (const efeito of efeitos) efeito();
  for (let k = 0; k < 8; k++) await Promise.resolve();
  montar = false; indice = 0;
  const arvore = modulo.exports.Inicio({ s: { token: 't', servidor: 'falso', usuarioId: 'u' }, pedir: () => {} });
  const fileiras = arvore.props.children.flat(Infinity).filter((n: any) => n?.type === 'fileira-teste');
  assert.deepEqual(Array.from(fileiras, (n: any) => n.props.titulo), ['Continuar', 'Próximo', 'Em alta no Brasil', 'Mídia', 'Filmes', 'Em breve']);
  assert.deepEqual(chamadas.sort(), ['bibliotecas', 'continuar', 'proximos']);
  assert.equal(fileiras[0].props.children[0].props.i.Id, 'em-curso');
  assert.equal(fileiras[1].props.children.length, 1);
  assert.equal(fileiras[1].props.children[0].props.i.Id, 'proximo');
  const cartao = fileiras[3].props.children[0];
  assert.equal(cartao.props.sobreposto, true);
  cartao.props.aoAbrir(biblioteca);
  assert.deepEqual(navegacoes, ['b/lib']);
});
