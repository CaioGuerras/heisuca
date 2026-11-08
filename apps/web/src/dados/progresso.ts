import type { Item } from '../api/tipos.ts';

// Percentual explícito tem prioridade; ticks só permitem calcular com duração real.
export function progressoAssistido(d: Item['UserData'], duracao?: number): number {
  if (d?.Played) return 100;
  const pct = d?.PlayedPercentage;
  const pos = d?.PlaybackPositionTicks;
  const valor = typeof pct === 'number' && Number.isFinite(pct) ? pct
    : pos && duracao && Number.isFinite(pos) && Number.isFinite(duracao) && duracao > 0 ? pos / duracao * 100 : 0;
  return Math.max(0, Math.min(100, valor));
}
