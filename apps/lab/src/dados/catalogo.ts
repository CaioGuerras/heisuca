// Consultas que o Lume faz além do adaptador do Heisuca (só Jellyfin, por ora): explorar com ordem e filtros,
// gêneros, "Mais como este" e a busca rápida da paleta.
import { cabecalho, obter } from '@w/api/jellyfin';
import type { Item, Sessao } from '@w/api/tipos';

const IMG = 'enableImageTypes=Primary,Backdrop,Thumb,Logo&imageTypeLimit=1';
const CAMPOS = `fields=Overview,Genres,PrimaryImageAspectRatio,ProductionYear,OfficialRating,CommunityRating,RunTimeTicks&${IMG}`;

export type Ordem = 'nome' | 'recentes' | 'lancamento' | 'nota';
export const ORDENS: { id: Ordem; nome: string }[] = [
  { id: 'recentes', nome: 'Chegaram agora' },
  { id: 'nome', nome: 'A–Z' },
  { id: 'lancamento', nome: 'Lançamento' },
  { id: 'nota', nome: 'Mais bem avaliados' },
];
const SORT: Record<Ordem, string> = {
  nome: 'sortBy=SortName&sortOrder=Ascending',
  recentes: 'sortBy=DateCreated,SortName&sortOrder=Descending',
  lancamento: 'sortBy=PremiereDate,ProductionYear,SortName&sortOrder=Descending',
  nota: 'sortBy=CommunityRating,SortName&sortOrder=Descending',
};

export type Filtro = { biblioteca?: string; ordem: Ordem; naoVistos: boolean; genero?: string; letra?: string };

export function consultaExplorar(s: Sessao, f: Filtro, inicio: number, limite: number): string {
  const p = [`userId=${s.usuarioId}`, 'recursive=true', 'includeItemTypes=Movie,Series', SORT[f.ordem],
    `startIndex=${inicio}`, `limit=${limite}`, CAMPOS, 'enableTotalRecordCount=true'];
  if (f.biblioteca) p.push(`parentId=${f.biblioteca}`);
  if (f.naoVistos) p.push('filters=IsUnplayed');
  if (f.genero) p.push(`genreIds=${f.genero}`);
  if (f.letra === '#') p.push('nameLessThan=A');
  else if (f.letra) p.push(`nameStartsWith=${encodeURIComponent(f.letra)}`);
  return `/Items?${p.join('&')}`;
}

export const explorar = (s: Sessao, f: Filtro, inicio = 0, limite = 48) =>
  obter<{ Items: Item[]; TotalRecordCount: number }>(s, consultaExplorar(s, f, inicio, limite));

export type Genero = { Id: string; Name: string };
export const generos = (s: Sessao, biblioteca?: string) =>
  obter<{ Items: Genero[] }>(s, `/Genres?userId=${s.usuarioId}&sortBy=SortName&includeItemTypes=Movie,Series` +
    (biblioteca ? `&parentId=${biblioteca}` : '')).then(d => d.Items);

export const semelhantes = (s: Sessao, id: string, limite = 12) =>
  obter<{ Items: Item[] }>(s, `/Items/${id}/Similar?userId=${s.usuarioId}&limit=${limite}&${CAMPOS}`).then(d => d.Items);

// busca da paleta: títulos e episódios num pedido só (o servidor ordena por relevância)
export async function buscaRapida(s: Sessao, termo: string, sinal?: AbortSignal): Promise<Item[]> {
  const r = await fetch(`${s.servidor}/Items?userId=${s.usuarioId}&searchTerm=${encodeURIComponent(termo)}&recursive=true` +
    `&includeItemTypes=Movie,Series,Episode&limit=14&${CAMPOS}`, { headers: { Authorization: cabecalho(s.token) }, signal: sinal });
  if (!r.ok) throw new Error(`busca: ${r.status}`);
  return (await r.json() as { Items: Item[] }).Items;
}

// "Minha lista": favoritos de todas as bibliotecas, os mais recentes primeiro
export const minhaLista = (s: Sessao) =>
  obter<{ Items: Item[] }>(s, `/Items?userId=${s.usuarioId}&recursive=true&filters=IsFavorite&includeItemTypes=Movie,Series` +
    `&sortBy=DatePlayed,DateCreated&sortOrder=Descending&limit=120&${CAMPOS}`).then(d => d.Items);

// buscas recentes que levaram a abrir um título (só o texto)
const CHAVE = 'lume.buscas';
export function recentes(): string[] { try { return JSON.parse(localStorage.getItem(CHAVE) || '[]'); } catch { return []; } }
export function lembrarBusca(t: string) {
  const x = t.trim(); if (!x) return;
  const l = [x, ...recentes().filter(y => y.toLowerCase() !== x.toLowerCase())].slice(0, 8);
  try { localStorage.setItem(CHAVE, JSON.stringify(l)); } catch { /* nada */ }
}
export function esquecerBusca(t?: string) {
  const l = t ? recentes().filter(y => y !== t) : [];
  try { localStorage.setItem(CHAVE, JSON.stringify(l)); } catch { /* nada */ }
}
