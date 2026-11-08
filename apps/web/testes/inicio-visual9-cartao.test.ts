import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import postcss from 'postcss';

// Rodada 9: cartão do destaque no Hisui < 600 px e vão arte→logo no celular. Lê o CSS real, sem navegador.
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

test('Hisui < 600 px: arte vira cartão com margem, cantos do tema, sombra e sem véu', () => {
  assert.equal(decl(H + '.destaque-artes', 'width', CEL), '100%');            // dentro do padding = --hs-margem
  assert.equal(decl(H + '.destaque-artes', 'border-radius', CEL), 'var(--hs-raio-cartao)');
  assert.equal(decl(H + '.destaque-artes', 'box-shadow', CEL), 'var(--hs-sombra)');
  assert.equal(decl(H + '.destaque-artes::after', 'background', CEL), 'none');
  assert.match(decl(H + '.destaque', 'padding-top', CEL) || '', /--hs-topo-respiro/);   // começa abaixo do topo
  assert.equal(decl('.destaque', 'padding', null), '0 var(--hs-margem) 6px');
});

test('Hisui ≥ 600 px e Shikkoku ficam como estavam (véu fora do bloco do celular)', () => {
  for (const sel of ['.destaque-artes', '.destaque-artes::after', '.destaque'])
    for (const media of ['(min-width: 600px)', '(min-width: 1024px)'])
      assert.equal(decl(H + sel, 'border-radius', media), undefined);
  assert.match(decl(H + '.destaque-artes::after', 'background', '(min-width: 1024px)') || '', /linear-gradient/);
  assert.equal(decl('[data-tema="shikkoku"] .destaque-artes', 'border-radius', CEL), undefined);
});

// Altura de conteúdo do texto no celular: casa 56 + 6, meta 11 × 1,5, sinopse 2 × 11 × 1,45, dois vãos de 6 (3 filhos).
const conteudo = 56 + 6 + 11 * 1.5 + 2 * 11 * 1.45 + 2 * 6;
test('celular: a folga do texto acima da logo cai de ~48 px para ≤ 6 px', () => {
  const min = parseFloat(decl('.destaque-texto', 'min-height', CEL)!);
  assert.ok(min >= conteudo && min - conteudo <= 6, `min-height ${min} vs conteúdo ${conteudo}`);
  assert.ok(parseFloat(decl('.destaque-texto', 'margin-top', CEL)!) < 0, 'Shikkoku: logo sobe sobre o pé dissolvido');
  assert.equal(decl(H + '.destaque-texto', 'margin-top', CEL), '12px');
});

test('celular: min-height do destaque acompanha o texto (pontos → "Continuar" igual à v8)', () => {
  const folga = (extra: number, mt: number, minTexto: number) => extra - (mt + minTexto + 38 + 6);
  assert.equal(folga(230, 8, 170), 8);   // v8
  const mt = parseFloat(decl('.destaque-texto', 'margin-top', CEL)!), mn = parseFloat(decl('.destaque-texto', 'min-height', CEL)!);
  assert.equal(decl('.destaque', 'min-height', CEL), `calc(62.5vw + ${8 + mt + mn + 38 + 6}px)`);
  assert.equal(decl(H + '.destaque', 'min-height', CEL),
    `calc((100vw - var(--hs-margem) * 2) * .625 + var(--hs-topo-respiro) + ${48 + 8 + 12 + mn + 38 + 6}px)`);
});

test('celular 360/412: cartão não passa da tela (sem rolagem lateral)', () => {
  for (const w of [360, 412]) {
    const margem = 14, cartao = w - 2 * margem;
    assert.ok(cartao + 2 * margem <= w);
    assert.ok(cartao * 10 / 16 < w);   // proporção 16:10 mantida
  }
});
