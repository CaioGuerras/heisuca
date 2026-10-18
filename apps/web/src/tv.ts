// TV de verdade (Tizen/webOS): detecção, teclas de mídia e saída do app. Mesmo caminho do jellyfin-tizen (tizen.js):
// Voltar (10009) chega sem registro; as teclas de mídia precisam de registerKey; sair é application.exit().
declare const tizen: any;

export const ehTV = /Tizen|Web0S|SMART-TV/i.test(navigator.userAgent);
const temTizen = () => typeof tizen !== 'undefined' && !!tizen.tvinputdevice;

const MIDIA = ['MediaPlay', 'MediaPause', 'MediaPlayPause', 'MediaStop', 'MediaRewind', 'MediaFastForward',
  'MediaTrackPrevious', 'MediaTrackNext'];

export function ligarTV(): void {
  if (!ehTV) return;
  document.documentElement.classList.add('tv');
  if (temTizen()) for (const k of MIDIA) { try { tizen.tvinputdevice.registerKey(k); } catch { /* tecla ausente no modelo */ } }
}

// Voltar na raiz: Tizen fecha pelo application.exit(); webOS (appinfo com disableBackHistoryAPI) fecha por window.close().
export function sairDoApp(): void {
  try { if (typeof tizen !== 'undefined') { tizen.application.getCurrentApplication().exit(); return; } } catch { /* segue */ }
  if (/Web0S/i.test(navigator.userAgent)) window.close();
}
