import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import postcss from 'postcss';

// Rodada 10 (Visão): vão do cartão ampliado e páginas de episódios junto do seletor de temporada. Lê o CSS/TSX reais.
const ler = (p: string) => readFileSync(new URL(p, import.meta.url), 'utf8');
const cartoes = postcss.parse(ler('../src/comp/cartoes.css'));
const titulo = postcss.parse(ler('../src/telas/titulo.css'));
const base = postcss.parse(ler('../src/estilo/base.css'));

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
const px = (v: string | undefined) => parseFloat(v || 'NaN');

test('cartão largo ampliado deixa ≥ 4 px até o vizinho em todo corte (1º da fileira cresce só para a direita)', () => {
  const HOVER = '(hover: hover) and (pointer: fine)';
  const escala = decl(cartoes, 'button.cartao-paisagem:hover', 'transform', HOVER) || '';
  // Visão 11: a escala do foco foi para o bloco do ponteiro fino (no toque ficava presa)
  assert.equal(escala, decl(cartoes, 'button.cartao-paisagem:focus-visible', 'transform', HOVER));
  const s = parseFloat(/scale\(([\d.]+)\)/.exec(escala)?.[1] || 'NaN');
  assert.ok(s > 1.02, 'o efeito continua');
  for (const sel of ['button.cartao-biblioteca:hover', 'button.cartao-top10:hover'])
    assert.equal(decl(cartoes, sel, 'transform', HOVER), escala);
  for (const media of [null, '(min-width: 600px)', '(min-width: 1024px)']) {
    const largura = px(decl(base, ':root', '--hs-cartao-paisagem', media)), vao = px(decl(base, ':root', '--hs-vao', media));
    assert.ok(vao - largura * (s - 1) >= 4, `${media}: ${largura} px × ${s} num vão de ${vao}`);
  }
  // pôster continua com 1.05 (cresce pouco)
  assert.match(decl(cartoes, 'button.cartao:hover', 'transform', HOVER) || '', /scale\(1\.05\)/);
});

test('páginas 1-10 / 11-12 vêm antes da fileira e, ≥ 720 px, ficam na linha do seletor de temporada', () => {
  const tsx = ler('../src/telas/Titulo.tsx');
  assert.ok(tsx.indexOf('class="titulo-paginas"') < tsx.indexOf('class="titulo-trilho" ref'));
  const M = '(min-width: 720px)';
  assert.equal(decl(titulo, '.titulo-eps', 'display', M), 'grid');
  assert.equal(decl(titulo, '.titulo-eps-cabeca', 'display', M), 'contents');
  assert.equal(decl(titulo, '.titulo-eps-cabeca > .titulo-temp', 'grid-row', M), '1');
  assert.equal(decl(titulo, '.titulo-eps > .titulo-paginas', 'grid-row', M), '1');
  assert.equal(decl(titulo, '.titulo-eps-cabeca > .fileira-tudo', 'grid-row', M), '1');
  assert.equal(decl(titulo, '.titulo-eps > .titulo-trilho', 'grid-column', M), '1 / -1');
  // celular: acima da fileira, com a margem da página
  assert.equal(decl(titulo, '.titulo-paginas', 'padding', null), '0 var(--hs-margem) 6px');
});

test('pausa do destaque: barras cheias por CSS (o "pause" de contorno some); play continua o SVG', () => {
  const inicio = postcss.parse(ler('../src/telas/inicio.css'));
  const P = '.destaque-pausa:not([aria-pressed="true"]) .icone';
  assert.equal(decl(inicio, P + ' svg', 'visibility', null), 'hidden');
  assert.equal(decl(inicio, P + '::before', 'background', null), 'currentColor');
  assert.equal(decl(inicio, P + '::before', 'left', null), '3.5px');
  assert.equal(decl(inicio, P + '::after', 'right', null), '3.5px');
});

test('busca: a lista compensa o padding lateral do item (capa alinhada com o campo)', () => {
  const busca = postcss.parse(ler('../src/telas/busca.css'));
  const pad = (decl(busca, '.busca-item', 'padding', null) || '').split(' ')[1];
  assert.equal(decl(busca, '.busca-lista', 'margin', null), `0 -${pad}`);
});
