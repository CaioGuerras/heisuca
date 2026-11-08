import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import postcss from 'postcss';

// Rodada 9: vão arte→logo no celular. Lê o CSS real, sem navegador.
const css = postcss.parse(readFileSync(new URL('../src/telas/inicio.css', import.meta.url), 'utf8'));
function decl(seletor: string, prop: string, media: string | null): string | undefined {
  let valor: string | undefined;
  css.walkRules(regra => {
    if (regra.selector !== seletor) return;
    const pai = regra.parent as any;
    if ((pai.type === 'atrule' ? pai.params : null) !== media) return;
    regra.walkDecls(prop, d => { valor = d.value; });
  });
  return valor;
}
const CEL = '(max-width: 600px)';
const H = '[data-tema="hisui"] ';

// Altura de conteúdo do texto no celular: casa 56 + 6, meta 11 × 1,5, sinopse 2 × 11 × 1,45, dois vãos de 6 (3 filhos).
const conteudo = 56 + 6 + 11 * 1.5 + 2 * 11 * 1.45 + 2 * 6;
test('celular: a folga do texto acima da logo cai de ~48 px para ≤ 6 px', () => {
  const min = parseFloat(decl('.destaque-texto', 'min-height', CEL)!);
  assert.ok(min >= conteudo && min - conteudo <= 6, `min-height ${min} vs conteúdo ${conteudo}`);
  assert.ok(parseFloat(decl('.destaque-texto', 'margin-top', CEL)!) < 0, 'Shikkoku: logo sobe sobre o pé dissolvido');
});

test('celular: min-height do destaque acompanha o texto (pontos → "Continuar" igual à v8)', () => {
  const folga = (extra: number, mt: number, minTexto: number) => extra - (mt + minTexto + 38 + 6);
  assert.equal(folga(230, 8, 170), 8);   // v8
  const mt = parseFloat(decl('.destaque-texto', 'margin-top', CEL)!), mn = parseFloat(decl('.destaque-texto', 'min-height', CEL)!);
  assert.equal(decl('.destaque', 'min-height', CEL), `calc(62.5vw + ${8 + mt + mn + 38 + 6}px)`);
});
