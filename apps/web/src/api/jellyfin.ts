import { ordemValida, type OrdemBiblioteca } from '../dados/ordem-biblioteca.ts';
import { previaJellyfin } from './trickplay.ts';
import type { ApiServidor, PaginaBusca } from './servidor.ts';
// Cliente Jellyfin mínimo, escrito do zero (só fetch). Cada função é um endpoint da API REST oficial (10.9+).
// Regra do PLANO §1.7: só aparece dado que o servidor tem; nada de valor inventado na falta.
import { VERSAO, idAparelho } from './contas.ts';
import { notificarExpiracao } from './expiracao.ts';
import type { Sessao, Hashes, Pessoa, Item, Usuario, LegendaRemota, Fluxo, EmBreve, Plano, FluxoPlano, OpcoesReproducao, PosicaoRelato } from './tipos.ts';
export type { Sessao, Item, Fluxo, LegendaRemota } from './tipos.ts';

export function cabecalho(token?: string): string {
  const p = [`Client="Heisuca"`, `Device="Navegador"`, `DeviceId="${idAparelho()}"`, `Version="${VERSAO}"`];
  if (token) p.push(`Token="${token}"`);
  return 'MediaBrowser ' + p.join(', ');
}

export async function pedir(s: Sessao, metodo: string, caminho: string, corpo?: unknown, keepalive = false, tipo = 'application/json'): Promise<Response> {
  const r = await fetch(s.servidor + caminho, {
    method: metodo, keepalive,
    headers: { Authorization: cabecalho(s.token), ...(corpo === undefined ? {} : { 'Content-Type': tipo }) },
    body: corpo === undefined ? undefined : typeof corpo === 'string' ? corpo : JSON.stringify(corpo),
  });
  if (r.status === 401) { notificarExpiracao(s); throw new Error('sessão vencida'); }
  if (!r.ok) throw new Error(`${caminho.split('?')[0]}: ${r.status}`);
  return r;
}
export const obter = <T,>(s: Sessao, caminho: string): Promise<T> => pedir(s, 'GET', caminho).then(r => r.json());

// ---- imagens (o servidor redimensiona; o tag faz o cache do navegador valer para sempre) ----
// Sempre WebP: o site exige Safari 15+/Chrome/Edge/Firefox atuais, todos leem WebP; o Jellyfin 10.11 converte na hora
// (e guarda em cache). Mesma qualidade do JPEG, arquivo bem menor; logos mantêm a transparência (WebP tem alfa).
const WEBP = 'format=Webp';
export type Medida = { largura?: number; altura?: number; qualidade?: number };
export function imagem(s: Sessao, id: string, tipo: string, tag?: string, m: Medida = {}, indice?: number): string {
  const q = [m.largura && `fillWidth=${Math.round(m.largura)}`, m.altura && `fillHeight=${Math.round(m.altura)}`,
    `quality=${m.qualidade ?? 85}`, WEBP, tag && `tag=${tag}`].filter(Boolean).join('&');
  return `${s.servidor}/Items/${id}/Images/${tipo}${indice !== undefined ? `/${indice}` : ''}?${q}`;
}
// pôster 2:3 (episódio cai no pôster da série)
export function capa(s: Sessao, i: Item, altura = 360): string {
  if (i.ImageTags?.Primary && i.Type !== 'Episode') return imagem(s, i.Id, 'Primary', i.ImageTags.Primary, { altura, qualidade: 90 });
  if (i.SeriesId && i.SeriesPrimaryImageTag) return imagem(s, i.SeriesId, 'Primary', i.SeriesPrimaryImageTag, { altura, qualidade: 90 });
  if (i.ImageTags?.Primary) return imagem(s, i.Id, 'Primary', i.ImageTags.Primary, { altura, qualidade: 90 });
  return '';
}
export function fundo(s: Sessao, i: Item, largura = 1920): string {
  if (i.BackdropImageTags?.length) return imagem(s, i.Id, 'Backdrop', i.BackdropImageTags[0], { largura, qualidade: 80 }, 0);
  if (i.ParentBackdropItemId && i.ParentBackdropImageTags?.length)
    return imagem(s, i.ParentBackdropItemId, 'Backdrop', i.ParentBackdropImageTags[0], { largura, qualidade: 80 }, 0);
  return '';
}
export function logo(s: Sessao, i: Item, largura = 600): string {
  if (i.ImageTags?.Logo) return imagem(s, i.Id, 'Logo', i.ImageTags.Logo, { largura, qualidade: 90 });
  if (i.ParentLogoItemId && i.ParentLogoImageTag) return imagem(s, i.ParentLogoItemId, 'Logo', i.ParentLogoImageTag, { largura, qualidade: 90 });
  return '';
}
// 16:9: miniatura do episódio, Thumb do filme/série, senão o fundo
export function paisagem(s: Sessao, i: Item, largura = 480): string {
  if (i.Type === 'Episode' && i.ImageTags?.Primary) return imagem(s, i.Id, 'Primary', i.ImageTags.Primary, { largura });
  if (i.ImageTags?.Thumb) return imagem(s, i.Id, 'Thumb', i.ImageTags.Thumb, { largura });
  if (i.ParentThumbItemId && i.ParentThumbImageTag) return imagem(s, i.ParentThumbItemId, 'Thumb', i.ParentThumbImageTag, { largura });
  return fundo(s, i, largura);
}
export const fotoPessoa = (s: Sessao, p: Pessoa, largura = 160) =>
  p.PrimaryImageTag ? imagem(s, p.Id, 'Primary', p.PrimaryImageTag, { largura, qualidade: 85 }) : '';
export const fotoUsuario = (s: Sessao, largura = 96) =>
  s.fotoTag ? `${s.servidor}/Users/${s.usuarioId}/Images/Primary?fillWidth=${largura}&quality=90&${WEBP}&tag=${s.fotoTag}` : '';

// BlurHash que o servidor já guarda de cada imagem (a cor da tela sai daqui; PLANO §2.2)
export function hashDe(i: Item | null | undefined, tipo: keyof Hashes = 'Backdrop'): string | undefined {
  if (!i?.ImageBlurHashes) return undefined;
  const t = i.ImageBlurHashes[tipo];
  if (!t) return undefined;
  const tag = tipo === 'Backdrop' ? (i.BackdropImageTags?.[0] || i.ParentBackdropImageTags?.[0])
    : tipo === 'Primary' ? (i.ImageTags?.Primary || i.SeriesPrimaryImageTag)
    : tipo === 'Logo' ? (i.ImageTags?.Logo || i.ParentLogoImageTag) : i.ImageTags?.[tipo];
  return (tag && t[tag]) || Object.values(t)[0];
}

// ---- listas ----
const IMG = 'enableImageTypes=Primary,Backdrop,Thumb,Logo&imageTypeLimit=1';
const CAMPOS = `fields=Overview,Genres,PrimaryImageAspectRatio,ProductionYear,PremiereDate,EndDate,Status,OfficialRating,CommunityRating&${IMG}`;

export const bibliotecas = (s: Sessao) =>
  obter<{ Items: Item[] }>(s, `/UserViews?userId=${s.usuarioId}`).then(d => d.Items);

// bibliotecas de vídeo (filmes, séries, coleções e mistas), na ordem do servidor
export const bibliotecasDeVideo = (s: Sessao) => bibliotecas(s).then(l =>
  l.filter(b => !b.CollectionType || ['movies', 'tvshows', 'boxsets', 'homevideos', 'mixed'].includes(b.CollectionType)));

export const continuar = (s: Sessao) =>
  obter<{ Items: Item[] }>(s, `/UserItems/Resume?userId=${s.usuarioId}&limit=20&mediaTypes=Video&${CAMPOS}`).then(d => d.Items);

export const proximos = (s: Sessao) =>
  obter<{ Items: Item[] }>(s, `/Shows/NextUp?userId=${s.usuarioId}&limit=20&enableResumable=false&enableRewatching=false&${CAMPOS}`).then(d => d.Items);

export const novidades = (s: Sessao, bibliotecaId: string, limite = 20) =>
  obter<Item[]>(s, `/Items/Latest?userId=${s.usuarioId}&parentId=${bibliotecaId}&limit=${limite}&${CAMPOS}`);

// destaque: os últimos adicionados que têm fundo e logo (PLANO §4 [P])
export const paraDestaque = (s: Sessao, limite = 9) =>
  obter<{ Items: Item[] }>(s, `/Items?userId=${s.usuarioId}&recursive=true&includeItemTypes=Movie,Series&sortBy=DateCreated&sortOrder=Descending` +
    `&imageTypes=Logo&limit=${limite * 3}&${CAMPOS}`).then(d => d.Items.filter(i => i.BackdropImageTags?.length && i.ImageTags?.Logo).slice(0, limite));

// Biblioteca: ordenação e filtro no servidor, inclusive nas páginas seguintes.
export const daBiblioteca = (s: Sessao, bibliotecaId: string, inicio = 0, limite = 60, escolha?: OrdemBiblioteca) =>
  obter<{ Items: Item[]; TotalRecordCount: number }>(s, `/Items?userId=${s.usuarioId}&parentId=${bibliotecaId}&recursive=true` +
    `&includeItemTypes=Movie,Series,BoxSet&sortBy=${ordemValida(escolha?.ordem).jellyfin}&sortOrder=${ordemValida(escolha?.ordem).valor === 'nome' ? 'Ascending' : 'Descending'}${escolha?.naoVistos ? '&filters=IsUnplayed' : ''}&startIndex=${inicio}&limit=${limite}&${CAMPOS}`);

// títulos de uma coleção (BoxSet), na ordem de lançamento (tela Título da coleção)
export const daColecao = (s: Sessao, colecaoId: string) =>
  obter<{ Items: Item[]; TotalRecordCount: number }>(s, `/Items?userId=${s.usuarioId}&parentId=${colecaoId}` +
    `&sortBy=PremiereDate,ProductionYear,SortName&sortOrder=Ascending&${CAMPOS}`).then(d => d.Items);

// favoritos de uma biblioteca (a tela Favoritos separa por biblioteca: PLANO §7)
export const favoritosDe = (s: Sessao, bibliotecaId: string, limite = 30) =>
  obter<{ Items: Item[]; TotalRecordCount: number }>(s, `/Items?userId=${s.usuarioId}&parentId=${bibliotecaId}&recursive=true&filters=IsFavorite` +
    `&includeItemTypes=Movie,Series,BoxSet&sortBy=SortName&limit=${limite}&${CAMPOS}`);

export const buscarAcervo = (s: Sessao, termo: string) =>
  obter<{ Items: Item[] }>(s, `/Items?userId=${s.usuarioId}&searchTerm=${encodeURIComponent(termo)}&recursive=true` +
    `&includeItemTypes=Movie,Series&limit=40&${CAMPOS}`).then(d => d.Items);

export const porIds = (s: Sessao, ids: string[]) => ids.length
  ? obter<{ Items: Item[] }>(s, `/Items?userId=${s.usuarioId}&ids=${ids.join(',')}&${CAMPOS}`).then(d => d.Items)
  : Promise.resolve([] as Item[]);

// ---- título ----
const CAMPOS_TITULO = `fields=Trickplay,RemoteTrailers,LocalTrailerCount,Overview,Genres,Taglines,Studios,People,Chapters,MediaStreams,ChildCount,PrimaryImageAspectRatio,` +
  `ProductionYear,PremiereDate,EndDate,Status,OfficialRating,CommunityRating&${IMG}`;
export const item = (s: Sessao, id: string) => obter<Item>(s, `/Items/${id}?userId=${s.usuarioId}&${CAMPOS_TITULO}`);

export const temporadas = (s: Sessao, serieId: string) =>
  obter<{ Items: Item[] }>(s, `/Shows/${serieId}/Seasons?userId=${s.usuarioId}&fields=ChildCount&${IMG}`).then(d => d.Items);

export const episodios = (s: Sessao, serieId: string, temporadaId: string) =>
  obter<{ Items: Item[] }>(s, `/Shows/${serieId}/Episodes?userId=${s.usuarioId}&seasonId=${temporadaId}&fields=Overview,MediaStreams&${IMG}`)
    .then(d => d.Items);

export const proximoDaSerie = (s: Sessao, serieId: string) =>
  obter<{ Items: Item[] }>(s, `/Shows/NextUp?userId=${s.usuarioId}&seriesId=${serieId}&limit=1&enableResumable=true&fields=Overview,MediaStreams`)
    .then(d => d.Items[0] ?? null);

// episódio seguinte a este na ordem da série (o "Próximo episódio" do player)
export const seguinte = (s: Sessao, ep: Item) =>
  obter<{ Items: Item[] }>(s, `/Shows/${ep.SeriesId}/Episodes?userId=${s.usuarioId}&startItemId=${ep.Id}&limit=2`).then(d => d.Items[1] ?? null);
export const anterior = async (s: Sessao, ep: Item) => {
  const d = await obter<{ Items: Item[] }>(s, `/Shows/${ep.SeriesId}/Episodes?userId=${s.usuarioId}&seasonId=${ep.SeasonId}`);
  const n = d.Items.findIndex(x => x.Id === ep.Id);
  return n > 0 ? d.Items[n - 1] : null;
};

// ---- ações do usuário ----
export const marcarAssistido = (s: Sessao, id: string, sim: boolean) =>
  pedir(s, sim ? 'POST' : 'DELETE', `/UserPlayedItems/${id}?userId=${s.usuarioId}`).then(r => r.json() as Promise<Item['UserData']>);
export const favoritar = (s: Sessao, id: string, sim: boolean) =>
  pedir(s, sim ? 'POST' : 'DELETE', `/UserFavoriteItems/${id}?userId=${s.usuarioId}`).then(r => r.json() as Promise<Item['UserData']>);

// ---- conta ----
export const euMesmo = (s: Sessao) => obter<Usuario>(s, `/Users/${s.usuarioId}`);
export const trocarSenha = (s: Sessao, atual: string, nova: string) =>
  pedir(s, 'POST', `/Users/${s.usuarioId}/Password`, { CurrentPw: atual, NewPw: nova });
// a API recebe a imagem em base64 no corpo, com o tipo da imagem no Content-Type (como o jellyfin-web faz)
export async function trocarFoto(s: Sessao, arquivo: Blob) {
  const b64 = await new Promise<string>((ok, erro) => { const r = new FileReader(); r.onload = () => ok(String(r.result).split(',')[1] || ''); r.onerror = erro; r.readAsDataURL(arquivo); });
  return pedir(s, 'POST', `/Users/${s.usuarioId}/Images/Primary`, b64, false, arquivo.type || 'image/jpeg');
}
export const removerFoto = (s: Sessao) => pedir(s, 'DELETE', `/Users/${s.usuarioId}/Images/Primary`);

// ---- legendas pela internet (plugin Open Subtitles; precisa da permissão "gerenciar legendas": PLANO §13) ----
export const buscarLegendas = (s: Sessao, itemId: string, idioma: 'pob' | 'por' | string) =>
  obter<LegendaRemota[]>(s, `/Items/${itemId}/RemoteSearch/Subtitles/${idioma}`);
export const baixarLegenda = (s: Sessao, itemId: string, legendaId: string) =>
  pedir(s, 'POST', `/Items/${itemId}/RemoteSearch/Subtitles/${encodeURIComponent(legendaId)}`);

// ---- reprodução ----
type Fonte = {
  Id: string; Container?: string; RunTimeTicks?: number; SupportsDirectPlay: boolean; SupportsDirectStream: boolean;
  SupportsTranscoding: boolean; TranscodingUrl?: string; MediaStreams: Fluxo[]; Size?: number; Bitrate?: number;
  DefaultAudioStreamIndex?: number; DefaultSubtitleStreamIndex?: number;
  MediaAttachments?: { Codec?: string; MimeType?: string; FileName?: string; DeliveryUrl?: string }[];
};
type Reproducao = { PlaySessionId: string; MediaSources: Fonte[]; ErrorCode?: string };

export const infoReproducao = (s: Sessao, id: string, corpo: Record<string, unknown>) =>
  pedir(s, 'POST', `/Items/${id}/PlaybackInfo?userId=${s.usuarioId}`, { UserId: s.usuarioId, ...corpo }).then(r => r.json() as Promise<Reproducao>);

export function urlDireta(s: Sessao, id: string, f: Fonte, sessaoReproducao: string): string {
  return `${s.servidor}/Videos/${id}/stream?static=true&mediaSourceId=${f.Id}&playSessionId=${sessaoReproducao}` +
    `&deviceId=${idAparelho()}&api_key=${s.token}`;
}

export const urlServidor = (s: Sessao, caminho: string) =>
  s.servidor + caminho + (caminho.includes('api_key=') || caminho.includes('ApiKey=') ? '' : `${caminho.includes('?') ? '&' : '?'}api_key=${s.token}`);

type Relato = {
  ItemId: string; MediaSourceId: string; PlaySessionId: string; PositionTicks: number; IsPaused: boolean;
  PlayMethod: 'DirectPlay' | 'DirectStream' | 'Transcode'; AudioStreamIndex?: number; SubtitleStreamIndex?: number; CanSeek: boolean;
};
const relatarJellyfin = (s: Sessao, fase: 'inicio' | 'progresso' | 'fim', r: Relato) =>
  pedir(s, 'POST', fase === 'inicio' ? '/Sessions/Playing' : fase === 'progresso' ? '/Sessions/Playing/Progress' : '/Sessions/Playing/Stopped',
    r, fase === 'fim').catch(() => undefined);

export const pararConversao = (s: Sessao, sessaoReproducao: string) =>
  pedir(s, 'DELETE', `/Videos/ActiveEncodings?deviceId=${idAparelho()}&playSessionId=${sessaoReproducao}`, undefined, true).catch(() => undefined);

// ---- listas que só alguns servidores publicam (o CGSERVER publica; sem elas, as fileiras não aparecem: PLANO §4) ----
// Top 10 do que o servidor tem, na ordem das tendências da semana (emalta.json, o mesmo que os apps leem)
export async function emAlta(s: Sessao): Promise<{ titulo: string; itens: Item[] }> {
  const j = await fetch(`${s.servidor}/cgflix/emalta.json?t=${Math.floor(Date.now() / 1800000)}`).then(r => r.ok ? r.json() : null) as { titulo?: string; itens?: { id: string }[] } | null;
  const ids = (j?.itens || []).map(i => i.id).filter(id => /^[0-9a-f]{32}$/.test(id)).slice(0, 10);
  if (!ids.length) return { titulo: '', itens: [] };
  const itens = await porIds(s, ids);
  const ordem = new Map(ids.map((id, n) => [id, n]));
  return { titulo: j?.titulo || 'Em alta', itens: itens.sort((a, b) => (ordem.get(a.Id) ?? 99) - (ordem.get(b.Id) ?? 99)) };
}

// Em breve: calendário do Sonarr/Radarr pelo plugin Home Screen Sections; o embreve.json diz, por id, o item do Jellyfin
// (temos → título) ou o TMDB (não temos → pedir). Mesma lógica do site atual.
type Secao = { Items?: { Name?: string; SeriesName?: string; PremiereDate?: string; ProviderIds?: Record<string, string>; Id?: string }[] };
let mapaEmBreve: Promise<{ m: Record<string, { jf: string | null; tmdb?: number }>; s: Record<string, { jf: string | null; tmdb?: number; nome?: string }> }> | null = null;
export async function emBreve(s: Sessao, tipo: 'tv' | 'movie'): Promise<EmBreve[]> {
  mapaEmBreve ??= fetch(`${s.servidor}/cgflix/embreve.json?t=${Math.floor(Date.now() / 600000)}`).then(r => { if (!r.ok) throw new Error('sem mapa'); return r.json(); });
  const [mapa, sec] = await Promise.all([mapaEmBreve,
    obter<Secao>(s, `/HomeScreen/Section/${tipo === 'tv' ? 'UpcomingShows' : 'UpcomingMovies'}?UserId=${s.usuarioId}`)]);
  const vistos = new Set<string>();
  return (sec.Items || []).flatMap(i => {
    const p = i.ProviderIds || {}, chave = tipo === 'tv' ? p.SonarrSeriesId : p.RadarrMovieId;
    const v = chave ? (tipo === 'tv' ? mapa.s : mapa.m)[chave] : undefined;
    if (!v || vistos.has(chave!)) return [];
    vistos.add(chave!);
    const nome = (tipo === 'tv' && mapa.s[chave!]?.nome) || i.SeriesName || i.Name || '';
    const poster = tipo === 'tv' ? p.SonarrPoster : p.RadarrPoster;  // capa do Sonarr/Radarr guardada pelo plugin
    const capa = poster && poster.startsWith('/HomeScreen/CachedImage/') ? s.servidor + poster
      : v.jf ? `${s.servidor}/Items/${v.jf}/Images/Primary?fillHeight=360&quality=90&${WEBP}` : '';
    const quando = i.PremiereDate ? new Date(i.PremiereDate).toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' }) : '';
    const sub = [quando, tipo === 'tv' ? (p.EpisodeInfo || '').split(' - ')[0] : ''].filter(Boolean).join(' · ');
    return [{ nome, sub, capa, jf: v.jf || undefined, tmdb: v.tmdb, tipo }];
  });
}

// usado só pelo login automático no Seerr (o site autoriza o código que o próprio Seerr pediu); o site não autoriza
// aparelhos de terceiros (PLANO §10: isso fica para os apps)
export const autorizarQuickConnect = (s: Sessao, codigo: string) =>
  pedir(s, 'POST', `/QuickConnect/Authorize?code=${encodeURIComponent(codigo)}&userId=${s.usuarioId}`);

// Sem início, conserva a chamada antiga. A Busca progressiva recebe página, total e cancelamento.
export function buscar(s: Sessao, termo: string, bibliotecaId: string): Promise<Item[]>;
export function buscar(s: Sessao, termo: string, bibliotecaId: string, inicio: number, limite?: number, sinal?: AbortSignal): Promise<PaginaBusca>;
export async function buscar(s: Sessao, termo: string, bibliotecaId: string, inicio?: number, limite = 30, sinal?: AbortSignal) {
  const caminho = `/Items?userId=${s.usuarioId}&parentId=${bibliotecaId}&searchTerm=${encodeURIComponent(termo)}` +
    `&recursive=true&includeItemTypes=Movie,Series&limit=${inicio === undefined ? 30 : limite}` +
    '&fields=Overview,ProductionYear,OfficialRating,CommunityRating&enableImageTypes=Primary&imageTypeLimit=1';
  if (inicio === undefined) return obter<{ Items: Item[] }>(s, caminho).then(d => d.Items);
  const r = await fetch(s.servidor + caminho + `&StartIndex=${inicio}&EnableTotalRecordCount=true`, {
    headers: { Authorization: cabecalho(s.token) }, signal: sinal,
  });
  if (r.status === 401) { notificarExpiracao(s); throw new Error('sessão vencida'); }
  if (!r.ok) throw new Error(`Busca: ${r.status}`);
  const d = await r.json() as PaginaBusca;
  return { Items: d.Items || [], TotalRecordCount: d.TotalRecordCount ?? (d.Items || []).length };
}
export const temArte = (_s: Sessao, i: Item) => !!(i.BackdropImageTags?.length && i.ImageTags?.Logo);
export const capaBiblioteca = (s: Sessao, i: Item) => i.ImageTags?.Primary ? imagem(s, i.Id, 'Primary', i.ImageTags.Primary, { largura: 480 }) : '';


const fluxosDoPlano = (s: Sessao, fluxos: Fluxo[]): FluxoPlano[] => fluxos.map(f => {
  const { DeliveryMethod, DeliveryUrl, ...dados } = f;
  return { ...dados, ...(f.Type === 'Subtitle' ? {
    entrega: DeliveryMethod === 'External' ? 'externa' : DeliveryMethod === 'Encode' ? 'gravada' : 'embutida',
    url: DeliveryUrl ? urlServidor(s, DeliveryUrl) : undefined,
  } : {}) };
});
const corpoReproducao = (o: OpcoesReproducao) => ({
  DeviceProfile: o.perfil, MaxStreamingBitrate: 140_000_000, AutoOpenLiveStream: true,
  AudioStreamIndex: o.audio, SubtitleStreamIndex: o.legenda,
  EnableDirectPlay: !o.semDireto, EnableDirectStream: true, EnableTranscoding: true,
});
async function preparar(s: Sessao, i: Pick<Item, 'Id'>, o: OpcoesReproducao): Promise<Plano> {
  const info = await infoReproducao(s, i.Id, corpoReproducao(o)), f = info.MediaSources[0];
  if (!f) {
    if (info.ErrorCode === 'NotAllowed') return { itemId: i.Id, url: '', tipo: 'direto', metodo: 'direto',
      sessaoReproducao: info.PlaySessionId, fonteId: '', inicioAplicado: 0, fluxos: [], fontesAss: [], erro: 'limiteTelas' };
    throw new Error(info.ErrorCode || 'Sem fonte de vídeo.');
  }
  const direto = f.SupportsDirectPlay && !o.semDireto;
  if (!direto && !f.TranscodingUrl) throw new Error('Este vídeo não pode ser tocado neste aparelho.');
  return { itemId: i.Id, url: direto ? urlDireta(s, i.Id, f, info.PlaySessionId) : urlServidor(s, f.TranscodingUrl!),
    tipo: direto ? 'direto' : 'hls', metodo: direto ? 'direto' : f.SupportsDirectStream ? 'remux' : 'conversao',
    sessaoReproducao: info.PlaySessionId, fonteId: f.Id, container: f.Container, duracaoTicks: f.RunTimeTicks,
    inicioAplicado: 0, fluxos: fluxosDoPlano(s, f.MediaStreams),
    fontesAss: (f.MediaAttachments || []).filter(a => a.DeliveryUrl && /font|ttf|otf|woff/i.test(`${a.MimeType} ${a.FileName} ${a.Codec}`))
      .slice(0, 8).map(a => urlServidor(s, a.DeliveryUrl!)),
    audioPadrao: f.DefaultAudioStreamIndex, legendaPadrao: f.DefaultSubtitleStreamIndex,
  };
}
// Relê apenas faixas; não cria nem troca a sessão/plano em reprodução.
async function faixas(s: Sessao, p: Plano, o: OpcoesReproducao): Promise<FluxoPlano[]> {
  const info = await infoReproducao(s, p.itemId, corpoReproducao(o));
  const lista = info.MediaSources[0]?.MediaStreams;
  if (!lista) throw new Error('sem lista de faixas');
  return fluxosDoPlano(s, lista);
}
function relatar(s: Sessao, p: Plano, fase: 'inicio' | 'progresso' | 'fim', r: PosicaoRelato) {
  return relatarJellyfin(s, fase, { ItemId: p.itemId, MediaSourceId: p.fonteId, PlaySessionId: p.sessaoReproducao,
    PositionTicks: r.posicaoTicks, IsPaused: r.pausado, PlayMethod: p.metodo === 'direto' ? 'DirectPlay' : p.metodo === 'remux' ? 'DirectStream' : 'Transcode',
    AudioStreamIndex: r.audio, SubtitleStreamIndex: r.legenda, CanSeek: true });
}
// Direto não abre conversão no servidor: nada a encerrar.
const parar = (s: Sessao, p: Plano) => p.tipo === 'hls' ? pararConversao(s, p.sessaoReproducao) : Promise.resolve();

export const similares = (s: Sessao, id: string) => obter<{ Items: Item[] }>(s,
  `/Items/${encodeURIComponent(id)}/Similar?userId=${encodeURIComponent(s.usuarioId)}&limit=12&fields=PrimaryImageAspectRatio`).then(d => d.Items);
export const trailers = (s: Sessao, id: string) => obter<Item[]>(s, `/Items/${encodeURIComponent(id)}/LocalTrailers?userId=${encodeURIComponent(s.usuarioId)}`);
const capacidadesJellyfin = Object.freeze({ favoritos: true, trocarSenha: true, foto: true, legendasRemotas: true, capitulos: true, emAlta: true, emBreve: true, similares: true, trailersLocais: true, previas: true });
export const jellyfin: ApiServidor = {
  similares, trailers, previaImagem: previaJellyfin,
  bibliotecas,
  bibliotecasDeVideo,
  continuar,
  proximos,
  novidades,
  destaque: paraDestaque,
  daBiblioteca,
  daColecao,
  favoritos: favoritosDe,
  buscar,
  porIds,
  item,
  temporadas,
  episodios,
  proximoDaSerie,
  seguinte,
  anterior,
  emAlta,
  emBreve,
  capaBiblioteca,
  capa,
  fundo,
  logo,
  paisagem,
  fotoPessoa,
  fotoUsuario,
  hashDe: (_s, i, tipo) => hashDe(i, tipo),
  temArte,
  marcarAssistido,
  favoritar,
  euMesmo,
  trocarSenha,
  trocarFoto,
  removerFoto,
  buscarLegendas,
  baixarLegenda,
  preparar, faixas, relatar, parar,
  capacidades: () => capacidadesJellyfin,
};
