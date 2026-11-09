// H4 (destaque: fusão + escada) e H5 (voltar sem perder o lugar: anim/rolagem.ts, e a arte de volta ao cartão)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const g = globalThis as any;
const rolou: number[] = [], ouvintes = new Map<string, Set<() => void>>();
g.window = { matchMedia: () => ({ matches: false }) }; g.innerHeight = 800;
g.scrollTo = (_: number, y: number) => { rolou.push(y); };
g.addEventListener = (e: string, f: () => void) => { if (!ouvintes.has(e)) ouvintes.set(e, new Set()); ouvintes.get(e)!.add(f); };
g.removeEventListener = (e: string, f: () => void) => { ouvintes.get(e)?.delete(f); };

const R = await import('../src/anim/rolagem.ts');
const { trocarDeVolta, acharAlvo } = await import('../src/anim/continuidade.ts');

const hist = (state: unknown = null) => ({ state, scrollRestoration: 'auto', replaceState(s: unknown) { this.state = s; } }) as any;

test('cada entrada ganha um id (sem perder o que já estava no state) e a rolagem fica manual', () => {
  const h = hist({ semRolar: true });
  R.iniciarRolagem(h);
  assert.equal(h.scrollRestoration, 'manual');
  assert.equal(typeof h.state.hs, 'string');
  assert.equal(h.state.semRolar, true);
});

test('sair grava a rolagem da entrada velha; voltar a ela devolve a lembrança', () => {
  const h = hist();
  R.iniciarRolagem(h); const home = h.state.hs;
  R.lembrar({ destaque: 'abc' });
  // o hashchange chega com a entrada nova já em vigor: grava a velha antes de entrar
  h.state = null;
  assert.equal(R.ehRetorno(h), false, 'tela aberta agora não é retorno');
  R.sairDaEntrada(640);
  assert.equal(R.entrarNaEntrada(h), undefined);
  // Voltar
  R.sairDaEntrada(0);
  h.state = { hs: home };
  assert.equal(R.ehRetorno(h), true);
  assert.deepEqual(R.entrarNaEntrada(h), { destaque: 'abc', y: 640 });
});

test('a rolagem volta assim que a página cresce, e o primeiro toque da pessoa para o restauro', async () => {
  const doc: any = { documentElement: { scrollHeight: 900 } };
  rolou.length = 0;
  const p = R.restaurarRolagem(1200, doc);
  await new Promise(r => setTimeout(r, 40));
  assert.ok(rolou.length >= 1 && rolou.every(y => y === 100), 'enquanto a página é curta, rola até onde dá');
  doc.documentElement.scrollHeight = 2400; await p;
  assert.equal(rolou.at(-1), 1200);
  assert.equal(ouvintes.get('wheel')?.size ?? 0, 0, 'sem ouvinte sobrando');

  rolou.length = 0; doc.documentElement.scrollHeight = 900;
  const q = R.restaurarRolagem(1200, doc);
  await new Promise(r => setTimeout(r, 20));
  for (const f of [...(ouvintes.get('touchstart') ?? [])]) f();
  await q; const n = rolou.length;
  await new Promise(r => setTimeout(r, 40));
  assert.equal(rolou.length, n, 'depois do toque não rola mais');
});

class El { props = new Map<string, string>(); attrs: Record<string, string> = {}; pai: El | null = null;
  rect = { width: 100, top: 10, bottom: 160, left: 0 };
  getAttribute(k: string) { return this.attrs[k] ?? null; }
  closest(s: string) { return s === '.img' ? this.pai : null; }
  getBoundingClientRect() { return this.rect; }
  style = { setProperty: (k: string, v: string) => this.props.set(k, v), removeProperty: (k: string) => this.props.delete(k) };
}
function cartao(src: string, top: number, left: number) {
  const moldura = new El(), img = new El();
  img.attrs.src = src; img.pai = moldura; moldura.rect = { width: 120, top, bottom: top + 180, left };
  return { moldura, img };
}

test('o alvo da volta é o cartão com a mesma imagem mais perto de onde estava', () => {
  const a = cartao('x.jpg', 300, 0), b = cartao('x.jpg', 520, 130), c = cartao('y.jpg', 520, 130), fora = cartao('x.jpg', 900, 130);
  const doc: any = { querySelectorAll: () => [a.img, b.img, c.img, fora.img] };
  assert.equal(acharAlvo({ src: 'x.jpg', top: 500, left: 130 }, doc), b.moldura);
  assert.equal(acharAlvo({ src: 'z.jpg', top: 500, left: 130 }, doc), null);
});

test('Voltar do título: a arte leva o nome, passa ao cartão de origem depois da foto e o nome sai no fim', async () => {
  const titulo = new El(), alvo = cartao('x.jpg', 410, 12);
  let cb: (() => Promise<void>) | null = null, acabar = () => undefined as void;
  const doc: any = { hidden: false, querySelector: (s: string) => s === '.titulo-arte' ? titulo : null,
    querySelectorAll: () => [alvo.img],
    startViewTransition: (f: () => Promise<void>) => { cb = f; return { finished: new Promise<void>(r => { acabar = r; }) }; } };
  // a home guardou de onde a arte saiu; a volta entra nessa entrada dentro do aplicar
  const h = hist(); R.iniciarRolagem(h); const home = h.state.hs;
  R.lembrar({ origem: { src: 'x.jpg', top: 400, left: 12 } });
  h.state = null; R.sairDaEntrada(0); R.entrarNaEntrada(h);
  let aplicou = 0;
  assert.equal(trocarDeVolta(() => { aplicou++; h.state = { hs: home }; R.entrarNaEntrada(h); }, doc, 100), true);
  assert.equal(titulo.props.get('view-transition-name'), 'hs-arte');
  await cb!();
  assert.equal(aplicou, 1);
  assert.equal(titulo.props.has('view-transition-name'), false, 'nunca dois elementos com o mesmo nome');
  assert.equal(alvo.moldura.props.get('view-transition-name'), 'hs-arte');
  acabar(); await new Promise(r => setTimeout(r));
  assert.equal(alvo.moldura.props.has('view-transition-name'), false);
});

test('de volta ao destaque voa a caixa das artes (com o degradê) e o texto ganha camada própria', async () => {
  const titulo = new El(), caixa = new El(), arteD = cartao('d.jpg', 0, 0), texto = new El();
  arteD.moldura.closest = (q: string) => q === '.destaque-artes' ? caixa : null;
  (caixa as any).classList = { contains: (c: string) => c === 'destaque-artes' };
  let cb: (() => Promise<void>) | null = null, acabar = () => undefined as void;
  const doc: any = { hidden: false, querySelector: (q: string) => q === '.titulo-arte' ? titulo : q === '.destaque-texto' ? texto : null,
    querySelectorAll: () => [arteD.img],
    startViewTransition: (f: () => Promise<void>) => { cb = f; return { finished: new Promise<void>(r => { acabar = r; }) }; } };
  const h = hist(); R.iniciarRolagem(h); const home = h.state.hs;
  R.lembrar({ origem: { src: 'd.jpg', top: 0, left: 0 } });
  h.state = null; R.sairDaEntrada(0); R.entrarNaEntrada(h);
  assert.equal(trocarDeVolta(() => { h.state = { hs: home }; R.entrarNaEntrada(h); }, doc, 100), true);
  await cb!();
  assert.equal(caixa.props.get('view-transition-name'), 'hs-arte');
  assert.equal(arteD.moldura.props.size, 0);
  assert.equal(texto.props.get('view-transition-name'), 'hs-destaque-texto');
  acabar(); await new Promise(r => setTimeout(r));
  assert.equal(caixa.props.size + texto.props.size, 0);
});

test('Voltar sem View Transitions, ou com o título fora da tela, fica com a saída do H3', () => {
  const titulo = new El();
  const doc: any = { hidden: false, querySelector: () => titulo, querySelectorAll: () => [] };
  assert.equal(trocarDeVolta(() => undefined, doc), false);
  doc.startViewTransition = () => ({ finished: Promise.resolve() });
  titulo.rect = { width: 100, top: -400, bottom: -10, left: 0 };
  assert.equal(trocarDeVolta(() => undefined, doc), false);
  assert.equal(titulo.props.size, 0);
});

test('H4: a arte do destaque dissolve e assenta; o texto entra em escada; de volta, nada entra de novo', () => {
  const css = readFileSync(new URL('../src/telas/inicio.css', import.meta.url), 'utf8');
  assert.match(css, /\.destaque-arte\.atual \{[^}]*destaque-revela var\(--m-grande\)[^}]*destaque-aproxima 900ms var\(--c-entra\)/);
  assert.match(css, /@keyframes destaque-aproxima \{ from \{ transform: scale\(1\.04\); \} \}/);
  assert.match(css, /\.destaque-meta \{ animation-delay: calc\(var\(--m-sobrepor\) \+ var\(--m-escada\)\); \}/);
  assert.match(css, /\.destaque-sinopse \{ animation-delay: calc\(var\(--m-sobrepor\) \+ var\(--m-escada\) \* 2\); \}/);
  assert.match(css, /\.destaque\.de-volta \.destaque-sinopse \{ animation: none; \}/);
  assert.doesNotMatch(css, /\.destaque-texto \{[^}]*animation/, 'o bloco inteiro não anima mais junto');
  assert.match(css, /reduce\) \{\s*\.destaque-arte\.atual, \.destaque-casa, \.destaque-meta, \.destaque-sinopse \{ animation: none !important; \}/);
  assert.doesNotMatch(css, /linear\(/);
});
