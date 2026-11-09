export const VELOCIDADES = [0.5, 0.75, 1, 1.25, 1.5, 2] as const;
export function aplicarVelocidade(video: { playbackRate: number } | null, valor: number) {
  if (video && (VELOCIDADES as readonly number[]).includes(valor)) video.playbackRate = valor;
}
export const ajustarVolume = (atual: number, direcao: number) => Math.max(0, Math.min(1, Math.round((atual + direcao * 0.05) * 100) / 100));
type Alvo = { tagName?: string; type?: string; isContentEditable?: boolean } | null;
export const campoDeTexto = (alvo: Alvo) => !!alvo && (alvo.isContentEditable || ['TEXTAREA', 'SELECT'].includes(alvo.tagName || '')
  || (alvo.tagName === 'INPUT' && !['range', 'checkbox', 'radio', 'button', 'submit', 'reset'].includes(alvo.type || 'text')));
export function acaoDaTecla(codigo: number, alvo: Alvo) {
  if (campoDeTexto(alvo)) return null;
  return ({ 38: 'volumeMais', 40: 'volumeMenos', 67: 'legenda', 74: 'recuar', 76: 'avancar', 80: 'pip' } as Record<number, string>)[codigo] || null;
}
type DocumentoPip = { pictureInPictureEnabled?: boolean; pictureInPictureElement?: unknown; exitPictureInPicture?: () => Promise<unknown> };
type VideoPip = { requestPictureInPicture?: () => Promise<unknown> };
export async function sairDoPip(doc: DocumentoPip, video: VideoPip | null) {
  if (video && doc.pictureInPictureElement === video) await doc.exitPictureInPicture?.();
}
export async function alternarPip(doc: DocumentoPip, video: VideoPip | null) {
  if (!video || !doc.pictureInPictureEnabled) return;
  if (doc.pictureInPictureElement === video) await sairDoPip(doc, video);
  else await video.requestPictureInPicture?.();
}
