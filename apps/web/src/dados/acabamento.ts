import type { Item } from '../api/tipos.ts';

export function faixaClassificacao(valor: string): string | null {
  const m = /^(?:BR[- ]?)?(L|LIVRE|10|12|14|16|18)$/.exec(valor.trim().toUpperCase());
  return m ? m[1] === 'LIVRE' ? 'L' : m[1] : null;
}

// Só mostra um total quando todas as temporadas regulares informam a contagem.
export function totalEpisodios(temporadas: Item[]): number | null {
  const regulares = temporadas.filter(t => (t.IndexNumber ?? 0) > 0);
  if (!regulares.length || regulares.some(t => !Number.isInteger(t.ChildCount) || t.ChildCount! < 0)) return null;
  return regulares.reduce((total, t) => total + t.ChildCount!, 0);
}
