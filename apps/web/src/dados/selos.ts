// Selos editoriais derivados exclusivamente dos fluxos já carregados do filme/episódio.
import type { Fluxo } from '../api/tipos.ts';

const portugues = (f: Fluxo) => /^(por|pt)([-_](br|pt))?$/i.test(f.Language || '');
export function selosDeMidia(fluxos: Fluxo[]): string[] {
  const selos: string[] = [];
  if (fluxos.some(f => f.Type === 'Audio' && portugues(f))) selos.push('Dublado');
  // Legenda forçada traduz apenas trechos: não anuncia uma legenda completa.
  if (fluxos.some(f => f.Type === 'Subtitle' && portugues(f) && !f.IsForced)) selos.push('Legendado');
  const videos = fluxos.filter(f => f.Type === 'Video');
  if (videos.some(f => (f.Width || 0) >= 3800 || (f.Height || 0) >= 2160)) selos.push('4K');
  if (videos.some(f => [f.VideoRangeType, f.VideoRange].some(v => /hdr|hlg|dovi|dolby\s*vision/i.test(v || '')))) selos.push('HDR');
  return selos;
}
