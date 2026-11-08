// Adaptador PMS. Referência medida: services/plex_client.dart e plex_mappers.dart (master).
import type { ApiServidor } from './servidor.ts';
import type { Sessao, Item, Pessoa, Fluxo, OpcoesReproducao, Plano } from './tipos.ts';
import { urlPlex, respostaPlex, ErroPlex, type QueryPlex } from './plex-tv.ts';
import { notificarExpiracao } from './expiracao.ts';

type Stream = { id: number; streamType: number; codec?: string; languageCode?: string; languageTag?: string;
  displayTitle?: string; title?: string; default?: boolean; selected?: boolean; forced?: boolean; key?: string;
  channels?: number; width?: number; height?: number; bitDepth?: number; frameRate?: number; bitrate?: number };
type Part = { id: number | string; key?: string; container?: string; duration?: number; Stream?: Stream[] };
type Media = { container?: string; duration?: number; videoCodec?: string; audioCodec?: string; Part?: Part[] };
type Metadado = { ratingKey?: string | number; key?: string; type?: string; title?: string;
  grandparentTitle?: string; parentTitle?: string; grandparentRatingKey?: string; parentRatingKey?: string;
  index?: number; parentIndex?: number; year?: number; originallyAvailableAt?: string; contentRating?: string;
  audienceRating?: number; rating?: number; summary?: string; tagline?: string; studio?: string; childCount?: number;
  Genre?: { tag: string }[]; Role?: { id: number; tag: string; role?: string; thumb?: string }[];
  Chapter?: { tag?: string; startTimeOffset: number }[]; Media?: Media[]; duration?: number; viewOffset?: number;
  viewCount?: number; leafCount?: number; viewedLeafCount?: number; thumb?: string; art?: string; grandparentArt?: string;
  grandparentThumb?: string; Image?: { type: string; url: string }[]; addedAt?: number };
type Container = { Metadata?: Metadado[]; Directory?: Metadado[]; Hub?: Container[]; totalSize?: number; size?: number };
const ticks = (ms?: number) => ms === undefined ? undefined : ms * 10_000;
const id = (v: string | number | undefined) => v === undefined ? undefined : String(v);
const cod = encodeURIComponent;
const adicionado = new WeakMap<Item, number>();
const streams = (m: Metadado) => m.Media?.[0]?.Part?.[0]?.Stream || [];
const tipo: Record<string, string> = { movie: 'Movie', show: 'Series', season: 'Season', episode: 'Episode', collection: 'BoxSet' };
function fluxo(f: Stream): Fluxo {
  return { Index: f.id, Type: ({ 1: 'Video', 2: 'Audio', 3: 'Subtitle' } as Record<number, string>)[f.streamType] || '',
    Codec: f.codec, Language: f.languageTag?.toLowerCase() === 'pt-br' ? 'pt-br' : f.languageCode,
    DisplayTitle: f.displayTitle, Title: f.title, IsDefault: f.default, IsForced: f.forced, IsExternal: !!f.key,
    Channels: f.channels, Width: f.width, Height: f.height, BitDepth: f.bitDepth, AverageFrameRate: f.frameRate,
    BitRate: f.bitrate === undefined ? undefined : f.bitrate * 1000 };
}
function mapear(m: Metadado): Item {
  const i: Item = { Id: id(m.ratingKey) || '', Type: tipo[m.type || ''] || '', Name: m.title || '',
    SeriesName: m.grandparentTitle, SeasonName: m.parentTitle, SeriesId: id(m.grandparentRatingKey), SeasonId: id(m.parentRatingKey),
    ParentId: id(m.parentRatingKey), IndexNumber: m.index, ParentIndexNumber: m.parentIndex, ProductionYear: m.year,
    PremiereDate: m.originallyAvailableAt, OfficialRating: m.contentRating, CommunityRating: m.audienceRating ?? m.rating,
    Overview: m.summary, Taglines: m.tagline ? [m.tagline] : undefined, Genres: m.Genre?.map(g => g.tag),
    Studios: m.studio ? [{ Name: m.studio }] : undefined, ChildCount: m.childCount,
    People: m.Role?.map(p => ({ Id: String(p.id), Name: p.tag, Role: p.role, PrimaryImageTag: p.thumb })),
    Chapters: m.Chapter?.map(c => ({ Name: c.tag, StartPositionTicks: ticks(c.startTimeOffset)! })),
    MediaStreams: streams(m).map(fluxo), RunTimeTicks: ticks(m.duration),
    ImageTags: { ...(m.thumb ? { Primary: m.thumb } : {}),
      ...(m.Image?.find(i => i.type === 'clearLogo')?.url ? { Logo: m.Image.find(i => i.type === 'clearLogo')!.url } : {}) },
    BackdropImageTags: m.art ? [m.art] : undefined, SeriesPrimaryImageTag: m.grandparentThumb,
    ParentBackdropItemId: m.grandparentRatingKey, ParentBackdropImageTags: m.grandparentArt ? [m.grandparentArt] : undefined,
    UserData: { Played: (m.viewCount || 0) > 0, PlaybackPositionTicks: ticks(m.viewOffset),
      PlayedPercentage: m.duration ? (m.viewOffset || 0) / m.duration * 100 : undefined,
      UnplayedItemCount: m.leafCount === undefined ? undefined : Math.max(0, m.leafCount - (m.viewedLeafCount || 0)), IsFavorite: false } };
  adicionado.set(i, m.addedAt || 0);
  return i;
}
async function pedir(s: Sessao, caminho: string, query?: QueryPlex, metodo?: string, keepalive = false) {
  try { return await respostaPlex(urlPlex(s.servidor, caminho, s.token, query), metodo, undefined, keepalive); }
  catch (e) { if (e instanceof ErroPlex && e.status === 401) notificarExpiracao(); throw e; }
}
async function ler(s: Sessao, caminho: string, query?: QueryPlex): Promise<Container> {
  const d = await (await pedir(s, caminho, query)).json() as { MediaContainer?: Container };
  return d.MediaContainer || {};
}
const metadata = (d: Container) => d.Metadata || [];
const itens = (d: Container) => metadata(d).map(mapear);
async function todos(s: Sessao, caminho: string): Promise<Item[]> {
  const saida: Item[] = [], paginas = new Set<string>(); let inicio = 0;
  while (true) {
    const d = await ler(s, caminho, { 'X-Plex-Container-Start': inicio, 'X-Plex-Container-Size': 100 });
    const lista = itens(d), assinatura = JSON.stringify(lista.map(i => i.Id));
    if (!lista.length || paginas.has(assinatura)) break;
    paginas.add(assinatura); saida.push(...lista); inicio += lista.length;
    if (d.totalSize !== undefined && inicio >= d.totalSize) break;
  }
  return saida;
}
async function bibliotecas(s: Sessao): Promise<Item[]> {
  const d = await ler(s, '/library/sections');
  return (d.Directory || []).map(b => ({ ...mapear(b), Id: b.key || '',
    CollectionType: ({ movie: 'movies', show: 'tvshows' } as Record<string, string>)[b.type || ''] || b.type }));
}
const bibliotecasDeVideo = (s: Sessao) => bibliotecas(s).then(l => l.filter(b => ['movies', 'tvshows'].includes(b.CollectionType || '')));
async function continuar(s: Sessao): Promise<Item[]> {
  const d = await ler(s, '/hubs', { identifier: 'home.continue,home.ondeck' });
  const saida: Item[] = [];
  for (const i of (d.Hub || []).flatMap(itens)) {
    const n = saida.findIndex(x => x.Id === i.Id || (i.Type === 'Episode' && i.SeriesId && x.SeriesId === i.SeriesId));
    if (n < 0) saida.push(i);
    else if (!saida[n].UserData?.PlaybackPositionTicks && i.UserData?.PlaybackPositionTicks) saida[n] = i;
  }
  return saida;
}
async function porIds(s: Sessao, ids: string[]): Promise<Item[]> {
  return ids.length ? itens(await ler(s, '/library/metadata/' + ids.map(cod).join(','))) : [];
}
async function item(s: Sessao, chave: string): Promise<Item> {
  const i = itens(await ler(s, `/library/metadata/${cod(chave)}`, { includeChapters: 1 }))[0];
  if (!i) throw new Error('Item Plex não encontrado.');
  return i;
}
async function novidades(s: Sessao, biblioteca: string, limite = 20): Promise<Item[]> {
  const recentes = itens(await ler(s, `/library/sections/${cod(biblioteca)}/recentlyAdded`, { 'X-Plex-Container-Size': limite }));
  const ids = [...new Set(recentes.filter(i => i.Type === 'Season' || i.Type === 'Episode')
    .map(i => i.Type === 'Episode' ? i.SeriesId : i.ParentId).filter((id): id is string => !!id))];
  const series = await porIds(s, ids), mapa = new Map(series.map(i => [i.Id, i]));
  const unicos = new Map<string, Item>();
  for (const i of recentes) {
    const serie = i.Type === 'Episode' ? i.SeriesId : i.Type === 'Season' ? i.ParentId : undefined;
    const obra = serie ? mapa.get(serie) : i;
    if (obra && !unicos.has(obra.Id)) { adicionado.set(obra, adicionado.get(i) || 0); unicos.set(obra.Id, obra); }
  }
  return [...unicos.values()].slice(0, limite);
}
async function destaque(s: Sessao, limite = 9): Promise<Item[]> {
  const libs = await bibliotecasDeVideo(s);
  const todas = (await Promise.all(libs.map(b => novidades(s, b.Id, limite)))).flat();
  return todas.sort((a, b) => (adicionado.get(b) || 0) - (adicionado.get(a) || 0))
    .filter((i, n, l) => l.findIndex(x => x.Id === i.Id) === n).slice(0, limite);
}
async function daBiblioteca(s: Sessao, biblioteca: string, inicio = 0, limite = 60) {
  const d = await ler(s, `/library/sections/${cod(biblioteca)}/all`, { 'X-Plex-Container-Start': inicio, 'X-Plex-Container-Size': limite });
  return { Items: itens(d), TotalRecordCount: d.totalSize ?? d.size ?? 0 };
}
const folhas = (s: Sessao, serie: string) => ler(s, `/library/metadata/${cod(serie)}/allLeaves`).then(itens);
async function buscar(s: Sessao, termo: string, biblioteca: string): Promise<Item[]> {
  const d = await ler(s, '/hubs/search', { query: termo, sectionId: biblioteca, limit: 30 });
  return (d.Hub || []).flatMap(itens).filter(i => i.Type === 'Movie' || i.Type === 'Series')
    .filter((i, n, l) => l.findIndex(x => x.Id === i.Id) === n);
}
function imagem(s: Sessao, caminho?: string, largura?: number, altura?: number): string {
  return caminho ? urlPlex(s.servidor, '/photo/:/transcode', s.token, { width: largura, height: altura, minSize: 1,
    // master plex_client.dart:4620-4627: evita reconversão repetida no PMS.
    upscale: 0, url: caminho }) : '';
}
const capa = (s: Sessao, i: Item, altura = 360) => imagem(s, i.Type === 'Episode' ? i.SeriesPrimaryImageTag || i.ImageTags?.Primary : i.ImageTags?.Primary, undefined, altura);
const fundo = (s: Sessao, i: Item, largura = 1920) => imagem(s, i.BackdropImageTags?.[0] || i.ParentBackdropImageTags?.[0], largura);
const logo = (s: Sessao, i: Item, largura = 600) => imagem(s, i.ImageTags?.Logo || i.ParentLogoImageTag, largura);
const naoSuportado = async (): Promise<never> => { throw new Error('naoSuportado'); };
const capacidades = Object.freeze({ favoritos: false, trocarSenha: false, foto: false, legendasRemotas: false,
  capitulos: true, emAlta: false, emBreve: false });

// Reprodução é implementada no commit seguinte, após o catálogo/entrada verde.
const preparar = (_s: Sessao, _i: Pick<Item, 'Id'>, _o: OpcoesReproducao): Promise<Plano> => naoSuportado();
export const plex: ApiServidor = {
  bibliotecas, bibliotecasDeVideo, continuar, proximos: s => continuar(s).then(l => l.filter(i => i.Type === 'Episode')),
  novidades, destaque, daBiblioteca, daColecao: (s, id) => todos(s, `/library/collections/${cod(id)}/children`),
  favoritos: async () => ({ Items: [], TotalRecordCount: 0 }), porIds, item,
  temporadas: (s, id) => todos(s, `/library/metadata/${cod(id)}/children`),
  episodios: (s, _serie, temporada) => todos(s, `/library/metadata/${cod(temporada)}/children`),
  proximoDaSerie: (s, id) => folhas(s, id).then(l => l.find(i => !i.UserData?.Played) || null),
  seguinte: (s, ep) => folhas(s, ep.SeriesId || '').then(l => { const n = l.findIndex(i => i.Id === ep.Id); return n < 0 ? null : l[n + 1] || null; }),
  anterior: (s, ep) => folhas(s, ep.SeriesId || '').then(l => { const n = l.findIndex(i => i.Id === ep.Id); return n > 0 ? l[n - 1] : null; }),
  emAlta: async () => ({ titulo: '', itens: [] }), emBreve: async () => [], buscar,
  capaBiblioteca: (s, i) => imagem(s, i.ImageTags?.Primary, 480), capa, fundo, logo,
  paisagem: (s, i, largura = 480) => imagem(s, i.ImageTags?.Primary || i.BackdropImageTags?.[0] || i.ParentBackdropImageTags?.[0], largura),
  fotoPessoa: (s: Sessao, p: Pessoa, largura = 160) => imagem(s, p.PrimaryImageTag, largura), fotoUsuario: s => s.fotoTag || '',
  hashDe: () => undefined, temArte: (_s, i) => !!((i.BackdropImageTags?.length || i.ParentBackdropImageTags?.length) && (i.ImageTags?.Logo || i.ParentLogoImageTag)),
  marcarAssistido: async (s, chave, sim) => {
    await pedir(s, sim ? '/:/scrobble' : '/:/unscrobble', { key: chave, identifier: 'com.plexapp.plugins.library' });
    return (await item(s, chave)).UserData;
  },
  euMesmo: async s => ({ Id: s.usuarioId, Name: s.nome, PrimaryImageTag: s.fotoTag, Policy: { EnableSubtitleManagement: false } }),
  favoritar: naoSuportado, trocarSenha: naoSuportado, trocarFoto: naoSuportado, removerFoto: naoSuportado,
  buscarLegendas: naoSuportado, baixarLegenda: naoSuportado, capacidades: () => capacidades,
  preparar, faixas: naoSuportado, relatar: naoSuportado, parar: async () => undefined,
};
