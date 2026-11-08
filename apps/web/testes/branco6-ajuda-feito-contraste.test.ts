import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import postcss from 'postcss';

// J9-10 (Branco 6, 08/11): passo "Feito" do Como usar sem opacity no corpo; a cor do texto mantém AA (≥ 4,5:1, texto de
// 14,5 px) sobre a superfície do cartão nos dois temas. Cores lidas do CSS real; sem DOM.
const ler = (p: string) => postcss.parse(readFileSync(new URL(p, import.meta.url), 'utf8'));
const base = ler('../src/estilo/base.css'), paginas = ler('../src/telas/paginas.css');
const rgb = (h: string) => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const lum = (c: number[]) => c.map(v => v / 255).map(v => v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4)
  .reduce((s, v, i) => s + v * [0.2126, 0.7152, 0.0722][i], 0);
const contraste = (a: string, b: string) => { const [x, y] = [lum(rgb(a)), lum(rgb(b))].sort((m, n) => n - m); return (x + .05) / (y + .05); };
function decl(css: postcss.Root, seletor: string, prop: string) {
  let v = ''; css.walkRules(r => { if (r.selector === seletor) r.walkDecls(prop, d => { v = d.value; }); }); return v;
}

test('Branco6: passo Feito não usa opacity no corpo nem no texto', () => {
  paginas.walkRules(r => {
    if (/\.ajuda-passo\.feito/.test(r.selector)) r.walkDecls('opacity', d => assert.fail(`${r.selector} { opacity: ${d.value} }`));
  });
  assert.equal(decl(paginas, '.ajuda-passo.feito .ajuda-texto', 'color'), 'var(--ajuda-feito-texto, var(--hs-texto-2))');
});

for (const tema of ['shikkoku', 'hisui']) test(`Branco6: texto do passo Feito ≥ 4,5:1 no ${tema}`, () => {
  const fundo = decl(base, `[data-tema="${tema}"]`, '--hs-tema-cor-superficie');
  const cor = decl(paginas, `[data-tema="${tema}"] .ajuda-passo.feito`, '--ajuda-feito-texto');
  const t2 = decl(base, `[data-tema="${tema}"]`, '--hs-tema-cor-texto-2');
  assert.match(cor, /^#[0-9a-f]{6}$/);
  const c = contraste(cor, fundo), c2 = contraste(t2, fundo);
  assert.ok(c >= 4.5, `${cor} em ${fundo} = ${c.toFixed(2)}:1`);
  assert.ok(c < c2, `ainda um tom abaixo do texto-2 (${c.toFixed(2)} < ${c2.toFixed(2)})`);  // "Feito" continua discreto
});
