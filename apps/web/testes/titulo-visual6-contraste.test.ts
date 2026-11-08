import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { runInNewContext } from 'node:vm';
import ts from 'typescript';
import postcss from 'postcss';
import type { RGB } from '../src/cor/oklch.ts';
import type { Paleta } from '../src/cor/paleta.ts';

const ler = (p: string) => readFileSync(new URL(p, import.meta.url), 'utf8');
const tokens: Record<string, string> = {};
postcss.parse(ler('../src/estilo/base.css')).walkRules('[data-tema="hisui"]', r => {
  r.walkDecls(d => { tokens[d.prop] = d.value; });
});
const nativo = createRequire(import.meta.url), cache = new Map<string, any>();
function carregar(arquivo: URL): any {
  if (cache.has(arquivo.href)) return cache.get(arquivo.href);
  const m = { exports: {} };
  const js = ts.transpileModule(readFileSync(arquivo, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText;
  runInNewContext(js, { module: m, exports: m.exports,
    document: { documentElement: { dataset: { tema: 'hisui' } } },
    getComputedStyle: () => ({ getPropertyValue: (n: string) => tokens[n] || '' }),
    require: (n: string) => n === 'preact/hooks' ? { useEffect: () => { throw new Error('hook fora do cálculo'); } }
      : n.startsWith('.') ? carregar(new URL(n + '.ts', arquivo)) : nativo(n),
  });
  cache.set(arquivo.href, m.exports);
  return m.exports;
}
const { paletaDe }: { paletaDe: (base: RGB | null) => Paleta } = carregar(new URL('../src/cor/paleta.ts', import.meta.url));
const { contraste, hex }: { contraste: (a: RGB, b: RGB) => number; hex: (h: string) => RGB } = carregar(new URL('../src/cor/oklch.ts', import.meta.url));

test('B4: estrela do Título Hisui mantém pelo menos 3:1 nas paletas reais e extremas', () => {
  let estrela = '';
  postcss.parse(ler('../src/telas/titulo.css')).walkRules(r => {
    if (r.parent?.type === 'root' && ['.titulo-estrela', '[data-tema="hisui"] .titulo-estrela'].includes(r.selector))
      r.walkDecls('color', d => { estrela = d.value; });
  });
  // Média de faixas inferiores de pôsteres reais em site_capturas/cel_roxo_7_inicio_inteira.png.
  // Retângulos e procedimento de coleta estão no handoff J6; o teste não depende de capturas externas.
  const reais: [string, RGB][] = [
    ['Ranma1/2', [117, 56, 30]], ['Black Clover', [118, 104, 77]],
    ['A Wild Last Boss', [69, 65, 96]], ['Ghost in the Shell', [25, 44, 84]],
    ['Mamma Mia', [128, 110, 91]], ['50/50', [135, 126, 115]],
    ['Missão Resgate', [112, 143, 159]], ['mãe!', [92, 80, 67]],
  ];
  const bases: (RGB | null)[] = [null, ...reais.map(([, rgb]) => rgb)];
  for (const r of [0, 32, 64, 96, 128, 160, 192, 224, 255])
    for (const g of [0, 32, 64, 96, 128, 160, 192, 224, 255])
      for (const b of [0, 32, 64, 96, 128, 160, 192, 224, 255]) bases.push([r, g, b]);
  let minimo = Infinity, pior: RGB | null = null, pagina: RGB = [0, 0, 0];
  for (const base of bases) {
    const p = paletaDe(base), razao = contraste(hex(estrela), p.pagina);
    if (razao < minimo) { minimo = razao; pior = base; pagina = p.pagina; }
  }
  console.log(`B4 | ${bases.length} paletas (8 pôsteres reais + 729 RGB + sem hash) | estrela ${estrela} | mínimo ${minimo.toFixed(6)}:1 | base ${pior} → página ${pagina}`);
  assert.ok(minimo >= 3, `contraste do ícone: ${minimo}`);
  for (const [nome, base] of reais) console.log(`B4 | ${nome} | página ${paletaDe(base).pagina} | ${contraste(hex(estrela), paletaDe(base).pagina).toFixed(6)}:1`);
});
