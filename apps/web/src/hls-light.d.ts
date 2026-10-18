// hls.js/light tem a mesma API da versão completa (sem EME, legendas internas e faixas alternativas)
declare module 'hls.js/light' {
  export * from 'hls.js';
  export { default } from 'hls.js';
}
