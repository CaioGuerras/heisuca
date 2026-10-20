import { defineConfig, type Plugin } from 'vite';
import preact from '@preact/preset-vite';

// Garante que o JASSUB use Canvas2DRenderer com transparência nativa (evita o bug de WebGL2/OffscreenCanvas opaco no Chromium Android/Windows)
// e desative o desynchronized: true.
function patchJassub(): Plugin {
  return {
    name: 'patch-jassub',
    transform(code, id) {
      if (id.includes('jassub')) {
        const res = code
          .replace(/desynchronized:\s*(!0|true)/g, 'desynchronized: false')
          .replace(/desynchronized:\s*1\b/g, 'desynchronized: 0')
          .replace(/this\._gpurender\s*=\s*new\s+WebGL2Renderer\(\)/g, 'this._gpurender = new Canvas2DRenderer()')
          .replace(/new\s+WebGL1Renderer\(\)/g, 'new Canvas2DRenderer()');
        return { code: res, map: null };
      }
    },
  };
}

// base relativa: o mesmo build serve no caminho de teste (/__heisuca/) e em qualquer domínio.
// Sem build legada (site-v2, 19/10): navegador antigo (TV antiga, TV box) vê a tela "use o app" do index.html, e não um
// site rebaixado (PLANO §3.4). Alvo mínimo: Chrome/Edge 88, Safari 15, Firefox 89 (o mesmo teste do index.html).
export default defineConfig({
  base: './',
  plugins: [preact(), patchJassub()],
  worker: { plugins: () => [patchJassub()] },
  build: { target: ['chrome88', 'edge88', 'safari15', 'firefox89'] },
  server: { proxy: { '^/(System|Users|UserViews|UserItems|UserPlayedItems|UserFavoriteItems|Items|Shows|Videos|Sessions|QuickConnect|HomeScreen|cgflix|__seerr)': 'http://127.0.0.1:13168' } },
});
