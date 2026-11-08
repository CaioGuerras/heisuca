import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { runInNewContext } from 'node:vm';
import ts from 'typescript';
import postcss from 'postcss';
import type { Paleta } from '../src/cor/paleta.ts';
import type { RGB } from '../src/cor/oklch.ts';
import { bancada, nos, resolver, texto } from './visual7-harness.ts';

// Biblioteca/Favoritos (Branco, 08/11): contagem real, resumo por biblioteca, esqueleto e vazio. Sem DOM nem rede.
const s = { tipo: 'jellyfin', token: 'teste', servidor: 'local', usuarioId: 'u' };
const bib = (Id: string) => ({ Id, Name: `Biblioteca ${Id}`, Type: 'CollectionFolder' });
const pagina = (n: number, total = n, p = 'a') => ({ Items: Array.from({ length: n }, (_, k) => ({ Id: `${p}${k}`, Name: `${p}${k}`, Type: 'Movie' })), TotalRecordCount: total });
const ler = (p: string) => readFileSync(new URL(p, import.meta.url), 'utf8');

function favoritosTela(api: { libs?: () => Promise<any[]>; favoritos: (id: string) => Promise<any> }) {
  const Fileira = () => null, CartaoPoster = () => null, EsqueletoCartoes = () => null, Icone = () => null, removidos = new Set<string>();
  const abas: string[] = [];
  const b = bancada('../src/telas/Favoritos.tsx', 'Favoritos', {
    '../api/servidor.ts': { bibliotecasDeVideo: api.libs || (async () => [bib('A'), bib('B')]), favoritos: (_: any, id: string) => api.favoritos(id), hashDe: () => '' },
    '../cor/paleta': { usePaleta() {}, fundoDesfocado: () => '' },
    '../comp/Cartoes': { CartaoPoster, EsqueletoCartoes }, '../comp/Fileira': { Fileira }, '../comp/Icone': { Icone },
    '../estado/usuario': { useMudancas() {}, dadosDe: (_: any, i: any) => ({ IsFavorite: !removidos.has(i.Id) }) },
    '../rota': { irTitulo() {}, irAba: (a: string) => abas.push(a) },
  }, { scrollY: 0, addEventListener() {}, removeEventListener() {} });
  return { b, abas, removidos, Fileira, EsqueletoCartoes, render: () => b.render('Favoritos', { s }) };
}

test('Favoritos: resumo soma o total real de cada biblioteca e desconta o que foi desfavoritado aqui', () => {
  const { b } = favoritosTela({ favoritos: async () => pagina(0) });
  const resumo = (l: any[]) => b.render('resumo', l);
  assert.equal(resumo([]), '');
  assert.equal(resumo([{ total: 1, carregados: 1, visiveis: 1 }]), '1 título');
  assert.equal(resumo([{ total: 62, carregados: 60, visiveis: 60 }, { total: 1, carregados: 1, visiveis: 1 }]), '63 títulos em 2 bibliotecas');
  // 2 desfavoritados na 1ª página: o total do servidor cai junto; biblioteca que ficou sem nenhum não conta
  assert.equal(resumo([{ total: 62, carregados: 60, visiveis: 58 }, { total: 1, carregados: 1, visiveis: 0 }]), '60 títulos');
  assert.equal(resumo([{ total: 1300, carregados: 60, visiveis: 60 }, { total: 4, carregados: 4, visiveis: 4 }]), '1.304 títulos em 2 bibliotecas');
});

test('Favoritos: carregando não repete "Favoritos" numa fileira; depois mostra o resumo e some ao desfavoritar', async () => {
  const t = favoritosTela({ favoritos: async id => id === 'A' ? pagina(60, 62) : pagina(1, 1, 'b') });
  let v = t.render();
  assert.equal(nos(v, t.Fileira).length, 0, 'sem fileira com título enquanto carrega');
  assert.equal(nos(v, t.EsqueletoCartoes).length, 1);
  assert.equal(texto(v).match(/Favoritos/g)?.length, 1, 'o título aparece uma vez só');
  t.b.efeitos(); await resolver();
  v = t.render();
  assert.match(texto(v), /63 títulos em 2 bibliotecas/);
  t.removidos.add('b0');
  v = t.render();
  assert.match(texto(v), /62 títulos(?! em)/);
  assert.deepEqual(nos(v, t.Fileira).map(n => n.props.titulo), ['Biblioteca A']);
});

test('Favoritos vazio: frase do plano e atalho real para a Biblioteca, sem linha de resumo', async () => {
  const t = favoritosTela({ favoritos: async () => pagina(0) });
  t.render(); t.b.efeitos(); await resolver();
  const v = t.render();
  assert.match(texto(v), /Toque em ♡ num título para guardá-lo aqui\./);
  assert.ok(!/títulos?\b/.test(texto(v).replace('num título', '')), 'sem contagem quando vazio');
  nos(v, 'button').find(n => /Abrir a Biblioteca/.test(texto(n))).props.onClick();
  assert.deepEqual(t.abas, ['b']);
});

test('Biblioteca: contagem no topo em pt-BR, singular e plural', () => {
  const b = bancada('../src/telas/Biblioteca.tsx', 'contagem', {});
  assert.equal(b.render('contagem', 1), '1 título');
  assert.equal(b.render('contagem', 0), '0 títulos');
  assert.equal(b.render('contagem', 1284), '1.284 títulos');
});

test('Biblioteca/Favoritos: anel de foco, nome em 2 linhas na grade e reduzir movimento', () => {
  const bib = ler('../src/telas/biblioteca.css'), fav = ler('../src/telas/favoritos.css');
  for (const css of [bib, fav]) {
    assert.match(css, /focus-visible \.cartao-arte \{\s*box-shadow: 0 0 0 2px var\(--hs-pagina\), 0 0 0 4px var\(--hs-texto\)/);
    assert.match(css, /-webkit-line-clamp: 2/);
    assert.match(css, /prefers-reduced-motion: reduce/);
    // chrome88: nada de :has, container queries, @layer, color-mix
    assert.doesNotMatch(css, /:has\(|@container|@layer|color-mix/);
  }
});

// Linhas novas (contagem/resumo). --hs-texto-2 dava 3,89:1 no Hisui; vão em --hs-texto (hierarquia por tamanho/peso),
// como os anos dos cartões nestas telas. Era: --hs-texto-2 (contagem da Biblioteca, resumo dos Favoritos) sobre a página, com o fundo desfocado
// da arte (8 %, preto ou branco no pior caso) por baixo: AA nas 730 paletas dos dois temas.
const base = postcss.parse(ler('../src/estilo/base.css'));
const nativo = createRequire(import.meta.url);
for (const tema of ['hisui', 'shikkoku']) test(`Biblioteca/Favoritos: linhas novas mantêm AA em ${tema}`, () => {
  const tokens: Record<string, string> = {};
  base.walkRules(`[data-tema="${tema}"]`, r => { r.walkDecls(d => { tokens[d.prop] = d.value; }); });
  const cache = new Map<string, any>();
  function carregar(arquivo: URL): any {
    if (cache.has(arquivo.href)) return cache.get(arquivo.href);
    const m = { exports: {} };
    const js = ts.transpileModule(readFileSync(arquivo, 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 } }).outputText;
    runInNewContext(js, { module: m, exports: m.exports, document: { documentElement: { dataset: { tema } } },
      getComputedStyle: () => ({ getPropertyValue: (n: string) => tokens[n] || '' }),
      require: (n: string) => n === 'preact/hooks' ? { useEffect: () => { throw new Error('hook'); } }
        : n.startsWith('.') ? carregar(new URL(n + '.ts', arquivo)) : nativo(n) });
    cache.set(arquivo.href, m.exports);
    return m.exports;
  }
  const { paletaDe }: { paletaDe: (b: RGB | null) => Paleta } = carregar(new URL('../src/cor/paleta.ts', import.meta.url));
  const { contraste }: { contraste: (a: RGB, b: RGB) => number } = carregar(new URL('../src/cor/oklch.ts', import.meta.url));
  for (const [arq, sel] of [['../src/telas/biblioteca.css', '.biblioteca-total'], ['../src/telas/favoritos.css', '.favoritos-resumo']]) {
    let cor = ''; postcss.parse(ler(arq)).walkRules(sel, r => r.walkDecls('color', d => { cor = d.value; }));
    assert.equal(cor, 'var(--hs-texto)', sel);
  }
  const op = Number(ler('../src/telas/favoritos.css').match(/\.favoritos-fundo \{[^}]*opacity: ([.\d]+)/)![1]);
  const vals = [0, 32, 64, 96, 128, 160, 192, 224, 255];
  let pior = Infinity;
  for (const r of vals) for (const g of vals) for (const b of [...vals, -1]) {
    const p = paletaDe(b < 0 ? null : [r, g, b]);
    for (const arte of [[0, 0, 0], [255, 255, 255]] as RGB[])
      pior = Math.min(pior, contraste(p.texto, p.pagina.map((v, k) => v * (1 - op) + arte[k] * op) as RGB));
  }
  assert.ok(pior >= 4.5, `${tema}: ${pior.toFixed(2)}:1`);
  console.log(`${tema} | texto sobre a página + arte ${op * 100}% | pior ${pior.toFixed(2)}:1`);
});
