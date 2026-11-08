// Guarda do alvo chrome88 (PLANO; regra da noite 07→08/11): nada de recurso que o Chrome 88 não tem no CSS nem no código.
// Comentários são ignorados (os arquivos citam "sem color-mix" de propósito).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

const RAIZ = new URL('../src/', import.meta.url).pathname;
const arquivos = (d: string): string[] => readdirSync(d).flatMap(n => {
  const p = join(d, n);
  return statSync(p).isDirectory() ? arquivos(p) : /\.(css|tsx?)$/.test(n) ? [p] : [];
});
const semComentarios = (txt: string, css: boolean) => css ? txt.replace(/\/\*[\s\S]*?\*\//g, '')
  : txt.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:'"`\\])\/\/.*$/gm, '$1');

const CSS: [RegExp, string][] = [[/:has\(/, ':has()'], [/color-mix\(/, 'color-mix()'], [/@layer\b/, '@layer'], [/@container\b/, '@container'],
  [/\bcontainer-type\s*:/, 'container-type']];
const JS: [RegExp, string][] = [[/AbortSignal\.(timeout|any)\b/, 'AbortSignal.timeout/any'], [/\bstructuredClone\(/, 'structuredClone'],
  [/\.at\(-?\d/, '.at()'], [/Object\.hasOwn\(/, 'Object.hasOwn']];

test('nenhum arquivo de src usa recurso fora do chrome88', () => {
  const todos = arquivos(RAIZ), achados: string[] = [];
  assert.ok(todos.length > 50, `só ${todos.length} arquivos lidos`);
  for (const f of todos) {
    const css = f.endsWith('.css'), txt = semComentarios(readFileSync(f, 'utf8'), css);
    for (const [re, nome] of css ? CSS : JS) if (re.test(txt)) achados.push(`${f.slice(RAIZ.length)}: ${nome}`);
  }
  assert.deepEqual(achados, []);
});
