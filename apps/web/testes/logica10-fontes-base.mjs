// Reproduz regressões com as fontes da base, sem alterar a worktree ou editar testes existentes.
// node --import ./testes/logica10-fontes-base.mjs --test testes/logica10-usuario.test.ts testes/logica10-hubs.test.ts
import { registerHooks } from 'node:module';
import { execFileSync } from 'node:child_process';

const fontes = new Map(['estado/usuario.ts', 'api/plex.ts'].map(p => [
  new URL('../src/' + p, import.meta.url).href,
  execFileSync('git', ['show', '8fa5fa6:apps/web/src/' + p], { encoding: 'utf8' }),
]));
registerHooks({ load(url, contexto, proximo) {
  const carregado = proximo(url, contexto);
  return fontes.has(url) ? { ...carregado, source: fontes.get(url) } : carregado;
} });
