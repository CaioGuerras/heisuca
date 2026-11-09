// H2: a arte do cartão tocado vira o fundo do título (anim/continuidade.ts) e o resto da troca segue o H3
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

class El { cls = ''; props = new Map<string, string>(); conectado = true; filhos: Record<string, El | null> = {}; pais: Record<string, El | null> = {};
  rect = { width: 100, top: 10, bottom: 160 };
  get isConnected() { return this.conectado; }
  closest(s: string) { return this.pais[s] ?? null; }
  querySelector(s: string) { return this.filhos[s] ?? null; }
  getBoundingClientRect() { return this.rect; }
  style = { setProperty: (k: string, v: string) => this.props.set(k, v), removeProperty: (k: string) => this.props.delete(k) };
}
const g = globalThis as any;
g.Element = El; g.window = { matchMedia: () => ({ matches: false }) }; g.innerHeight = 800;

const { lembrarToques, trocarComArte } = await import('../src/anim/continuidade.ts');

function cenario(comVT: boolean) {
  const ouvintes: ((e: unknown) => void)[] = [], classes = new Set<string>(), log: string[] = [];
  let cb: (() => Promise<void>) | null = null;
  const doc: any = { hidden: false, documentElement: { classList: { add: (c: string) => classes.add(c), remove: (c: string) => classes.delete(c) } },
    addEventListener: (_: string, f: (e: unknown) => void) => ouvintes.push(f), removeEventListener: () => undefined, querySelector: () => null };
  if (comVT) doc.startViewTransition = (f: () => Promise<void>) => { cb = f; log.push('vt'); return { finished: new Promise<void>(() => undefined) }; };
  const arte = new El(), cartao = new El(), alvo = new El();
  cartao.filhos['.cartao-arte'] = arte; alvo.pais['.cartao'] = cartao;
  lembrarToques(doc);
  return { doc, arte, alvo, classes, log, tocar: () => ouvintes.forEach(f => f({ target: alvo })), rodar: () => cb!() };
}

test('sem View Transitions a troca fica com a saída do H3', () => {
  const c = cenario(false); c.tocar();
  let n = 0;
  assert.equal(trocarComArte(() => n++, c.doc), false);
  assert.equal(n, 0);
});

test('toque recente num cartão: a arte leva o nome, que passa para o título depois da foto', async () => {
  const c = cenario(true); c.tocar();
  let n = 0;
  assert.equal(trocarComArte(() => n++, c.doc), true);
  assert.equal(c.arte.props.get('view-transition-name'), 'hs-arte');
  assert.equal(n, 0, 'a rota só troca dentro da transição');
  await c.rodar();
  assert.equal(n, 1);
  assert.equal(c.arte.props.has('view-transition-name'), false, 'nunca dois elementos com o mesmo nome');
  assert.ok(c.classes.has('hs-vt'));
});

test('sem toque recente (link, voltar do navegador) não há arte compartilhada', () => {
  const c = cenario(true);
  assert.equal(trocarComArte(() => undefined, c.doc), false);
  c.tocar(); c.alvo.pais['.cartao']!.filhos['.cartao-arte']!.rect = { width: 100, top: 900, bottom: 1000 };
  assert.equal(trocarComArte(() => undefined, c.doc), false, 'arte fora da tela não voa');
});

test('o nome só existe durante a transição e o CSS segue o chrome88', () => {
  const css = readFileSync(new URL('../src/estilo/transicoes.css', import.meta.url), 'utf8');
  assert.match(css, /html\.hs-vt \.titulo-arte \{ view-transition-name: hs-arte; \}/);
  assert.match(css, /::view-transition-new\(root\) \{ animation: none; \}/);
  assert.doesNotMatch(css, /linear\(/);
});

test('no cartão voa só a imagem (a nota e os selos ficam no lugar)', async () => {
  const c = cenario(true), img = new El();
  c.arte.filhos['.img'] = img; c.tocar();
  assert.equal(trocarComArte(() => undefined, c.doc), true);
  assert.equal(img.props.get('view-transition-name'), 'hs-arte');
  assert.equal(c.arte.props.has('view-transition-name'), false);
});
