import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { runInNewContext } from 'node:vm';
import postcss from 'postcss';
import ts from 'typescript';
import type { Paleta } from '../src/cor/paleta.ts';
import type { RGB } from '../src/cor/oklch.ts';

// Somente cálculo offline: executa paletaDe/contraste reais, sem hooks, navegador ou rede.
const ler = (p: string) => readFileSync(new URL(p, import.meta.url), 'utf8');
const tokens: Record<string, string> = {};
postcss.parse(ler('../src/estilo/base.css')).walkRules('[data-tema="hisui"]', regra => {
  regra.walkDecls(d => { tokens[d.prop] = d.value; });
});
const nativo = createRequire(import.meta.url);
const cache = new Map<string, unknown>();
function carregar(arquivo: URL): any {
  if (cache.has(arquivo.href)) return cache.get(arquivo.href);
  const modulo = { exports: {} };
  const js = ts.transpileModule(readFileSync(arquivo, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText;
  runInNewContext(js, {
    module: modulo, exports: modulo.exports,
    document: { documentElement: { dataset: { tema: 'hisui' } } },
    getComputedStyle: () => ({ getPropertyValue: (nome: string) => tokens[nome] || '' }),
    require: (nome: string) => {
      if (nome === 'preact/hooks') return { useEffect: () => { throw new Error('hook fora do cálculo'); } };
      return nome.startsWith('.') ? carregar(new URL(nome + '.ts', arquivo)) : nativo(nome);
    },
  }, { filename: arquivo.pathname });
  cache.set(arquivo.href, modulo.exports);
  return modulo.exports;
}
const { paletaDe }: { paletaDe: (base: RGB | null) => Paleta } = carregar(new URL('../src/cor/paleta.ts', import.meta.url));
const { contraste, hex }: { contraste: (a: RGB, b: RGB) => number; hex: (h: string) => RGB } = carregar(new URL('../src/cor/oklch.ts', import.meta.url));

// Interpola os stops do CSS real; todos os stops têm a mesma cor da página.
// O resultado é apenas a opacidade composta do véu, sem simular layout/renderização.
let fundo = '';
postcss.parse(ler('../src/telas/inicio.css')).walkRules(regra => {
  if (regra.selector === '.destaque-artes::after' && regra.parent?.type === 'root'
    || regra.selector === '[data-tema="hisui"] .destaque-artes::after') {
    regra.walkDecls('background', d => { fundo = d.value; });
  }
});
function opacidade(x: number, y: number, altura: number): number {
  let livre = 1;
  for (const camada of postcss.list.comma(fundo)) {
    assert.ok(camada.startsWith('linear-gradient('), camada);
    const [direcao, ...cores] = postcss.list.comma(camada.slice(16, -1));
    assert.ok(direcao === '90deg' || direcao === '180deg', direcao);
    const tamanho = direcao === '90deg' ? 1440 : altura, pos = direcao === '90deg' ? x : y;
    const stops = cores.map(cor => {
      const m = cor.match(/^(.*?)\s+(calc\(100% - (\d+)px\)|([\d.]+)%)$/);
      assert.ok(m, cor);
      const p = m[3] ? tamanho - Number(m[3]) : tamanho * Number(m[4]) / 100;
      const a = m[1] === 'var(--hs-pagina)' ? 1 : m[1] === 'var(--hs-pagina-0)' ? 0
        : Number(m[1].match(/,\s*([\d.]+)\)$/)?.[1]);
      assert.ok(Number.isFinite(a), cor);
      return { p, a };
    });
    let a = stops[stops.length - 1].a;
    if (pos <= stops[0].p) a = stops[0].a;
    else for (let i = 1; i < stops.length; i++) {
      if (pos <= stops[i].p) {
        const anterior = stops[i - 1], atual = stops[i];
        a = anterior.a + (atual.a - anterior.a) * (pos - anterior.p) / (atual.p - anterior.p);
        break;
      }
    }
    livre *= 1 - a;
  }
  return 1 - livre;
}
const compor = (pagina: RGB, arte: RGB, a: number): RGB => pagina.map((v, i) => v * a + arte[i] * (1 - a)) as RGB;
function alfaSuperficie(arquivo: string, seletor: string): number {
  let valor = '';
  postcss.parse(ler(arquivo)).walkRules(seletor, regra => {
    regra.walkDecls('background', d => { valor = d.value; });
  });
  const m = valor.match(/^rgba\(var\(--hs-superficie-rgb\),\s*([\d.]+)\)$/);
  assert.ok(m, `${seletor}: fundo sem superfície mensurável (${valor})`);
  return Number(m[1]);
}
const bases: (RGB | null)[] = [null];
for (const r of [0, 32, 64, 96, 128, 160, 192, 224, 255])
  for (const g of [0, 32, 64, 96, 128, 160, 192, 224, 255])
    for (const b of [0, 32, 64, 96, 128, 160, 192, 224, 255]) bases.push([r, g, b]);

test('Hisui desktop conserva o centro/direita da arte e cobre o canto esquerdo', () => {
  for (const h of [560, 720, 900]) {
    for (const x of [0.55, 0.7, 0.9]) {
      assert.ok(opacidade(1440 * x, h * .3, h) <= .02, `centro/direita lavado: x=${x}, h=${h}`);
    }
    assert.equal(opacidade(1440 * .12, h * .2, h), 1, `canto esquerdo exposto: h=${h}`);
  }
});

test('Hisui: texto principal AA no pior fundo do véu desktop, em 730 paletas', () => {
  // Os 290 px inferiores acomodam logo/casa (140), dados (23), sinopse (44), gaps/controles/padding (82).
  let menorAlfa = 1;
  for (const h of [560, 720, 900]) for (const x of [0, .12, .5, .7, .97, 1]) {
    for (const fim of [290, 250, 150, 0]) menorAlfa = Math.min(menorAlfa, opacidade(x * 1440, h - fim, h));
  }
  assert.ok(menorAlfa >= .98, `véu insuficiente na região do texto: ${menorAlfa}`);
  let corEstrela = '';
  postcss.parse(ler('../src/telas/inicio.css')).walkRules(regra => {
    if (regra.selector === '.destaque-estrela' || regra.selector === '[data-tema="hisui"] .destaque-estrela')
      regra.walkDecls('color', d => { corEstrela = d.value; });
  });
  assert.match(corEstrela, /^#[0-9a-f]{6}$/i);
  let minimo = Infinity, semHash = Infinity, estrela = Infinity;
  for (const base of bases) {
    const p = paletaDe(base);
    for (const arte of [[0, 0, 0], [255, 255, 255]] as RGB[]) {
      const valor = contraste(p.texto, compor(p.pagina, arte, menorAlfa));
      estrela = Math.min(estrela, contraste(hex(corEstrela), compor(p.pagina, arte, menorAlfa)));
      minimo = Math.min(minimo, valor);
      if (!base) semHash = Math.min(semHash, valor);
      assert.ok(valor >= 4.5, `${base}: ${valor}`);
    }
  }
  assert.ok(estrela >= 4.5, `estrela sobre véu: ${estrela}`);
  console.log(`Hisui | nome textual/dados/sinopse | ${bases.length} paletas x preto/branco | véu mínimo ${menorAlfa} | ${minimo.toFixed(2)}:1; sem hash ${semHash.toFixed(2)}:1`);
  console.log(`Hisui | estrela ${corEstrela} sobre véu mínimo | ${estrela.toFixed(2)}:1`);
});

test('Hisui: selos e vidro claro mantêm texto AA sobre os extremos de fundo', () => {
  const alfaSelo = alfaSuperficie('../src/telas/titulo.css', '[data-tema="hisui"] .titulo-selos li');
  const alfaIdade = alfaSuperficie('../src/comp/classificacao.css', '[data-tema="hisui"] .selo-idade:not([class*="idade-"])');
  const alfaIlha = alfaSuperficie('../src/comp/navegacao.css', '[data-tema="hisui"] .ilha');
  const alfaRedondo = alfaSuperficie('../src/comp/navegacao.css', '[data-tema="hisui"] .redondo');
  let selos = Infinity, vidro = Infinity;
  for (const base of bases) {
    const p = paletaDe(base);
    for (const arte of [[0, 0, 0], [255, 255, 255]] as RGB[]) {
      for (const a of [alfaSelo, alfaIdade]) selos = Math.min(selos, contraste(p.texto, compor(p.superficie, arte, a)));
      vidro = Math.min(vidro, contraste(p.texto, compor(p.superficie, arte, alfaRedondo)),
        contraste(p.texto, compor(p.superficie, arte, alfaIlha)), contraste(p.texto2, compor(p.superficie, arte, alfaIlha)));
    }
  }
  const acento = contraste(hex(tokens['--hs-tema-cor-botao-fundo']), hex(tokens['--hs-tema-cor-botao-texto']));
  assert.ok(selos >= 4.5 && vidro >= 4.5 && acento >= 4.5);
  console.log(`Hisui | selos ${alfaSelo}/${alfaIdade} | ${selos.toFixed(2)}:1; vidro ${alfaIlha}/${alfaRedondo} (principal/secundário) | ${vidro.toFixed(2)}:1; selo verde/branco | ${acento.toFixed(2)}:1`);
});
