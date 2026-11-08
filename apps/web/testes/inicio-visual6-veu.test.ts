import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import postcss from 'postcss';

const css = postcss.parse(readFileSync(new URL('../src/telas/inicio.css', import.meta.url), 'utf8'));

// Mede a composição do CSS real, sem navegador. Não pretende homologar o recorte da foto.
function veu(largura: number, altura: number, x: number, y: number): number {
  let fundo = '', prioridade = -1;
  css.walkRules(regra => {
    if (!['.destaque-artes::after', '[data-tema="hisui"] .destaque-artes::after'].includes(regra.selector)) return;
    const pai = regra.parent;
    if (pai?.type === 'atrule') {
      if (pai.name !== 'media') return;
      const min = pai.params.match(/min-width:\s*(\d+)px/), max = pai.params.match(/max-width:\s*(\d+)px/);
      if (min && largura < Number(min[1]) || max && largura > Number(max[1])) return;
    }
    const p = regra.selector.includes('data-tema') ? 1 : 0;
    if (p >= prioridade) regra.walkDecls('background', d => { fundo = d.value; prioridade = p; });
  });
  let livre = 1;
  for (const camada of postcss.list.comma(fundo)) {
    const [direcao, ...cores] = postcss.list.comma(camada.slice('linear-gradient('.length, -1));
    assert.ok(direcao === '90deg' || direcao === '180deg');
    const tamanho = direcao === '90deg' ? largura : altura, pos = direcao === '90deg' ? x : y;
    const stops = cores.map((cor, i) => {
      const m = cor.match(/^(.*?)(?:\s+(calc\(100% - (\d+)px\)|([\d.]+)%))?$/)!;
      const p = m[3] ? tamanho - Number(m[3]) : m[4] ? tamanho * Number(m[4]) / 100 : i === 0 ? 0 : tamanho;
      const a = m[1] === 'var(--hs-pagina)' ? 1 : m[1] === 'var(--hs-pagina-0)' ? 0
        : Number(m[1].match(/^rgba\(var\(--hs-pagina-rgb\),\s*([\d.]+)\)$/)?.[1]);
      assert.ok(Number.isFinite(a), `stop fora da cor da página: ${cor}`);
      return { p, a };
    });
    let a = stops[stops.length - 1].a;
    if (pos <= stops[0].p) a = stops[0].a;
    else for (let k = 1; k < stops.length; k++) if (pos <= stops[k].p) {
      const antes = stops[k - 1], depois = stops[k];
      a = antes.a + (depois.a - antes.a) * (pos - antes.p) / (depois.p - antes.p);
      break;
    }
    livre *= 1 - a;
  }
  return 1 - livre;
}

test('A1: Hisui dissolve topo e direita na cor da página, inclusive a 360/412 px', () => {
  for (const w of [360, 412, 768, 1440]) for (const h of [560, 720, 900]) {
    assert.equal(veu(w, h, w * .7, 0), 1, `topo: ${w}×${h}`);
    assert.ok(veu(w, h, w * .7, h * .08) >= .79, `topo curto: ${w}×${h}`);
    assert.ok(veu(w, h, w * .7, h * .12) >= .59, `faixa exposta: ${w}×${h}`);
    assert.equal(veu(w, h, w, h * .3), 1, `borda direita: ${w}×${h}`);
    assert.ok(veu(w, h, w * .98, h * .3) >= .79, `direita curta: ${w}×${h}`);
    assert.ok(veu(w, h, w * .7, h * .3) <= .02, `centro lavado: ${w}×${h}`);
  }
});
