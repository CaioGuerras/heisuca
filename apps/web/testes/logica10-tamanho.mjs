// Build só em memória: não grava dist nem cache de configuração em node_modules.
// Rodar de apps/web com OXC_NUM_THREADS=2 RAYON_NUM_THREADS=2 UV_THREADPOOL_SIZE=2.
import { execFileSync } from 'node:child_process';
import { resolve } from 'node:path';
import { build } from 'vite';

const arquivos = ['src/estado/usuario.ts', 'src/api/plex.ts'];
const originais = new Map(arquivos.map(p => [resolve(p), execFileSync('git', ['show', `8fa5fa6:apps/web/${p}`], { encoding: 'utf8' })]));
// Mesmas contas de teste e mesmo gzip do scripts/publicar-teste, sem executar o publicador.
process.env.VITE_SO_USUARIO = 'caioguerras,teste-cgflix,clara,clarapinto';
let base, final;
for (const [etapa, substituir] of [['base', arquivos], ['item1', arquivos.slice(1)], ['final', []]]) {
  const fontes = new Map(substituir.map(p => [resolve(p), originais.get(resolve(p))]));
  const resultados = await build({ configLoader: 'native', logLevel: 'warn',
    plugins: [{ name: 'logica10-fontes-base', enforce: 'pre', load(id) { return fontes.get(id); } }],
    build: { write: false } });
  const saidas = (Array.isArray(resultados) ? resultados : [resultados]).flatMap(r => r.output);
  const chunks = saidas.filter(c => c.type === 'chunk' && c.isEntry && /^assets\/index-.*\.js$/.test(c.fileName));
  if (chunks.length !== 1) throw new Error(`Entrada inesperada: ${chunks.map(c => c.fileName)}`);
  const c = chunks[0], gzip = execFileSync('gzip', ['-9', '-n', '-c'], { input: c.code }).length;
  console.log(JSON.stringify({ etapa, arquivo: c.fileName, bytes: Buffer.byteLength(c.code), gzip,
    deltaReferencia: gzip - 26678 }));
  const api = saidas.find(c => c.type === 'chunk' && c.modules[resolve('src/api/plex.ts')]);
  if (api) console.log(JSON.stringify({ etapa, api: api.fileName,
    gzip: execFileSync('gzip', ['-9', '-n', '-c'], { input: api.code }).length }));
  if (etapa === 'base') {
    if (c.fileName !== 'assets/index-BonQBGJF.js') throw new Error(`Base divergiu da publicação: ${c.fileName}`);
    base = gzip;
  }
  if (etapa === 'final') final = gzip;
}
console.log(JSON.stringify({ deltaMedido: final - base, deltaReferencia: final - 26678, teto: 27078 }));
if (final - 26678 > 400) throw new Error(`Excedeu +0,4 KB gzip: +${final - 26678} B`);
