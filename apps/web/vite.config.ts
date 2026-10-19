import { defineConfig } from 'vite';
import preact from '@preact/preset-vite';

// base relativa: o mesmo build serve no caminho de teste (/__heisuca/) e em qualquer domínio.
// Sem build legada (site-v2, 19/10): navegador antigo (TV antiga, TV box) vê a tela "use o app" do index.html, e não um
// site rebaixado (PLANO §3.4). Alvo mínimo: Chrome/Edge 88, Safari 15, Firefox 89 (o mesmo teste do index.html).
export default defineConfig({
  base: './',
  plugins: [preact()],
  build: { target: ['chrome88', 'edge88', 'safari15', 'firefox89'] },
  server: { proxy: { '^/(System|Users|UserViews|UserItems|UserPlayedItems|UserFavoriteItems|Items|Shows|Videos|Sessions|QuickConnect|HomeScreen|cgflix|__seerr)': 'http://127.0.0.1:13168' } },
});
