import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import postcss from 'postcss';

// Rodada 11 (Visão): anos com meia-risca, grade do Título sem cartão crescendo, vazio dos Favoritos no computador,
// anel do episódio atual por dentro e escala do foco só com ponteiro fino. Lê o CSS/TSX reais.
const ler = (p: string) => readFileSync(new URL(p, import.meta.url), 'utf8');
const cartoes = postcss.parse(ler('../src/comp/cartoes.css'));
const titulo = postcss.parse(ler('../src/telas/titulo.css'));
const favoritos = postcss.parse(ler('../src/telas/favoritos.css'));
const HOVER = '(hover: hover) and (pointer: fine)';

function decl(css: postcss.Root, seletor: string, prop: string, media: string | null): string | undefined {
  let valor: string | undefined;
  css.walkRules(regra => {
    if (!regra.selectors.includes(seletor)) return;
    const pai = regra.parent as any;
    if ((pai.type === 'atrule' ? pai.params : null) !== media) return;
    regra.walkDecls(prop, d => { valor = d.value; });
  });
  return valor;
}

// anos() sai do Cartoes.tsx real (o .tsx importa CSS e não roda no node): tira os tipos e avalia só a função.
function carregarAnos(): (i: Record<string, unknown>) => string {
  const fonte = ler('../src/comp/Cartoes.tsx');
  const m = /export function anos\(i: Item\): string \{([\s\S]*?)\n\}/.exec(fonte);
  assert.ok(m, 'anos() no Cartoes.tsx');
  return new Function('i', m![1]) as (i: Record<string, unknown>) => string;
}

test('anos: série com fim usa meia-risca sem espaços ("2023–2026"); ano único e filme ficam como estão', () => {
  const anos = carregarAnos();
  assert.equal(anos({ Type: 'Series', ProductionYear: 2023, EndDate: '2026-06-01T00:00:00Z' }), '2023–2026');
  assert.equal(anos({ Type: 'Series', ProductionYear: 2020, EndDate: '2020-12-01T00:00:00Z' }), '2020');
  assert.equal(anos({ Type: 'Series', ProductionYear: 2019 }), '2019');
  assert.equal(anos({ Type: 'Movie', ProductionYear: 2007, EndDate: '2010-01-01T00:00:00Z' }), '2007');
  assert.equal(anos({ Type: 'Movie' }), '');
  assert.doesNotMatch(anos({ Type: 'Series', ProductionYear: 1997, EndDate: '1998-06-01T00:00:00Z' }), / |-/);
});

test('grade da coleção no Título: o cartão não cresce (só a arte se ergue, com ponteiro fino) e o foco tem anel', () => {
  for (const sel of ['.titulo-grade button.cartao', '.titulo-grade button.cartao:hover', '.titulo-grade button.cartao:focus-visible'])
    assert.equal(decl(titulo, sel, 'transform', null), 'none', sel);
  assert.equal(decl(titulo, '.titulo-grade button.cartao:hover .cartao-arte', 'transform', HOVER), 'translateY(-4px)');
  assert.equal(decl(titulo, '.titulo-grade button.cartao:hover .cartao-arte', 'transform', null), undefined);
  assert.match(decl(titulo, '.titulo-grade button.cartao:focus-visible .cartao-arte', 'box-shadow', null)
    ?? decl(titulo, 'main .titulo-grade button.cartao:focus-visible .cartao-arte', 'box-shadow', null) ?? '', /4px var\(--hs-texto\)/);
  assert.match(decl(titulo, '.titulo-grade .cartao-arte', 'transform', '(prefers-reduced-motion: reduce)') || '', /none/);
});

test('Favoritos vazio: maior no computador (≥ 1024 px) e igual no celular', () => {
  const D = '(min-width: 1024px)';
  // celular intacto
  assert.equal(decl(favoritos, '.favoritos-vazio', 'max-width', null), '320px');
  assert.equal(decl(favoritos, '.favoritos-vazio', 'font-size', null), '15px');
  // computador
  assert.ok(parseFloat(decl(favoritos, '.favoritos-vazio', 'max-width', D) || '0') >= 440);
  assert.ok(parseFloat(decl(favoritos, '.favoritos-vazio', 'font-size', D) || '0') >= 18);
  assert.equal(decl(favoritos, '.favoritos-vazio > .icone', 'width', D), '60px'); // com !important: vence o style do Icone
  assert.ok(parseFloat(decl(favoritos, '.favoritos-vazio .pilula', 'min-height', D) || '0') >= 48);
});

test('anel do episódio atual por dentro da arte (não passa da margem da página)', () => {
  assert.equal(decl(titulo, '.titulo-ep.atual .titulo-ep-arte', 'box-shadow', null), undefined);
  const anel = decl(titulo, '.titulo-ep.atual .titulo-ep-arte::after', 'box-shadow', null) || '';
  assert.match(anel, /^inset 0 0 0 2px var\(--hs-texto\), inset 0 0 0 4px var\(--hs-pagina\)$/);
  assert.equal(decl(titulo, '.titulo-ep.atual .titulo-ep-arte::after', 'inset', null), '0');
  assert.equal(decl(titulo, '.titulo-ep.atual .titulo-ep-arte::after', 'pointer-events', null), 'none');
  assert.equal(decl(titulo, '.titulo-ep-arte', 'position', null), 'relative');
});

test('escala do cartão (hover e foco) só com ponteiro fino: nada de scale > 1 fora do bloco do hover', () => {
  cartoes.walkDecls('transform', d => {
    const s = parseFloat(/scale\(([\d.]+)\)/.exec(d.value)?.[1] || '0');
    if (s <= 1) return;
    const pai = (d.parent as any).parent;
    assert.equal(pai.type === 'atrule' ? pai.params : null, HOVER, `${(d.parent as any).selector}: ${d.value}`);
  });
  // o anel do teclado continua em qualquer aparelho
  assert.equal(decl(cartoes, '.cartao:focus-visible', 'outline', null), '2px solid var(--hs-texto)');
  // cartão largo com foco usa 1.03 (antes perdia para button.cartao:focus-visible e ia a 1.05)
  assert.equal(decl(cartoes, 'button.cartao-top10:focus-visible', 'transform', HOVER), 'translateY(-3px) scale(1.03)');
});
