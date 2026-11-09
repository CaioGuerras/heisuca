import { defineConfig, type Plugin } from 'vite';
import preact from '@preact/preset-vite';
import { fileURLToPath } from 'node:url';

// Lume (lab do Heisuca): interface nova, mesma camada de dados do apps/web (@w). Alvo: navegadores atuais (sem chrome88).
function patchJassub(): Plugin {
  return {
    name: 'patch-jassub',
    transform(code, id) {
      if (id.includes('jassub')) {
        return { code: code.replace(/desynchronized:\s*(!0|true)/g, 'desynchronized: false').replace(/desynchronized:\s*1\b/g, 'desynchronized: 0')
          .replace(/this\._gpurender\s*=\s*new\s+WebGL2Renderer\(\)/g, 'this._gpurender = new Canvas2DRenderer()')
          .replace(/new\s+WebGL1Renderer\(\)/g, 'new Canvas2DRenderer()'), map: null };
      }
    },
  };
}

// o player do Heisuca é reaproveitado inteiro, mas o carregamento dele tem o selo da marca: no Lume entra o nosso
function trocarCarregando(): Plugin {
  const nosso = fileURLToPath(new URL('./src/player/Carregando.tsx', import.meta.url));
  return {
    name: 'lume-carregando', enforce: 'pre',
    resolveId(fonte, quem) { if (quem?.includes('/web/src/telas/') && fonte === '../player/Carregando') return nosso; },
  };
}

export default defineConfig({
  base: './',
  plugins: [trocarCarregando(), preact(), patchJassub()],
  worker: { plugins: () => [patchJassub()] },
  resolve: {
    alias: { '@w': fileURLToPath(new URL('../web/src', import.meta.url)) },
    // os arquivos do web importam pacotes; todos saem do node_modules do lab (uma cópia só do preact)
    dedupe: ['preact', 'hls.js', 'blurhash', 'jassub', '@material-symbols/svg-300', '@fontsource-variable/inter'],
  },
  build: { target: ['chrome120', 'edge120', 'safari17', 'firefox121'] },
});
