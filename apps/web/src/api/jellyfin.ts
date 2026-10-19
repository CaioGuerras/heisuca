// Cliente Jellyfin mínimo, escrito do zero (só fetch). Cada função é um endpoint da API REST oficial.
const VERSAO = '0.1.0';
const CHAVE = 'heisuca.sessao';

export type Sessao = { servidor: string; token: string; usuarioId: string; nome: string };
export type Pessoa = { Id: string; Name: string; Role?: string; Type?: string; PrimaryImageTag?: string };
export type Item = {
  Id: string; Name: string; Type: string; SeriesName?: string; SeriesId?: string; ProductionYear?: number;
  Overview?: string; ImageTags?: Record<string, string>; BackdropImageTags?: string[];
  ParentBackdropItemId?: string; ParentBackdropImageTags?: string[]; SeriesPrimaryImageTag?: string;
  IndexNumber?: number; ParentIndexNumber?: number; CollectionType?: string; SeasonId?: string;
  OfficialRating?: string; CommunityRating?: number; RunTimeTicks?: number; Genres?: string[]; Taglines?: string[];
  ChildCount?: number; ImageBlurHashes?: unknown; ParentLogoItemId?: string; ParentLogoImageTag?: string;
  UserData?: { PlayedPercentage?: number; Played?: boolean; PlaybackPositionTicks?: number; UnplayedItemCount?: number; IsFavorite?: boolean };
  People?: Pessoa[];
  MediaStreams?: Fluxo[];
  MediaSources?: Fonte[];
  Width?: number; Height?: number; Container?: string;
};

function idAparelho(): string {
  let id = localStorage.getItem('heisuca.aparelho');
  if (!id) { id = Math.random().toString(36).slice(2) + Date.now().toString(36); localStorage.setItem('heisuca.aparelho', id); }
  return id;
}

function cabecalho(token?: string): string {
  const p = [`Client="Heisuca"`, `Device="Navegador"`, `DeviceId="${idAparelho()}"`, `Version="${VERSAO}"`];
  if (token) p.push(`Token="${token}"`);
  return 'MediaBrowser ' + p.join(', ');
}

const CHAVE_SERVIDORES = 'heisuca.servidores';

export type ServidorSalvo = {
  id: string;
  nome: string;
  url: string;
  usuario: string;
  token: string;
  usuarioId: string;
  tipo: 'jellyfin' | 'plex' | 'webdav' | 'smb';
};

export function servidoresSalvos(): ServidorSalvo[] {
  try {
    const list = JSON.parse(localStorage.getItem(CHAVE_SERVIDORES) || '[]');
    return Array.isArray(list) ? list : [];
  } catch {
    return [];
  }
}

export function salvarServidor(srv: ServidorSalvo): void {
  const lista = servidoresSalvos().filter(s => s.url !== srv.url);
  lista.unshift(srv);
  localStorage.setItem(CHAVE_SERVIDORES, JSON.stringify(lista));
}

export function alternarParaServidor(srv: ServidorSalvo): Sessao {
  const s: Sessao = { servidor: srv.url, token: srv.token, usuarioId: srv.usuarioId, nome: srv.usuario };
  localStorage.setItem(CHAVE, JSON.stringify(s));
  return s;
}

export function removerServidorSalvo(url: string): void {
  const lista = servidoresSalvos().filter(s => s.url !== url);
  localStorage.setItem(CHAVE_SERVIDORES, JSON.stringify(lista));
}

export function servidorPadrao(): string {
  return (import.meta.env.VITE_SERVIDOR as string | undefined) || location.origin;
}

export function sessaoSalva(): Sessao | null {
  try { return JSON.parse(localStorage.getItem(CHAVE) || 'null'); } catch { return null; }
}

export function sair(): void { localStorage.removeItem(CHAVE); }

export async function entrar(servidor: string, usuario: string, senha: string, nomeServidor?: string): Promise<Sessao> {
  const urlLimpa = servidor.replace(/\/+$/, '');
  const r = await fetch(urlLimpa + '/Users/AuthenticateByName', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: cabecalho() },
    body: JSON.stringify({ Username: usuario, Pw: senha }),
  });
  if (r.status === 401) throw new Error('Usuário ou senha incorretos.');
  if (!r.ok) throw new Error(`O servidor respondeu ${r.status}.`);
  const d = await r.json();
  const s: Sessao = { servidor: urlLimpa, token: d.AccessToken, usuarioId: d.User.Id, nome: d.User.Name };
  localStorage.setItem(CHAVE, JSON.stringify(s));

  const nomeFinal = nomeServidor || (urlLimpa.includes('docaio') ? 'CGSERVER' : 'Jellyfin');
  salvarServidor({
    id: urlLimpa,
    nome: nomeFinal,
    url: urlLimpa,
    usuario: d.User.Name,
    token: d.AccessToken,
    usuarioId: d.User.Id,
    tipo: 'jellyfin',
  });
  return s;
}

async function pedir(s: Sessao, metodo: string, caminho: string, corpo?: unknown, keepalive = false): Promise<Response> {
  const r = await fetch(s.servidor + caminho, {
    method: metodo, keepalive,
    headers: { Authorization: cabecalho(s.token), ...(corpo === undefined ? {} : { 'Content-Type': 'application/json' }) },
    body: corpo === undefined ? undefined : JSON.stringify(corpo),
  });
  if (r.status === 401) { sair(); location.reload(); }
  if (!r.ok) throw new Error(`${caminho.split('?')[0]}: ${r.status}`);
  return r;
}

const obter = <T,>(s: Sessao, caminho: string): Promise<T> => pedir(s, 'GET', caminho).then(r => r.json());

const CAMPOS = 'fields=Overview,PrimaryImageAspectRatio&enableImageTypes=Primary,Backdrop,Thumb,Logo';

export const bibliotecas = (s: Sessao) =>
  obter<{ Items: Item[] }>(s, `/UserViews?userId=${s.usuarioId}`).then(d => d.Items);

export const continuar = (s: Sessao) =>
  obter<{ Items: Item[] }>(s, `/UserItems/Resume?userId=${s.usuarioId}&limit=16&mediaTypes=Video&${CAMPOS}`)
    .then(d => d.Items);

export const novidades = (s: Sessao, bibliotecaId: string) =>
  obter<Item[]>(s, `/Items/Latest?userId=${s.usuarioId}&parentId=${bibliotecaId}&limit=20&${CAMPOS}`);

export function capa(s: Sessao, i: Item, altura = 360): string {
  if (i.ImageTags?.Primary) return `${s.servidor}/Items/${i.Id}/Images/Primary?fillHeight=${altura}&quality=90&tag=${i.ImageTags.Primary}`;
  if (i.SeriesId && i.SeriesPrimaryImageTag) return `${s.servidor}/Items/${i.SeriesId}/Images/Primary?fillHeight=${altura}&quality=90&tag=${i.SeriesPrimaryImageTag}`;
  return '';
}

export function fundo(s: Sessao, i: Item, largura = 1920): string {
  if (i.BackdropImageTags?.length) return `${s.servidor}/Items/${i.Id}/Images/Backdrop/0?fillWidth=${largura}&quality=80&tag=${i.BackdropImageTags[0]}`;
  if (i.ParentBackdropItemId && i.ParentBackdropImageTags?.length)
    return `${s.servidor}/Items/${i.ParentBackdropItemId}/Images/Backdrop/0?fillWidth=${largura}&quality=80&tag=${i.ParentBackdropImageTags[0]}`;
  return '';
}

export function logo(s: Sessao, i: Item, largura = 600): string {
  if (i.ImageTags?.Logo) return `${s.servidor}/Items/${i.Id}/Images/Logo?fillWidth=${largura}&quality=90&tag=${i.ImageTags.Logo}`;
  if (i.ParentLogoItemId && i.ParentLogoImageTag) return `${s.servidor}/Items/${i.ParentLogoItemId}/Images/Logo?fillWidth=${largura}&quality=90&tag=${i.ParentLogoImageTag}`;
  return '';
}

// miniatura 16:9 do episódio (cai na capa da série se faltar)
export function miniatura(s: Sessao, i: Item, largura = 480): string {
  if (i.ImageTags?.Primary) return `${s.servidor}/Items/${i.Id}/Images/Primary?fillWidth=${largura}&quality=85&tag=${i.ImageTags.Primary}`;
  return fundo(s, i, largura);
}

// ---- página do título ----
const CAMPOS_TITULO = 'fields=Overview,Genres,Taglines,PrimaryImageAspectRatio,ChildCount,People,MediaStreams,MediaSources&enableImageTypes=Primary,Backdrop,Thumb,Logo';

export const item = (s: Sessao, id: string) => obter<Item>(s, `/Items/${id}?userId=${s.usuarioId}&${CAMPOS_TITULO}`);

export function fotoPessoa(s: Sessao, p: { Id?: string; Name: string; PrimaryImageTag?: string }, tamanho = 160): string {
  if (p.Id && p.PrimaryImageTag) return `${s.servidor}/Items/${p.Id}/Images/Primary?fillWidth=${tamanho}&quality=85&tag=${p.PrimaryImageTag}`;
  return `${s.servidor}/Persons/${encodeURIComponent(p.Name)}/Images/Primary?fillWidth=${tamanho}&quality=85`;
}

export function fotoUsuario(s: Sessao, tamanho = 120): string {
  return `${s.servidor}/Users/${s.usuarioId}/Images/Primary?fillWidth=${tamanho}&quality=90`;
}

export const temporadas = (s: Sessao, serieId: string) =>
  obter<{ Items: Item[] }>(s, `/Shows/${serieId}/Seasons?userId=${s.usuarioId}&fields=ChildCount`).then(d => d.Items);

export const episodios = (s: Sessao, serieId: string, temporadaId: string) =>
  obter<{ Items: Item[] }>(s, `/Shows/${serieId}/Episodes?userId=${s.usuarioId}&seasonId=${temporadaId}&fields=Overview,MediaStreams&enableImageTypes=Primary,Backdrop,Thumb`)
    .then(d => d.Items);

export const proximoDaSerie = (s: Sessao, serieId: string) =>
  obter<{ Items: Item[] }>(s, `/Shows/NextUp?userId=${s.usuarioId}&seriesId=${serieId}&limit=1&enableResumable=true&fields=Overview`)
    .then(d => d.Items[0] ?? null);

// episódio seguinte a este na ordem da série (para o "Próximo episódio" do player)
export const seguinte = (s: Sessao, ep: Item) =>
  obter<{ Items: Item[] }>(s, `/Shows/${ep.SeriesId}/Episodes?userId=${s.usuarioId}&startItemId=${ep.Id}&limit=2`)
    .then(d => d.Items[1] ?? null);

export const marcarAssistido = (s: Sessao, id: string, sim: boolean) =>
  pedir(s, sim ? 'POST' : 'DELETE', `/UserPlayedItems/${id}?userId=${s.usuarioId}`).then(r => r.json());

export const marcarFavorito = (s: Sessao, id: string, sim: boolean) =>
  pedir(s, sim ? 'POST' : 'DELETE', `/UserFavoriteItems/${id}?userId=${s.usuarioId}`).then(r => r.json());

// ---- reprodução ----
export type Fluxo = {
  Index: number; Type: 'Video' | 'Audio' | 'Subtitle' | string; Codec?: string; Language?: string; DisplayTitle?: string;
  Title?: string; IsDefault?: boolean; IsForced?: boolean; IsExternal?: boolean; IsTextSubtitleStream?: boolean;
  DeliveryMethod?: 'External' | 'Encode' | 'Embed' | 'Hls' | 'Drop'; DeliveryUrl?: string; Channels?: number;
};
export type Fonte = {
  Id: string; Container?: string; RunTimeTicks?: number; SupportsDirectPlay: boolean; SupportsDirectStream: boolean;
  SupportsTranscoding: boolean; TranscodingUrl?: string; MediaStreams: Fluxo[];
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

// ---- navegação: bibliotecas, busca, favoritos, Em alta, Em breve (mesmas fontes do site atual) ----
const CAMPOS_GRADE = 'fields=PrimaryImageAspectRatio,Overview&enableImageTypes=Primary,Backdrop,Logo';

export const daBiblioteca = (s: Sessao, bibliotecaId: string, inicio = 0, limite = 60) =>
  obter<{ Items: Item[]; TotalRecordCount: number }>(s, `/Items?userId=${s.usuarioId}&parentId=${bibliotecaId}&recursive=true` +
    `&includeItemTypes=Movie,Series,BoxSet&sortBy=DateCreated,SortName&sortOrder=Descending&startIndex=${inicio}&limit=${limite}&${CAMPOS_GRADE}`);

export const buscarAcervo = (s: Sessao, termo: string) =>
  obter<{ Items: Item[] }>(s, `/Items?userId=${s.usuarioId}&searchTerm=${encodeURIComponent(termo)}&recursive=true` +
    `&includeItemTypes=Movie,Series&limit=40&${CAMPOS_GRADE}`).then(d => d.Items);

export const favoritos = (s: Sessao) =>
  obter<{ Items: Item[] }>(s, `/Items?userId=${s.usuarioId}&filters=IsFavorite&recursive=true&includeItemTypes=Movie,Series,Episode` +
    `&sortBy=SortName&${CAMPOS_GRADE}`).then(d => d.Items);

export const porIds = (s: Sessao, ids: string[]) => ids.length
  ? obter<{ Items: Item[] }>(s, `/Items?userId=${s.usuarioId}&ids=${ids.join(',')}&${CAMPOS_GRADE}`).then(d => d.Items)
  : Promise.resolve([] as Item[]);

// Top 10 do que temos, na ordem das tendências da semana (cgf-em-alta, cron diário; o site atual usa o mesmo arquivo)
export async function emAlta(s: Sessao): Promise<{ titulo: string; itens: Item[] }> {
  const j = await fetch(`${s.servidor}/cgflix/emalta.json?t=${Math.floor(Date.now() / 1800000)}`).then(r => r.json()) as { titulo?: string; itens?: { id: string }[] };
  const ids = (j.itens || []).map(i => i.id).filter(id => /^[0-9a-f]{32}$/.test(id));
  const itens = await porIds(s, ids);
  const ordem = new Map(ids.map((id, n) => [id, n]));
  return { titulo: j.titulo || 'Em alta no Brasil', itens: itens.sort((a, b) => (ordem.get(a.Id) ?? 99) - (ordem.get(b.Id) ?? 99)) };
}

// Em breve: calendário do Sonarr/Radarr pelo plugin Home Screen Sections; o mapa embreve.json (cgf-embreve) diz, por id,
// o item do Jellyfin (temos → título) ou o TMDB (não temos → pedir). Mesma lógica do site atual.
export type EmBreve = { nome: string; sub: string; capa: string; jf?: string; tmdb?: number; tipo: 'tv' | 'movie' };
type Secao = { Items?: { Name?: string; SeriesName?: string; PremiereDate?: string; ProviderIds?: Record<string, string>; Id?: string; ImageTags?: Record<string, string> }[] };
let mapaEmBreve: Promise<{ m: Record<string, { jf: string | null; tmdb?: number }>; s: Record<string, { jf: string | null; tmdb?: number; nome?: string }> }> | null = null;
export async function emBreve(s: Sessao, tipo: 'tv' | 'movie'): Promise<EmBreve[]> {
  mapaEmBreve ??= fetch(`${s.servidor}/cgflix/embreve.json?t=${Math.floor(Date.now() / 600000)}`).then(r => r.json());
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

export const autorizarQuickConnect = (s: Sessao, codigo: string) =>
  pedir(s, 'POST', `/QuickConnect/Authorize?code=${encodeURIComponent(codigo)}&userId=${s.usuarioId}`);
