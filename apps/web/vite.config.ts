import { defineConfig } from 'vite';
import preact from '@preact/preset-vite';
import legacy from '@vitejs/plugin-legacy';

// base relativa: o mesmo build serve no caminho de teste da VPS e dentro do pacote da TV (Tizen/webOS).
// legacy: TVs Samsung 2017+ têm Chromium 56 (Tizen 3.0); a build moderna fica para navegadores atuais.
export default defineConfig({
  base: './',
  plugins: [preact(), legacy({ targets: ['chrome >= 56', 'safari >= 13', 'defaults'] })],
  server: { proxy: { '^/(Users|UserViews|UserItems|Items|Videos|Sessions)': 'http://127.0.0.1:13168' } },
});
