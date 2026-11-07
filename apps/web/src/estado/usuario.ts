// Visto e favorito mudam num lugar e valem em todas as telas (o mesmo título aparece em várias fileiras).
import { useEffect, useState } from 'preact/hooks';
import { favoritar, marcarAssistido, type Item, type Sessao } from '../api/servidor.ts';

type Dados = NonNullable<Item['UserData']>;
const chave = (s: Sessao, i: Item) => JSON.stringify([s.servidorId || s.servidor, s.usuarioId, i.Id]);
const trocas = new Map<string, Dados>();
const ouvintes = new Set<() => void>();
const avisar = () => ouvintes.forEach(f => f());

export function dadosDe(s: Sessao, i: Item): Dados { return { ...(i.UserData || {}), ...(trocas.get(chave(s, i)) || {}) }; }

export function useDados(s: Sessao, i: Item): Dados {
  const [, set] = useState(0);
  useEffect(() => { const f = () => set(n => n + 1); ouvintes.add(f); return () => { ouvintes.delete(f); }; }, []);
  return dadosDe(s, i);
}

async function trocar(s: Sessao, i: Item, parcial: Dados, chamada: () => Promise<Item['UserData']>) {
  const antes = trocas.get(chave(s, i));
  trocas.set(chave(s, i), { ...(antes || {}), ...parcial }); avisar();      // otimista
  try { const d = await chamada(); trocas.set(chave(s, i), { ...(trocas.get(chave(s, i)) || {}), ...(d || {}), ...parcial }); avisar(); }
  catch (e) {
    const atual: Dados = { ...(trocas.get(chave(s, i)) || {}) };
    for (const k of Object.keys(parcial) as (keyof Dados)[]) { if (antes && k in antes) (atual as Record<string, unknown>)[k] = antes[k]; else delete atual[k]; }
    if (Object.keys(atual).length) trocas.set(chave(s, i), atual); else trocas.delete(chave(s, i));
    avisar(); throw e;
  }
}
export const alternarVisto = (s: Sessao, i: Item) => { const v = !dadosDe(s, i).Played; return trocar(s, i, { Played: v }, () => marcarAssistido(s, i.Id, v)).then(() => v); };
export const alternarFavorito = (s: Sessao, i: Item) => { const v = !dadosDe(s, i).IsFavorite; return trocar(s, i, { IsFavorite: v }, () => favoritar(s, i.Id, v)).then(() => v); };
// re-renderiza quem precisa saber de qualquer troca (ex.: Favoritos esconde o que acabou de ser desfavoritado)
export function useMudancas(): void {
  const [, set] = useState(0);
  useEffect(() => { const f = () => set(n => n + 1); ouvintes.add(f); return () => { ouvintes.delete(f); }; }, []);
}
