import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { criarBusca, buscaInicial, type EstadoBusca } from '../src/telas/busca-progressiva.ts';
import { apiDe, buscar, quandoExpirar, type Item, type Sessao } from '../src/api/servidor.ts';
import { bancada, nos, resolver, texto } from './visual7-harness.ts';

const lib = (Id = 'A', CollectionType = 'movies'): Item => ({ Id, Name: `Biblioteca ${Id}`, Type: 'CollectionFolder', CollectionType });
const item = (Id: string, Name = Id, Type = 'Movie'): Item => ({ Id, Name, Type });
const pagina = (Items: Item[], TotalRecordCount = Items.length) => ({ Items, TotalRecordCount });
function pendente<T>() {
  let ok!: (v: T) => void, falhar!: (e: Error) => void;
  const promessa = new Promise<T>((a, b) => { ok = a; falhar = b; });
  return { promessa, ok, falhar };
}

test('Busca8: avança pelo total, anexa novos títulos e não reordena os anteriores', async () => {
  const inicios: number[] = [], estados: EstadoBusca[] = [];
  const busca = criarBusca('lua', async () => [lib()], async (_b, inicio) => {
    inicios.push(inicio);
    return inicio === 0 ? pagina([item('1', 'Outra história'), item('2', 'Lua cheia')], 4)
      : pagina([item('3', 'Lua nova'), item('4', 'A viagem')], 4);
  }, e => estados.push(e));
  await busca.carregar();
  assert.deepEqual(estados[estados.length - 1].itens?.map(i => i.Id), ['2', '1']);
  const anteriores = estados[estados.length - 1].itens;
  await busca.carregar(); await busca.carregar();
  assert.deepEqual(inicios, [0, 2]);
  assert.deepEqual(estados[estados.length - 1].itens?.map(i => i.Id), ['2', '1', '3', '4']);
  assert.deepEqual(anteriores?.map(i => i.Id), ['2', '1'], 'estado publicado é uma foto imutável da página');
  assert.equal(estados[estados.length - 1].mais, false);
});

test('Busca8: cursores independentes contam itens brutos e preservam biblioteca do tipo correto', async () => {
  let estado = buscaInicial;
  const chamadas: [string, number][] = [];
  const busca = criarBusca('lua', async () => [lib('A', 'tvshows'), lib('B'), lib('C', 'boxsets')], async (b, inicio) => {
    chamadas.push([b.Id, inicio]);
    return b.Id === 'A' ? pagina([item('1')], 1)
      : inicio === 0 ? pagina([item('1'), item('2')], 3) : pagina([item('3')], 3);
  }, e => { estado = e; });
  await busca.carregar(); await busca.carregar();
  assert.deepEqual(chamadas, [['A', 0], ['B', 0], ['B', 2]]);
  assert.deepEqual(estado.itens?.map(i => [i.Id, i.biblioteca]), [['1', 'Biblioteca B'], ['2', 'Biblioteca B'], ['3', 'Biblioteca B']]);
});

test('Busca8: duas notificações do observador não duplicam a página em andamento', async () => {
  const lote = pendente<ReturnType<typeof pagina>>(); let chamadas = 0;
  const busca = criarBusca('lua', async () => [lib()], () => { chamadas++; return lote.promessa; }, () => {});
  const primeira = busca.carregar(); await resolver();
  await busca.carregar();
  assert.equal(chamadas, 1);
  lote.ok(pagina([item('1')])); await primeira;
  await busca.carregar(); assert.equal(chamadas, 1);
});

test('Busca8: trocar termo aborta a página antiga e ignora resposta que desobedece o sinal', async () => {
  const lote = pendente<ReturnType<typeof pagina>>();
  let sinal!: AbortSignal;
  const estados: EstadoBusca[] = [], novos: EstadoBusca[] = [];
  const velha = criarBusca('lua', async () => [lib()], (_b, _n, s) => { sinal = s; return lote.promessa; }, e => estados.push(e));
  const primeira = velha.carregar(); await resolver();
  velha.cancelar(); assert.equal(sinal.aborted, true);
  const nova = criarBusca('sol', async () => [lib()], async () => pagina([item('sol')]), e => novos.push(e));
  await nova.carregar(); const antes = estados.length;
  lote.ok(pagina([item('lua')], 100)); await primeira; await velha.carregar();
  assert.equal(estados.length, antes, 'resposta obsoleta não publica estado nem libera página antiga');
  assert.deepEqual(novos[novos.length - 1].itens?.map(i => i.Id), ['sol']);
});

test('Busca8: cancelar enquanto descobre bibliotecas impede iniciar busca antiga', async () => {
  const libs = pendente<Item[]>(); let chamadas = 0, publicacoes = 0;
  const busca = criarBusca('lua', () => libs.promessa, async () => { chamadas++; return pagina([]); }, () => { publicacoes++; });
  const p = busca.carregar(); busca.cancelar();
  libs.ok([lib()]); await p;
  assert.equal(chamadas, 0); assert.equal(publicacoes, 1);
});

test('Busca8: falha parcial conserva resultados e repete a biblioteca que falhou no mesmo início', async () => {
  let falhar = true, estado = buscaInicial;
  const chamadas: [string, number][] = [];
  const busca = criarBusca('lua', async () => [lib('A'), lib('B')], async (b, inicio) => {
    chamadas.push([b.Id, inicio]);
    if (b.Id === 'B' && falhar) throw new Error('offline');
    return pagina([item(b.Id)]);
  }, e => { estado = e; });
  await busca.carregar();
  assert.equal(estado.erro, true); assert.equal(estado.mais, true);
  assert.deepEqual(estado.itens?.map(i => i.Id), ['A']);
  falhar = false; await busca.carregar();
  assert.deepEqual(chamadas, [['A', 0], ['B', 0], ['B', 0]]);
  assert.deepEqual(estado.itens?.map(i => i.Id), ['A', 'B']);
  assert.equal(estado.erro, false); assert.equal(estado.mais, false);
});

test('Busca8: falha no lote seguinte mantém os títulos e tenta o mesmo cursor novamente', async () => {
  let estado = buscaInicial, falhar = true; const inicios: number[] = [];
  const busca = criarBusca('lua', async () => [lib()], async (_b, inicio) => {
    inicios.push(inicio);
    if (inicio > 0 && falhar) throw new Error('offline');
    return pagina([item(String(inicio))], 2);
  }, e => { estado = e; });
  await busca.carregar(); await busca.carregar();
  assert.deepEqual(estado.itens?.map(i => i.Id), ['0']); assert.equal(estado.erro, true);
  falhar = false; await busca.carregar();
  assert.deepEqual(inicios, [0, 1, 1]);
  assert.deepEqual(estado.itens?.map(i => i.Id), ['0', '1']);
});

test('Busca8: falha na descoberta de bibliotecas é recuperável', async () => {
  let vezes = 0, estado = buscaInicial;
  const busca = criarBusca('lua', async () => { if (++vezes === 1) throw new Error('offline'); return [lib()]; },
    async () => pagina([item('1')]), e => { estado = e; });
  await busca.carregar(); assert.equal(estado.erro, true);
  await busca.carregar(); assert.equal(vezes, 2); assert.equal(estado.erro, false); assert.equal(estado.itens?.length, 1);
});

test('Busca8: fim vazio, ausência de bibliotecas e página vazia encerram sem loop', async () => {
  for (const bibliotecas of [[], [lib()]]) {
    let chamadas = 0, estado = buscaInicial;
    const busca = criarBusca('lua', async () => bibliotecas, async () => { chamadas++; return pagina([], 99); }, e => { estado = e; });
    await busca.carregar(); await busca.carregar();
    assert.equal(chamadas, bibliotecas.length); assert.deepEqual(estado.itens, []);
    assert.equal(estado.mais, false); assert.equal(estado.erro, false);
  }
});

const s: Sessao = { tipo: 'jellyfin', servidor: 'https://jf.example.invalid', token: 'ficticio', usuarioId: 'u', nome: 'Teste' };
async function comFetch(responder: (u: URL, init?: RequestInit) => Response | Promise<Response>, executar: () => Promise<void>) {
  const anterior = globalThis.fetch, armazenamento = Object.getOwnPropertyDescriptor(globalThis, 'localStorage');
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: { getItem: () => 'aparelho-ficticio' } });
  globalThis.fetch = async (u, init) => responder(new URL(String(u)), init);
  try { await executar(); } finally {
    globalThis.fetch = anterior;
    if (armazenamento) Object.defineProperty(globalThis, 'localStorage', armazenamento);
    else Reflect.deleteProperty(globalThis, 'localStorage');
  }
}
const json = (d: unknown, status = 200) => new Response(JSON.stringify(d), { status });

test('Busca8: contrato Jellyfin encaminha início, limite, termo, total e sinal sem rede', async () => {
  const controle = new AbortController();
  await comFetch((u, init) => {
    assert.equal(u.searchParams.get('StartIndex'), '30'); assert.equal(u.searchParams.get('limit'), '15');
    assert.equal(u.searchParams.get('EnableTotalRecordCount'), 'true');
    assert.equal(u.searchParams.get('parentId'), 'biblioteca'); assert.equal(u.searchParams.get('searchTerm'), 'ação & lua');
    assert.equal(init?.signal, controle.signal); assert.match(String((init?.headers as any).Authorization), /Token="ficticio"/);
    return json(pagina([item('31')], 67));
  }, async () => {
    assert.deepEqual(await buscar(s, 'ação & lua', 'biblioteca', 30, 15, controle.signal), pagina([item('31')], 67));
  });
});

test('Busca8: contrato Plex usa o total recebido dos hubs e não oferece próxima página', async () => {
  const plex = { ...s, tipo: 'plex' as const, servidor: 'https://pms.example.invalid' }, controle = new AbortController(); let chamadas = 0;
  await comFetch((u, init) => {
    chamadas++;
    assert.equal(u.pathname, '/hubs/search'); assert.equal(u.searchParams.get('sectionId'), 'B');
    assert.equal(u.searchParams.get('limit'), '30'); assert.equal(init?.signal, controle.signal);
    return json({ MediaContainer: { totalSize: 999, Hub: [
      { size: 99, Metadata: [{ ratingKey: '1', type: 'movie', title: 'Lua' }, { ratingKey: '9', type: 'episode' }] },
      { Metadata: [{ ratingKey: '1', type: 'movie', title: 'Lua' }], Directory: [{ ratingKey: '2', title: 'Sol', childCount: 1 }] },
    ] } });
  }, async () => {
    const r = await apiDe(plex).buscar(plex, 'lua', 'B', 0, 30, controle.signal);
    assert.deepEqual(r.Items.map(i => i.Id), ['1', '2']); assert.equal(r.TotalRecordCount, 2);
    assert.deepEqual(await apiDe(plex).buscar(plex, 'lua', 'B', 2), pagina([]));
    assert.equal(chamadas, 1);
  });
});

test('Busca8: os dois adaptadores propagam cancelamento e notificam 401 na busca paginada', async () => {
  for (const tipo of ['jellyfin', 'plex'] as const) {
    const sessao = { ...s, tipo }, controle = new AbortController(); controle.abort();
    await comFetch(async (_u, init) => {
      assert.equal(init?.signal?.aborted, true); throw new DOMException('cancelada', 'AbortError');
    }, async () => { await assert.rejects(buscar(sessao, 'lua', 'A', 0, 30, controle.signal), { name: 'AbortError' }); });
    let expirou = 0; quandoExpirar(() => { expirou++; });
    try {
      await comFetch(() => json({}, 401), async () => { await assert.rejects(buscar(sessao, 'lua', 'A', 0)); });
      assert.equal(expirou, 1);
    } finally { quandoExpirar(null); }
    await comFetch(() => json({}, 503), async () => { await assert.rejects(buscar(sessao, 'lua', 'A', 0), /503/); });
  }
});

// Componentes reais com portas em memória. Não usa servidor, navegador nem temporizadores reais.
function tela(responder: (inicio: number, termo: string, sinal: AbortSignal) => Promise<ReturnType<typeof pagina>>, comSeerr = false) {
  const timers = new Map<number, () => void>(); let proximo = 0, observador: any;
  class Observador {
    callback: (e: { isIntersecting: boolean }[]) => void;
    desconectado = false;
    constructor(callback: (e: { isIntersecting: boolean }[]) => void, opcoes: any) {
      assert.equal(opcoes.rootMargin, '400px 0px'); this.callback = callback; observador = this;
    }
    observe() {} disconnect() { this.desconectado = true; }
  }
  const b = bancada('../src/telas/Busca.tsx', 'Busca', {
    '../api/servidor.ts': { bibliotecasDeVideo: async () => [lib()], buscar: (_s: any, termo: string, _b: string, inicio: number, _limite: number, sinal: AbortSignal) => responder(inicio, termo, sinal),
      capa: () => '', hashDe: () => '' },
    '../api/seerr': { temSeerr: async () => comSeerr, buscar: async () => { throw new Error('offline'); } },
    '../cor/paleta': { usePaleta() {} }, '../comp/Cartoes': { nota: () => '' },
    './busca-progressiva.ts': { criarBusca, buscaInicial },
  }, { setTimeout: (f: () => void) => { const id = ++proximo; timers.set(id, f); return id; },
    clearTimeout: (id: number) => timers.delete(id), IntersectionObserver: Observador });
  const render = () => {
    const v = b.render('Busca', { s });
    for (const n of nos(v)) if (n.ref) n.ref.current = { focus() {} };
    return v;
  };
  const relogio = () => { for (const [id, f] of [...timers]) { timers.delete(id); f(); } };
  const digitar = (valor: string) => nos(render(), 'input')[0].props.onInput({ target: { value: valor } });
  return { b, render, digitar, relogio, observar: () => observador };
}

test('Busca8: tela distingue vazio, uma letra, sem resultado e erro com repetição', async () => {
  let falhar = true;
  const t = tela(async () => { if (falhar) throw new Error('offline'); return pagina([]); });
  assert.match(texto(t.render()), /Qual história/); t.b.efeitos(); await resolver();
  t.digitar('l'); assert.match(texto(t.render()), /Digite mais uma letra/);
  t.digitar('lua'); t.render(); t.b.efeitos(); t.relogio(); await resolver();
  let v = t.render();
  assert.match(texto(v), /Não deu para buscar/); assert.doesNotMatch(texto(v), /Nada encontrado/);
  falhar = false; nos(v, 'button').find(n => texto(n) === 'Tentar de novo').props.onClick();
  assert.doesNotMatch(texto(t.render()), /Nada encontrado/, 'repetição em andamento não vira estado sem resultado');
  await resolver();
  v = t.render(); assert.match(texto(v), /Nada encontrado para “lua”/); assert.doesNotMatch(texto(v), /Não deu/);
  t.b.desmontar();
});

test('Busca8: observador anexa próximo bloco, sinaliza carregamento e desliga no fim', async () => {
  const lote = pendente<ReturnType<typeof pagina>>(); const chamadas: number[] = [];
  const t = tela(async inicio => { chamadas.push(inicio); return inicio ? lote.promessa : pagina([item('1')], 2); });
  t.render(); t.b.efeitos(); await resolver();
  t.digitar('lua'); t.render(); t.b.efeitos(); t.relogio(); await resolver();
  t.render(); t.b.efeitos();
  const observador = t.observar(); assert.ok(observador);
  observador.callback([{ isIntersecting: true }]); observador.callback([{ isIntersecting: true }]); await resolver();
  assert.deepEqual(chamadas, [0, 1]);
  assert.match(texto(t.render()), /Buscando mais títulos/);
  lote.ok(pagina([item('2')], 2)); await resolver();
  const v = t.render(); t.b.efeitos();
  assert.equal(nos(v, 'ul')[0].props.children.length, 2);
  assert.equal(observador.desconectado, true);
  assert.doesNotMatch(texto(v), /Buscando mais títulos/); t.b.desmontar();
});

test('Busca8: tela repete Seerr após erro e evita vazio enganoso', async () => {
  const t = tela(async () => pagina([]), true);
  t.render(); t.b.efeitos(); await resolver();
  t.digitar('lua'); t.render(); t.b.efeitos(); t.relogio(); await resolver();
  let v = t.render();
  assert.match(texto(v), /Pedidos indisponíveis/); assert.doesNotMatch(texto(v), /Nada encontrado/);
  nos(v, 'button').find(n => texto(n) === 'Tentar de novo').props.onClick();
  t.render(); t.b.efeitos(); v = t.render();
  assert.doesNotMatch(texto(v), /Pedidos indisponíveis/);
  t.relogio(); await resolver(); assert.match(texto(t.render()), /Pedidos indisponíveis/); t.b.desmontar();
});

test('Busca8: digitar outro termo aborta imediatamente, antes do debounce, e descarta resultado antigo', async () => {
  const lote = pendente<ReturnType<typeof pagina>>(); let sinalAntigo!: AbortSignal;
  const termos: string[] = [];
  const t = tela(async (_inicio, termo, sinal) => {
    termos.push(termo);
    if (termo === 'lua') { sinalAntigo = sinal; return lote.promessa; }
    return pagina([item('sol', 'Sol da manhã')]);
  });
  t.render(); t.b.efeitos(); await resolver();
  t.digitar('lua'); t.render(); t.b.efeitos(); t.relogio(); await resolver();
  assert.equal(sinalAntigo.aborted, false);
  t.digitar('sol'); assert.equal(sinalAntigo.aborted, true);
  assert.deepEqual(termos, ['lua'], 'o novo termo ainda aguarda os 300 ms');
  lote.ok(pagina([item('lua', 'Lua antiga')])); await resolver();
  assert.doesNotMatch(texto(t.render()), /Lua antiga/);
  t.b.efeitos(); t.relogio(); await resolver();
  assert.match(texto(t.render()), /Sol da manhã/); assert.deepEqual(termos, ['lua', 'sol']); t.b.desmontar();
});

test('Busca8: estados usam o texto principal dos temas, foco, alvo de 44px e redução de movimento', () => {
  const css = readFileSync(new URL('../src/telas/busca.css', import.meta.url), 'utf8');
  assert.match(css, /\.busca-estado\s*\{[^}]*color: var\(--hs-texto\)/);
  assert.match(css, /\.busca-fim\s*\{[^}]*min-height: 44px[^}]*color: var\(--hs-texto\)/);
  assert.match(css, /\.busca-estado \.pilula\s*\{[^}]*min-height: 44px/);
  assert.match(css, /\.busca-estado \.pilula:focus-visible\s*\{[^}]*outline: 2px/);
  assert.match(css, /@media \(prefers-reduced-motion: reduce\)/);
});
