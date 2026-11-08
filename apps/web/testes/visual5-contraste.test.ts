import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { runInNewContext } from 'node:vm';
import ts from 'typescript';
import postcss from 'postcss';
import type { Paleta } from '../src/cor/paleta.ts';
import type { RGB } from '../src/cor/oklch.ts';

// Paleta real em contexto isolado para os dois temas; não monta hooks nem acessa rede/DOM.
const ler = (p: string) => readFileSync(new URL(p, import.meta.url), 'utf8');
const nativo = createRequire(import.meta.url);
const base = postcss.parse(ler('../src/estilo/base.css'));
const cartoes = postcss.parse(ler('../src/comp/cartoes.css'));
const titulo = postcss.parse(ler('../src/telas/titulo.css'));
function propriedade(css: typeof base, seletor: string, chave: string): string {
  let valor = '';
  css.walkRules(seletor, r => { r.walkDecls(chave, d => { valor = d.value; }); });
  return valor;
}
for (const tema of ['hisui', 'shikkoku']) test(`Visual5: novos nomes de biblioteca e faixas de áudio mantêm AA em ${tema}`, () => {
  const tokens: Record<string, string> = {};
  base.walkRules(`[data-tema="${tema}"]`, r => { r.walkDecls(d => { tokens[d.prop] = d.value; }); });
  const cache = new Map<string, any>();
  function carregar(arquivo: URL): any {
    if (cache.has(arquivo.href)) return cache.get(arquivo.href);
    const m = { exports: {} };
    const js = ts.transpileModule(readFileSync(arquivo, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
    }).outputText;
    runInNewContext(js, { module: m, exports: m.exports,
      document: { documentElement: { dataset: { tema } } },
      getComputedStyle: () => ({ getPropertyValue: (n: string) => tokens[n] || '' }),
      require: (n: string) => n === 'preact/hooks' ? { useEffect: () => { throw new Error('hook fora do cálculo'); } }
        : n.startsWith('.') ? carregar(new URL(n + '.ts', arquivo)) : nativo(n),
    });
    cache.set(arquivo.href, m.exports);
    return m.exports;
  }
  const { paletaDe }: { paletaDe: (base: RGB | null) => Paleta } = carregar(new URL('../src/cor/paleta.ts', import.meta.url));
  const { contraste }: { contraste: (a: RGB, b: RGB) => number } = carregar(new URL('../src/cor/oklch.ts', import.meta.url));
  assert.equal(propriedade(cartoes, '.cartao-biblioteca-legenda', 'background'), 'var(--hs-pagina)');
  assert.equal(propriedade(cartoes, '.cartao-biblioteca-legenda', 'color'), 'var(--hs-texto)');
  assert.equal(propriedade(titulo, '.titulo-midia-faixa h4', 'color'), 'var(--hs-texto-2)');
  const match = propriedade(titulo, '.titulo-midia-cartao', 'background').match(/^rgba\(var\(--hs-superficie-rgb\), ([.\d]+)\)$/);
  assert.ok(match);
  const alfa = Number(match[1]);
  const bases: (RGB | null)[] = [null];
  for (const r of [0, 32, 64, 96, 128, 160, 192, 224, 255])
    for (const g of [0, 32, 64, 96, 128, 160, 192, 224, 255])
      for (const b of [0, 32, 64, 96, 128, 160, 192, 224, 255]) bases.push([r, g, b]);
  let biblioteca = Infinity, faixa = Infinity;
  for (const cor of bases) {
    const p = paletaDe(cor);
    const superficie = p.superficie.map((v, k) => v * alfa + p.pagina[k] * (1 - alfa)) as RGB;
    biblioteca = Math.min(biblioteca, contraste(p.texto, p.pagina));
    faixa = Math.min(faixa, contraste(p.texto2, superficie));
  }
  assert.ok(biblioteca >= 4.5, String(biblioteca));
  assert.ok(faixa >= 4.5, String(faixa));
  console.log(`${tema} | 730 paletas | biblioteca ${biblioteca.toFixed(2)}:1 | faixa de áudio ${faixa.toFixed(2)}:1`);
});
