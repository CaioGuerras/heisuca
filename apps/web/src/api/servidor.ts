// Contrato comum. Cada chamada leva sua sessão: chamadas pendentes não seguem a troca de servidor.
import type { Sessao, TipoServidor, Item, Pessoa, Hashes, EmBreve, Usuario, LegendaRemota, OpcoesReproducao, Plano, FluxoPlano, PosicaoRelato } from './tipos.ts';
import { jellyfin } from './jellyfin.ts';
import { plex } from './plex.ts';
export type * from './tipos.ts';
export { quandoExpirar } from './expiracao.ts';
export { entradaJellyfin } from './entrada-jellyfin.ts';
export { entradaPlex } from './entrada-plex.ts';
export { autorizarPlex, cancelada, conectarPlex, ErroEntradaPlex, passoSeguinte, type Autorizacao, type RecursoPlex } from './fluxo-plex.ts';

// Suporte estático do adaptador; disponibilidade de Quick Connect/Seerr continua na detecção atual.
export type Capacidades = { favoritos: boolean; trocarSenha: boolean; foto: boolean; legendasRemotas: boolean;
  capitulos: boolean; emAlta: boolean; emBreve: boolean };
export type PaginaBusca = { Items: Item[]; TotalRecordCount: number };
export interface ApiServidor {
  bibliotecas(s: Sessao): Promise<Item[]>;
  bibliotecasDeVideo(s: Sessao): Promise<Item[]>;
  continuar(s: Sessao): Promise<Item[]>;
  proximos(s: Sessao): Promise<Item[]>;
  novidades(s: Sessao, bibliotecaId: string, limite?: number): Promise<Item[]>;
  destaque(s: Sessao, limite?: number): Promise<Item[]>;
  daBiblioteca(s: Sessao, bibliotecaId: string, inicio?: number, limite?: number): Promise<{ Items: Item[]; TotalRecordCount: number }>;
  daColecao(s: Sessao, colecaoId: string): Promise<Item[]>;
  favoritos(s: Sessao, bibliotecaId: string, limite?: number): Promise<{ Items: Item[]; TotalRecordCount: number }>;
  buscar(s: Sessao, termo: string, bibliotecaId: string): Promise<Item[]>;
  buscar(s: Sessao, termo: string, bibliotecaId: string, inicio: number, limite?: number, sinal?: AbortSignal): Promise<PaginaBusca>;
  porIds(s: Sessao, ids: string[]): Promise<Item[]>;
  item(s: Sessao, id: string): Promise<Item>;
  temporadas(s: Sessao, serieId: string): Promise<Item[]>;
  episodios(s: Sessao, serieId: string, temporadaId: string): Promise<Item[]>;
  proximoDaSerie(s: Sessao, serieId: string): Promise<Item | null>;
  seguinte(s: Sessao, ep: Item): Promise<Item | null>;
  anterior(s: Sessao, ep: Item): Promise<Item | null>;
  emAlta(s: Sessao): Promise<{ titulo: string; itens: Item[] }>;
  emBreve(s: Sessao, tipo: 'tv' | 'movie'): Promise<EmBreve[]>;
  capaBiblioteca(s: Sessao, i: Item): string;
  capa(s: Sessao, i: Item, altura?: number): string;
  fundo(s: Sessao, i: Item, largura?: number): string;
  logo(s: Sessao, i: Item, largura?: number): string;
  paisagem(s: Sessao, i: Item, largura?: number): string;
  fotoPessoa(s: Sessao, p: Pessoa, largura?: number): string;
  fotoUsuario(s: Sessao, largura?: number): string;
  hashDe(s: Sessao, i: Item | null | undefined, tipo?: keyof Hashes): string | undefined;
  temArte(s: Sessao, i: Item): boolean;
  marcarAssistido(s: Sessao, id: string, sim: boolean): Promise<Item['UserData']>;
  favoritar(s: Sessao, id: string, sim: boolean): Promise<Item['UserData']>;
  euMesmo(s: Sessao): Promise<Usuario>;
  trocarSenha(s: Sessao, atual: string, nova: string): Promise<unknown>;
  trocarFoto(s: Sessao, arquivo: Blob): Promise<unknown>;
  removerFoto(s: Sessao): Promise<unknown>;
  buscarLegendas(s: Sessao, itemId: string, idioma: string): Promise<LegendaRemota[]>;
  baixarLegenda(s: Sessao, itemId: string, legendaId: string): Promise<unknown>;
  preparar(s: Sessao, item: Pick<Item, 'Id'>, opcoes: OpcoesReproducao): Promise<Plano>;
  faixas(s: Sessao, plano: Plano, opcoes: OpcoesReproducao): Promise<FluxoPlano[]>;
  relatar(s: Sessao, plano: Plano, fase: 'inicio' | 'progresso' | 'fim', posicao: PosicaoRelato): Promise<unknown>;
  parar(s: Sessao, plano: Plano): Promise<unknown>;
  capacidades(): Readonly<Capacidades>;
}

// Uma instância por tipo, sem leitura de localStorage.
const adaptadores: Partial<Record<TipoServidor, ApiServidor>> = { jellyfin, plex };
export function adaptador(tipo: TipoServidor): ApiServidor {
  const api = adaptadores[tipo];
  if (!api) throw new Error(`Adaptador ${tipo} ainda não disponível.`);
  return api;
}
export const apiDe = (s: Sessao): ApiServidor => adaptador(s.tipo);
// As telas escondem o que o servidor da sessão não faz (favoritos, senha, foto, em alta, em breve). Jellyfin: tudo true.
export const pode = (s: Sessao, c: keyof Capacidades): boolean => apiDe(s).capacidades()[c];

// Fachada mantém chamadas explícitas das telas, sem expor transporte/URLs específicos de Jellyfin.
export const bibliotecas: ApiServidor['bibliotecas'] = (s, ...args) => apiDe(s).bibliotecas(s, ...args);
export const bibliotecasDeVideo: ApiServidor['bibliotecasDeVideo'] = (s, ...args) => apiDe(s).bibliotecasDeVideo(s, ...args);
export const continuar: ApiServidor['continuar'] = (s, ...args) => apiDe(s).continuar(s, ...args);
export const proximos: ApiServidor['proximos'] = (s, ...args) => apiDe(s).proximos(s, ...args);
export const novidades: ApiServidor['novidades'] = (s, ...args) => apiDe(s).novidades(s, ...args);
export const destaque: ApiServidor['destaque'] = (s, ...args) => apiDe(s).destaque(s, ...args);
export const daBiblioteca: ApiServidor['daBiblioteca'] = (s, ...args) => apiDe(s).daBiblioteca(s, ...args);
export const daColecao: ApiServidor['daColecao'] = (s, ...args) => apiDe(s).daColecao(s, ...args);
export const favoritos: ApiServidor['favoritos'] = (s, ...args) => apiDe(s).favoritos(s, ...args);
export function buscar(s: Sessao, termo: string, bibliotecaId: string): Promise<Item[]>;
export function buscar(s: Sessao, termo: string, bibliotecaId: string, inicio: number, limite?: number, sinal?: AbortSignal): Promise<PaginaBusca>;
export function buscar(s: Sessao, termo: string, bibliotecaId: string, inicio?: number, limite?: number, sinal?: AbortSignal) {
  return inicio === undefined ? apiDe(s).buscar(s, termo, bibliotecaId) : apiDe(s).buscar(s, termo, bibliotecaId, inicio, limite, sinal);
}
export const porIds: ApiServidor['porIds'] = (s, ...args) => apiDe(s).porIds(s, ...args);
export const item: ApiServidor['item'] = (s, ...args) => apiDe(s).item(s, ...args);
export const temporadas: ApiServidor['temporadas'] = (s, ...args) => apiDe(s).temporadas(s, ...args);
export const episodios: ApiServidor['episodios'] = (s, ...args) => apiDe(s).episodios(s, ...args);
export const proximoDaSerie: ApiServidor['proximoDaSerie'] = (s, ...args) => apiDe(s).proximoDaSerie(s, ...args);
export const seguinte: ApiServidor['seguinte'] = (s, ...args) => apiDe(s).seguinte(s, ...args);
export const anterior: ApiServidor['anterior'] = (s, ...args) => apiDe(s).anterior(s, ...args);
export const emAlta: ApiServidor['emAlta'] = (s, ...args) => apiDe(s).emAlta(s, ...args);
export const emBreve: ApiServidor['emBreve'] = (s, ...args) => apiDe(s).emBreve(s, ...args);
export const capaBiblioteca: ApiServidor['capaBiblioteca'] = (s, ...args) => apiDe(s).capaBiblioteca(s, ...args);
export const capa: ApiServidor['capa'] = (s, ...args) => apiDe(s).capa(s, ...args);
export const fundo: ApiServidor['fundo'] = (s, ...args) => apiDe(s).fundo(s, ...args);
export const logo: ApiServidor['logo'] = (s, ...args) => apiDe(s).logo(s, ...args);
export const paisagem: ApiServidor['paisagem'] = (s, ...args) => apiDe(s).paisagem(s, ...args);
export const fotoPessoa: ApiServidor['fotoPessoa'] = (s, ...args) => apiDe(s).fotoPessoa(s, ...args);
export const fotoUsuario: ApiServidor['fotoUsuario'] = (s, ...args) => apiDe(s).fotoUsuario(s, ...args);
export const hashDe: ApiServidor['hashDe'] = (s, ...args) => apiDe(s).hashDe(s, ...args);
export const temArte: ApiServidor['temArte'] = (s, ...args) => apiDe(s).temArte(s, ...args);
export const marcarAssistido: ApiServidor['marcarAssistido'] = (s, ...args) => apiDe(s).marcarAssistido(s, ...args);
export const favoritar: ApiServidor['favoritar'] = (s, ...args) => apiDe(s).favoritar(s, ...args);
export const euMesmo: ApiServidor['euMesmo'] = (s, ...args) => apiDe(s).euMesmo(s, ...args);
export const trocarSenha: ApiServidor['trocarSenha'] = (s, ...args) => apiDe(s).trocarSenha(s, ...args);
export const trocarFoto: ApiServidor['trocarFoto'] = (s, ...args) => apiDe(s).trocarFoto(s, ...args);
export const removerFoto: ApiServidor['removerFoto'] = (s, ...args) => apiDe(s).removerFoto(s, ...args);
export const buscarLegendas: ApiServidor['buscarLegendas'] = (s, ...args) => apiDe(s).buscarLegendas(s, ...args);
export const baixarLegenda: ApiServidor['baixarLegenda'] = (s, ...args) => apiDe(s).baixarLegenda(s, ...args);
export const preparar: ApiServidor['preparar'] = (s, ...args) => apiDe(s).preparar(s, ...args);
export const faixas: ApiServidor['faixas'] = (s, ...args) => apiDe(s).faixas(s, ...args);
export const relatar: ApiServidor['relatar'] = (s, ...args) => apiDe(s).relatar(s, ...args);
export const parar: ApiServidor['parar'] = (s, ...args) => apiDe(s).parar(s, ...args);
