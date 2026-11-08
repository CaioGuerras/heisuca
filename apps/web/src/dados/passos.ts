// Como usar (PLANO §11): quais passos valem para esta conta, o que já foi marcado e o progresso. Sem DOM (testável no node).
// Os passos marcados ficam no aparelho (localStorage, JSON de ids); lixo ou id antigo no armazenamento não quebra nada.
export type IdPasso = 'entrar' | 'senha' | 'foto' | 'instalar' | 'pedir';

// senha e foto só onde o servidor deixa trocar (no Plex, não); pedir só com Seerr
export const passosDaConta = (c: { senha: boolean; foto: boolean; seerr: boolean }): IdPasso[] =>
  (['entrar', 'senha', 'foto', 'instalar', 'pedir'] as IdPasso[]).filter(p => (p !== 'senha' || c.senha) && (p !== 'foto' || c.foto) && (p !== 'pedir' || c.seerr));

export function lerFeitos(bruto: string | null): string[] {
  try {
    const v: unknown = JSON.parse(bruto || '[]');
    return Array.isArray(v) ? v.filter((x, i): x is string => typeof x === 'string' && v.indexOf(x) === i) : [];
  } catch { return []; }
}

export const alternarFeito = (feitos: string[], id: string) => feitos.includes(id) ? feitos.filter(x => x !== id) : [...feitos, id];

export function progresso(passos: string[], feitos: string[]) {
  const n = passos.filter(p => feitos.includes(p)).length, total = passos.length;
  return { feitos: n, total, pct: total ? Math.round((n / total) * 100) : 0, completo: total > 0 && n === total,
    proximo: passos.find(p => !feitos.includes(p)) ?? null };
}
