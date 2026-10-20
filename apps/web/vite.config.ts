import { defineConfig, type Plugin } from 'vite';
import preact from '@preact/preset-vite';

// Garante que o JASSUB não use desynchronized: true no WebGL/2D context,
// o que quebra a composição DirectComposition/SurfaceView e causa tela preta no Chrome do Android e Windows (issue #70 do JASSUB).
function patchJassubDesynchronized(): Plugin {
  return {
    name: 'patch-jassub-desynchronized',
    transform(code, id) {
      if (id.includes('jassub')) {
        return {
          code: code
            .replace(/desynchronized:\s*(!0|true)/g, 'desynchronized: false')
            .replace(/desynchronized:\s*1\b/g, 'desynchronized: 0'),
          map: null,
        };
      }
    },
  };
}

// base relativa: o mesmo build serve no caminho de teste (/__heisuca/) e em qualquer domínio.
// Sem build legada (site-v2, 19/10): navegador antigo (TV antiga, TV box) vê a tela "use o app" do index.html, e não um
// site rebaixado (PLANO §3.4). Alvo mínimo: Chrome/Edge 88, Safari 15, Firefox 89 (o mesmo teste do index.html).
export default defineConfig({
  base: './',
  plugins: [preact(), patchJassubDesynchronized()],
  worker: { plugins: () => [patchJassubDesynchronized()] },
  build: { target: ['chrome88', 'edge88', 'safari15', 'firefox89'] },
  server: { proxy: { '^/(System|Users|UserViews|UserItems|UserPlayedItems|UserFavoriteItems|Items|Shows|Videos|Sessions|QuickConnect|HomeScreen|cgflix|__seerr)': 'http://127.0.0.1:13168' } },
});
