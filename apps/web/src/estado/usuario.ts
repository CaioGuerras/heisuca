// Visto e favorito mudam num lugar e valem em todas as telas (o mesmo título aparece em várias fileiras).
import { useEffect, useState } from 'preact/hooks';
import { favoritar, marcarAssistido, type Item, type Sessao } from '../api/jellyfin';

type Dados = NonNullable<Item['UserData']>;
const trocas = new Map<string, Dados>();
const ouvintes = new Set<() => void>();
const avisar = () => ouvintes.forEach(f => f());

export function dadosDe(i: Item): Dados { return { ...(i.UserData || {}), ...(trocas.get(i.Id) || {}) }; }

export function useDados(i: Item): Dados {
  const [, set] = useState(0);
  useEffect(() => { const f = () => set(n => n + 1); ouvintes.add(f); return () => { ouvintes.delete(f); }; }, []);
  return dadosDe(i);
}

async function trocar(i: Item, parcial: Dados, chamada: () => Promise<Item['UserData']>) {
  const antes = trocas.get(i.Id);
  trocas.set(i.Id, { ...(antes || {}), ...parcial }); avisar();      // otimista
  try { const d = await chamada(); trocas.set(i.Id, { ...(trocas.get(i.Id) || {}), ...(d || {}), ...parcial }); avisar(); }
  catch (e) {
    const atual: Dados = { ...(trocas.get(i.Id) || {}) };
    for (const k of Object.keys(parcial) as (keyof Dados)[]) { if (antes && k in antes) (atual as Record<string, unknown>)[k] = antes[k]; else delete atual[k]; }
    if (Object.keys(atual).length) trocas.set(i.Id, atual); else trocas.delete(i.Id);
    avisar(); throw e;
  }
}
export const alternarVisto = (s: Sessao, i: Item) => { const v = !dadosDe(i).Played; return trocar(i, { Played: v }, () => marcarAssistido(s, i.Id, v)).then(() => v); };
export const alternarFavorito = (s: Sessao, i: Item) => { const v = !dadosDe(i).IsFavorite; return trocar(i, { IsFavorite: v }, () => favoritar(s, i.Id, v)).then(() => v); };
// re-renderiza quem precisa saber de qualquer troca (ex.: Favoritos esconde o que acabou de ser desfavoritado)
export function useMudancas(): void {
  const [, set] = useState(0);
  useEffect(() => { const f = () => set(n => n + 1); ouvintes.add(f); return () => { ouvintes.delete(f); }; }, []);
}
