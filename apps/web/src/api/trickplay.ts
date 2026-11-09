import type { Item, Sessao } from './tipos.ts';
export type PreviaImagem = { url: string; largura: number; altura: number; x: number; y: number; larguraFolha: number; alturaFolha: number };
// Apenas calcula o recorte. A imagem só será pedida pelo CSS quando a prévia entrar no DOM.
export function previaJellyfin(s: Sessao, i: Item, seg: number): PreviaImagem | null {
  const opcoes = Object.values(i.Trickplay || {}).flatMap(fonte => Object.values(fonte))
    .filter(t => [t.Width, t.Height, t.TileWidth, t.TileHeight, t.Interval, t.ThumbnailCount].every(n => Number.isFinite(n) && n > 0))
    .sort((a, b) => a.Width - b.Width);
  const t = opcoes.find(t => t.Width >= 160) || opcoes[0];
  if (!t || !Number.isFinite(seg)) return null;
  const quadro = Math.min(t.ThumbnailCount - 1, Math.max(0, Math.floor(seg * 1000 / t.Interval)));
  const porFolha = t.TileWidth * t.TileHeight, folha = Math.floor(quadro / porFolha), indice = quadro % porFolha;
  return { url: `${s.servidor}/Videos/${encodeURIComponent(i.Id)}/Trickplay/${t.Width}/${folha}.jpg?api_key=${encodeURIComponent(s.token)}`,
    largura: t.Width, altura: t.Height, larguraFolha: t.Width * t.TileWidth, alturaFolha: t.Height * t.TileHeight, x: (indice % t.TileWidth) * t.Width, y: Math.floor(indice / t.TileWidth) * t.Height };
}
