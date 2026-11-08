import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import postcss from 'postcss';

// Halo cinza do Hisui ≥ 1024 px (Branco 6, 08/11; auditoria da Visão 10, item 5): uma camada "lighten" com a MESMA forma
// do véu levanta o escuro da arte para a cor da página nas bordas. Só Hisui e só ≥ 1024 px; Shikkoku intocado.
const css = postcss.parse(readFileSync(new URL('../src/telas/inicio.css', import.meta.url), 'utf8'));
const regras = (sel: string) => { const l: postcss.Rule[] = []; css.walkRules(r => { if (r.selector === sel) l.push(r); }); return l; };
const valor = (r: postcss.Rule, p: string) => { let v = ''; r.walkDecls(p, d => { v = d.value; }); return v; };
const media = (r: postcss.Rule) => r.parent?.type === 'atrule' ? (r.parent as postcss.AtRule).params : '';

test('Branco6: Hisui ≥ 1024 levanta o escuro da arte nas bordas (lighten), com a forma do véu do desktop', () => {
  const antes = regras('[data-tema="hisui"] .destaque-artes::before');
  assert.equal(antes.length, 1, 'uma única camada, nada no celular nem no tablet');
  assert.equal(media(antes[0]), '(min-width: 1024px)');
  assert.equal(valor(antes[0], 'mix-blend-mode'), 'lighten');
  assert.equal(valor(antes[0], 'pointer-events'), 'none');
  const veu = regras('[data-tema="hisui"] .destaque-artes::after').find(r => media(r) === '(min-width: 1024px)')!;
  assert.equal(valor(antes[0], 'background'), valor(veu, 'background'), 'mesmas faixas do véu: centro da arte intocado');
  assert.ok(!/rgb\(0 0 0|#000|black/.test(valor(antes[0], 'background')), 'nenhuma cor escura na camada');
});

test('Branco6: Shikkoku continua com o lighten de página inteira, sem mudança', () => {
  const s = regras('[data-tema="shikkoku"] .destaque-artes::before');
  assert.equal(s.length, 1);
  assert.equal(media(s[0]), '');
  assert.equal(valor(s[0], 'background-color'), 'var(--hs-pagina)');
  assert.equal(valor(s[0], 'mix-blend-mode'), 'lighten');
});
