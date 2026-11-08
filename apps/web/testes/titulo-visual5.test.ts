import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { runInNewContext } from 'node:vm';
import ts from 'typescript';
import type { Fluxo, Item } from '../src/api/tipos.ts';

// Executa as funções reais da tela com hooks mínimos, sem DOM, rede ou navegador.
const nativo = createRequire(import.meta.url);
let estado: unknown;
let iniciar = true;
const fonte = readFileSync(new URL('../src/telas/Titulo.tsx', import.meta.url), 'utf8');
const modulo = { exports: {} as Record<string, any> };
const js = ts.transpileModule(fonte + '\nexport { InfoMidia, Episodios, FotoElenco };', {
  compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022,
    jsx: ts.JsxEmit.ReactJSX, jsxImportSource: 'preact' },
}).outputText;
runInNewContext(js, { module: modulo, exports: modulo.exports, Intl, require: (nome: string) => {
  if (nome === 'preact/jsx-runtime') return nativo(nome);
  if (nome === 'preact/hooks') return {
    useMemo: (f: () => unknown) => f(), useEffect: () => {}, useRef: () => ({ current: null }),
    useState: (v: unknown) => { if (iniciar) estado = v; return [estado, (x: unknown) => { estado = x; }]; },
  };
  return {};
} });
type No = { type?: unknown; props?: Record<string, any> };
function nos(v: any, tipo: string): No[] {
  if (!v || typeof v !== 'object') return [];
  if (Array.isArray(v)) return v.flatMap(x => nos(x, tipo));
  return [...(v.type === tipo ? [v] : []), ...nos(v.props?.children, tipo)];
}
function texto(v: any): string {
  if (v === null || v === undefined || typeof v === 'boolean') return '';
  if (typeof v !== 'object') return String(v);
  return Array.isArray(v) ? v.map(texto).join('') : texto(v.props?.children);
}
const fluxo = (Type: string, dados: Partial<Fluxo> = {}): Fluxo => ({ Index: 0, Type, ...dados });
const midia = (video?: Fluxo, audios: Fluxo[] = []) => modulo.exports.InfoMidia({ video, audios });

test('Info mídia omite seção e linhas sem dado, inclusive Unknown e idioma indefinido', () => {
  assert.equal(midia(), null);
  assert.equal(midia(fluxo('Video'), [fluxo('Audio')]), null);
  assert.equal(midia(fluxo('Video', { VideoRangeType: 'Unknown', VideoRange: 'Unknown' }), [fluxo('Audio', { Language: 'und' })]), null);
  const t = texto(midia(fluxo('Video', { Codec: 'hevc' })));
  assert.match(t, /HEVC/);
  for (const ausente of ['H.264', 'Resolução', 'Faixa dinâmica', 'Quadros por segundo', 'Taxa de bits', 'Áudio']) assert.ok(!t.includes(ausente), t);
});

test('Info mídia reúne múltiplas faixas em apenas dois cartões e preserva falso explícito', () => {
  const v = midia(fluxo('Video', { Width: 1920, Height: 1080, Codec: 'h264', Profile: 'High', VideoRange: 'SDR', RealFrameRate: 23.976 }),
    [fluxo('Audio', { Language: 'por', Codec: 'aac', Channels: 2, IsDefault: false }), fluxo('Audio'),
      fluxo('Audio', { Language: 'jpn', Codec: 'flac', IsDefault: true })]);
  const cartoes = nos(v, 'div').filter(n => n.props?.class === 'titulo-midia-cartao');
  assert.equal(cartoes.length, 2);
  assert.deepEqual(nos(v, 'h3').map(texto), ['Vídeo', 'Áudio']);
  const t = texto(v);
  for (const esperado of ['1920 × 1080', 'H.264 · High', 'SDR', '23,976', 'Português', 'Estéreo (2.0)', 'Não', 'Japonês', 'Sim']) assert.ok(t.includes(esperado), esperado + ': ' + t);
  assert.ok(!t.includes('Faixa 2'), 'faixa vazia não aparece');
});

test('Info mídia mantém apenas cartão com dados e não inventa SDR, canais ou codec', () => {
  const v = midia(undefined, [fluxo('Audio', { IsDefault: false })]);
  assert.deepEqual(nos(v, 'dt').map(texto), ['Padrão']);
  assert.deepEqual(nos(v, 'dd').map(texto), ['Não']);
  assert.equal(nos(v, 'h3').length, 1);
});

const eps = (n: number): Item[] => Array.from({ length: n }, (_, k) => ({ Id: String(k + 1), Name: `Ep ${k + 1}`, Type: 'Episode', IndexNumber: k + 1 }));
function episodios(lista: Item[], atual: Item | null = null, primeira = true) {
  iniciar = primeira;
  return modulo.exports.Episodios({ s: {}, eps: lista, atual });
}
test('episódios: limites de dez, última página incompleta e episódio atual na página correta', () => {
  for (const n of [0, 1, 10]) assert.equal(nos(episodios(eps(n)), 'button').length, 0);
  for (const [n, rotulos] of [[11, ['1-10', '11']], [12, ['1-10', '11-12']], [21, ['1-10', '11-20', '21']]] as const) {
    const lista = eps(n), v = episodios(lista, lista[n - 1]);
    const botoes = nos(v, 'button');
    assert.deepEqual(botoes.map(texto), rotulos);
    assert.equal(botoes[botoes.length - 1].props?.['aria-selected'], true);
    const trilho = nos(v, 'div').find(n => n.props?.class === 'titulo-trilho');
    const itens = (trilho?.props?.children || []).map((n: No) => n.props?.e.Id);
    assert.deepEqual(itens, lista.slice(10 * Math.floor((n - 1) / 10)).map(i => i.Id));
    botoes[0].props?.onClick();
    const primeira = nos(episodios(lista, lista[n - 1], false), 'div').find(n => n.props?.class === 'titulo-trilho');
    assert.deepEqual(primeira?.props?.children.map((n: No) => n.props?.e.Id), lista.slice(0, 10).map(i => i.Id));
  }
});

test('elenco usa silhueta sem URL e depois de falha da foto, mantendo o mesmo quadrado', () => {
  iniciar = true;
  const semFoto = modulo.exports.FotoElenco({});
  assert.equal(semFoto.props.class, 'titulo-pessoa-foto');
  assert.equal(nos(semFoto, 'span')[1].props?.class, 'titulo-silhueta');
  iniciar = true;
  const comFoto = modulo.exports.FotoElenco({ src: 'https://foto.example.invalid/pessoa', hash: 'hash' });
  assert.equal(comFoto.props.children.props.hash, 'hash');
  comFoto.props.children.props.aoErro();
  iniciar = false;
  const falhou = modulo.exports.FotoElenco({ src: 'https://foto.example.invalid/pessoa' });
  assert.equal(nos(falhou, 'span')[1].props?.class, 'titulo-silhueta');
});
