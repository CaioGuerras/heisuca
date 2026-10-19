// Cliente Jellyfin mínimo, escrito do zero (só fetch). Cada função é um endpoint da API REST oficial (10.9+).
// Regra do PLANO §1.7: só aparece dado que o servidor tem; nada de valor inventado na falta.
const VERSAO = '0.2.0';

export type Sessao = {
  servidor: string; token: string; usuarioId: string; nome: string;
  servidorId?: string; nomeServidor?: string; fotoTag?: string;
};
export type Hashes = Partial<Record<'Primary' | 'Backdrop' | 'Thumb' | 'Logo' | 'Banner', Record<string, string>>>;
export type Pessoa = { Id: string; Name: string; Role?: string; Type?: string; PrimaryImageTag?: string };
export type Capitulo = { Name?: string; StartPositionTicks: number };
export type Item = {
  Id: string; Name: string; Type: string; SeriesName?: string; SeriesId?: string; SeasonId?: string; SeasonName?: string;
  ProductionYear?: number; PremiereDate?: string; EndDate?: string; Status?: string; Overview?: string;
  ImageTags?: Record<string, string>; BackdropImageTags?: string[]; ImageBlurHashes?: Hashes;
  ParentBackdropItemId?: string; ParentBackdropImageTags?: string[]; ParentThumbItemId?: string; ParentThumbImageTag?: string;
  SeriesPrimaryImageTag?: string; ParentLogoItemId?: string; ParentLogoImageTag?: string; ParentId?: string;
  IndexNumber?: number; ParentIndexNumber?: number; CollectionType?: string; ChildCount?: number;
  OfficialRating?: string; CommunityRating?: number; RunTimeTicks?: number; Genres?: string[]; Taglines?: string[];
  Studios?: { Name: string }[]; People?: Pessoa[]; Chapters?: Capitulo[]; MediaStreams?: Fluxo[];
  UserData?: { PlayedPercentage?: number; Played?: boolean; PlaybackPositionTicks?: number; UnplayedItemCount?: number; IsFavorite?: boolean };
};

export function idAparelho(): string {
  let id = '';
  try { id = localStorage.getItem('heisuca.aparelho') || ''; } catch { /* modo privado */ }
  if (!id) { id = Math.random().toString(36).slice(2) + Date.now().toString(36); try { localStorage.setItem('heisuca.aparelho', id); } catch { /* nada */ } }
  return id;
}

export function cabecalho(token?: string): string {
  const p = [`Client="Heisuca"`, `Device="Navegador"`, `DeviceId="${idAparelho()}"`, `Version="${VERSAO}"`];
  if (token) p.push(`Token="${token}"`);
  return 'MediaBrowser ' + p.join(', ');
}

// 401 = a sessão venceu (senha trocada em outro aparelho, token apagado): o app volta para a entrada.
let aoExpirar: (() => void) | null = null;
export const quandoExpirar = (f: (() => void) | null) => { aoExpirar = f; };

export async function pedir(s: Sessao, metodo: string, caminho: string, corpo?: unknown, keepalive = false, tipo = 'application/json'): Promise<Response> {
  const r = await fetch(s.servidor + caminho, {
    method: metodo, keepalive,
    headers: { Authorization: cabecalho(s.token), ...(corpo === undefined ? {} : { 'Content-Type': tipo }) },
    body: corpo === undefined ? undefined : typeof corpo === 'string' ? corpo : JSON.stringify(corpo),
  });
  if (r.status === 401) { aoExpirar?.(); throw new Error('sessão vencida'); }
  if (!r.ok) throw new Error(`${caminho.split('?')[0]}: ${r.status}`);
  return r;
}
export const obter = <T,>(s: Sessao, caminho: string): Promise<T> => pedir(s, 'GET', caminho).then(r => r.json());

// ---- imagens (o servidor redimensiona; o tag faz o cache do navegador valer para sempre) ----
type Medida = { largura?: number; altura?: number; qualidade?: number };
export function imagem(s: Sessao, id: string, tipo: string, tag?: string, m: Medida = {}, indice?: number): string {
  const q = [m.largura && `fillWidth=${Math.round(m.largura)}`, m.altura && `fillHeight=${Math.round(m.altura)}`,
    `quality=${m.qualidade ?? 85}`, tag && `tag=${tag}`].filter(Boolean).join('&');
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
  s.fotoTag ? `${s.servidor}/Users/${s.usuarioId}/Images/Primary?fillWidth=${largura}&quality=90&tag=${s.fotoTag}` : '';

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

// biblioteca inteira em ordem alfabética (sem ordenar nem filtrar: PLANO §6)
export const daBiblioteca = (s: Sessao, bibliotecaId: string, inicio = 0, limite = 60) =>
  obter<{ Items: Item[]; TotalRecordCount: number }>(s, `/Items?userId=${s.usuarioId}&parentId=${bibliotecaId}&recursive=true` +
    `&includeItemTypes=Movie,Series,BoxSet&sortBy=SortName&sortOrder=Ascending&startIndex=${inicio}&limit=${limite}&${CAMPOS}`);

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
const CAMPOS_TITULO = `fields=Overview,Genres,Taglines,Studios,People,Chapters,MediaStreams,ChildCount,PrimaryImageAspectRatio,` +
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
export type Usuario = { Id: string; Name: string; HasPassword?: boolean; PrimaryImageTag?: string;
  Policy?: { IsAdministrator?: boolean; EnableSubtitleManagement?: boolean } };
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
export type LegendaRemota = { Id: string; Name?: string; ProviderName?: string; Format?: string; DownloadCount?: number;
  ThreeLetterISOLanguageName?: string; IsHashMatch?: boolean; Comment?: string };
export const buscarLegendas = (s: Sessao, itemId: string, idioma: 'pob' | 'por' | string) =>
  obter<LegendaRemota[]>(s, `/Items/${itemId}/RemoteSearch/Subtitles/${idioma}`);
export const baixarLegenda = (s: Sessao, itemId: string, legendaId: string) =>
  pedir(s, 'POST', `/Items/${itemId}/RemoteSearch/Subtitles/${encodeURIComponent(legendaId)}`);

// ---- reprodução ----
export type Fluxo = {
  Index: number; Type: 'Video' | 'Audio' | 'Subtitle' | string; Codec?: string; Language?: string; DisplayTitle?: string;
  Title?: string; IsDefault?: boolean; IsForced?: boolean; IsExternal?: boolean; IsTextSubtitleStream?: boolean;
  DeliveryMethod?: 'External' | 'Encode' | 'Embed' | 'Hls' | 'Drop'; DeliveryUrl?: string; Channels?: number; ChannelLayout?: string;
  Width?: number; Height?: number; Profile?: string; RealFrameRate?: number; AverageFrameRate?: number; BitRate?: number;
  VideoRange?: string; VideoRangeType?: string; SampleRate?: number; AspectRatio?: string; BitDepth?: number;
};
export type Fonte = {
  Id: string; Container?: string; RunTimeTicks?: number; SupportsDirectPlay: boolean; SupportsDirectStream: boolean;
  SupportsTranscoding: boolean; TranscodingUrl?: string; MediaStreams: Fluxo[]; Size?: number; Bitrate?: number;
  DefaultAudioStreamIndex?: number; DefaultSubtitleStreamIndex?: number;
  MediaAttachments?: { Codec?: string; MimeType?: string; FileName?: string; DeliveryUrl?: string }[];
};
export type Reproducao = { PlaySessionId: string; MediaSources: Fonte[]; ErrorCode?: string };

export const infoReproducao = (s: Sessao, id: string, corpo: Record<string, unknown>) =>
  pedir(s, 'POST', `/Items/${id}/PlaybackInfo?userId=${s.usuarioId}`, { UserId: s.usuarioId, ...corpo }).then(r => r.json() as Promise<Reproducao>);

export function urlDireta(s: Sessao, id: string, f: Fonte, sessaoReproducao: string): string {
  return `${s.servidor}/Videos/${id}/stream?static=true&mediaSourceId=${f.Id}&playSessionId=${sessaoReproducao}` +
    `&deviceId=${idAparelho()}&api_key=${s.token}`;
}

export const urlServidor = (s: Sessao, caminho: string) =>
  s.servidor + caminho + (caminho.includes('api_key=') || caminho.includes('ApiKey=') ? '' : `${caminho.includes('?') ? '&' : '?'}api_key=${s.token}`);

export type Relato = {
  ItemId: string; MediaSourceId: string; PlaySessionId: string; PositionTicks: number; IsPaused: boolean;
  PlayMethod: 'DirectPlay' | 'DirectStream' | 'Transcode'; AudioStreamIndex?: number; SubtitleStreamIndex?: number; CanSeek: boolean;
};
export const relatar = (s: Sessao, fase: 'inicio' | 'progresso' | 'fim', r: Relato) =>
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
export type EmBreve = { nome: string; sub: string; capa: string; jf?: string; tmdb?: number; tipo: 'tv' | 'movie' };
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
      : v.jf ? `${s.servidor}/Items/${v.jf}/Images/Primary?fillHeight=360&quality=90` : '';
    const quando = i.PremiereDate ? new Date(i.PremiereDate).toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' }) : '';
    const sub = [quando, tipo === 'tv' ? (p.EpisodeInfo || '').split(' - ')[0] : ''].filter(Boolean).join(' · ');
    return [{ nome, sub, capa, jf: v.jf || undefined, tmdb: v.tmdb, tipo }];
  });
}

// usado só pelo login automático no Seerr (o site autoriza o código que o próprio Seerr pediu); o site não autoriza
// aparelhos de terceiros (PLANO §10: isso fica para os apps)
export const autorizarQuickConnect = (s: Sessao, codigo: string) =>
  pedir(s, 'POST', `/QuickConnect/Authorize?code=${encodeURIComponent(codigo)}&userId=${s.usuarioId}`);
