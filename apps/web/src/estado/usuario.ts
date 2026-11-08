// Visto e favorito mudam num lugar e valem em todas as telas (o mesmo título aparece em várias fileiras).
import { useEffect, useState } from 'preact/hooks';
import { favoritar, marcarAssistido, type Item, type Sessao } from '../api/servidor.ts';

type Dados = NonNullable<Item['UserData']>;
const chave = (s: Sessao, i: Item) => JSON.stringify([s.servidorId || s.servidor, s.usuarioId, i.Id]);
const trocas = new Map<string, Dados>();
type Mutacao = { parcial: Dados; fim: Promise<void> };
const filas = new Map<string, Mutacao[]>();
const ouvintes = new Set<() => void>();
const avisar = () => ouvintes.forEach(f => f());

export function dadosDe(s: Sessao, i: Item): Dados {
  const k = chave(s, i), d = { ...(i.UserData || {}), ...(trocas.get(k) || {}) };
  for (const m of filas.get(k) || []) Object.assign(d, m.parcial);
  return d;
}

export function useDados(s: Sessao, i: Item): Dados {
  const [, set] = useState(0);
  useEffect(() => { const f = () => set(n => n + 1); ouvintes.add(f); return () => { ouvintes.delete(f); }; }, []);
  return dadosDe(s, i);
}

async function trocar(s: Sessao, i: Item, parcial: Dados, chamada: () => Promise<Item['UserData']>) {
  const k = chave(s, i), fila = filas.get(k) || [];
  const anterior = fila.length ? fila[fila.length - 1].fim : Promise.resolve();
  // Só o confirmado entra em trocas; dadosDe sobrepõe as ações ainda pendentes, na ordem dos cliques.
  const m: Mutacao = { parcial, fim: anterior.catch(() => {}).then(async () => {
    try { const d = await chamada(); trocas.set(k, { ...(trocas.get(k) || {}), ...(d || {}), ...parcial }); }
    finally { fila.shift(); if (!fila.length) filas.delete(k); avisar(); }
  }) };
  fila.push(m); filas.set(k, fila); avisar();
  return m.fim;
}
export const alternarVisto = (s: Sessao, i: Item) => { const v = !dadosDe(s, i).Played; return trocar(s, i, { Played: v }, () => marcarAssistido(s, i.Id, v)).then(() => v); };
export const alternarFavorito = (s: Sessao, i: Item) => { const v = !dadosDe(s, i).IsFavorite; return trocar(s, i, { IsFavorite: v }, () => favoritar(s, i.Id, v)).then(() => v); };
// re-renderiza quem precisa saber de qualquer troca (ex.: Favoritos esconde o que acabou de ser desfavoritado)
export function useMudancas(): void {
  const [, set] = useState(0);
  useEffect(() => { const f = () => set(n => n + 1); ouvintes.add(f); return () => { ouvintes.delete(f); }; }, []);
}
