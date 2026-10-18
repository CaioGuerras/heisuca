// Cliente Jellyfin mínimo, escrito do zero (só fetch). Cada função é um endpoint da API REST oficial.
const VERSAO = '0.1.0';
const CHAVE = 'heisuca.sessao';

export type Sessao = { servidor: string; token: string; usuarioId: string; nome: string };
export type Item = {
  Id: string; Name: string; Type: string; SeriesName?: string; SeriesId?: string; ProductionYear?: number;
  Overview?: string; ImageTags?: Record<string, string>; BackdropImageTags?: string[];
  ParentBackdropItemId?: string; ParentBackdropImageTags?: string[]; SeriesPrimaryImageTag?: string;
  IndexNumber?: number; ParentIndexNumber?: number; CollectionType?: string; SeasonId?: string;
  OfficialRating?: string; CommunityRating?: number; RunTimeTicks?: number; Genres?: string[]; Taglines?: string[];
  ChildCount?: number; ImageBlurHashes?: unknown; ParentLogoItemId?: string; ParentLogoImageTag?: string;
  UserData?: { PlayedPercentage?: number; Played?: boolean; PlaybackPositionTicks?: number; UnplayedItemCount?: number };
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

export function servidorPadrao(): string {
  return (import.meta.env.VITE_SERVIDOR as string | undefined) || location.origin;
}

export function sessaoSalva(): Sessao | null {
  try { return JSON.parse(localStorage.getItem(CHAVE) || 'null'); } catch { return null; }
}

export function sair(): void { localStorage.removeItem(CHAVE); }

export async function entrar(servidor: string, usuario: string, senha: string): Promise<Sessao> {
  const r = await fetch(servidor + '/Users/AuthenticateByName', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: cabecalho() },
    body: JSON.stringify({ Username: usuario, Pw: senha }),
  });
  if (r.status === 401) throw new Error('Usuário ou senha incorretos.');
  if (!r.ok) throw new Error(`O servidor respondeu ${r.status}.`);
  const d = await r.json();
  const s: Sessao = { servidor, token: d.AccessToken, usuarioId: d.User.Id, nome: d.User.Name };
  localStorage.setItem(CHAVE, JSON.stringify(s));
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

const CAMPOS = 'fields=Overview,PrimaryImageAspectRatio&enableImageTypes=Primary,Backdrop,Thumb';

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
const CAMPOS_TITULO = 'fields=Overview,Genres,Taglines,PrimaryImageAspectRatio,ChildCount&enableImageTypes=Primary,Backdrop,Thumb,Logo';

export const item = (s: Sessao, id: string) => obter<Item>(s, `/Items/${id}?userId=${s.usuarioId}&${CAMPOS_TITULO}`);

export const temporadas = (s: Sessao, serieId: string) =>
  obter<{ Items: Item[] }>(s, `/Shows/${serieId}/Seasons?userId=${s.usuarioId}&fields=ChildCount`).then(d => d.Items);

export const episodios = (s: Sessao, serieId: string, temporadaId: string) =>
  obter<{ Items: Item[] }>(s, `/Shows/${serieId}/Episodes?userId=${s.usuarioId}&seasonId=${temporadaId}&fields=Overview&enableImageTypes=Primary,Backdrop,Thumb`)
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
